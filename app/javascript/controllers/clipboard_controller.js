import { Controller } from "@hotwired/stimulus"

// Copies a line of trash talk so it can be pasted into Sleeper chat.
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    await navigator.clipboard.writeText(this.sourceTarget.textContent.trim())
    this.buttonTarget.textContent = "Copied!"
    setTimeout(() => { this.buttonTarget.textContent = "Copy" }, 1500)
  }
}
