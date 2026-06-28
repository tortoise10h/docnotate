import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        text: String
    }

    static targets = ["defaultIcon", "successIcon"]

    async copy(event) {
        event.preventDefault()
        event.stopPropagation()

        try {
            await navigator.clipboard.writeText(this.textValue)
            this.showSuccess()
        } catch (error) {
            console.error("Failed to copy to clipboard:", error)
        }
    }

    showSuccess() {
        this.defaultIconTarget.classList.add("document__copy-icon--hidden")
        this.successIconTarget.classList.remove("document__copy-icon--hidden")

        if (this.successTimeout) {
            clearTimeout(this.successTimeout)
        }

        this.successTimeout = setTimeout(() => {
            this.defaultIconTarget.classList.remove("document__copy-icon--hidden")
            this.successIconTarget.classList.add("document__copy-icon--hidden")
        }, 2000)
    }

    disconnect() {
        if (this.successTimeout) {
            clearTimeout(this.successTimeout)
        }
    }
}
