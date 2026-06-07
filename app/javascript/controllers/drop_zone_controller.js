import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.preventDrag = ["dragenter", "dragover", "dragleave", "drop"]
    this.preventDrag.forEach(eventName => {
      this.element.addEventListener(eventName, this.preventDefaults, false)
    })
  }

  disconnect() {
    this.preventDrag.forEach(eventName => {
      this.element.removeEventListener(eventName, this.preventDefaults, false)
    })
  }

  preventDefaults = (e) => {
    e.preventDefault()
    e.stopPropagation()
  }

  highlight = () => {
    this.element.classList.add("drop-zone--active")
  }

  unhighlight = () => {
    this.element.classList.remove("drop-zone--active")
  }

  dragEnter = () => {
    this.highlight()
  }

  dragOver = () => {
    this.highlight()
  }

  dragLeave = () => {
    this.unhighlight()
  }

  drop = (e) => {
    this.unhighlight()
    const files = e.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  open = () => {
    this.inputTarget.click()
  }

  submit = () => {
    this.element.closest("form").requestSubmit()
  }
}
