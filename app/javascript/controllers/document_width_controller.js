import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button"]

    toggle() {
        const wide = this.element.classList.toggle("document--markdown-wide")
        this.buttonTarget.setAttribute("aria-pressed", wide)
        this.buttonTarget.dataset.tooltip = wide ? "Switch to reading view (⇧⌘X)" : "Switch to wide view (⇧⌘X)"
        this.dispatch("change")
    }
}
