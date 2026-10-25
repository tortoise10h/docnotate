import { Controller } from "@hotwired/stimulus"

// Switches the paper between the rendered file and the previous-comments list, so the
// file keeps the full height. The nav's inbox button toggles between the two views.
export default class extends Controller {
    static targets = ["panel"]

    connect() {
        this.view = "document"
    }

    showDocument() {
        if (this.view !== "document") {
            this.show("document")
        }
    }

    showArchived() {
        this.show(this.view === "archived" ? "document" : "archived")
    }

    show(view) {
        if (view === "archived" && this.view === "document") {
            this.lastDocumentScrollY = window.scrollY
            window.scrollTo({ top: 0, behavior: "instant" })
        } else if (view === "document" && this.view === "archived") {
            if (this.lastDocumentScrollY !== undefined) {
                window.scrollTo({ top: this.lastDocumentScrollY, behavior: "instant" })
            }
        }

        this.view = view

        const inboxButton = this.element.querySelector(".document__comment-inbox-button")
        if (inboxButton) this.updateInboxButton(inboxButton, view === "archived")

        this.panelTargets.forEach(panel => {
            panel.hidden = panel.dataset.view !== view
        })

        this.element.dispatchEvent(new CustomEvent("comment-popover:hide", { bubbles: true }))
        this.element.dispatchEvent(new CustomEvent("comment-create:reset", { bubbles: true }))
    }

    updateInboxButton(button, inArchived) {
        const label = inArchived ? "Back to document" : "Previous comments"

        button.setAttribute("aria-pressed", inArchived)
        button.setAttribute("aria-label", label)
        button.dataset.tooltip = label
    }
}
