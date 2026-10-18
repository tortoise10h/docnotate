import { Controller } from "@hotwired/stimulus"
import { install, uninstall, normalizeHotkey } from "@github/hotkey"

const KEY_GLYPHS = {
    Meta: "⌘", Control: "Ctrl", Alt: "⌥", Shift: "⇧",
    Enter: "↵", Escape: "Esc", Space: "␣",
    ArrowUp: "↑", ArrowDown: "↓", ArrowLeft: "←", ArrowRight: "→"
}

// Turbo replaces DOM fragments, so each element owns its binding lifecycle
export default class extends Controller {
    static targets = ["hint"]

    connect() {
        install(this.element)
        this.renderHint()
    }

    disconnect() {
        uninstall(this.element)
    }

    // Derived from the binding so the label always matches data-hotkey and the local platform
    renderHint() {
        if (!this.hasHintTarget) return

        const hotkey = (this.element.dataset.hotkey || "").split(",")[0]
        if (!hotkey) return

        this.hintTarget.textContent = hotkey
            .split(" ")
            .map(key => normalizeHotkey(key).split("+").map(part => KEY_GLYPHS[part] || part).join(""))
            .join(" ")
    }
}
