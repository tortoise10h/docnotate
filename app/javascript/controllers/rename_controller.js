import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]

  edit() {
    this.originalValue = this.inputTarget.value
    this.displayTarget.hidden = true
    this.formTarget.hidden = false
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
