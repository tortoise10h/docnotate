import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button"]

    connect() {
        this.boundToggleVisibility = this.toggleVisibility.bind(this)
        window.addEventListener("scroll", this.boundToggleVisibility)
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
    }

    scrollToTop(event) {
        event.preventDefault()
        window.scrollTo({ top: 0, behavior: "smooth" })
    }
}
