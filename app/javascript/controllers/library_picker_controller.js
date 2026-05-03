import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "showLabel", "hideLabel"]

  toggle() {
    this.listTarget.classList.toggle("hidden")
    this.showLabelTarget.classList.toggle("hidden")
    this.hideLabelTarget.classList.toggle("hidden")
  }
}
