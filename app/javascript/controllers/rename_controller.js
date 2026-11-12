import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]

  edit() {
    this.originalValue = this.inputTarget.value
    this.displayTarget.hidden = true
    this.formTarget.hidden = false

    const panel = document.getElementById("document_switcher_panel")
    if (panel) panel.hidden = true

    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel() {
    if (this.originalValue !== undefined) {
      this.inputTarget.value = this.originalValue
    }
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
  }
}
