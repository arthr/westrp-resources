/**
 * WestRP UI Engine — Toast Notification Component
 * 1:1 Red Dead Redemption 2 Theme (Authentic 1899 Frontier Dispatch)
 */

class ToastComponent {
  constructor() {
    this.container = document.getElementById('toast-container');
  }

  show(title, message, type = 'primary', duration = 3800) {
    if (!this.container) {
      this.container = document.getElementById('toast-container');
      if (!this.container) return;
    }

    // Normalização para as 3 variantes autênticas do RDR2:
    // 1. Vermelha: perigo, crimes e erros
    // 2. Laranja: wanted, alertas e avisos
    // 3. Primária (bg.png): telegramas, registros contábeis e notificações padrão
    const typeStr = String(type || 'primary').toLowerCase();
    const isSuccess = ['success', 'registro'].includes(typeStr);
    const isInfo = ['info'].includes(typeStr);
    const isRed = ['danger', 'error', 'red'].includes(typeStr);
    const isOrange = ['wanted', 'warning', 'alert', 'orange'].includes(typeStr);
    const variantClass = isRed ? 'toast--red' : isOrange ? 'toast--orange' : isSuccess ? 'toast--success' : isInfo ? 'toast--info' : 'toast--primary';

    let tagText = 'DESPACHO';
    if (isRed) {
      tagText = (typeStr === 'error' || typeStr === 'danger') ? 'PERIGO' : 'ALERTA';
    } else if (isOrange) {
      tagText = (typeStr === 'wanted' || typeStr === 'warning' || typeStr === 'alert') ? 'AVISO' : 'TELEGRAMA';
    } else if (isSuccess) {
      tagText = (typeStr === 'success' || typeStr === 'registro') ? 'REGISTRO' : 'SUCESSO';
    } else if (isInfo) {
      tagText = (typeStr === 'info') ? 'INFORMAÇÃO' : 'NOTIFICAÇÃO';
    } else {
      tagText = 'TELEGRAMA';
    }

    const toast = document.createElement('div');
    toast.className = `toast-item ${variantClass}`;

    toast.innerHTML = `
      <div class="toast-header">
        <span class="toast-tag">${tagText}</span>
        <span class="toast-title">${title || 'NOTIFICAÇÃO'}</span>
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

