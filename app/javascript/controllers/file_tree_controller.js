import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    nodesUrl: { type: String, default: "/filesystem/nodes" },
    activePath: { type: String, default: "" }
  }

  static targets = ["folder"]

  async toggleFolder(event) {
    const itemEl = event.currentTarget
    const folderEl = itemEl.closest("[data-folder-path]")
    if (!folderEl) return

    const folderPath = folderEl.dataset.folderPath
    const hasChildren = folderEl.dataset.hasChildren === "true"
    const isLoaded = folderEl.dataset.loaded === "true"
    const isExpanded = folderEl.getAttribute("aria-expanded") === "true"
    const childrenContainer = folderEl.querySelector(":scope > .file-tree__children")
    const spinner = itemEl.querySelector(".file-tree__spinner")

    if (isExpanded) {
      folderEl.setAttribute("aria-expanded", "false")
      if (childrenContainer) {
        childrenContainer.hidden = true
      }
      return
    }

    // Expanding
    folderEl.setAttribute("aria-expanded", "true")

    if (isLoaded) {
      if (childrenContainer) {
        childrenContainer.hidden = false
      }
      return
    }

    if (!hasChildren) {
      if (childrenContainer) {
        childrenContainer.innerHTML = '<div class="file-tree__empty-hint">Empty folder</div>'
        childrenContainer.hidden = false
      }
      folderEl.dataset.loaded = "true"
      return
    }

    // Not loaded yet - fetch child nodes
    if (spinner) spinner.hidden = false

    try {
      let url = `${this.nodesUrlValue}?path=${encodeURIComponent(folderPath)}`
      if (this.activePathValue) {
        url += `&active_file_path=${encodeURIComponent(this.activePathValue)}`
      }

      const response = await fetch(url, {
        headers: {
          Accept: "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) {
        throw new Error(`Failed to load directory: ${response.statusText}`)
      }

      const html = await response.text()
      if (childrenContainer) {
        childrenContainer.innerHTML = html
        childrenContainer.hidden = false
      }
      folderEl.dataset.loaded = "true"
    } catch (error) {
      console.error("Error loading directory nodes:", error)
      folderEl.setAttribute("aria-expanded", "false")
    } finally {
      if (spinner) spinner.hidden = true
    }
  }
}
