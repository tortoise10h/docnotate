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

    const wrapper = document.createElement("div")
    wrapper.className = "document__mermaid"
    wrapper.appendChild(this.expandButton(source))

    const canvas = document.createElement("div")
    canvas.className = "document__mermaid-canvas"
    wrapper.appendChild(canvas)

    pre.insertAdjacentElement("beforebegin", wrapper)

    const diagram = mount(canvas, source, {
      zoom: "auto",
      onError: (error) => {
        // Redraw failures keep mount's own overlay; only a failed first draw
        // falls back to the raw source block.
        if (pre.classList.contains("document-node--mermaid-source-hidden") || pre.dataset.mermaidFailed) return
        pre.dataset.mermaidFailed = "true"
        wrapper.remove()
        pre.insertAdjacentElement("afterend", this.errorNotice(error))
      }
    })

    if (diagram.error) {
      diagram.destroy()
    } else {
      pre.classList.add("document-node--mermaid-source-hidden")
    }
  }

  // Opens the shared wide-view modal; bubbles to the mermaid-modal controller
  // wired on the paper element.
  expandButton(source) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "icon-button icon-button--sm document__mermaid-expand"
    button.dataset.tooltip = "Open wide view"
    button.setAttribute("aria-label", "Open diagram in wide view")
    button.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6"/><path d="M9 21H3v-6"/><path d="m21 3-7 7"/><path d="m3 21 7-7"/></svg>'
    button.addEventListener("click", () => this.dispatch("expand", { detail: { source } }))
    return button
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
