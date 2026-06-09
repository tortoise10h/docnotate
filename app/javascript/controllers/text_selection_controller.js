import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "content", "form", "startBlockId", "endBlockId", "selectedText", "prefixText", "postfixText"]

    connect() {
	this.contentTarget.addEventListener("mouseup", this.evaluateSelection.bind(this))
	document.addEventListener("mousedown", this.handleOutsideClick.bind(this))
    }

    disconnect() {
	this.contentTarget.removeEventListener("mouseup", this.evaluateSelection.bind(this))
	document.removeEventListener("mousedown", this.handleOutsideClick.bind(this))
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
	const blockIds = this.collectBlockIds(range)
	if (blockIds.length === 0) return

	const rects = range.getClientRects()
	if (rects.length === 0) return

	const lastRect = rects[rects.length - 1] // Target the very last line segment of selection
	const containerRect = this.element.getBoundingClientRect()

	// Place button absolute to container at the exact end edge of selection
	const leftOffset = lastRect.right - containerRect.left
	const topOffset = lastRect.bottom - containerRect.top

	this.showButton(leftOffset, topOffset, blockIds, selectedText)
    }

    collectBlockIds(range) {
	const blockIds = []
	const blocks = this.contentTarget.querySelectorAll("[id]")

	blocks.forEach(block => {
	    if (this.rangeIntersectsNode(range, block)) {
		blockIds.push(block.id)
	    }
	})

	return blockIds
    }

    rangeIntersectsNode(range, node) {
	if (range.intersectsNode) {
	    return range.intersectsNode(node)
	}

	// Fallback for browsers without range.intersectsNode
	const nodeRange = document.createRange()
	nodeRange.selectNode(node)
	return range.compareBoundaryPoints(Range.START_TO_END, nodeRange) <= 0 &&
	    range.compareBoundaryPoints(Range.END_TO_START, nodeRange) >= 0
    }

    showButton(left, top, blockIds, text) {
	this.buttonTarget.style.left = `${left}px`
	this.buttonTarget.style.top = `${top}px`
	this.buttonTarget.style.display = "inline-flex"

	// Populate hidden form fields for normal submission
	this.startBlockIdTarget.value = blockIds.length > 0 ? blockIds[0] : ""
	this.endBlockIdTarget.value = blockIds.length > 0 ? blockIds[blockIds.length - 1] : ""
	this.selectedTextTarget.value = text

	const selection = window.getSelection()
	const range = selection.getRangeAt(0)
	this.prefixTextTarget.value = this.extractPrefix(range)
	this.postfixTextTarget.value = this.extractPostfix(range)
    }

    hideButton() {
	this.buttonTarget.style.display = "none"
	this.startBlockIdTarget.value = ""
	this.endBlockIdTarget.value = ""
	this.selectedTextTarget.value = ""
	this.prefixTextTarget.value = ""
	this.postfixTextTarget.value = ""
    }

    extractPrefix(range) {
	const node = range.startContainer
	if (node.nodeType !== Node.TEXT_NODE) return ""

	const text = node.textContent
	const prefixStart = Math.max(0, range.startOffset - 50)
	return text.slice(prefixStart, range.startOffset).trimStart()
    }

    extractPostfix(range) {
	const node = range.endContainer
	if (node.nodeType !== Node.TEXT_NODE) return ""

	const text = node.textContent
	const postfixEnd = Math.min(text.length, range.endOffset + 50)
	return text.slice(range.endOffset, postfixEnd).trimEnd()
    }

    handleOutsideClick(event) {
	// Don't hide if the user is clicking the comment button itself
	if (this.buttonTarget.contains(event.target)) return

	this.hideButton()

	// Only clear the text selection when clicking outside the document paper
	if (!this.element.contains(event.target)) {
	    window.getSelection().removeAllRanges()
	}
    }
}
