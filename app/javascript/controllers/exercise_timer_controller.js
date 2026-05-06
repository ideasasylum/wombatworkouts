import { Controller } from "@hotwired/stimulus"

// Countdown timer for time-based exercises. Uses Date.now() deltas so the
// remaining time stays accurate even if the tab is backgrounded between ticks.
//
// Visible buttons by state:
//   idle      → Start
//   running   → Pause
//   paused    → Continue + Reset (split 50/50)
//   finished  → Restart
export default class extends Controller {
  static targets = ["display", "startButton", "pauseButton", "continueButton", "resetButton"]
  static values = { seconds: Number }

  connect() {
    this.remainingMs = this.secondsValue * 1000
    this.state = "idle"
    this.tickHandle = null
    this.deadline = null
    this.wakeLock = null
    // Browsers release the wake lock when the page is hidden; re-acquire when
    // it comes back into view, but only if the timer is still running.
    this.handleVisibilityChange = () => {
      if (document.visibilityState === "visible" && this.state === "running") {
        this.#requestWakeLock()
      }
    }
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
    this.render()
  }

  disconnect() {
    this.#stopTick()
    this.#releaseWakeLock()
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
  }

  start() {
    this.remainingMs = this.secondsValue * 1000
    this.displayTarget.classList.remove("text-green-600")
    this.#run()
  }

  resume() {
    this.#run()
  }

  pause() {
    if (this.state !== "running") return
    this.remainingMs = Math.max(0, this.deadline - Date.now())
    this.state = "paused"
    this.#stopTick()
    this.#releaseWakeLock()
    this.render()
  }

  reset() {
    this.state = "idle"
    this.remainingMs = this.secondsValue * 1000
    this.deadline = null
    this.#stopTick()
    this.#releaseWakeLock()
    this.displayTarget.classList.remove("text-green-600")
    this.render()
  }

  #run() {
    this.deadline = Date.now() + this.remainingMs
    this.state = "running"
    this.#startTick()
    this.#requestWakeLock()
    this.render()
  }

  #startTick() {
    this.#stopTick()
    this.tickHandle = setInterval(() => this.#tick(), 100)
  }

  #stopTick() {
    if (this.tickHandle) {
      clearInterval(this.tickHandle)
      this.tickHandle = null
    }
  }

  #tick() {
    const remaining = this.deadline - Date.now()
    if (remaining <= 0) {
      this.remainingMs = 0
      this.state = "finished"
      this.#stopTick()
      this.#releaseWakeLock()
      this.#cue()
      this.render()
      return
    }
    this.remainingMs = remaining
    this.#paintDisplay()
  }

  render() {
    this.#paintDisplay()
    this.#show(this.startButtonTarget, this.state === "idle" || this.state === "finished")
    this.#show(this.pauseButtonTarget, this.state === "running")
    this.#show(this.continueButtonTarget, this.state === "paused")
    this.#show(this.resetButtonTarget, this.state === "paused")
    this.startButtonTarget.textContent = this.state === "finished" ? "Restart" : "Start"
  }

  #show(el, visible) {
    el.style.display = visible ? "" : "none"
  }

  #paintDisplay() {
    const totalSeconds = Math.ceil(this.remainingMs / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const secs = totalSeconds % 60
    this.displayTarget.textContent = `${minutes}:${secs.toString().padStart(2, "0")}`
  }

  #cue() {
    this.displayTarget.classList.add("text-green-600")
    try {
      const Ctx = window.AudioContext || window.webkitAudioContext
      if (!Ctx) return
      const ctx = new Ctx()
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = "sine"
      osc.frequency.value = 880
      gain.gain.setValueAtTime(0.0001, ctx.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.3, ctx.currentTime + 0.02)
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.6)
      osc.connect(gain).connect(ctx.destination)
      osc.start()
      osc.stop(ctx.currentTime + 0.65)
      osc.onended = () => ctx.close()
    } catch (_e) {
      // Audio is a nice-to-have; ignore failures (e.g. autoplay restrictions).
    }
  }

  async #requestWakeLock() {
    if (!("wakeLock" in navigator)) return
    if (this.wakeLock) return
    try {
      this.wakeLock = await navigator.wakeLock.request("screen")
      this.wakeLock.addEventListener("release", () => {
        this.wakeLock = null
      })
    } catch (_e) {
      // Wake lock is a hint; ignore failures (e.g. low battery, permissions).
    }
  }

  async #releaseWakeLock() {
    if (!this.wakeLock) return
    const lock = this.wakeLock
    this.wakeLock = null
    try {
      await lock.release()
    } catch (_e) {
      // ignore
    }
  }
}
