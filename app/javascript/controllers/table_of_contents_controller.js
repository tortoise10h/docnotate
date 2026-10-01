import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["link", "toggle"]

    connect() {
        this.headings = this.linkTargets.flatMap(link => {
            const heading = document.getElementById(link.dataset.tableOfContentsHeadingId)
            return heading ? [{ link, heading }] : []
        })

        if (this.headings.length === 0) return

        this.observer = new IntersectionObserver(
            () => this.updateActiveLink(),
            { rootMargin: "-88px 0px 0px 0px", threshold: 0 }
        )
        this.headings.forEach(({ heading }) => this.observer.observe(heading))
        this.updateActiveLink()
    }

    updateToggle() {
        this.toggleTarget.querySelector("span").textContent = this.element.open ? "On this page" : "Contents"
        if (this.element.open && this.activeLink) {
            this.activeLink.scrollIntoView({ block: "nearest" })
        }
    }

    disconnect() {
        this.observer?.disconnect()
    }

    select(event) {
        event.preventDefault()

        const item = this.headings.find(({ link }) => link === event.currentTarget)
        if (!item) return

        item.heading.scrollIntoView({ behavior: "smooth", block: "start" })
    }

    updateActiveLink() {
        const threshold = 88
        let activeHeading = this.headings[0]

        this.headings.forEach(item => {
            if (item.heading.getBoundingClientRect().top <= threshold) activeHeading = item
        })

        this.setActiveLink(activeHeading.link)
    }

    setActiveLink(activeLink) {
        this.activeLink = activeLink

        this.linkTargets.forEach(link => {
            const isActive = link === activeLink
            link.classList.toggle("document__toc-item--active", isActive)

            if (isActive) {
                link.setAttribute("aria-current", "location")
                if (this.element.open) link.scrollIntoView({ block: "nearest" })
            } else {
                link.removeAttribute("aria-current")
            }
        })
    }
}
