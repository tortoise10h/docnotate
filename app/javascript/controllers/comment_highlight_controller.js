import { Controller } from "@hotwired/stimulus"
import { BLOCK_SELECTOR } from "utils/dom_selectors"

export default class extends Controller {
    static targets = ["source", "popover", "popoverBody", "popoverDate"]

    connect() {
	this.comments = []
	this.commentsById = new Map()
	this.allMarks = []

	this.boundHandleMarkClick = this.handleMarkClick.bind(this)
	this.contentEl = this.element.querySelector(".document__content")
	this.contentEl.addEventListener("click", this.boundHandleMarkClick)

	this.loadComments()
    }

    disconnect() {
	this.contentEl.removeEventListener("click", this.boundHandleMarkClick)
    }

    loadComments() {
	let payload = []
	try {
	    payload = JSON.parse(this.sourceTarget.textContent)
	} catch {
	    payload = []
	}

	this.comments = payload
	this.commentsById.clear()
	this.comments.forEach(comment => this.commentsById.set(comment.id, comment))
	this.applyAllComments()
    }

    applyAllComments() {
	this.comments.forEach(comment => this.applyComment(comment))
    }

    applyComment(comment) {
	const startBlock = document.getElementById(comment.start_block_id)
	const endBlock = document.getElementById(comment.end_block_id)
	if (!startBlock || !endBlock) return

	const blocks = this.collectBlocksBetween(startBlock, endBlock)
	blocks.forEach((block, index) => {
	    const isFirst = index === 0
	    const isLast = index === blocks.length - 1
	    const blockTextLength = this.blockTextLength(block)

	    const from = isFirst ? comment.start_offset : 0
	    const to = isLast ? comment.end_offset : blockTextLength

	    if (from >= to) return

	    const marks = this.wrapTextRange(block, from, to, comment.id)
	    this.allMarks.push(...marks)
	})
    }

    collectBlocksBetween(startBlock, endBlock) {
	if (startBlock === endBlock) return [startBlock]

	const allBlocks = Array.from(this.contentEl.querySelectorAll(BLOCK_SELECTOR))
	const startIndex = allBlocks.indexOf(startBlock)
	const endIndex = allBlocks.indexOf(endBlock)

	if (startIndex === -1 || endIndex === -1) return []

	return allBlocks.slice(startIndex, endIndex + 1)
    }

    blockTextLength(blockEl) {
	const walker = document.createTreeWalker(blockEl, NodeFilter.SHOW_TEXT, null, false)
	let length = 0
	let node
	while ((node = walker.nextNode()) !== null) {
	    length += node.textContent.length
	}
	return length
    }

    wrapTextRange(rootEl, from, to, commentId) {
	const walker = document.createTreeWalker(rootEl, NodeFilter.SHOW_TEXT, null, false)
	const highlights = []
	let cursor = 0
	let textNode

	while ((textNode = walker.nextNode()) !== null) {
	    const nodeLength = textNode.textContent.length
	    const nodeStart = cursor
	    const nodeEnd = cursor + nodeLength

	    const overlapStart = Math.max(from, nodeStart)
	    const overlapEnd = Math.min(to, nodeEnd)

	    if (overlapStart < overlapEnd) {
		highlights.push({
		    textNode,
		    localStart: overlapStart - nodeStart,
		    localEnd: overlapEnd - nodeStart
		})
	    }

	    cursor += nodeLength
	}

	const marks = []
	highlights.forEach(({ textNode, localStart, localEnd }) => {
	    const parent = textNode.parentNode
	    textNode.splitText(localEnd)
	    const highlightedNode = textNode.splitText(localStart)
	    const mark = document.createElement("mark")

	    mark.className = "document__comment-highlight"
	    mark.dataset.commentId = commentId
	    mark.textContent = highlightedNode.textContent
	    parent.replaceChild(mark, highlightedNode)
	    marks.push(mark)
	})

	return marks
    }

    handleMarkClick(event) {
	const mark = event.target.closest(".document__comment-highlight")
	if (!mark) return

	const commentId = mark.dataset.commentId
	const comment = this.commentsById.get(Number(commentId))
	if (!comment) return

	this.showPopover(mark, comment)
    }

    showPopover(mark, comment) {
	const markRect = mark.getBoundingClientRect()
	const containerRect = this.element.getBoundingClientRect()

	this.popoverBodyTarget.textContent = comment.content
	this.popoverDateTarget.textContent = new Date(comment.created_at).toLocaleString()

	this.popoverTarget.style.display = "flex"
	this.popoverTarget.style.left = `${markRect.left - containerRect.left}px`
	this.popoverTarget.style.top = `${markRect.bottom - containerRect.top + 4}px`
    }

    hidePopover() {
	this.popoverTarget.style.display = "none"
    }
}
