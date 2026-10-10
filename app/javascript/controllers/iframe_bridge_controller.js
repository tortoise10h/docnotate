import { Controller } from "@hotwired/stimulus"

// The frame is sandboxed without allow-same-origin, so its messages arrive with origin "null".
const BLOCK_ID_PATTERN = /^block-[0-9a-f]+$/
const RECT_KEYS = ["left", "top", "right", "bottom"]
const FRAME_TOP_SLACK = 8
const LATEST_ONLY_TYPES = new Set(["docnotate:applyComments", "docnotate:focusComment"])

export default class extends Controller {
    static targets = ["frame"]

    connect() {
        this.frameReady = false
        this.pendingMessages = []
        this.boundReceive = this.receive.bind(this)
        window.addEventListener("message", this.boundReceive)
    }

    disconnect() {
        window.removeEventListener("message", this.boundReceive)
    }

    receive(event) {
        if (event.source !== this.frameTarget.contentWindow || event.origin !== "null") return

        const message = event.data
        if (!message || typeof message.type !== "string") return

        switch (message.type) {
            case "docnotate:ready":
                this.handleReady()
                break
            case "docnotate:selection":
                this.handleSelection(message)
                break
            case "docnotate:selectionMoved":
                this.handleSelectionMoved(message)
                break
            case "docnotate:pointerdown":
                this.dispatch("pointerdown")
                break
            case "docnotate:marksApplied":
                this.handleMarksApplied(message)
                break
            case "docnotate:markClick":
                this.handleMarkClick(message)
                break
            case "docnotate:markRect":
                this.handleMarkRect(message)
                break
            case "docnotate:headings":
                this.handleHeadings(message)
                break
        }
    }

    // Comment payload is the single source for highlights, so it is re-read from the DOM each time.
    pushComments() {
        this.send({ type: "docnotate:applyComments", comments: this.currentComments() })
    }

    scrollToComment(event) {
        const commentId = event.detail.commentId
        if (!Number.isInteger(commentId)) return

        this.focusComment(commentId)
        this.send({ type: "docnotate:scrollTo", commentId })
    }

    scrollToBlock(event) {
        const blockId = event.detail.blockId
        if (!BLOCK_ID_PATTERN.test(blockId)) return

        this.send({ type: "docnotate:scrollTo", blockId })
    }

    unfocusComment() {
        this.focusComment(null)
    }

    clearSelection() {
        this.send({ type: "docnotate:clearSelection" })
    }

    handleReady() {
        this.frameReady = true
        this.postToFrame({ type: "docnotate:ack" })
        this.flushPendingMessages()
        this.pushComments()
    }

    handleSelection(message) {
        const rect = lastRect(message.rects)
        if (!rect || !validSelection(message)) return

        this.dispatch("selection", {
            detail: {
                blockIds: message.blockIds,
                startOffset: message.startOffset,
                endOffset: message.endOffset,
                selectedText: message.selectedText,
                prefixText: message.prefixText,
                postfixText: message.postfixText,
                ...this.anchorFor(rect)
            }
        })
    }

    handleSelectionMoved(message) {
        const rect = lastRect(message.rects)
        if (!rect) return

        this.dispatch("selectionMoved", { detail: this.anchorFor(rect) })
    }

    handleMarksApplied(message) {
        const markedIds = integerList(message.markedIds)
        const anchoredIds = integerList(message.anchoredIds)
        if (!markedIds || !anchoredIds) return

        this.dispatch("marksApplied", { detail: { markedIds, anchoredIds } })
    }

    handleMarkClick(message) {
        const rect = lastRect([message.rect])
        if (!Number.isInteger(message.commentId) || !rect) return

        this.dispatch("markClick", { detail: { commentId: message.commentId, rect: this.viewportRect(rect) } })
    }

    handleMarkRect(message) {
        if (!Number.isInteger(message.commentId)) return

        const rect = message.rect ? lastRect([message.rect]) : null
        this.dispatch("markRect", {
            detail: { commentId: message.commentId, rect: rect ? this.viewportRect(rect) : null }
        })
    }

    handleHeadings(message) {
        if (!Array.isArray(message.entries)) return

        // A heading is "current" once it reaches the top edge of the frame, not the page header
        const frameTop = this.frameTarget.getBoundingClientRect().top
        const entries = message.entries
            .filter(entry => entry && BLOCK_ID_PATTERN.test(entry.blockId) && Number.isFinite(entry.top))
            .map(entry => ({ blockId: entry.blockId, top: frameTop + entry.top }))

        this.dispatch("headings", { detail: { entries, threshold: frameTop + FRAME_TOP_SLACK } })
    }

    focusComment(commentId) {
        this.send({ type: "docnotate:focusComment", commentId })
    }

    currentComments() {
        const source = this.element.querySelector("#comment_payload_source")
        try {
            return JSON.parse(source.textContent).current ?? []
        } catch {
            return []
        }
    }

    // Translates a frame-relative rect into the paper's coordinate space
    anchorFor(rect) {
        const frameBox = this.frameTarget.getBoundingClientRect()
        const paperBox = this.element.getBoundingClientRect()

        return {
            left: frameBox.left - paperBox.left + rect.right,
            top: frameBox.top - paperBox.top + rect.bottom
        }
    }

    // Popovers position against viewport coordinates, like the markdown marks do
    viewportRect(rect) {
        const frameBox = this.frameTarget.getBoundingClientRect()

        return {
            left: frameBox.left + rect.left,
            top: frameBox.top + rect.top,
            right: frameBox.left + rect.right,
            bottom: frameBox.top + rect.bottom
        }
    }

    send(message) {
        if (!this.frameReady) {
            if (LATEST_ONLY_TYPES.has(message.type)) {
                this.pendingMessages = this.pendingMessages.filter(queued => queued.type !== message.type)
            }
            this.pendingMessages.push(message)
            return
        }

        this.postToFrame(message)
    }

    flushPendingMessages() {
        this.pendingMessages.splice(0).forEach(message => this.postToFrame(message))
    }

    postToFrame(message) {
        this.frameTarget.contentWindow.postMessage(message, "*")
    }
}

function lastRect(rects) {
    const rect = Array.isArray(rects) ? rects.at(-1) : null
    return rect && RECT_KEYS.every(key => Number.isFinite(rect[key])) ? rect : null
}

function integerList(value) {
    return Array.isArray(value) && value.every(Number.isInteger) ? value : null
}

function validSelection(message) {
    return Array.isArray(message.blockIds) &&
        message.blockIds.length > 0 &&
        message.blockIds.every(id => typeof id === "string" && BLOCK_ID_PATTERN.test(id)) &&
        Number.isInteger(message.startOffset) &&
        Number.isInteger(message.endOffset) &&
        typeof message.selectedText === "string" &&
        typeof message.prefixText === "string" &&
        typeof message.postfixText === "string"
}
