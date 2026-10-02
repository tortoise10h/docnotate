import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel", "form", "input", "error"]

  connect() {
    this.configured = this.element.dataset.editorOpenConfigured === "true"
    this.boundClickOutside = this.clickOutside.bind(this)
    this.boundKeydown = this.keydown.bind(this)
  }

  disconnect() {
    this.removeDocumentListeners()
  }

  open() {
    if (this.configured) {
      this.openInEditor()
    } else {
      this.openPanel()
    }
  }

  openPanel() {
    this.panelTarget.hidden = false
    this.setExpanded(true)
    this.addDocumentListeners()
    this.inputTarget.focus()
  }

  close() {
    if (this.panelTarget.hidden) return

    this.panelTarget.hidden = true
    this.setExpanded(false)
    this.removeDocumentListeners()
  }

  setExpanded(expanded) {
    this.buttonTargets.forEach(button => button.setAttribute("aria-expanded", String(expanded)))
  }

  async choose(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const submitter = event.submitter
    if (submitter && submitter.name === "editor_name") {
      formData.set("editor_name", submitter.value)
    }

    await this.submit(formData)
  }

  async openInEditor() {
    await this.submit(new FormData())
  }

  async submit(formData) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    let response

    try {
      response = await fetch(this.url, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          ...(token ? { "X-CSRF-Token": token } : {})
        },
        body: formData
      })
    } catch {
      this.showError("Network error. Please try again.")
      return
    }

    if (response.ok) {
      this.close()
      this.configured = true
      this.element.dataset.editorOpenConfigured = "true"
    } else {
      const data = await response.json().catch(() => ({}))
      this.openPanel()
      this.showError(data.error || "Unable to open file in editor")
    }
  }

  get url() {
    return this.element.dataset.editorOpenUrl
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  keydown(event) {
    if (event.key === "Escape") this.close()
  }

  addDocumentListeners() {
    document.addEventListener("click", this.boundClickOutside)
    document.addEventListener("keydown", this.boundKeydown)
  }

  removeDocumentListeners() {
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("keydown", this.boundKeydown)
  }
}
