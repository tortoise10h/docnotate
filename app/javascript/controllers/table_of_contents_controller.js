import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["link", "toggle", "panel"]

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

        this.onKeydown = (event) => {
            if (event.key === "Escape") this.close()
        }
        document.addEventListener("keydown", this.onKeydown)
    }

    disconnect() {
        this.observer?.disconnect()
        document.removeEventListener("keydown", this.onKeydown)
    }

    open() {
        this.panelTarget.hidden = false
        this.toggleTarget.hidden = true
        this.toggleTarget.setAttribute("aria-expanded", "true")

        if (this.activeLink) this.activeLink.scrollIntoView({ block: "nearest" })
    }

    close() {
        if (this.panelTarget.hidden) return

        this.panelTarget.hidden = true
        this.toggleTarget.hidden = false
        this.toggleTarget.setAttribute("aria-expanded", "false")
        this.toggleTarget.focus()
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
                if (!this.panelTarget.hidden) link.scrollIntoView({ block: "nearest" })
            } else {
                link.removeAttribute("aria-current")
            }
        })
    }
}
