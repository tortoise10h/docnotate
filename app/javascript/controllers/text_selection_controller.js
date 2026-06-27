import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "content", "form", "startBlockId", "endBlockId", "selectedText", "prefixText", "postfixText", "commentInput", "commentText"]

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
	const blockIds = this.collectBlockIds(range)
	if (blockIds.length === 0) return

	const rects = range.getClientRects()
	if (rects.length === 0) return

	const prefixText = this.extractPrefix(range)
	const postfixText = this.extractPostfix(range)

	// One active highlight at a time: clear any prior mark before wrapping the new selection
	this.clearActiveHighlight()

	// Wrap the selected range in persistent <mark> elements and remove the native selection
	this.highlightRange(range)
	selection.removeAllRanges()

	const lastRect = rects[rects.length - 1] // Target the very last line segment of selection
	const containerRect = this.element.getBoundingClientRect()

	// Place button absolute to container at the exact end edge of selection
	const leftOffset = lastRect.right - containerRect.left
	const topOffset = lastRect.bottom - containerRect.top

	this.showButton(leftOffset, topOffset, blockIds, selectedText, prefixText, postfixText)
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

    highlightRange(range) {
	const walker = document.createTreeWalker(
	    this.contentTarget,
	    NodeFilter.SHOW_TEXT,
	    null,
	    false
	)

	const highlights = []
	let textNode
	while ((textNode = walker.nextNode()) !== null) {
	    if (!this.rangeIntersectsNode(range, textNode)) continue

	    const isStartNode = textNode === range.startContainer
	    const isEndNode = textNode === range.endContainer
	    const textLength = textNode.textContent.length

	    const startOffset = isStartNode ? range.startOffset : 0
	    const endOffset = isEndNode ? range.endOffset : textLength

	    if (startOffset >= endOffset) continue

	    highlights.push({ textNode, startOffset, endOffset })
	}

	highlights.forEach(({ textNode, startOffset, endOffset }) => {
	    const parent = textNode.parentNode
	    textNode.splitText(endOffset)
	    const highlightNode = textNode.splitText(startOffset)
	    const mark = document.createElement("mark")

	    mark.className = "document__selection-highlight"
	    mark.textContent = highlightNode.textContent
	    parent.replaceChild(mark, highlightNode)
	    this.activeMarks.push(mark)
	})

	return this.activeMarks
    }

    clearActiveHighlight() {
	this.activeMarks.forEach(mark => {
	    mark.replaceWith(document.createTextNode(mark.textContent))
	})
	this.activeMarks = []
	this.contentTarget.normalize()
    }

    showButton(left, top, blockIds, text, prefixText, postfixText) {
	this.buttonTarget.style.left = `${left}px`
	this.buttonTarget.style.top = `${top}px`
	this.buttonTarget.style.display = "inline-flex"
	this.commentInputTarget.style.display = "none"
	this.commentInputTarget.style.left = `${left}px`
	this.commentInputTarget.style.top = `${top}px`

	// Populate hidden form fields for normal submission
	this.startBlockIdTarget.value = blockIds.length > 0 ? blockIds[0] : ""
	this.endBlockIdTarget.value = blockIds.length > 0 ? blockIds[blockIds.length - 1] : ""
	this.selectedTextTarget.value = text
	this.prefixTextTarget.value = prefixText
	this.postfixTextTarget.value = postfixText
    }

    showCommentInput(event) {
	event.preventDefault()
	event.stopPropagation()

	this.buttonTarget.style.display = "none"
	this.commentInputTarget.style.display = "flex"
	this.commentTextTarget.focus()
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
