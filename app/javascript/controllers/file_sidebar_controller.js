import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "panel", "backdrop", "frame"]

  connect() {
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
    this.loaded = false
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  toggle() {
    if (this.panelTarget.hidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.hidden = false
    if (this.hasBackdropTarget) {
      this.backdropTarget.hidden = false
    }
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "true")
    }

    if (!this.loaded && this.hasFrameTarget) {
      const src = this.frameTarget.dataset.src || this.frameTarget.getAttribute("src")
      if (src && !this.frameTarget.getAttribute("src")) {
        this.frameTarget.src = src
      }
      this.loaded = true
    }
  }

  close() {
    if (this.panelTarget.hidden) return

    this.panelTarget.hidden = true
    if (this.hasBackdropTarget) {
      this.backdropTarget.hidden = true
    }
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "false")
      this.toggleTarget.focus()
    }
  }

  keydown(event) {
    if (event.key === "Escape" && !this.panelTarget.hidden) {
      event.preventDefault()
      this.close()
    }
  }
}
