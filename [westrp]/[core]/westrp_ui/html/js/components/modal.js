/**
 * WestRP UI Engine — Modal & Slider Panel Component (RdrModal & RdrSlider)
 * 1:1 Red Dead Redemption 2 Theme (Inspired by redm-vue-ui)
 */

class ModalComponent {
  constructor() {
    this.container = document.getElementById('rdr-modal-container');
    this.dialog = document.getElementById('rdr-modal-dialog');
    this.closeBtn = document.getElementById('rdr-modal-close-btn');
    this.contentEl = document.getElementById('rdr-modal-content');

    this.isOpen = false;
    this.currentOptions = null;
    this.primaryButtonIndex = -1;
    this.isConfirmMode = false;
    this.confirmResolved = false;
    this.currentConfirmId = null;

    this.setupEvents();
  }

  initEls() {
    if (!this.container) {
      this.container = document.getElementById('rdr-modal-container');
      this.dialog = document.getElementById('rdr-modal-dialog');
      this.closeBtn = document.getElementById('rdr-modal-close-btn');
      this.contentEl = document.getElementById('rdr-modal-content');
    }
  }

  setupEvents() {
    this.initEls();

    if (this.closeBtn) {
      this.closeBtn.addEventListener('click', () => this.close());
    }

    if (this.container) {
      // Clicar no backdrop (fora do modal) fecha o modal se closeOnOverlay !== false
      this.container.addEventListener('click', (e) => {
        if (e.target === this.container) {
          if (!this.currentOptions || this.currentOptions.closeOnOverlay !== false) {
            this.close();
          }
        }
      });
    }
  }

  /**
   * Abre o Modal RDR2 com animação nativa zoomAndFadeIn
   * @param {Object} options
   *   id?: string
   *   tag?: string
   *   title?: string
   *   subtitle?: string
   *   content?: string
   *   submessage?: string
   *   html?: string
   *   danger?: boolean
   *   width?: string (ex: '520px', '60%')
   *   height?: string (ex: 'auto', '60%')
   *   closable?: boolean (default: true)
   *   closeOnOverlay?: boolean (default: true)
   *   enterToConfirm?: boolean (default: true)
   *   buttons?: Array<{ label: string, variant?: string, action?: string, isPrimary?: boolean, onClick?: Function }>
   *   onClose?: Function
   */
  open(options = {}) {
    this.initEls();
    if (!this.container || !this.contentEl) return;

    this.currentOptions = options;

    // Configuração de dimensões
    if (this.dialog) {
      this.dialog.style.width = options.width || '520px';
      if (options.height) {
        this.dialog.style.height = options.height;
      } else {
        this.dialog.style.height = 'auto';
      }

      // Estilo de perigo / alerta crítico (textura bg-red.png)
      if (options.danger) {
        this.dialog.classList.add('rdr-modal--danger');
      } else {
        this.dialog.classList.remove('rdr-modal--danger');
      }
    }

    // Controle do botão Fechar (X)
    if (this.closeBtn) {
      this.closeBtn.style.display = options.closable === false ? 'none' : 'flex';
    }

    // Montar conteúdo visual autêntico RDR2
    let innerHtml = '';

    if (options.tag) {
      innerHtml += `<span class="rdr-modal__tag ${options.danger ? 'rdr-modal__tag--danger' : ''}">${options.tag}</span>`;
    }

    if (options.title) {
      innerHtml += `
        <div class="rdr-header">
          <h2>${options.title}</h2>
          <hr class="rdr-divider">
        </div>
      `;
    }

    if (options.subtitle) {
      innerHtml += `
        <p class="rdr-modal__subtitle">
          ${options.subtitle}
        </p>
      `;
    }

    if (options.html) {
      innerHtml += options.html;
    } else if (options.content) {
      innerHtml += `
        <p class="rdr-modal__content">
          ${options.content}
        </p>
      `;
    }

    if (options.submessage) {
      innerHtml += `
        <p class="rdr-modal__submessage">
          ${options.submessage}
        </p>
      `;
    }

    // Identificação do botão primário para disparo via [ENTER]
    this.primaryButtonIndex = -1;
    if (options.buttons && options.buttons.length > 0) {
      let primIdx = options.buttons.findIndex(b => b.isPrimary === true || b.action === 'confirm');
      if (primIdx === -1) {
        primIdx = options.buttons.findIndex(b => b.variant === 'default' || b.variant === 'danger');
      }
      if (primIdx === -1) {
        primIdx = options.buttons.length - 1; // Fallback: último botão de ação
      }
      this.primaryButtonIndex = primIdx;

      innerHtml += `<div class="rdr-modal-actions">`;
      options.buttons.forEach((btn, idx) => {
        const isPrimary = idx === this.primaryButtonIndex;
        const variant = btn.variant || (isPrimary ? (options.danger ? 'danger' : 'default') : 'subtle');
        const primaryClass = isPrimary ? 'rdr-button--primary-action' : '';
        const hintHtml = (isPrimary && options.enterToConfirm !== false) ? `<span class="rdr-modal-btn__hint">[ENTER]</span>` : '';
        innerHtml += `
          <button class="rdr-button rdr-button--${variant} ${primaryClass}" data-btn-idx="${idx}">
            <span class="rdr-button__label">${btn.label}</span>
            ${hintHtml}
          </button>
        `;
      });
      innerHtml += `</div>`;
    }

    this.contentEl.innerHTML = innerHtml;

    // Vincular cliques dos botões
    if (options.buttons && options.buttons.length > 0) {
      const btnEls = this.contentEl.querySelectorAll('.rdr-modal-actions button');
      btnEls.forEach((el) => {
        const idx = parseInt(el.getAttribute('data-btn-idx'), 10);
        const btnConfig = options.buttons[idx];
        el.addEventListener('click', () => {
          if (window.uiAudio) window.uiAudio.playSelect();
          if (btnConfig.onClick) {
            btnConfig.onClick();
          }
          if (btnConfig.action === 'close') {
            this.close();
          } else if (btnConfig.action && !this.isConfirmMode) {
            fetch('https://westrp_ui/modalAction', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ action: btnConfig.action, modalId: options.id || 'default_modal' })
            }).catch(() => {});
            this.close();
          }
        });
      });
    }

    this.container.classList.remove('is-closing');
    this.container.style.display = 'flex';
    // Forçar reflow para ativar animação CSS zoomAndFadeIn
    void this.container.offsetWidth;
    this.container.classList.add('is-open');

    this.isOpen = true;
    if (window.uiAudio) window.uiAudio.playNav();
  }

  /**
   * Executa a ação do botão primário ao pressionar a tecla [ENTER]
   * @returns {boolean} Se a ação foi executada
   */
  submitPrimary() {
    if (!this.isOpen) return false;
    this.initEls();

    const btnEls = this.contentEl ? this.contentEl.querySelectorAll('.rdr-modal-actions button') : [];
    if (btnEls.length > 0) {
      let targetBtn = null;
      if (this.primaryButtonIndex >= 0 && btnEls[this.primaryButtonIndex]) {
        targetBtn = btnEls[this.primaryButtonIndex];
      } else {
        targetBtn = this.contentEl.querySelector('.rdr-button--default, .rdr-button--danger, .rdr-button--primary-action') || btnEls[btnEls.length - 1];
      }

      if (targetBtn) {
        targetBtn.click();
        return true;
      }
    }

    // Se for um modal informativo simples sem botões, Enter fecha
    this.close();
    return true;
  }

  /**
   * Abre um modal de confirmação binária (Sim/Não) rápida ou crítica
   * Substitui oficialmente o confirm-modal com visual autêntico RDR2
   * @param {Object} options
   */
  openConfirm(options = {}) {
    this.isConfirmMode = true;
    this.confirmResolved = false;
    this.currentConfirmId = options.id || 'default_confirm';

    const isDanger = options.danger === true;
    const confirmLabel = options.confirmLabel || (isDanger ? 'SIM, EXCLUIR' : 'CONFIRMAR');
    const cancelLabel = options.cancelLabel || 'CANCELAR';

    const buttons = [
      {
        label: cancelLabel,
        variant: 'subtle',
        action: 'cancel',
        onClick: () => {
          this.resolveConfirm(false, options);
        }
      },
      {
        label: confirmLabel,
        variant: isDanger ? 'danger' : 'default',
        action: 'confirm',
        isPrimary: true,
        onClick: () => {
          this.resolveConfirm(true, options);
        }
      }
    ];

    this.open({
      id: this.currentConfirmId,
      tag: options.tag || (isDanger ? 'PERIGO • AÇÃO IRREVERSÍVEL' : 'CONFIRMAÇÃO'),
      title: options.title || 'DESEJA CONTINUAR?',
      subtitle: options.subtitle || null,
      content: options.message || '',
      submessage: options.submessage || null,
      danger: isDanger,
      closable: options.closable !== false,
      closeOnOverlay: options.closeOnOverlay !== false,
      enterToConfirm: true,
      buttons: buttons,
      onClose: () => {
        if (!this.confirmResolved) {
          this.resolveConfirm(false, options);
        }
      }
    });
  }

  /**
   * Conclui a resolução da confirmação disparando os callbacks Lua correspondentes
   */
  resolveConfirm(confirmed, options) {
    if (this.confirmResolved) return;
    this.confirmResolved = true;

    if (confirmed) {
      if (options && typeof options.onConfirm === 'function') {
        options.onConfirm();
      }
      fetch('https://westrp_ui/confirmSubmit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: this.currentConfirmId, confirmed: true })
      }).catch(() => {});
    } else {
      if (options && typeof options.onCancel === 'function') {
        options.onCancel();
      }
      fetch('https://westrp_ui/confirmCancel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: this.currentConfirmId })
      }).catch(() => {});
    }

    this.close();
  }

  /**
   * Fecha o modal com animação suave zoomAndFadeOut
   */
  close() {
    if (!this.isOpen) return;
    this.initEls();

    if (this.container) {
      this.container.classList.remove('is-open');
      this.container.classList.add('is-closing');
      setTimeout(() => {
        if (!this.isOpen && this.container) {
          this.container.style.display = 'none';
          this.container.classList.remove('is-closing');
          if (this.dialog) this.dialog.classList.remove('rdr-modal--danger');
        }
      }, 250);
    }

    this.isOpen = false;

    if (this.isConfirmMode) {
      if (!this.confirmResolved) {
        this.resolveConfirm(false, this.currentOptions);
      }
      this.isConfirmMode = false;
      this.confirmResolved = false;
      this.currentConfirmId = null;
    } else {
      if (this.currentOptions && this.currentOptions.onClose) {
        this.currentOptions.onClose();
      }

      fetch('https://westrp_ui/modalClosed', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ modalId: this.currentOptions?.id || 'default_modal' })
      }).catch(() => {});
    }

    this.currentOptions = null;
    this.primaryButtonIndex = -1;
  }
}

class SliderPanelComponent {
  constructor() {
    this.container = document.getElementById('rdr-slider-container');
    this.panel = document.getElementById('rdr-slider-panel');
    this.closeBtn = document.getElementById('rdr-slider-close-btn');
    this.contentEl = document.getElementById('rdr-slider-content');

    this.isOpen = false;
    this.currentOptions = null;

    this.setupEvents();
  }

  initEls() {
    if (!this.container) {
      this.container = document.getElementById('rdr-slider-container');
      this.panel = document.getElementById('rdr-slider-panel');
      this.closeBtn = document.getElementById('rdr-slider-close-btn');
      this.contentEl = document.getElementById('rdr-slider-content');
    }
  }

  setupEvents() {
    this.initEls();

    if (this.closeBtn) {
      this.closeBtn.addEventListener('click', () => this.close());
    }

    if (this.container) {
      this.container.addEventListener('click', (e) => {
        if (e.target === this.container) {
          if (!this.currentOptions || this.currentOptions.closeOnOverlay !== false) {
            this.close();
          }
        }
      });
    }
  }

  /**
   * Abre a gaveta lateral RDR2 deslizando pela borda (slide-in)
   * @param {Object} options
   *   side?: 'right' | 'left' (default: 'right')
   *   width?: string (default: '360px')
   *   title?: string
   *   content?: string
   *   html?: string
   *   closable?: boolean (default: true)
   *   closeOnOverlay?: boolean (default: true)
   *   onClose?: Function
   */
  open(options = {}) {
    this.initEls();
    if (!this.container || !this.panel || !this.contentEl) return;

    this.currentOptions = options;
    const side = options.side === 'left' ? 'left' : 'right';

    // Configurar posição e largura
    this.panel.classList.remove('rdr-slider__panel--left', 'rdr-slider__panel--right');
    this.panel.classList.add(`rdr-slider__panel--${side}`);
    this.panel.style.width = options.width || '360px';

    if (this.closeBtn) {
      this.closeBtn.style.display = options.closable === false ? 'none' : 'flex';
    }

    let innerHtml = '';
    if (options.title) {
      innerHtml += `
        <div class="rdr-header" style="margin-bottom: var(--rdr-spacing-md);">
          <h3>${options.title}</h3>
          <hr class="rdr-divider">
        </div>
      `;
    }

    if (options.html) {
      innerHtml += options.html;
    } else if (options.content) {
      innerHtml += `
        <p style="color: var(--rdr-color-text); font-size: var(--rdr-font-size-xs); line-height: 1.5; margin-bottom: var(--rdr-spacing-md);">
          ${options.content}
        </p>
      `;
    }

    this.contentEl.innerHTML = innerHtml;

    this.container.style.display = 'block';
    void this.container.offsetWidth;
    this.container.classList.add('is-open');

    this.isOpen = true;
    if (window.uiAudio) window.uiAudio.playNav();
  }

  close() {
    if (!this.isOpen) return;
    this.initEls();

    if (this.container) {
      this.container.classList.remove('is-open');
      setTimeout(() => {
        if (!this.isOpen) {
          this.container.style.display = 'none';
        }
      }, 300);
    }

    this.isOpen = false;

    if (this.currentOptions && this.currentOptions.onClose) {
      this.currentOptions.onClose();
    }

    fetch('https://westrp_ui/sliderPanelClosed', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sliderId: this.currentOptions?.id || 'default_slider' })
    }).catch(() => {});

    this.currentOptions = null;
  }

  toggle(options = {}) {
    if (this.isOpen) {
      this.close();
    } else {
      this.open(options);
    }
  }
}

window.uiModal = new ModalComponent();
window.uiSliderPanel = new SliderPanelComponent();
