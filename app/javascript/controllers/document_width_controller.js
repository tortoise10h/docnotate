import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button"]

    toggle() {
        const wide = this.element.classList.toggle("document--markdown-wide")
        this.buttonTarget.setAttribute("aria-pressed", wide)
        this.buttonTarget.dataset.tooltip = wide ? "Switch to reading view" : "Switch to wide view"
        this.dispatch("change")
    }
}
