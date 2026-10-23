import { Controller } from "@hotwired/stimulus"

const REMOTE_EDGE_GAP = 24

export default class extends Controller {
    static targets = [
        "source", "content", "popover", "popoverBody", "popoverDate", "deleteForm",
        "popoverEditBody", "popoverEditText", "editForm", "editError"
    ]
    static values = { remote: Boolean }

    connect() {
	this.currentComment = null
	this.documentId = this.element.dataset.documentId
    }

    // A null rect means the anchor is unknown (remote nav) or off-screen (remote scroll)
    show(event) {
	const { comment, rect } = event.detail
	if (!comment) return

	this.currentComment = comment
	this.render(comment)
	if (rect) this.placeAt(rect)
    }

    placeAt(rect) {
	this.popoverTarget.style.display = "flex"
	this.position(rect)
    }

    reposition(event) {
	const { commentId, rect } = event.detail
	if (commentId !== this.currentComment?.id) return

	if (rect) {
	    this.placeAt(rect)
	} else {
	    this.popoverTarget.style.display = "none"
	}
    }

    render(comment) {
	if (comment.content_html) {
	    // Server renders markdown but ships no wrapper; the class carries the
	    // markdown styling shared with the archived-comments view
	    this.popoverBodyTarget.innerHTML = `<div class="document__comment-markdown">${comment.content_html}</div>`
	} else {
	    this.popoverBodyTarget.textContent = comment.content
	}
	this.popoverDateTarget.textContent = new Date(comment.created_at).toLocaleString()
	this.deleteFormTarget.action = this.commentEndpoint(comment)
	this.exitEditMode()
    }

    commentEndpoint(comment) {
	return `/documents/${this.documentId}/comments/${comment.id}`
    }

    position(markRect) {
	const contentRect = this.contentTarget.getBoundingClientRect()
	const containerRect = this.element.getBoundingClientRect()
	const left = this.remoteValue
	    ? contentRect.right - containerRect.left - this.popoverTarget.offsetWidth - REMOTE_EDGE_GAP
	    : Math.max(16, Math.min(markRect.right + 16, document.documentElement.clientWidth - this.popoverTarget.offsetWidth - 16)) - containerRect.left

	this.popoverTarget.style.left = `${left}px`
	const top = !this.remoteValue && left + containerRect.left < markRect.right
	    ? markRect.bottom + 8
	    : markRect.top
	this.popoverTarget.style.top = `${top - containerRect.top}px`
    }

    editComment() {
	if (!this.currentComment) return

	this.editFormTarget.action = this.commentEndpoint(this.currentComment)
	this.popoverBodyTarget.hidden = true
	this.popoverEditBodyTarget.hidden = false
	this.popoverEditTextTarget.value = this.currentComment.content
	this.popoverEditTextTarget.focus()
	this.popoverEditTextTarget.dispatchEvent(new Event("input"))
    }

    cancelEdit() {
	this.exitEditMode()
    }

    exitEditMode() {
	this.popoverBodyTarget.hidden = false
	this.popoverEditBodyTarget.hidden = true
	this.popoverEditTextTarget.value = ""
	if (this.hasEditErrorTarget) this.editErrorTarget.textContent = ""
    }

    hide() {
	this.exitEditMode()
	this.popoverTarget.style.display = "none"
	this.currentComment = null
	this.dispatch("closed")
    }

    reload() {
	const openCommentId = this.currentComment?.id
	if (openCommentId == null) return

	const comments = this.parseComments()
	const updated = comments.find(comment => comment.id === openCommentId)
	if (!updated) {
	    this.hide()
	    return
	}

	if (this.remoteValue) {
	    this.show({ detail: { comment: updated } })
	    return
	}

	const newMark = this.findMarkForComment(updated.id)
	if (newMark) this.show({ detail: { comment: updated, rect: newMark.getBoundingClientRect() } })
    }

    parseComments() {
	try {
	    const parsed = JSON.parse(this.sourceTarget.textContent)
	    return Array.isArray(parsed) ? parsed : (parsed.current || [])
	} catch {
	    return []
	}
    }

    findMarkForComment(commentId) {
	return this.element.querySelector(`.document__comment-highlight[data-comment-id="${commentId}"]`)
    }
}
