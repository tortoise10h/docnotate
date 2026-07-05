import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["source", "button", "divider"]

    connect() {
        this.copyTimeout = null
        this.loadComments()
    }

    disconnect() {
        if (this.copyTimeout) clearTimeout(this.copyTimeout)
    }

    loadComments() {
        let payload = { current: [], archived: [] }
        try {
            const parsed = JSON.parse(this.sourceTarget.textContent)
            payload = Array.isArray(parsed) ? { current: parsed, archived: [] } : parsed
        } catch {
            payload = { current: [], archived: [] }
        }

        // Keep only current inline comments whose start block still exists in the DOM.
        // Archived/previous comments don't have a start_block_id, so they're ignored.
        this.orderedComments = (payload.current || [])
            .filter(comment => comment.start_block_id && document.getElementById(comment.start_block_id))
            .sort((a, b) => {
                const elA = document.getElementById(a.start_block_id)
                const elB = document.getElementById(b.start_block_id)
                if (elA === elB) return 0
                const position = elA.compareDocumentPosition(elB)
                return position & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
            })

        const visible = this.orderedComments.length > 0
        this.buttonTarget.style.display = visible ? "inline-flex" : "none"
        this.dividerTarget.style.display = visible ? "block" : "none"
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
