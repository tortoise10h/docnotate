# Start Building Button on the Document View

## Goal
Let the user kick off an agent build session directly from the document view, instead of going to the agent console to type the prompt themselves. A **floating rocket button** below the "Copy comments" button opens a popup; the user can type an optional custom message, confirm/edit the working directory, **choose which agent to build with**, and submit. On submit we spawn a **new window in the user's default terminal** running the chosen agent with a seeded message that always ends with:

```
Please start building with the plan <absolute path to the plan file>
```

For v1 the only implemented agent is **OpenCode**, but the design is fully wired for multi-agent:
- A **registry** of available agents, each with its **own launcher model**.
- The popup **lets the user pick an agent** before submitting (the dropdown ships for v1, only containing OpenCode — adding an agent later is one registry + one launcher class, no controller/view changes).
- A **config file** sets the **default agent** so users don't have to pick every time.

## Context
- The plan being built IS the document being viewed — `@document.file_path` (the file the user pasted on the home page and is currently reviewing in DocNotate).
- The comment navigation rail lives in `app/views/documents/show.html.erb:68-88` — `.document__comment-nav` with prev / count / next / divider / **Copy comments button**. The new **Start building** button sits in a **separate block directly under the Copy comments button** (not inside the same `.document__comment-nav` block), as a floating round green button with a rocket icon and a hover tooltip.
- `opencode run -i "<message>"` runs an interactive session seeded with the message (verified via `opencode run --help`): the `-i` flag puts it in "direct interactive split-footer mode", which is what we want — the spawned terminal stays interactive after the seeded message is sent. `opencode run` without `-i` would print output and exit; not what we want.
- OpenCode operates on the directory the process is launched in, so we `cd <dir> && opencode run -i ...`.
- Rails runs locally as a single-user local-first app (see `README.md:53-57`). No auth; the server process can read files / launch subprocesses on the user's machine. v1 does not need a background job — terminal spawn is fast and one-shot.
- Project conventions to honor (from `AGENTS.md`):
  - No service objects. Logic that's too general / not tied to a specific AR model goes in a **PORO extending ActiveModel** for validation. → `AgentSession` PORO.
  - Model-specific modules scoped under a pluralized namespace under `app/models/<plural>/`. → `AgentSessions::*` launchers and `AgentSessions::Registry`.
  - Controllers follow **37signals style**: when logic is nested, create a dedicated controller (not stuff more actions into `DocumentsController`). → `Agents::BuildersController`.
  - Pure CSS with BEM, organized as foundation / components / pages. New `document__start-build*` and `document__modal*` blocks go in `app/assets/stylesheets/pages/document.css`.
  - Hotwire (Turbo + Stimulus), importmap-registered controllers.
  - Minitest; only necessary tests, no JS test harness exists.

## Multi-agent design (built ahead, only OpenCode shipped for v1)

### Registry — `app/models/agent_sessions/registry.rb` (new)
```ruby
module AgentSessions
  class Registry
    DEFAULT_AGENT = Rails.configuration.x.docnotate.default_agent.presence || "opencode"

    # key => launcher class. Adding an agent = one entry here + one launcher file.
    LAUNCHERS = {
      "opencode" => AgentSessions::OpenCodeLauncher
    }.freeze

    def self.all
      LAUNCHERS.keys.map { |key| { key: key, name: key.humanize } }
    end

    def self.default
      DEFAULT_AGENT
    end

    def self.launcher_for(key)
      LAUNCHERS.fetch(key) { raise ArgumentError, "Unknown agent: #{key}" }
    end
  end
end
```
`Registry.all` is what the popup's `<select>` iterates to render options, so future agents appear automatically once registered.

### Default-agent config — `config/agents.yml` (new) + initializer
```yaml
# config/agents.yml
default: opencode
```
```ruby
# config/initializers/agents.rb
agents_config = YAML.load_file(Rails.root.join("config/agents.yml")) rescue {}
Rails.application.config.x.docnotate.default_agent = agents_config["default"] || "opencode"
```
Tuning the default is a one-line change in `config/agents.yml` + restart — no code change. This is also the natural hook for a future "Settings" UI to write this file.

### Per-agent launcher models — `app/models/agent_sessions/<agent>_launcher.rb`
Each agent ships as its own PORO launcher under the `AgentSessions` namespace. v1 contains only:
- `app/models/agent_sessions/open_code_launcher.rb`

Adding a new agent = new launcher file + one line in `Registry::LAUNCHERS`. The `AgentSession` form PORO and the controller never change.

## Workflow

### 1. Routes — `config/routes.rb`
37signals style: nest the build action under a dedicated namespaced controller.

```ruby
Rails.application.routes.draw do
  root "home#index"

  resources :documents, only: [:show] do
    collection do
      get :open
    end
    namespace :agents do
      resources :builders, only: [:create]
    end
    resources :comments, only: [:create, :destroy]
  end
end
```
This produces `POST /documents/:document_id/agents/builders`, handled by `Agents::BuildersController#create` (`app/controllers/agents/builders_controller.rb`). `DocumentsController` stays thin — no `start_build` action bolted onto it.

### 2. PORO form object — `app/models/agent_session.rb` (new)
Extends `ActiveModel` for validation (per AGENTS.md). Holds everything needed to build and launch the session, including the **chosen agent**:

```ruby
class AgentSession
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :document, :custom_prompt, :working_dir, :agent

  validates :document,    presence: true
  validates :working_dir, presence: true
  validate  :working_dir_must_exist
  validates :custom_prompt, length: { maximum: 4000 }, allow_blank: true
  validates :agent, inclusion: { in: ->(_){ AgentSessions::Registry::LAUNCHERS.keys } }

  def initialize(attrs = {})
    super(attrs)
    self.agent ||= AgentSessions::Registry.default
  end

  def file_path
    document&.file_path
  end

  def build_prompt
    [custom_prompt&.strip, "Please start building with the plan #{file_path}"]
      .reject(&:blank?)
      .join("\n\n")
  end

  def start
    return false unless valid?
    AgentSessions::Registry.launcher_for(agent).new(self).launch
  end

  private

  def working_dir_must_exist
    return if working_dir.blank?
    errors.add(:working_dir, "does not exist") unless Dir.exist?(working_dir)
  end
end
```
The `agent` validation reads from the Registry, so new agents become valid choices the moment they register — no code change here when adding agents.

### 3. OpenCode launcher — `app/models/agent_sessions/open_code_launcher.rb` (new)
Builds the shell command and spawns the terminal. **Only WezTerm and Apple Terminal are supported for v1** (iTerm is intentionally skipped); if WezTerm isn't detected, fall back to a new Apple Terminal window.

```ruby
require "open3"

module AgentSessions
  class OpenCodeLauncher
    def initialize(session)
      @session = session
    end

    def launch
      adapter.spawn(working_dir, shell_command)
    end

    private

    def shell_command
      %{cd #{sh_quote(working_dir)} && opencode run -i #{sh_quote(@session.build_prompt)}}
    end

    def working_dir
      @session.working_dir
    end

    # ENV["TERM_PROGRAM"] is inherited from the shell that launched the Rails server,
    # which is itself launched by the user's terminal. So the value reflects the
    # terminal the user prefers for development — e.g. run `bin/rails dev` from
    # WezTerm => ENV["TERM_PROGRAM"] == "WezTerm"; from Ghostty => "ghostty";
    # from Terminal.app => "Apple_Terminal". If the server is launched from a
    # context without a terminal (launchd, a daemon, an IDE without a TTY),
    # TERM_PROGRAM is unset and we fall back to Terminal.app.
    def adapter
      case ENV["TERM_PROGRAM"]
      when "WezTerm" then WezTermAdapter
      else                 TerminalAdapter # Apple Terminal fallback (always available on macOS)
      end
    end

    def sh_quote(s)
      "'" + s.to_s.gsub("'", "'\\''") + "'"
    end

    module TerminalAdapter
      def self.spawn(cwd, sh_cmd)
        script = <<~OSA
          tell application "Terminal"
            do script "#{osa_escape(sh_cmd)}"
            activate
          end tell
        OSA
        Open3.capture3("osascript", "-e", script)
        true
      rescue
        false
      end

      def self.osa_escape(s)
        s.to_s.gsub("\\", "\\\\").gsub('"', '\\"')
      end
    end

    module WezTermAdapter
      def self.spawn(cwd, sh_cmd)
        Open3.capture3("wezterm", "cli", "spawn", "--cwd", cwd, "--", "sh", "-c", sh_cmd)
        true
      rescue
        false
      end
    end
  end
end
```
Notes:
- Double-layered escaping (`sh_quote` for the shell string + `osa_escape` for AppleScript) is the injection-safe core; embedded quotes in the user's custom prompt can't break out of either layer.
- `Open3.capture3` returns whether the spawn succeeded so the controller can set a flash on failure (plain `system` would swallow errors).
- Adding iTerm later = adding an `ITermAdapter` module and a `when "iTerm.app"` line — already-shaped seam, deliberately left unwired for v1.

### 4. Controller — `app/controllers/agents/builders_controller.rb` (new)
37signals style: small, dedicate, RESTful `create`.

```ruby
module Agents
  class BuildersController < ApplicationController
    def create
      document = Document.find(params[:document_id])
      session = AgentSession.new(
        document:      document,
        custom_prompt:  params[:custom_prompt],
        working_dir:    params[:working_dir].presence || File.dirname(document.file_path),
        agent:          params[:agent].presence || AgentSessions::Registry.default
      )

      if session.start
        redirect_to open_documents_path(file_path: document.file_path), notice: "Started #{session.agent.humanize}"
      else
        redirect_to open_documents_path(file_path: document.file_path),
                    alert: session.errors.full_messages.to_sentence
      end
    end
  end
end
```
Synchronous spawn, no background job for v1. Success and failure both redirect back to the document with a flash.

### 5. View — `app/views/documents/show.html.erb`

#### Floating rocket button — in a separate block under the Copy comments button
The copy button is the last child of `.document__comment-nav` (lines `app/views/documents/show.html.erb:81-87`). Immediately after `.document__comment-nav` closes (and inside `.document__paper`), add a **separate** `.document__start-build-rail` block containing only the rocket button:

```erb
<div class="document__start-build-rail">
  <button type="button" class="document__start-build"
          data-tooltip="Start building with this plan"
          data-action="click->start-build#open"
          aria-label="Start building">
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-1.93.07-2.56a1.83 1.83 0 0 0-2.56.07z"/><path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"/><path d="M9 12H4s.55-3.03 2-4c1.62-1.16 5 0 7 2"/><path d="M12 15v5s3.03-.55 4-2c1.16-1.62 0-5-2-7"/></svg>
  </button>
</div>
```
- Green background (same color as selection highlight `#5fd47e`), white rocket icon, **no text**.
- Tooltip appears on hover explaining the button's purpose (CSS-only tooltip using the existing `data-tooltip` attribute pattern that the document title and copy buttons already use).
- Separate block (`.document__start-build-rail`) so it's visually and structurally independent of the comment nav — losing the comment nav (e.g. zero comments) doesn't affect the start-build button.

#### Wire the Stimulus controller
The document view's root `.document` element (line 1) gains `start-build`:
```erb
<div class="document" data-controller="scroll-to-top start-build">
```
At the end of `.document`, after `.document__paper` closes, render the modal partial:
```erb
<%= render "start_build_modal" %>
```

#### Modal partial — `app/views/documents/_start_build_modal.html.erb` (new)
Rendered inline, toggled by Stimulus. Includes the **agent selector** (multi-agent seam), the optional custom prompt, and the working-directory field with a parent-dir stepper.

```erb
<div class="document__modal-backdrop" data-start-build-target="backdrop"
     data-action="click->start-build#backdropClose keydown.esc@window->start-build#close">
  <form class="document__modal" data-start-build-target="modal"
        action="<%= agents_builders_path(@document) %>" method="post"
        data-turbo="true">
    <header class="document__modal-header">
      <h2 class="document__modal-title">Start building</h2>
      <button type="button" class="document__modal-close"
              data-action="click->start-build#close" aria-label="Close">&times;</button>
    </header>

    <label class="document__modal-label" for="agent">Agent</label>
    <select class="document__modal-select" id="agent" name="agent" data-start-build-target="agent">
      <% AgentSessions::Registry.all.each do |a| %>
        <option value="<%= a[:key] %>" <%= "selected" if a[:key] == AgentSessions::Registry.default %>>
          <%= a[:name] %>
        </option>
      <% end %>
    </select>

    <label class="document__modal-label" for="custom_prompt">Custom prompt (optional)</label>
    <textarea class="document__modal-textarea" id="custom_prompt" name="custom_prompt"
              placeholder="Add instructions before building..."
              data-start-build-target="customPrompt"></textarea>

    <label class="document__modal-label" for="working_dir">Working directory</label>
    <div class="document__modal-dir-row">
      <button type="button" class="document__modal-parent" data-action="click->start-build#parent"
              data-tooltip="Use parent directory">&larr;</button>
      <input class="document__modal-input" id="working_dir" name="working_dir"
             value="<%= File.dirname(@document.file_path) %>"
             data-start-build-target="workingDir">
    </div>

    <footer class="document__modal-actions">
      <button type="button" class="document__modal-cancel" data-action="click->start-build#close">Cancel</button>
      <button type="submit" class="button">Start</button>
    </footer>
  </form>
</div>
```
The `<select>` is populated from `AgentSessions::Registry.all`, so when a future agent registers, it shows up here for free. The "↑ parent" button steps the working-dir up one level via Stimulus so users can climb out of a nested plan dir to the project root without retyping; the field stays editable for custom edits.

The final `Please start building with the plan <path>` line is appended by `AgentSession#build_prompt` (PORO), **not** by the form/view — keeps that invariant in the model.

### 6. Stimulus controller — `app/javascript/controllers/start_build_controller.js` (new)
Auto-registered via the project's existing `eagerLoadControllersFrom` setup (no importmap change).

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "modal", "customPrompt", "workingDir", "agent"]

  open()          { this.backdropTarget.classList.add("document__modal-backdrop--open"); this.customPromptTarget.focus() }
  close()         { this.backdropTarget.classList.remove("document__modal-backdrop--open") }
  backdropClose(e) { if (e.target === this.backdropTarget) this.close() }

  parent() {
    const current = this.workingDirTarget.value.replace(/\/$/, "")
    if (current && current !== "/") {
      this.workingDirTarget.value = current.split("/").slice(0, -1).join("/") || "/"
    }
  }
}
```
Hidden via CSS; `.document__modal-backdrop--open` reveals it. Form is a normal Turbo-submitted POST that redirects on success/failure.

### 7. CSS — `app/assets/stylesheets/pages/document.css`
Append. Reuses `.button` for the submit. The tooltip reuses the existing `data-tooltip` CSS pattern already used by the document title and copy buttons (assumed present in the codebase; verify before finalizing — if not present, factor a small shared `.tooltip` rule into `components/`).

```css
/* Start building floating rocket button (under copy-comments) */
.document__start-build-rail {
  position: fixed;
  right: 24px;
  /* sits visually below the comment nav rail; nav rail bottom ≈ 132px from viewport bottom */
  bottom: 24px;
  z-index: 20;
}

.document__start-build {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 999px;
  background: #5fd47e;          /* same green as selection highlight */
  border: 1px solid #4dbb6a;
  color: #ffffff;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(46, 139, 74, 0.35);
  transition: background-color 0.15s ease, transform 0.1s ease;
}
.document__start-build:hover  { background: #4dbb6a; transform: translateY(-1px); }
.document__start-build:active { transform: translateY(0); }

/* Modal */
.document__modal-backdrop {
  display: none;
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.35);
  z-index: 100;
  align-items: center; justify-content: center;
}
.document__modal-backdrop--open { display: flex; }

.document__modal {
  width: min(480px, 90vw);
  background: #ffffff;
  border-radius: 16px;
  padding: 20px;
  display: flex; flex-direction: column; gap: 12px;
  box-shadow: 0 20px 50px rgba(0,0,0,0.25);
}
.document__modal-header  { display: flex; justify-content: space-between; align-items: center; }
.document__modal-title    { font-size: 1rem; font-weight: 600; margin: 0; }
.document__modal-close  { background: none; border: none; font-size: 1.25rem; cursor: pointer; line-height: 1; }
.document__modal-label  { font-size: 0.8125rem; color: #6b7280; }
.document__modal-textarea, .document__modal-input, .document__modal-select {
  width: 100%; border: 1px solid #e5e7eb; border-radius: 8px;
  padding: 8px 10px; font-size: 0.875rem; box-sizing: border-box; background: #fff;
}
.document__modal-textarea { min-height: 96px; resize: vertical; }
.document__modal-dir-row  { display: flex; gap: 8px; align-items: center; }
.document__modal-parent   {
  padding: 6px 10px; background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; cursor: pointer;
}
.document__modal-actions  { display: flex; justify-content: flex-end; gap: 8px; margin-top: 4px; }
.document__modal-cancel  { background: none; border: none; color: #6b7280; cursor: pointer; padding: 6px 12px; }
```

### 8. Tests — `test/`
Keep minimal per AGENTS.md.

- `test/models/agent_session_test.rb`
  - `build_prompt` returns just the plan line when `custom_prompt` is blank.
  - `build_prompt` puts the custom prompt first, blank line, then the plan line when present.
  - Invalid when `working_dir` doesn't exist; valid when it does.
  - Invalid `agent` (not in registry) → rejected; default agent applied when none given.
- `test/controllers/agents/builders_controller_test.rb`
  - Successful spawn (stub `AgentSession#start` to return `true`) → 302 redirect with notice.
  - Validation failure (stub to return `false` with errors) → 302 redirect with alert.
- Stub the launcher's `Open3.capture3` / `system` calls so tests don't actually spawn terminals.

## Behavior Summary
1. User opens any markdown plan in DocNotate.
2. Sees a green floating rocket button below the "Copy comments" button (hover tooltip: "Start building with this plan").
3. Click → modal opens with: **Agent dropdown** (only OpenCode for v1), optional custom-prompt textarea, working-directory field (defaulting to the plan's directory) + "↑ parent" button.
4. Submit posts `POST /documents/:id/agents/builders`.
5. `Agents::BuildersController#create` instantiates `AgentSession`, runs `#start`, which dispatches via `AgentSessions::Registry` to the agent's own launcher (e.g. `AgentSessions::OpenCodeLauncher`) → spawns a **new window in the user's detected terminal** (WezTerm, or Apple Terminal as fallback) running `cd <dir> && opencode run -i '<combined prompt>'`.
6. The final line of the prompt is always `Please start building with the plan <plan file absolute path>`.
7. User is redirected back to the document with a green `Started OpenCode` flash (or red alert on launch failure).

## Risks / Open questions
- **Terminal detection depends on where the Rails server runs (confirmed).** `ENV["TERM_PROGRAM"]` is inherited from the launching shell, which inherits it from the terminal app. Run `bin/rails dev` from WezTerm → `WezTerm`; from Ghostty → `ghostty`; from Terminal.app → `Apple_Terminal`; from an IDE/launchd without a TTY → unset → fall back to Terminal.app. **Action item for v1:** document this in the README so the user knows the build button spawns in "whatever terminal you launched DocNotate from."
- **AppleScript automation permission.** On first spawn macOS may prompt for permission to control Terminal.app. If denied, the spawn silently fails → user sees the alert flash and can manually launch `opencode run` from their own terminal. Acceptable for v1; documented edge case.
- **Synchronous spawn, no DB persistence for v1.** `agents/builders#create` runs the spawn inline and redirects. No `agent_sessions` table yet. The seam is intentional: when supporting history/multiple agents, add an `AgentSession < ApplicationRecord` migration and replace the PORO with the AR model — controller + launcher interfaces stay the same.
- **Single-platform (macOS) for v1.** Terminal adapters are macOS-only. Linux/Windows adapters later = new modules under `AgentSessions::` + extending the `adapter` switch; no controller/view changes.
- **Ghostty support.** v1 only handles `WezTerm` explicitly and falls back to Terminal.app for anything else (including Ghostty). If Ghostty should spawn its own window rather than Terminal.app, add a `GhosttyAdapter` + `when "ghostty"` line — but the fallback is acceptable for v1. Worth confirming with the user whether Ghostty-specific spawning is wanted now or can wait.
- **Tooltip CSS.** The plan assumes the existing `data-tooltip` styling used by the document title and copy buttons is reusable. Before finalizing, verify that rule lives in a shared location (e.g. a `components/tooltip.css` or within `foundation.css`); if it's inline per-element, factor a small shared `.tooltip` rule into `components/` so the rocket button and the modal's parent button both reuse it.
- **Working-dir validation timing.** PORO validates `Dir.exist?` at submit time. If the dir is removed between submit and launch, the spawn silently fails — acceptable for a local-first single-user tool.
- **Prompt size.** `custom_prompt` capped at 4000 chars in the PORO validation, well within shell ARG_MAX — no separate guard needed.