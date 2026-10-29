import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    handlePaste(event) {
        const text = event.clipboardData?.getData("text")
        if (text && /^file:/i.test(text.trim())) {
            event.preventDefault()
            const cleaned = this.cleanPath(text)
            const start = this.element.selectionStart ?? 0
            const end = this.element.selectionEnd ?? 0
            const current = this.element.value

            this.element.value = current.slice(0, start) + cleaned + current.slice(end)
            const newPos = start + cleaned.length
            this.element.setSelectionRange(newPos, newPos)
            this.element.dispatchEvent(new Event("input", { bubbles: true }))
        }
    }

    handleInput() {
        const value = this.element.value
        if (/^file:/i.test(value.trim())) {
            this.element.value = this.cleanPath(value)
        }
    }

    cleanPath(path) {
        let cleaned = path.trim()
        cleaned = cleaned
            .replace(/^file:\/\/localhost(?=\/|$)/i, "")
            .replace(/^file:\/\//i, "")
            .replace(/^file:/i, "")
            .split(/[?#]/)[0]

        try {
            cleaned = decodeURIComponent(cleaned)
        } catch {
            // Keep as-is if malformed percent encoding
        }

        if (/^\/[a-zA-Z]:\//.test(cleaned)) {
            cleaned = cleaned.replace(/^\//, "")
        } else if (!cleaned.startsWith("/") && !/^[a-zA-Z]:/.test(cleaned)) {
            cleaned = `/${cleaned}`
        }

        return cleaned
    }
}
