import { Controller } from "@hotwired/stimulus"

const DEBOUNCE_MS = 130
const BADGE_LABELS = { markdown: "md", html: "html", org: "org" }
const SEPARATOR_PATTERN = /[\s\-_./\\]+/

export default class extends Controller {
  static targets = ["backdrop", "panel", "input", "heading", "list", "empty"]
  static values = {
    searchUrl: String,
    openUrl: String,
    recent: Array
  }

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    this.boundKeydown = this.keydown.bind(this)
    this.boundShortcut = this.handleShortcut.bind(this)
    this.boundOpenTrigger = this.handleOpenTrigger.bind(this)
    this.boundBeforeCache = this.handleBeforeCache.bind(this)
    this.debounceTimer = null
    this.abortController = null
    this.selectedIndex = -1
    this.previousFocus = null

    document.addEventListener("keydown", this.boundShortcut)
    document.addEventListener("click", this.boundOpenTrigger)
    document.addEventListener("turbo:before-cache", this.boundBeforeCache)
  }

  disconnect() {
    this.cancelPendingSearch()
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("keydown", this.boundKeydown)
    document.removeEventListener("keydown", this.boundShortcut)
    document.removeEventListener("click", this.boundOpenTrigger)
    document.removeEventListener("turbo:before-cache", this.boundBeforeCache)
  }

  get isOpen() {
    return !this.panelTarget.hidden
  }

  get optionElements() {
    return Array.from(this.listTarget.querySelectorAll("[role='option']"))
  }

  open() {
    if (this.isOpen) return

    this.previousFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null
    this.backdropTarget.hidden = false
    this.panelTarget.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
    this.inputTarget.value = ""
    this.renderRecent()
    this.inputTarget.focus()

    document.addEventListener("click", this.boundClickOutside)
    document.addEventListener("keydown", this.boundKeydown)
  }

  close({ restoreFocus = true } = {}) {
    if (!this.isOpen) return

    this.cancelPendingSearch()
    this.backdropTarget.hidden = true
    this.panelTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")

    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("keydown", this.boundKeydown)

    if (restoreFocus) this.restoreFocus()
    this.previousFocus = null
  }

  handleBeforeCache() {
    this.close({ restoreFocus: false })
  }

  restoreFocus() {
    if (this.previousFocus && this.previousFocus !== document.body && this.previousFocus.isConnected) {
      this.previousFocus.focus()
    }
  }

  clickOutside(event) {
    if (!this.panelTarget.contains(event.target)) {
      this.close()
    }
  }

  handleShortcut(event) {
    if (event.defaultPrevented || this.isOpen) return
    if (!this.isPaletteShortcut(event)) return

    event.preventDefault()
    this.open()
  }

  handleOpenTrigger(event) {
    if (event.defaultPrevented || this.isOpen) return
    const trigger = event.target instanceof Element ? event.target.closest("[data-file-palette-open]") : null
    if (!trigger) return

    event.preventDefault()
    this.open()
  }

  keydown(event) {
    if (event.key === "Escape" || this.isPaletteShortcut(event)) {
      event.preventDefault()
      this.close()
      return
    }

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveSelection(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveSelection(-1)
    } else if (event.key === "Enter" && !event.isComposing) {
      event.preventDefault()
      this.openSelected()
    }
  }

  search() {
    const query = this.inputTarget.value.trim()
    this.cancelPendingSearch()

    if (!query) {
      this.renderRecent()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchMatches(query), DEBOUNCE_MS)
  }

  async fetchMatches(query) {
    this.abortController = new AbortController()
    const url = new URL(this.searchUrlValue, window.location.origin)
    url.searchParams.set("query", query)

    try {
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })
      if (!response.ok) return

      const items = await response.json()
      if (!this.isOpen || this.inputTarget.value.trim() !== query) return

      this.renderMatches(items, query)
    } catch (error) {
      if (error.name !== "AbortError") {
        this.renderMatches([], query)
      }
    }
  }

  cancelPendingSearch() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }

  renderRecent() {
    this.headingTarget.textContent = "Recent files"
    this.renderItems(this.recentValue, {
      query: "",
      emptyMessage: "No recent files yet."
    })
  }

  renderMatches(items, query) {
    this.headingTarget.textContent = "Matching files"
    this.renderItems(items, {
      query,
      emptyMessage: `No files matching "${query}"`
    })
  }

  renderItems(items, { query, emptyMessage }) {
    this.listTarget.textContent = ""

    if (!items || items.length === 0) {
      this.listTarget.hidden = true
      this.emptyTarget.textContent = emptyMessage
      this.emptyTarget.hidden = false
      this.selectedIndex = -1
      this.inputTarget.removeAttribute("aria-activedescendant")
      return
    }

    this.emptyTarget.hidden = true
    this.listTarget.hidden = false

    const fragment = document.createDocumentFragment()
    items.forEach((item, index) => {
      fragment.appendChild(this.buildRow(item, index, query))
    })
    this.listTarget.appendChild(fragment)
    this.setSelectedIndex(0, { scroll: false })
  }

  buildRow(item, index, query) {
    const li = document.createElement("li")
    li.className = "file-palette__row"
    li.setAttribute("role", "none")

    const link = document.createElement("a")
    link.id = `file_palette_option_${item.id}`
    link.href = this.buildOpenUrl(item.file_path)
    link.className = "file-palette__item"
    link.setAttribute("role", "option")
    link.setAttribute("aria-selected", "false")
    link.tabIndex = -1
    link.dataset.filePaletteIndex = String(index)
    link.dataset.turboPrefetch = "false"
    link.dataset.action = "mouseenter->file-palette#selectFromHover click->file-palette#openFromClick"

    const main = document.createElement("span")
    main.className = "file-palette__item-main"
    main.appendChild(this.buildBadge(item.file_type))

    const text = document.createElement("span")
    text.className = "file-palette__item-text"

    const name = document.createElement("span")
    name.className = "file-palette__item-name"
    this.appendHighlightedText(name, item.display_name, query)

    const path = document.createElement("span")
    path.className = "file-palette__item-path"
    path.textContent = item.file_path

    text.append(name, path)
    main.appendChild(text)
    link.appendChild(main)

    if (item.time_ago) {
      const time = document.createElement("span")
      time.className = "file-palette__item-time"
      time.textContent = item.time_ago
      link.appendChild(time)
    }

    li.appendChild(link)
    return li
  }

  buildBadge(fileType) {
    const modifier = Object.hasOwn(BADGE_LABELS, fileType) ? fileType : "other"
    const badge = document.createElement("span")
    badge.className = `file-badge file-badge--${modifier}`
    badge.textContent = BADGE_LABELS[fileType] || fileType
    return badge
  }

  appendHighlightedText(container, text, query) {
    const trimmed = (query || "").trim()
    const tokens = trimmed.split(SEPARATOR_PATTERN).filter(Boolean)
    if (tokens.length === 0) {
      container.textContent = text
      return
    }

    // Prefer the full query first so literal separator matches (e.g. "palette-alpha") stay one <mark>.
    const terms = Array.from(new Set([trimmed, ...tokens])).sort((a, b) => b.length - a.length)
    const pattern = new RegExp(terms.map((term) => this.escapeRegExp(term)).join("|"), "gi")

    let lastIndex = 0
    for (const match of text.matchAll(pattern)) {
      if (match.index > lastIndex) {
        container.appendChild(document.createTextNode(text.slice(lastIndex, match.index)))
      }

      const mark = document.createElement("mark")
      mark.className = "file-palette__match"
      mark.textContent = match[0]
      container.appendChild(mark)

      lastIndex = match.index + match[0].length
    }

    if (lastIndex === 0) {
      container.textContent = text
    } else if (lastIndex < text.length) {
      container.appendChild(document.createTextNode(text.slice(lastIndex)))
    }
  }

  escapeRegExp(value) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  }

  buildOpenUrl(filePath) {
    const url = new URL(this.openUrlValue, window.location.origin)
    url.searchParams.set("file_path", filePath)
    return `${url.pathname}${url.search}`
  }

  selectFromHover(event) {
    const index = Number(event.currentTarget.dataset.filePaletteIndex)
    if (Number.isInteger(index)) {
      this.setSelectedIndex(index, { scroll: false })
    }
  }

  moveSelection(delta) {
    const count = this.optionElements.length
    if (count === 0) return

    const base = this.selectedIndex < 0 ? 0 : this.selectedIndex
    const nextIndex = (base + delta + count) % count
    this.setSelectedIndex(nextIndex, { scroll: true })
  }

  setSelectedIndex(index, { scroll }) {
    const options = this.optionElements
    if (options.length === 0 || index < 0 || index >= options.length) {
      this.selectedIndex = -1
      this.inputTarget.removeAttribute("aria-activedescendant")
      return
    }

    this.selectedIndex = index
    options.forEach((option, i) => {
      const selected = i === index
      option.classList.toggle("file-palette__item--active", selected)
      option.setAttribute("aria-selected", String(selected))
    })

    const active = options[index]
    this.inputTarget.setAttribute("aria-activedescendant", active.id)
    if (scroll) active.scrollIntoView({ block: "nearest" })
  }

  openSelected() {
    const active = this.optionElements[this.selectedIndex]
    if (!active) return

    this.visitUrl(active.getAttribute("href"))
  }

  openFromClick(event) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

    event.preventDefault()
    this.visitUrl(event.currentTarget.getAttribute("href"))
  }

  visitUrl(url) {
    if (!url) return

    this.close({ restoreFocus: false })
    if (window.Turbo) {
      window.Turbo.visit(url)
    } else {
      window.location.assign(url)
    }
  }

  isPaletteShortcut(event) {
    const isMac = /Mac|iPod|iPhone|iPad/i.test(navigator.platform)
    const primaryMod = isMac ? event.metaKey && !event.ctrlKey : event.ctrlKey && !event.metaKey
    return primaryMod && !event.altKey && !event.shiftKey && event.key.toLowerCase() === "k"
  }
}
