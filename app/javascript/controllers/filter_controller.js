import { Controller } from "@hotwired/stimulus"

// Auto-submits the surrounding filter form: debounced while typing,
// immediate on select change. The form targets a Turbo Frame, so the
// list updates in place and the URL stays shareable.
export default class extends Controller {
    search() {
        clearTimeout(this.timeout)
        this.timeout = setTimeout(() => this.element.requestSubmit(), 250)
    }

    filter() {
        this.element.requestSubmit()
    }

    disconnect() {
        clearTimeout(this.timeout)
    }
}
