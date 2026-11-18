import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "header"]

    connect() {
        this.boundToggleVisibility = this.toggleVisibility.bind(this)
        window.addEventListener("scroll", this.boundToggleVisibility, { passive: true })
        this.toggleVisibility()
    }

    disconnect() {
        window.removeEventListener("scroll", this.boundToggleVisibility)
    }

    toggleVisibility() {
        const scrollTop = window.scrollY || document.documentElement.scrollTop
        if (scrollTop > 300) {
            this.buttonTarget.classList.add("document__scroll-top-button--visible")
        } else {
            this.buttonTarget.classList.remove("document__scroll-top-button--visible")
        }

        if (this.hasHeaderTarget) {
            const isStuck = scrollTop > 0 && this.headerTarget.getBoundingClientRect().top <= 1
            this.headerTarget.classList.toggle("document__header--scrolled", isStuck)
        }
    }

    scrollToTop(event) {
        event.preventDefault()
        window.scrollTo({ top: 0, behavior: "smooth" })
    }
}
