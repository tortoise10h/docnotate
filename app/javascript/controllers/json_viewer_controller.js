import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const block = event.target.closest(".json-block")
    if (!block) return

    const isCollapsed = block.dataset.collapsed === "true"
    block.dataset.collapsed = (!isCollapsed).toString()

    const toggle = block.querySelector(":scope > .json-line > .json-line__toggle")
    if (toggle) {
      toggle.setAttribute("aria-expanded", isCollapsed.toString())
    }
  }

  expandAll() {
    this.element.querySelectorAll(".json-block").forEach(block => {
      block.dataset.collapsed = "false"
      const toggle = block.querySelector(":scope > .json-line > .json-line__toggle")
      if (toggle) toggle.setAttribute("aria-expanded", "true")
    })
  }

  collapseAll() {
    const blocks = this.element.querySelectorAll(".json-block")
    blocks.forEach(block => {
      const depth = Number(block.dataset.depth || 0)
      if (depth >= 1 || blocks.length === 1) {
        block.dataset.collapsed = "true"
        const toggle = block.querySelector(":scope > .json-line > .json-line__toggle")
        if (toggle) toggle.setAttribute("aria-expanded", "false")
      }
    })
  }
}
