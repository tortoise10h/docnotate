# Plan: Dashboard Item Keyboard Shortcuts

## Goal

Add keyboard shortcuts that operate on the currently selected item in the dashboard. The same key (e.g. `d`) dispatches to different docker commands depending on which section is active. **All actions require confirmation.**

## Key Bindings

| Key | Container        | Image            | Volume           | Network          |
|-----|------------------|------------------|------------------|------------------|
| `d` | delete (confirmed) | delete (confirmed) | delete (confirmed) | delete (confirmed) |
| `r` | restart (confirmed) | —                | —                | —                |
| `s` | stop (confirmed)    | —                | —                | —                |

Keys with no binding for a section are silently ignored (no-op).

## Architecture: Section-Aware Dispatch

Since the same key maps to different actions per section, we use a **dispatch table** — a single keymap with dispatcher functions that resolve the correct action based on the active section.

### Dispatch Table

```
lzdockel-dashboard-item-keymap-entries:
  ?d → Containers → lzdockel-container-delete
      → Images     → lzdockel-image-delete
      → Volumes    → lzdockel-volume-delete
      → Networks   → lzdockel-network-delete
  ?r → Containers → lzdockel-container-restart
  ?s → Containers → lzdockel-container-stop
```

### Dispatcher Function

`lzdockel-dashboard-dispatch-action` (in `lzdockel-dashboard.el`):
1. Get the selected item via `lzdockel-dashboard-get-selected-item`
2. Get the current section name from `lzdockel-dashboard-current-section`
3. Look up the action function in the dispatch table
4. If found, call it with the item **and pass `#'lzdockel-dashboard-refresh` as the callback** so the dashboard refreshes after the action completes
5. Otherwise no-op

### Keymap Bindings

In `lzdockel-dashboard-mode-map`, add:
- `d` → `(lambda () (interactive) (lzdockel-dashboard-dispatch-action ?d))`
- `r` → `(lambda () (interactive) (lzdockel-dashboard-dispatch-action ?r))`
- `s` → `(lambda () (interactive) (lzdockel-dashboard-dispatch-action ?s))`

## File Changes

### 1. `lzdockel-core.el` — Move `lzdockel-dashboard--get` and add action helper

**Move** `lzdockel-dashboard--get` from `lzdockel-dashboard.el` to `lzdockel-core.el`, renaming it to `lzdockel-core-get`. This avoids circular dependencies — both the dashboard and the module action functions need this alist lookup utility.

**Add** `lzdockel-core-action-run`:

```elisp
(defun lzdockel-core-action-run (confirm-prompt args &optional callback)
  "Run a docker action with confirmation.
CONFIRM-PROMPT is shown as a yes/no question. ARGS are passed to
docker. CALLBACK is called on success."
  (when (yes-or-no-p confirm-prompt)
    (lzdockel-core-run
     (lambda (_output)
       (when callback (funcall callback)))
     args)))
```

This centralizes the confirmation + async execution pattern so each module doesn't duplicate it. The caller passes the refresh callback — the dashboard passes `#'lzdockel-dashboard-refresh`.

### 2. `lzdockel-dashboard.el` — Use `lzdockel-core-get`

Update all call sites of `lzdockel-dashboard--get` to use `lzdockel-core-get`. Remove the old function definition.

### 3. `lzdockel-container.el` — Add action functions

Each action function takes `(item callback)` — the item alist and a success callback. All actions prompt for confirmation via `lzdockel-core-action-run`.

```elisp
(defun lzdockel-container-delete (item callback)
  "Delete the container referenced by ITEM, with confirmation.
CALLBACK is called on success."
  (lzdockel-core-action-run
   (format "Delete container %s? " (lzdockel-core-get item 'Names))
   `("container" "rm" ,(lzdockel-core-get item 'ID))
   callback))

(defun lzdockel-container-restart (item callback)
  "Restart the container referenced by ITEM, with confirmation.
CALLBACK is called on success."
  (lzdockel-core-action-run
   (format "Restart container %s? " (lzdockel-core-get item 'Names))
   `("container" "restart" ,(lzdockel-core-get item 'ID))
   callback))

(defun lzdockel-container-stop (item callback)
  "Stop the container referenced by ITEM, with confirmation.
CALLBACK is called on success."
  (lzdockel-core-action-run
   (format "Stop container %s? " (lzdockel-core-get item 'Names))
   `("container" "stop" ,(lzdockel-core-get item 'ID))
   callback))
```

### 4. `lzdockel-image.el` — Add delete action

```elisp
(defun lzdockel-image-delete (item callback)
  "Delete the image referenced by ITEM, with confirmation.
CALLBACK is called on success."
  (lzdockel-core-action-run
   (format "Delete image %s:%s? "
           (lzdockel-core-get item 'Repository)
           (lzdockel-core-get item 'Tag))
   `("image" "rm" ,(lzdockel-core-get item 'ID))
   callback))
```

### 5. `lzdockel-volume.el` — Add delete action

```elisp
(defun lzdockel-volume-delete (item callback)
  "Delete the volume referenced by ITEM, with confirmation.
CALLBACK is called on success."
  (lzdockel-core-action-run
   (format "Delete volume %s? " (lzdockel-core-get item 'Name))
   `("volume" "rm" ,(lzdockel-core-get item 'Name))
   callback))
```

### 6. `lzdockel-network.el` — Add delete action

```elisp
(defun lzdockel-network-delete (item callback)
  "Delete the network referenced by ITEM, with confirmation.
CALLBACK is called on success."
  (lzdockel-core-action-run
   (format "Delete network %s? " (lzdockel-core-get item 'Name))
   `("network" "rm" ,(lzdockel-core-get item 'ID))
   callback))
```

### 7. `lzdockel-dashboard.el` — Add dispatch table, dispatcher, and key bindings

```elisp
(defvar lzdockel-dashboard-item-keymap-entries
  '((?d . (("Containers" . lzdockel-container-delete)
           ("Images"     . lzdockel-image-delete)
           ("Volumes"    . lzdockel-volume-delete)
           ("Networks"   . lzdockel-network-delete)))
    (?r . (("Containers" . lzdockel-container-restart)))
    (?s . (("Containers" . lzdockel-container-stop))))
  "Dispatch table mapping keys to section-specific action functions.")

(defun lzdockel-dashboard-dispatch-action (key)
  "Execute the action bound to KEY for the current section and item."
  (let* ((item (lzdockel-dashboard-get-selected-item))
         (section-name (car (nth lzdockel-dashboard-current-section
                                 lzdockel-dashboard-sections)))
         (entries (cdr (assoc key lzdockel-dashboard-item-keymap-entries)))
         (action-fn (cdr (assoc section-name entries))))
    (when (and item action-fn)
      (funcall action-fn item #'lzdockel-dashboard-refresh))))
```

Update `lzdockel-dashboard-mode-map` to include:
```elisp
(define-key map (kbd "d") (lambda () (interactive) (lzdockel-dashboard-dispatch-action ?d)))
(define-key map (kbd "r") (lambda () (interactive) (lzdockel-dashboard-dispatch-action ?r)))
(define-key map (kbd "s") (lambda () (interactive) (lzdockel-dashboard-dispatch-action ?s)))
```

## Execution Order

1. Move `lzdockel-dashboard--get` → `lzdockel-core-get` in `lzdockel-core.el`, update references in `lzdockel-dashboard.el`, remove old definition
2. Add `lzdockel-core-action-run` to `lzdockel-core.el`
3. Add action functions to `lzdockel-container.el`, `lzdockel-image.el`, `lzdockel-volume.el`, `lzdockel-network.el` (all already require `lzdockel-core`)
4. Add dispatch table, dispatcher, and key bindings to `lzdockel-dashboard.el`
5. Test all actions manually

## Design Decisions

- **All actions require confirmation**: Yes/no prompt before every action (delete, restart, stop).
- **Callback pattern**: Each action function takes `(item callback)` — the dashboard passes `#'lzdockel-dashboard-refresh` so the view auto-refreshes after any action completes.
- **`lzdockel-core-get` moved from dashboard**: Avoids circular dependency since module action functions need to extract fields from item alists.
- **Extensible dispatch table**: New keys/actions can be added by extending `lzdockel-dashboard-item-keymap-entries` — no keymap changes needed.

## Future Extensions

- **`f` for force-delete**: `docker rm -f`, `docker rmi -f`, etc.
- **`l` for logs**: Container logs in a separate buffer
- **`e` for exec**: Exec into a container