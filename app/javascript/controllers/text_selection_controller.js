import { Controller } from "@hotwired/stimulus"
import { BLOCK_SELECTOR } from "utils/dom_selectors"
import {
    blockIdOf,
    computeBlockOffsets,
    extractPostfix,
    extractPrefix,
    highlightRange,
    selectedLeafBlocks,
    unwrapHighlights
} from "utils/text_anchors"

export default class extends Controller {
    static targets = ["button", "content", "form", "startBlockId", "endBlockId", "startOffset", "endOffset", "selectedText", "prefixText", "postfixText", "commentInput", "commentText", "copyButton"]

    connect() {
        this.activeMarks = []

        this.boundEvaluateSelection = this.evaluateSelection.bind(this)
        this.boundHandleMouseDown = this.handleMouseDown.bind(this)
        this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)

        this.contentTarget.addEventListener("mouseup", this.boundEvaluateSelection)
        this.contentTarget.addEventListener("mousedown", this.boundHandleMouseDown)
        document.addEventListener("mousedown", this.boundHandleOutsideClick)
    }

    disconnect() {
        this.contentTarget.removeEventListener("mouseup", this.boundEvaluateSelection)
        this.contentTarget.removeEventListener("mousedown", this.boundHandleMouseDown)
        document.removeEventListener("mousedown", this.boundHandleOutsideClick)
    }

    evaluateSelection() {
        const selection = window.getSelection()
        const selectedText = selection.toString().trim()

        // Always hide the button first if there's no actual text selected
        if (!selectedText) {
            this.hideButton()
            return
        }

        const range = selection.getRangeAt(0)

        // Collect all blocks intersected by the selection
        const blocks = selectedLeafBlocks(Array.from(this.contentTarget.querySelectorAll(BLOCK_SELECTOR)), range)
        if (blocks.length === 0) return

        const rects = range.getClientRects()
        if (rects.length === 0) return

        const prefixText = extractPrefix(range)
        const postfixText = extractPostfix(range)

        const { startOffset, endOffset } = computeBlockOffsets(range, blocks[0], blocks[blocks.length - 1])

        // One active highlight at a time: clear any prior mark before wrapping the new selection
        this.clearActiveHighlight()

        // Wrap the selected range in persistent <mark> elements and remove the native selection
        this.activeMarks = highlightRange(range, this.contentTarget)
        selection.removeAllRanges()

        const lastRect = rects[rects.length - 1] // Target the very last line segment of selection
        const containerRect = this.element.getBoundingClientRect()

        // Place button absolute to container at the exact end edge of selection
        const leftOffset = lastRect.right - containerRect.left
        const topOffset = lastRect.bottom - containerRect.top

        this.showButton(leftOffset, topOffset, blocks.map(blockIdOf), selectedText, prefixText, postfixText, startOffset, endOffset)
    }

    // The HTML viewer's bridge computes the anchor position in this container's coordinates
    showFromFrame({ detail }) {
        this.showButton(detail.left, detail.top, detail.blockIds, detail.selectedText, detail.prefixText, detail.postfixText, detail.startOffset, detail.endOffset)
    }

    moveFromFrame({ detail }) {
        this.buttonTarget.style.left = `${detail.left}px`
        this.buttonTarget.style.top = `${detail.top}px`
        this.commentInputTarget.style.left = `${detail.left}px`
        this.commentInputTarget.style.top = `${detail.top}px`
    }

    clearActiveHighlight() {
        unwrapHighlights(this.activeMarks, this.contentTarget)
        this.activeMarks = []
    }

    showButton(left, top, blockIds, text, prefixText, postfixText, startOffset, endOffset) {
        this.buttonTarget.style.left = `${left}px`
        this.buttonTarget.style.top = `${top}px`
        this.buttonTarget.style.display = "inline-flex"
        this.commentInputTarget.style.display = "none"
        this.commentInputTarget.style.left = `${left}px`
        this.commentInputTarget.style.top = `${top}px`

        // Pass the selected text to the dedicated copy controller
        this.copyButtonTarget.dataset.selectionCopyTextValue = text

        // Populate hidden form fields for normal submission
        this.startBlockIdTarget.value = blockIds.length > 0 ? blockIds[0] : ""
        this.endBlockIdTarget.value = blockIds.length > 0 ? blockIds[blockIds.length - 1] : ""
        this.startOffsetTarget.value = startOffset
        this.endOffsetTarget.value = endOffset
        this.selectedTextTarget.value = text
        this.prefixTextTarget.value = prefixText
        this.postfixTextTarget.value = postfixText

        this.keepWithinViewport(this.buttonTarget)
    }

    showCommentInput(event) {
        event.preventDefault()
        event.stopPropagation()

        this.buttonTarget.style.display = "none"
        this.commentInputTarget.style.display = "flex"
        this.keepWithinViewport(this.commentInputTarget)
        this.commentTextTarget.focus()
    }

    keepWithinViewport(element) {
        if (!this.contentTarget.classList.contains("document__content")) return

        const containerRect = this.element.getBoundingClientRect()
        const rect = element.getBoundingClientRect()
        const left = Math.max(16, Math.min(rect.left, document.documentElement.clientWidth - rect.width - 16))
        element.style.left = `${left - containerRect.left}px`
    }

    cancel() {
        this.hideButton()
    }

    hideButton() {
        this.clearActiveHighlight()

        this.buttonTarget.style.display = "none"
        this.commentInputTarget.style.display = "none"
        this.commentTextTarget.value = ""
        this.startBlockIdTarget.value = ""
        this.endBlockIdTarget.value = ""
        this.startOffsetTarget.value = ""
        this.endOffsetTarget.value = ""
        this.selectedTextTarget.value = ""
        this.prefixTextTarget.value = ""
        this.postfixTextTarget.value = ""
        this.copyButtonTarget.dataset.selectionCopyTextValue = ""

        // Lets the HTML viewer's bridge clear the selection marks inside the frame
        this.dispatch("hidden")
    }

    handleMouseDown() {
        this.clearActiveHighlight()
    }

    handleOutsideClick(event) {
        // Don't hide if the user is clicking the comment button or input area
        if (this.buttonTarget.contains(event.target)) return
        if (this.commentInputTarget.contains(event.target)) return

        this.hideButton()

        // Only clear the text selection when clicking outside the document paper
        if (!this.element.contains(event.target)) {
            window.getSelection().removeAllRanges()
        }
    }
}
