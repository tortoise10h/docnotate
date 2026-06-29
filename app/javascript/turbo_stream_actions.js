import { Turbo } from "@hotwired/turbo-rails"

Turbo.StreamActions.reload_comments = function() {
  this.targetElements.forEach(el =>
    el.dispatchEvent(new CustomEvent("comment-highlight:reload", { bubbles: true }))
  )
}

Turbo.StreamActions.reset_create_form = function() {
  this.targetElements.forEach(el =>
    el.dispatchEvent(new CustomEvent("comment-create:reset", { bubbles: true }))
  )
}
