import { Controller } from "@hotwired/stimulus"

// Renders code blocks with highlight.js mapped to the shared paper palette.
// Lazy-loads the bundle so pages without code blocks do not pay the cost.
export default class extends Controller {
  connect() {
    const blocks = [...this.element.querySelectorAll("pre code:not(.language-mermaid)")].filter(
      (el) => !el.dataset.highlighted
    )
    if (blocks.length === 0) return

    import("highlight.js").then(({ default: hljs }) => {
      let hadMarks = false

      blocks.forEach((el) => {
        if (el.dataset.highlighted) return

        const blockHadMarks = Boolean(
          el.querySelector(".document__comment-highlight") ||
          el.closest("pre")?.querySelector(".document__comment-highlight")
        )

        const src = el.textContent
        if (!src || src.trim() === "") {
          el.dataset.highlighted = "true"
          return
        }

        const match = el.className.match(/\blanguage-([\w-]+)\b/)
        const lang = match ? match[1] : null

        try {
          let highlighted = null
          if (lang) {
            if (hljs.getLanguage(lang)) {
              highlighted = hljs.highlight(src, { language: lang, ignoreIllegals: true }).value
            }
          } else {
            highlighted = hljs.highlightAuto(src).value
          }

          if (highlighted !== null) {
            el.innerHTML = highlighted
            if (blockHadMarks) hadMarks = true
          }
        } catch {
          // Leave text unhighlighted on parse error
        } finally {
          el.dataset.highlighted = "true"
        }
      })

      if (hadMarks) {
        this.element.dispatchEvent(new CustomEvent("comment-highlight:reload", { bubbles: true }))
      }
    }).catch(() => {
      // Leave raw code blocks if highlighter fails to load
    })
  }
}
