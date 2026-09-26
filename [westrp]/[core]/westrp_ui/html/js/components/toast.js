/**
 * WestRP UI Engine — Toast Notification Component
 * 1:1 Red Dead Redemption 2 Theme (Authentic 1899 Frontier Dispatch)
 */

class ToastComponent {
  constructor() {
    this.container = document.getElementById('toast-container');
    this.tagLabels = {
      info: 'TELEGRAMA',
      success: 'REGISTRO',
      error: 'ALERTA',
      warning: 'AVISO',
      alert: 'ALERTA'
    };
  }

  show(title, message, type = 'info', duration = 3800) {
    if (!this.container) {
      this.container = document.getElementById('toast-container');
      if (!this.container) return;
    }

    const toast = document.createElement('div');
    toast.className = `toast-item toast--${type}`;

    const tagText = this.tagLabels[type] || 'NOTIFICAÇÃO';

    toast.innerHTML = `
      <div class="toast-header">
        <span class="toast-tag">${tagText}</span>
        <span class="toast-title">${title || 'AVISO'}</span>
      </div>
      <div class="toast-divider"></div>
      <div class="toast-body">
        <p class="toast-message">${message || ''}</p>
      </div>
    `;

    this.container.appendChild(toast);
    if (window.uiAudio) window.uiAudio.playNav();

    setTimeout(() => {
      toast.classList.add('removing');
      setTimeout(() => {
        if (toast.parentNode) toast.parentNode.removeChild(toast);
      }, 250);
    }, duration);
  }
}

window.uiToast = new ToastComponent();

