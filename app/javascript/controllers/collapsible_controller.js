import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible"
export default class extends Controller {
  static targets = ["content", "arrow"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")

    // Rotate arrow icon
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.toggle("rotate-180")
    }
  }
}
