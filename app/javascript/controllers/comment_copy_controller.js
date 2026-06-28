import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["source", "button"]

    connect() {
        this.copyTimeout = null
        this.loadComments()
    }

    disconnect() {
        if (this.copyTimeout) clearTimeout(this.copyTimeout)
    }

    loadComments() {
        let payload = []
        try {
            payload = JSON.parse(this.sourceTarget.textContent)
        } catch {
            payload = []
        }

        // Keep only comments whose start block still exists in the DOM,
        // sorted by document position (top-to-bottom reading order).
        this.orderedComments = payload
            .filter(comment => document.getElementById(comment.start_block_id))
            .sort((a, b) => {
                const elA = document.getElementById(a.start_block_id)
                const elB = document.getElementById(b.start_block_id)
                if (elA === elB) return 0
                const position = elA.compareDocumentPosition(elB)
                return position & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
            })

        this.buttonTarget.style.display =
            this.orderedComments.length > 0 ? "inline-flex" : "none"
    }

    async copyComments() {
        if (this.orderedComments.length === 0) return

        const text = this.orderedComments.map((comment, index) => {
            const selectedText = (comment.selected_text || "").trim()
            const content = (comment.content || "").trim()
            return `${index + 1}. "${selectedText}"\n> ${content}`
        }).join("\n\n")

        try {
            await navigator.clipboard.writeText(text)
            this.flashCopied()
        } catch (error) {
            console.error("Failed to copy comments:", error)
        }
    }

    flashCopied() {
        this.buttonTarget.dataset.tooltip = "Copied!"
        this.buttonTarget.setAttribute("aria-label", "Copied!")
        if (this.copyTimeout) clearTimeout(this.copyTimeout)
        this.copyTimeout = setTimeout(() => {
            this.buttonTarget.dataset.tooltip = "Copy comments"
            this.buttonTarget.setAttribute("aria-label", "Copy comments")
        }, 2000)
    }
}
