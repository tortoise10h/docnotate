# Agent skill enhancements — session handoff

## Goal

Summarize what we just shipped on the agent-skills side of DocNotate, capture the open questions / decisions, and set up the next session to keep improving the agent's skills (more skills to add or enhance).

## Context

- DocNotate ships with agent-facing "skills" — small, on-demand instruction packs an agent loads to perform a specific workflow.
- The first release included one skill, `plannotate` (at `.opencode/skills/plannotate/SKILL.md`), used to write a plan markdown file under `plans/` and open it in the local DocNotate web UI for inline review.
- The user wants to standardize how skills are organized so the same definitions work across multiple agents (opencode, plus others in the future), make the DocNotate base URL configurable per environment, and tighten the skill so the agent does **planning only** when invoked.

## What we did this session

### 1. Moved the skill to the cross-agent-standard location

- New path: `.agents/skills/docnotate-plan/SKILL.md` (was `.opencode/skills/plannotate/SKILL.md`).
- Old path deleted.
- opencode auto-discovers `.agents/skills/<name>/SKILL.md`, so the skill still loads in opencode. It is also now in the path other agent-compatible tools look at.

### 2. Renamed and re-described the skill

- Skill `name` (frontmatter, must be lowercase-alphanumeric + hyphens): `docnotate-plan`.
- Slash command the user types: `/docnotate:plan`.
- Description updated to trigger on `/docnotate:plan` (and the existing natural-language phrasings like "plan and annotate", "plan and review in DocNotate").

### 3. Made the DocNotate base URL configurable

- New env var: `DOCNOTATE_ROOT_URL` (e.g. `http://localhost:4000`).
- Skill resolves with a fallback to `http://localhost:3535` and strips a trailing slash, so either form works.
- The `open` command in the skill now uses `"${DOCNOTATE_ROOT_URL}/documents/open?file_path=…"`.
- `.opencode/opencode.json:7` permission pattern broadened from `http://localhost:3535/documents/open*` to `http://localhost:*/documents/open*` so any localhost port is auto-allowed.

### 4. Added a "what this skill does NOT do" guardrails block

The skill now opens with an explicit guardrail section saying, while running it:

- Do not modify the codebase (no edits, no writes outside `plans/`).
- Do not run side-effecting commands (no migrations, installs, builds, commits, pushes, deploys).
- Do not start implementing the plan in the same turn.
- Do not open non-DocNotate URLs.

The closing note also reminds the agent the plan is a proposal until the user explicitly approves it.

## What changed on disk

- Added: `.agents/skills/docnotate-plan/SKILL.md`
- Removed: `.opencode/skills/plannotate/SKILL.md` (and its now-empty parent dir)
- Edited: `.opencode/opencode.json` (permission pattern only)

## Open questions / things to consider for the next session

- **What other skills does DocNotate want to ship?** The user's first message said "the next part I'd like to enhance is the agent's skills" (plural), so there are more to design. Some candidates worth discussing:
  - A "implement this plan" skill (the natural follow-up to `docnotate:plan`) — reads comments off a DocNotate plan, revises the plan, then implements step by step, checking off as it goes.
  - A "review my changes" skill — opens a diff or list of changed files in DocNotate for the user to comment on.
  - A "fix this comment" skill — pulls a single comment out of DocNotate and addresses it.
  - A "create doc" skill — picks a local file (or set of files) and opens it in DocNotate as a working document, distinct from a plan.
- **Shared conventions for the new skills.** Now that we have a real first skill, the next session should extract and document the shared structure: frontmatter shape, the `What this skill does NOT do` block, the URL/host resolution pattern, the "where does it write its outputs" pattern, the "how does the user kick it off" pattern. Should probably live in a top-level `AGENTS.md` (or a dedicated `docs/agent-skills.md`) so future skills stay consistent.
- **Skill discovery for non-opencode agents.** We standardized on `.agents/skills/`, but only opencode reads it natively today. Decide if the project also needs `.claude/skills/` symlinks/mirrors, or if we wait for the other agents to catch up.
- **Permission patterns in `opencode.json`.** We broadened the `open` pattern to any localhost port. If we add more skills that hit other URLs, decide whether to keep broadening the pattern, scope per-skill, or move skill permissions into per-agent config blocks.
- **The `plans/` directory.** It currently has 15+ plan files. Worth deciding: should it stay top-level, move under `docs/`, be gitignored, or be split into `plans/active/` and `plans/archive/`?

## Plan for the next session

1. Read the comments the user left on this handoff plan in DocNotate and confirm which of the open questions they want to tackle first.
2. Pick one (or a small set) of the candidate skills to add next, and use `docnotate:plan` to scope it properly.
3. Before writing the new skill, factor out shared conventions into `docs/agent-skills.md` (or `AGENTS.md`) so the new skill(s) follow the same shape as `docnotate-plan`.
4. Land the new skill(s) under `.agents/skills/`, update `opencode.json` permissions if they need new auto-allowed commands, and re-run through `docnotate:plan` to verify the loop still works end-to-end.
