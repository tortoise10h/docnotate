import { Controller } from "@hotwired/stimulus"

const VIEWPORT_PADDING = 16

export default class extends Controller {
  static targets = ["toggle", "panel"]

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    this.boundKeydown = this.keydown.bind(this)
    this.boundPosition = this.positionPanel.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("keydown", this.boundKeydown)
    window.removeEventListener("resize", this.boundPosition)
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
    this.positionPanel()
    this.toggleTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.boundClickOutside)
    document.addEventListener("keydown", this.boundKeydown)
    window.addEventListener("resize", this.boundPosition)
  }

  close() {
    if (this.panelTarget.hidden) return

    this.panelTarget.hidden = true
    this.panelTarget.style.left = ""
    this.toggleTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("keydown", this.boundKeydown)
    window.removeEventListener("resize", this.boundPosition)
  }

  positionPanel() {
    const container = this.panelTarget.offsetParent || this.element
    const containerRect = container.getBoundingClientRect()
    const toggleRect = this.toggleTarget.getBoundingClientRect()
    const panelWidth = this.panelTarget.offsetWidth
    const viewportWidth = document.documentElement.clientWidth

    const maxLeft = Math.max(VIEWPORT_PADDING, viewportWidth - VIEWPORT_PADDING - panelWidth)
    const desiredLeft = toggleRect.right - panelWidth
    const clampedLeft = Math.max(VIEWPORT_PADDING, Math.min(desiredLeft, maxLeft))
    const relativeLeft = clampedLeft - containerRect.left - container.clientLeft

    this.panelTarget.style.left = `${relativeLeft}px`
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.toggleTarget.focus()
    }
  }
}
