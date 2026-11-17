import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        text: String,
        sourceSelector: String
    }

    static targets = ["defaultIcon", "successIcon"]

    connect() {
        this.originalTooltip = this.element.dataset.tooltip || null
        this.originalAriaLabel = this.element.getAttribute("aria-label")
    }

    async copy(event) {
        if (event) {
            event.preventDefault()
            event.stopPropagation()
        }

        const text = this.readText()
        if (text === null) {
            console.error("Failed to copy to clipboard: source text unavailable")
            this.showFailure()
            return
        }

        try {
            if (navigator.clipboard?.writeText) {
                await navigator.clipboard.writeText(text)
            } else if (!this.fallbackCopy(text)) {
                throw new Error("Clipboard API unavailable")
            }
            this.showSuccess()
        } catch (error) {
            console.error("Failed to copy to clipboard:", error)
            this.showFailure()
        }
    }

    readText() {
        if (this.hasSourceSelectorValue) {
            const source = document.querySelector(this.sourceSelectorValue)
            if (!source) return null
            return "value" in source ? source.value : source.textContent
        }
        return this.hasTextValue ? this.textValue : null
    }

    fallbackCopy(text) {
        const textarea = document.createElement("textarea")
        textarea.value = text
        textarea.setAttribute("readonly", "")
        textarea.style.position = "fixed"
        textarea.style.opacity = "0"
        document.body.appendChild(textarea)
        textarea.select()

        let copied = false
        try {
            copied = document.execCommand("copy")
        } finally {
            textarea.remove()
        }
        return copied
    }

    showSuccess() {
        this.captureOriginals()
        this.element.classList.remove("document__copy-button--error")
        this.element.dataset.tooltip = "Copied!"
        this.element.setAttribute("aria-label", "Copied!")

        if (this.hasDefaultIconTarget && this.hasSuccessIconTarget) {
            this.defaultIconTarget.classList.add("document__copy-icon--hidden")
            this.successIconTarget.classList.remove("document__copy-icon--hidden")
        }

        this.scheduleReset()
    }

    showFailure() {
        this.captureOriginals()
        this.element.classList.add("document__copy-button--error")
        this.element.dataset.tooltip = "Copy failed"
        this.element.setAttribute("aria-label", "Copy failed")

        if (this.hasDefaultIconTarget && this.hasSuccessIconTarget) {
            this.defaultIconTarget.classList.remove("document__copy-icon--hidden")
            this.successIconTarget.classList.add("document__copy-icon--hidden")
        }

        this.scheduleReset()
    }

    captureOriginals() {
        if (this.originalTooltip === undefined) {
            this.originalTooltip = this.element.dataset.tooltip || null
        }
        if (this.originalAriaLabel === undefined) {
            this.originalAriaLabel = this.element.getAttribute("aria-label")
        }
    }

    scheduleReset() {
        if (this.feedbackTimeout) {
            clearTimeout(this.feedbackTimeout)
        }
        this.feedbackTimeout = setTimeout(() => {
            this.resetState()
        }, 2000)
    }

    resetState() {
        this.element.classList.remove("document__copy-button--error")
        if (this.hasDefaultIconTarget && this.hasSuccessIconTarget) {
            this.defaultIconTarget.classList.remove("document__copy-icon--hidden")
            this.successIconTarget.classList.add("document__copy-icon--hidden")
        }
        if (this.originalTooltip) {
            this.element.dataset.tooltip = this.originalTooltip
        } else if (this.originalTooltip === null) {
            delete this.element.dataset.tooltip
        }
        if (this.originalAriaLabel) {
            this.element.setAttribute("aria-label", this.originalAriaLabel)
        }
    }

    disconnect() {
        if (this.feedbackTimeout) {
            clearTimeout(this.feedbackTimeout)
        }
        this.resetState()
    }
}
