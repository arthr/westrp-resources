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
   * Abre o Modal RDR2 com animação zoomAndFadeIn
   * @param {Object} options
   *   title?: string
   *   subtitle?: string
   *   content?: string
   *   html?: string
   *   width?: string (ex: '540px', '60%')
   *   height?: string (ex: 'auto', '60%')
   *   closable?: boolean (default: true)
   *   closeOnOverlay?: boolean (default: true)
   *   buttons?: Array<{ label: string, variant?: string, action?: string, onClick?: Function }>
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
    }

    // Controle do botão Fechar (X)
    if (this.closeBtn) {
      this.closeBtn.style.display = options.closable === false ? 'none' : 'flex';
    }

    // Montar conteúdo
    let innerHtml = '';

    if (options.title) {
      innerHtml += `
        <div class="rdr-header" style="margin-bottom: var(--rdr-spacing-md);">
          <h2>${options.title}</h2>
          <hr class="rdr-divider">
        </div>
      `;
    }

    if (options.subtitle) {
      innerHtml += `
        <p style="color: var(--rdr-color-text-muted); font-size: var(--rdr-font-size-xs); margin-top: -8px; margin-bottom: var(--rdr-spacing-md);">
          ${options.subtitle}
        </p>
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

    // Botões de ação no rodapé do modal (se fornecidos)
    if (options.buttons && options.buttons.length > 0) {
      innerHtml += `<div class="rdr-modal-actions" style="display: flex; justify-content: flex-end; gap: var(--rdr-spacing-sm); margin-top: var(--rdr-spacing-lg);">`;
      options.buttons.forEach((btn, idx) => {
        const variant = btn.variant || (idx === options.buttons.length - 1 ? 'default' : 'subtle');
        innerHtml += `
          <button class="rdr-button rdr-button--${variant}" data-btn-idx="${idx}">
            <span class="rdr-button__label">${btn.label}</span>
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
          } else if (btnConfig.action) {
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

    this.container.style.display = 'flex';
    // Forçar reflow para ativar animação CSS
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
      }, 250);
    }

    this.isOpen = false;

    if (this.currentOptions && this.currentOptions.onClose) {
      this.currentOptions.onClose();
    }

    fetch('https://westrp_ui/modalClosed', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ modalId: this.currentOptions?.id || 'default_modal' })
    }).catch(() => {});

    this.currentOptions = null;
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
