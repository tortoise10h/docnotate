import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    resize() {
	const textarea = this.element
	textarea.style.height = "auto"
	textarea.style.height = `${textarea.scrollHeight}px`
    }
}
