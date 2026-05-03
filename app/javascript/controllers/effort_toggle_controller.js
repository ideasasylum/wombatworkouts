import { Controller } from "@hotwired/stimulus"

// Switches the exercise form between "reps per set" and "time per set" modes.
// The inactive field is hidden and blanked so the model's exactly-one validator passes.
export default class extends Controller {
  static targets = ["repsButton", "timeButton", "repsField", "timeField", "repsInput", "timeInput"]
  static values = { mode: String }

  connect() {
    this.render()
  }

  selectReps(event) {
    event.preventDefault()
    this.modeValue = "reps"
    this.timeInputTarget.value = ""
    if (this.repsInputTarget.value === "") this.repsInputTarget.value = "10"
    this.render()
  }

  selectTime(event) {
    event.preventDefault()
    this.modeValue = "time"
    this.repsInputTarget.value = ""
    if (this.timeInputTarget.value === "") this.timeInputTarget.value = "30"
    this.render()
  }

  render() {
    const reps = this.modeValue === "reps"
    this.repsFieldTarget.classList.toggle("hidden", !reps)
    this.timeFieldTarget.classList.toggle("hidden", reps)
    this.#paint(this.repsButtonTarget, reps)
    this.#paint(this.timeButtonTarget, !reps)
  }

  #paint(button, active) {
    button.setAttribute("aria-pressed", active ? "true" : "false")
    if (active) {
      button.classList.add("bg-[rgb(26,26,26)]", "text-white")
      button.classList.remove("bg-white", "text-[rgb(26,26,26)]")
    } else {
      button.classList.add("bg-white", "text-[rgb(26,26,26)]")
      button.classList.remove("bg-[rgb(26,26,26)]", "text-white")
    }
  }
}
