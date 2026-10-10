import { Controller } from "@hotwired/stimulus"

// Switches an HTML paper between the rendered file and the previous-comments list, so the
// file keeps the full height. The nav's inbox button toggles between the two views.
export default class extends Controller {
    static targets = ["panel"]

    connect() {
        this.view = "document"
    }

    showArchived() {
        this.show(this.view === "archived" ? "document" : "archived")
    }

    show(view) {
        this.view = view

        const inboxButton = this.element.querySelector(".document__comment-inbox-button")
        if (inboxButton) this.updateInboxButton(inboxButton, view === "archived")

        this.panelTargets.forEach(panel => {
            panel.hidden = panel.dataset.view !== view
        })
    }

    updateInboxButton(button, inArchived) {
        const label = inArchived ? "Back to document" : "Previous comments"

        button.setAttribute("aria-pressed", inArchived)
        button.setAttribute("aria-label", label)
        button.dataset.tooltip = label
    }
}
