# DocNotate

Building with AI agents means reading a lot of plans and documents they produce. Reviewing them is awkward: you either stop reading, copy the offending part into the AI console, and lose your flow — or you finish reading and have forgotten half your feedback.

DocNotate fixes that. Open any markdown file in a clean, read-only view, highlight anything you want to change, and drop an inline comment right where it belongs. When you're done, copy all your comments — with their surrounding snippets — in one click and paste them into your AI console as a single, complete prompt.

## Demo

<!-- TODO: add demo video -->

## Features

- Open any local markdown file (HTML support included) in a clean, read-only view
- Highlight text and leave inline comments that stay anchored to the content
- Copy all comments with their surrounding snippets in one click
- Comment inbox to review, edit, and resolve comments as they get fixed
- Table of contents with quick navigation
- Markdown extras: tables, syntax highlighting, and Mermaid diagrams
- All-files page to browse, rename, delete, and revisit recently opened documents
- Open a document in your preferred editor directly from the app

## Installation

### Run locally

Requires [Ruby](https://www.ruby-lang.org/) 4.0 (any version manager works — `.tool-versions` is included).

```bash
git clone https://github.com/tortoise10h/docnotate.git
cd docnotate
bin/setup
```

That's it — `bin/setup` installs dependencies, prepares the SQLite database, and starts the server. Open http://localhost:3535 and open a file by its path.

To start the server again later, run:

```bash
bin/dev
```

### Run with Docker

*A Docker image isn't finalized yet — we'll finalize the Dockerfile and update this section later.*

## Tech stack

DocNotate is deliberately lightweight:

- **Vanilla Rails 8** with ERB templates — no frontend framework
- **Hotwire** (Turbo + Stimulus) for the interactive bits
- **SQLite** as the only database, and the Solid suite (cache, queue, cable) running on it
- **No Node build step** — JavaScript is served via importmap
- Everything runs on your machine against your local files — no accounts, no external services

## Credits

DocNotate's product philosophy is inspired by [Basecamp](https://basecamp.com) and [Zed](https://zed.dev): simple and intuitive over complex and fancy — just make it work and be friendly. The UI style borrows a lot from Zed's documentation.
