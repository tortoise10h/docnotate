---
name: plannotate
description: Plan a feature/task and open the resulting plan file in DocNotate for inline review. Use whenever the user invokes /plannotate, asks to "plan and annotate", "plan and review in DocNotate", or wants to plan a task and have the plan opened in the DocNotate web UI for commenting. Triggers on /plannotate or any request that combines planning a feature/implementation with opening the plan in DocNotate for review.
---

# Plannotate

Plan the user's task as you normally would, then write the plan to a markdown file under the project's `plans/` directory, and open that file in the local DocNotate web app so the user can annotate inline comments before handing feedback back to you.

## Why this exists

Planning usually happens in the agent TUI, then feedback in a separate tool forces context switching. By writing the plan to a file and popping it into DocNotate in one shot, the user can highlight and comment on the plan without leaving their flow — then paste all comments back into the TUI as a single follow-up prompt.

## Workflow

### 1. Plan

Do the planning the way you normally would for the task the user gave you:
- Explore the relevant parts of the codebase to ground the plan in reality (real file paths, existing conventions, current dependencies).
- Break the work into clear, ordered steps.
- Call out assumptions, risks, and open questions.

Keep the plan practical and specific to *this* codebase — no generic filler.

### 2. Clarify ambiguities

Review the task and your exploration. If anything is genuinely ambiguous or would meaningfully change the shape of the plan — scope boundaries, key design decisions, preferred approach among reasonable alternatives, business rules, target APIs/contracts — resolve it with the user *before* writing the plan file. Ping them all at once rather than one at a time.

Use the `question` (ask-questions) tool to surface the things worth clarifying, batched into a single tool call offering concrete options where useful. Don't pepper the user with trivial questions; only ask what would actually lead to a meaningfully different plan. Write short, clearly-worded question text and provide specific, actionable option labels (optionally with descriptions) so the user can decide fast.

Once the user answers, proceed to write the plan informed by their response. If after exploration there's nothing worth asking — or the user already gave enough detail — skip this step and go straight to writing the plan.

### 3. Write the plan to `plans/<plan_file>.md`

- The `plans/` directory is relative to the **project root** (the current working directory of the session). If it does not exist, create it.
- Pick a short, kebab-case filename derived from the task (e.g. `plans/add-jwt-auth.md`, `plans/refactor-connection-pool.md`). If the user named the file, use their name exactly.
- Write the plan as markdown. A reasonable structure:

  ```markdown
  # <Plan title>

  ## Goal
  <one or two sentences>

  ## Context
  <what you found in the codebase that informs the plan — reference real file paths>

  ## Plan
  1. <step>
  2. <step>
  ...

  ## Risks / Open questions
  - <item>
  ```

  Adapt the structure to the task — don't force it if something simpler fits.

### 4. Open the plan in DocNotate

Once the file is written, open it in the local DocNotate instance by running the `open` command (macOS) with the **absolute** path to the file you just created:

```bash
open "http://localhost:3535/documents/open?file_path=<absolute_path_to_plan_file>"
```

- Use the absolute path (not `~`, not relative) so the URL is unambiguous.
- If the `open` command isn't available on this platform (e.g. Linux without `xdg-open`, Windows), use the platform equivalent (`xdg-open`, `start`) and tell the user what you ran.
- DocNotate must already be running on port 3535. If the command fails or the URL doesn't respond, tell the user to start DocNotate and re-run the open command — don't silently swallow the error.

### 5. Tell the user what to do next

Briefly tell the user:
- Where the plan file lives (absolute path).
- That DocNotate should now be open with the plan loaded.
- That when they're done commenting, they can use DocNotate's copy button and paste the comments back here as their next message, and you'll revise the plan from there.

Keep it short — no need to re-summarize the plan itself, it's already in the file they're looking at.

## Notes

- Don't commit the plan file unless the user asks. The `plans/` directory may be gitignored or kept on purpose; respect whichever.
- If an existing plan file exists with the same name, overwrite it only if the new task is clearly a revision of the same thing. Otherwise pick a distinct filename to avoid losing prior plans.
- This skill is paired with DocNotate running locally on port 3535. The plan file is plain markdown — the user can still open and read it even if DocNotate isn't running, they just lose the inline-commenting workflow.