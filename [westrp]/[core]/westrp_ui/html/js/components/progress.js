/**
 * WestRP UI Engine — Action Progress Bar Component
 * Substituto Oficial do vorp_progressbar
 */

class ProgressBarComponent {
  constructor() {
    this.container = document.getElementById('progressbar-container');
    this.labelEl = document.getElementById('progressbar-label');
    this.pctEl = document.getElementById('progressbar-percentage');
    this.fillEl = document.getElementById('progressbar-fill');
    this.timer = null;
    this.active = false;
  }

  initEls() {
    if (!this.container) {
      this.container = document.getElementById('progressbar-container');
      this.labelEl = document.getElementById('progressbar-label');
      this.pctEl = document.getElementById('progressbar-percentage');
      this.fillEl = document.getElementById('progressbar-fill');
    }
  }

  start(options) {
    this.initEls();
    if (!this.container) return;

    this.cancel(false); // Cancela anterior se houver sem chamar callback

    const label = options.label || "REALIZANDO AÇÃO...";
    const duration = Math.max(options.duration || 3000, 200);

    this.labelEl.textContent = label;
    this.pctEl.textContent = "0%";
    this.fillEl.style.width = "0%";
    this.container.style.display = 'block';
    this.active = true;

    const startTime = Date.now();
    const interval = 25; // 40 FPS no JS

    this.timer = setInterval(() => {
      if (!this.active) {
        clearInterval(this.timer);
        return;
      }

      const elapsed = Date.now() - startTime;
      const progress = Math.min(elapsed / duration, 1.0);
      const percentage = Math.floor(progress * 100);

      this.fillEl.style.width = `${progress * 100}%`;
      this.pctEl.textContent = `${percentage}%`;

      if (progress >= 1.0) {
        clearInterval(this.timer);
        this.active = false;
        setTimeout(() => {
          this.container.style.display = 'none';
          this.postCallback('progressComplete');
        }, 120);
      }
    }, interval);
  }

  cancel(notifyClient = true) {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    if (this.active) {
      this.active = false;
      if (this.container) this.container.style.display = 'none';
      if (notifyClient) {
        this.postCallback('progressCancel');
      }
    }
  }

  isActive() {
    return this.active;
  }

  postCallback(endpoint) {
    fetch(`https://westrp_ui/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    }).catch(() => {});
  }
}

window.uiProgress = new ProgressBarComponent();
