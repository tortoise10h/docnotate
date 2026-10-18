import { Controller } from "@hotwired/stimulus"

// Renders ```mermaid code blocks as SVG diagrams with Pele (https://pele.run).
// The source <pre> is hidden instead of removed: its block id anchors comments
// and keeps multi-block comment spans resolvable.
export default class extends Controller {
  connect() {
    const sources = [...this.element.querySelectorAll("pre code.language-mermaid")].filter((code) => {
      const pre = code.closest("pre")
      if (pre.dataset.mermaidProcessed) return false
      pre.dataset.mermaidProcessed = "true"
      return true
    })
    if (sources.length === 0) return

    // Lazy-load so the diagram bundle is only fetched on pages that have diagrams.
    import("pele").then(({ mount }) => {
      sources.forEach((code) => this.renderBlock(mount, code))
    }).catch(() => {
      // Leave the raw code blocks when the renderer cannot be loaded.
    })
  }

  renderBlock(mount, code) {
    const pre = code.closest("pre")
    const source = code.textContent
    if (source.trim() === "") return

    const container = document.createElement("div")
    container.className = "document__mermaid"
    pre.insertAdjacentElement("beforebegin", container)

    const diagram = mount(container, source, {
      zoom: "auto",
      onError: (error) => {
        // Redraw failures keep mount's own overlay; only a failed first draw
        // falls back to the raw source block.
        if (pre.classList.contains("document-node--mermaid-source-hidden") || pre.dataset.mermaidFailed) return
        pre.dataset.mermaidFailed = "true"
        container.remove()
        pre.insertAdjacentElement("afterend", this.errorNotice(error))
      }
    })

    if (diagram.error) {
      diagram.destroy()
    } else {
      pre.classList.add("document-node--mermaid-source-hidden")
    }
  }

  errorNotice(error) {
    const notice = document.createElement("details")
    notice.className = "document__mermaid-error"

    const summary = document.createElement("summary")
    summary.className = "document__mermaid-error-summary"
    summary.textContent = "Couldn't render diagram"
    notice.appendChild(summary)

    // Error text can quote the diagram source, so it must go in as plain text.
    const detail = document.createElement("pre")
    detail.className = "document__mermaid-error-detail"
    detail.textContent = [ error?.message, error?.snippet ].filter(Boolean).join("\n\n")
    notice.appendChild(detail)

    return notice
  }
}
