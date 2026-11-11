import { Controller } from "@hotwired/stimulus"
import { OverType, toolbarButtons } from "overtype"

export default class extends Controller {
  static targets = [
    "editButton",
    "editorPanel",
    "editorContainer",
    "form",
    "contentInput",
    "dialog",
    "cancelDialogButton",
    "error",
    "readOnlyContent"
  ]

  static values = {
    initialContent: String
  }

  connect() {
    this.confirmed = false
    this.boundKeydown = this.handleKeydown.bind(this)
    window.addEventListener("keydown", this.boundKeydown)

    this.themeObserver = new MutationObserver(this.handleThemeChange.bind(this))
    this.themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-theme"]
    })
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundKeydown)
    this.themeObserver?.disconnect()
    this.cleanupEditor()
  }

  get initialContent() {
    if (this.hasInitialContentValue) {
      return this.initialContentValue
    }
    return this.hasContentInputTarget ? this.contentInputTarget.defaultValue : ""
  }

  get isEditing() {
    return this.element.classList.contains("document--editing")
  }

  get currentTheme() {
    const isDark = document.documentElement.getAttribute("data-theme") === "dark" ||
      (window.matchMedia("(prefers-color-scheme: dark)").matches && document.documentElement.getAttribute("data-theme") !== "light")
    return isDark ? "cave" : "solar"
  }

  handleThemeChange() {
    if (this.editor) {
      this.editor.setTheme(this.currentTheme)
    }
  }

  enterEditMode() {
    this.element.classList.add("document--editing")

    if (this.hasReadOnlyContentTarget) {
      this.readOnlyContentTarget.hidden = true
    }

    if (this.hasEditButtonTarget) {
      this.editButtonTarget.disabled = true
      this.editButtonTarget.setAttribute("aria-disabled", "true")
    }

    if (this.hasEditorPanelTarget) {
      this.editorPanelTarget.hidden = false
    }

    this.initEditor()
    this.editor?.focus()
  }

  exitEditMode() {
    this.element.classList.remove("document--editing")

    if (this.hasReadOnlyContentTarget) {
      this.readOnlyContentTarget.hidden = false
    }

    if (this.hasEditButtonTarget) {
      this.editButtonTarget.disabled = false
      this.editButtonTarget.removeAttribute("aria-disabled")
    }

    if (this.hasEditorPanelTarget) {
      this.editorPanelTarget.hidden = true
    }

    this.hideError()
  }

  initEditor() {
    if (this.editor) return

    if (this.hasEditorContainerTarget) {
      this.editorContainerTarget.textContent = ""
      const buttons = [
        toolbarButtons.bold,
        toolbarButtons.italic,
        toolbarButtons.code,
        toolbarButtons.separator,
        toolbarButtons.link,
        toolbarButtons.separator,
        toolbarButtons.h1,
        toolbarButtons.h2,
        toolbarButtons.h3,
        toolbarButtons.separator,
        toolbarButtons.bulletList,
        toolbarButtons.orderedList,
        toolbarButtons.taskList,
        toolbarButtons.separator,
        toolbarButtons.quote
      ]

      const instances = new OverType(this.editorContainerTarget, {
        value: this.initialContent,
        toolbar: true,
        toolbarButtons: buttons,
        autoResize: false,
        theme: this.currentTheme,
        fontFamily: '"Lilex", ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace',
        fontSize: "0.9375rem",
        lineHeight: 1.65,
        padding: "24px 32px"
      })
      this.editor = Array.isArray(instances) ? instances[0] : instances
    }
  }

  cancel() {
    if (this.editor) {
      this.editor.setValue(this.initialContent)
    }
    this.exitEditMode()
  }

  save(event) {
    if (this.confirmed) return

    if (event) event.preventDefault()
    if (!this.editor) return

    const markdown = this.editor.getValue()
    if (this.hasContentInputTarget) {
      this.contentInputTarget.value = markdown
    }

    this.hideError()

    if (this.hasDialogTarget) {
      this.dialogTarget.showModal()
      if (this.hasCancelDialogButtonTarget) {
        this.cancelDialogButtonTarget.focus()
      }
    }
  }

  confirmSave() {
    this.confirmed = true
    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close()
    }
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  cancelSave() {
    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close()
    }
    this.confirmed = false
    this.editor?.focus()
  }

  handleDialogCancel(event) {
    event.preventDefault()
    this.cancelSave()
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) {
      this.cancelSave()
    }
  }

  async handleSubmitEnd(event) {
    if (!event.detail.success) {
      this.confirmed = false
      const response = event.detail.fetchResponse?.response
      if (response) {
        const text = await response.text()
        if (text && !text.includes("<turbo-stream")) {
          this.showError(text)
        }
      }
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.hidden = false
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.hidden = true
    }
  }

  handleKeydown(event) {
    const isMac = navigator.platform.toUpperCase().indexOf("MAC") >= 0
    const isMod = isMac ? event.metaKey : event.ctrlKey

    if (isMod && event.shiftKey && (event.key === "e" || event.key === "E")) {
      if (!this.isEditing) {
        event.preventDefault()
        this.enterEditMode()
      }
      return
    }

    if (this.isEditing && isMod && (event.key === "Enter" || event.keyCode === 13)) {
      if (!this.hasDialogTarget || !this.dialogTarget.open) {
        event.preventDefault()
        this.save(event)
      }
    }
  }

  cleanupEditor() {
    if (this.editor) {
      this.editor.destroy()
      this.editor = null
    }
  }
}
