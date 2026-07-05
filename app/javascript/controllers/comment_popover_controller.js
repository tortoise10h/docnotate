import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "source", "content", "popover", "popoverBody", "popoverDate", "deleteForm",
        "popoverEditBody", "popoverEditText", "editForm", "editError"
    ]

    connect() {
	this.currentComment = null
	this.currentMark = null
	this.documentId = this.element.dataset.documentId
    }

    show(event) {
	const { comment, mark } = event.detail
	if (!comment || !mark) return

	this.currentComment = comment
	this.currentMark = mark
	this.render(comment)
	this.position(mark)
	this.popoverTarget.style.display = "flex"
    }

    render(comment) {
	this.popoverBodyTarget.textContent = comment.content
	this.popoverDateTarget.textContent = new Date(comment.created_at).toLocaleString()
	this.deleteFormTarget.action = this.commentEndpoint(comment)
	this.exitEditMode()
    }

    commentEndpoint(comment) {
	return `/documents/${this.documentId}/comments/${comment.id}`
    }

    position(mark) {
	const markRect = mark.getBoundingClientRect()
	const contentRect = this.contentTarget.getBoundingClientRect()
	const containerRect = this.element.getBoundingClientRect()

	this.popoverTarget.style.left = `${contentRect.right - containerRect.left + 16}px`
	this.popoverTarget.style.top = `${markRect.top - containerRect.top}px`
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
    }

    reload() {
	const openCommentId = this.currentComment?.id
	if (openCommentId == null) return

	const comments = this.parseComments()
	const updated = comments.find(comment => comment.id === openCommentId)
	if (!updated) {
	    this.currentComment = null
	    this.currentMark = null
	    this.hide()
	    return
	}

	const newMark = this.findMarkForComment(updated.id)
	if (newMark) this.show({ detail: { comment: updated, mark: newMark } })
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
