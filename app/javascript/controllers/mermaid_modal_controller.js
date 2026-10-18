import { Controller } from "@hotwired/stimulus"

// Wide-view dialog for mermaid diagrams: the document column is narrow, so the
// modal re-mounts the source at full width with zoom always available.
export default class extends Controller {
  static targets = ["dialog", "canvas"]

  async open(event) {
    const source = event.detail?.source
    if (!source) return

    this.dialogTarget.showModal()
    this.canvasTarget.textContent = ""

    const { mount } = await import("pele")
    // The dialog may have been closed while the bundle was loading.
    if (!this.dialogTarget.open) return

    this.diagram = mount(this.canvasTarget, source, { zoom: true })
  }

  close() {
    this.cleanup()
    this.dialogTarget.close()
  }

  // Also invoked via the dialog's close event, which covers the native Escape
  // path in browsers that fire it. Idempotent by design.
  cleanup() {
    this.diagram?.destroy()
    this.diagram = null
    this.canvasTarget.textContent = ""
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
