# Add Copy Button for Highlighted Selection

## Goal
Add an icon-only copy button next to the existing "Add Note" floating button so users can copy the currently highlighted text to the clipboard, since the custom `<mark>`-based highlight clears the native browser selection and breaks Cmd/Ctrl+C.

## Context
- `app/javascript/controllers/text_selection_controller.js` already manages the selection lifecycle: on mouseup it wraps the selected range in `<mark class="document__selection-highlight">`, removes the native selection, and positions the "Add Note" button. The selected plain text is stored in the hidden `selectedTextTarget` input.
- `app/views/documents/show.html.erb` renders the floating form/toolbar with a single `document__selection-button` (Add Note) and the hidden comment form (`commentInputTarget`).
- `app/assets/stylesheets/pages/document.css` styles `.document__selection-button` and `.document__selection-highlight`. There is no grouped-toolbar style yet.
- Existing copy UX patterns:
  - `app/javascript/controllers/comment_copy_controller.js` uses `navigator.clipboard.writeText()` and flashes a tooltip via `data-tooltip`.
  - `app/javascript/controllers/clipboard_controller.js` swaps between a default icon and a success checkmark icon.
- No existing JS/controller tests cover this behavior, so verification will be manual in-browser.

## Plan

### 1. Group the floating toolbar buttons in `app/views/documents/show.html.erb`
- Wrap the existing Add Note button and the new copy button in a single positioned container (e.g., `.document__selection-toolbar`) so both buttons share the same absolute placement and sit side-by-side.
- Keep the existing `data-text-selection-target="button"` on the toolbar container, or move it to the wrapper and rename targets if needed. Because the JS currently toggles `display`/`position` on `buttonTarget`, the simplest path is to make `buttonTarget` the toolbar wrapper and let the inner Add Note button keep its own click action.
- Add the copy button inside the toolbar:
  - `type="button"`
  - `data-action="click->text-selection#copySelectedText"`
  - Two SVG icons: default copy icon and success checkmark icon; toggle a CSS class to swap them.
  - `aria-label="Copy selected text"`.

### 2. Extend `app/javascript/controllers/text_selection_controller.js`
- Add new targets to `static targets`: e.g., `copyButton`, `copyDefaultIcon`, `copySuccessIcon`.
- Add `copyTimeout` instance state in `connect()` and clear it in `disconnect()`.
- Add `copySelectedText(event)`:
  - `preventDefault()` / `stopPropagation()` so the click doesn't dismiss the highlight via `handleOutsideClick`.
  - Read `this.selectedTextTarget.value`. Guard against empty string.
  - Call `navigator.clipboard.writeText(text)`.
  - On success, call `flashCopyButton()`; on failure, log to console (matching existing controller patterns).
- Add `flashCopyButton()`:
  - Toggle visibility classes on the default/success icons.
  - Clear any existing timeout, then revert after ~2 seconds.
  - Do **not** clear the highlight or hide the toolbar.
- Update `showButton()` to display the toolbar wrapper instead of the single button, and ensure both icons are reset to the default state whenever a new selection is made.
- Update `hideButton()` so it also resets the copy button icon state.

### 3. Style the toolbar in `app/assets/stylesheets/pages/document.css`
- Introduce `.document__selection-toolbar` as the positioned, `display: none` wrapper that holds the buttons in a row with a small gap.
- Move the existing `.document__selection-button` styles so it is one item inside the toolbar (no absolute positioning on the button itself).
- Add `.document__selection-copy-button` for the icon-only copy button:
  - Same height/padding/visual treatment as the Add Note button for consistency.
  - Subtle hover state.
- Add `.document__selection-copy-icon--hidden` to hide the success icon by default (mirroring `.document__copy-icon--hidden`).
- Keep z-index at `10` so the toolbar floats above the document content.

### 4. Verify in browser
- Select text → toolbar appears with Add Note + copy icon.
- Click copy → checkmark icon flashes, text is on the clipboard, highlight remains.
- Click Add Note → comment card opens, highlight remains.
- Click Cancel or outside the toolbar → toolbar and highlight disappear.
- Start a new selection before dismissing the old one → only the new selection is highlighted; toolbar shows default copy icon.
- Test near the right edge of the paper → toolbar should not overflow the viewport (the existing single button already has this issue; consider a `max-width`/adjustment if it becomes worse with two buttons).

## Risks / Open questions
- **Clipboard permission:** `navigator.clipboard.writeText()` requires a secure context and a user gesture. The click satisfies the gesture, but HTTP localhost or older browsers may fall back silently. No fallback is planned unless requested.
- **Outside-click dismissal:** The `handleOutsideClick` listener hides the toolbar when clicking outside. We must ensure the copy button is considered "inside" so copying doesn't immediately dismiss the highlight.
- **Toolbar reflow on small viewports:** Adding a second button increases the toolbar width. If the selection ends near the right edge of the paper, the toolbar may be clipped. A simple safeguard is to keep the toolbar narrow (icon-only buttons) and defer a dynamic position adjustment to a follow-up if needed.
- **Target naming:** If we change `buttonTarget` from the Add Note button to the toolbar wrapper, we need to audit every method that references `this.buttonTarget` (`showButton`, `showCommentInput`, `hideButton`, `handleOutsideClick`) and update the ERB target attributes accordingly.
