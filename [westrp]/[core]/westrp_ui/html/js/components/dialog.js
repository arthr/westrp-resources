/**
 * WestRP UI Engine — Dialog & Confirm Component
 * Substituto Oficial do vorp_inputs e prompt modals do RedM
 */

class DialogComponent {
  constructor() {
    this.container = document.getElementById('dialog-container');
    this.tagEl = document.getElementById('dialog-tag');
    this.titleEl = document.getElementById('dialog-title');
    this.subtitleEl = document.getElementById('dialog-subtitle');
    this.fieldsContainer = document.getElementById('dialog-form-fields');
    this.btnSubmit = document.getElementById('dialog-btn-submit');
    this.btnCancel = document.getElementById('dialog-btn-cancel');
    this.btnClose = document.getElementById('dialog-close-btn');

    this.confirmContainer = document.getElementById('confirm-container');
    this.confirmModal = document.getElementById('confirm-modal');
    this.confirmTagEl = document.getElementById('confirm-tag');
    this.confirmTitleEl = document.getElementById('confirm-title');
    this.confirmMsgEl = document.getElementById('confirm-message');
    this.confirmSubMsgEl = document.getElementById('confirm-submessage');
    this.confirmBtnSubmit = document.getElementById('confirm-btn-confirm');
    this.confirmBtnCancel = document.getElementById('confirm-btn-cancel');

    this.currentDialogId = null;
    this.currentConfirmId = null;
    this.isOpen = false;
    this.isConfirmOpen = false;

    this.setupEvents();
  }

  initEls() {
    if (!this.container) {
      this.container = document.getElementById('dialog-container');
      this.tagEl = document.getElementById('dialog-tag');
      this.titleEl = document.getElementById('dialog-title');
      this.subtitleEl = document.getElementById('dialog-subtitle');
      this.fieldsContainer = document.getElementById('dialog-form-fields');
      this.btnSubmit = document.getElementById('dialog-btn-submit');
      this.btnCancel = document.getElementById('dialog-btn-cancel');
      this.btnClose = document.getElementById('dialog-close-btn');
    }
    if (!this.confirmContainer) {
      this.confirmContainer = document.getElementById('confirm-container');
      this.confirmModal = document.getElementById('confirm-modal');
      this.confirmTagEl = document.getElementById('confirm-tag');
      this.confirmTitleEl = document.getElementById('confirm-title');
      this.confirmMsgEl = document.getElementById('confirm-message');
      this.confirmSubMsgEl = document.getElementById('confirm-submessage');
      this.confirmBtnSubmit = document.getElementById('confirm-btn-confirm');
      this.confirmBtnCancel = document.getElementById('confirm-btn-cancel');
    }
  }

  setupEvents() {
    if (this.btnSubmit) {
      this.btnSubmit.addEventListener('click', () => this.submitDialog());
    }
    if (this.btnCancel) {
      this.btnCancel.addEventListener('click', () => this.closeDialog());
    }
    if (this.btnClose) {
      this.btnClose.addEventListener('click', () => this.closeDialog());
    }
    if (this.confirmBtnSubmit) {
      this.confirmBtnSubmit.addEventListener('click', () => this.submitConfirm());
    }
    if (this.confirmBtnCancel) {
      this.confirmBtnCancel.addEventListener('click', () => this.closeConfirm());
    }
  }

  openDialog(options) {
    this.initEls();
    if (!this.container) return;

    this.currentDialogId = options.id || 'default_dialog';
    this.tagEl.textContent = options.tag || 'FORMULÁRIO';
    this.titleEl.textContent = options.title || 'ENTRADA DE DADOS';
    this.subtitleEl.textContent = options.subtitle || '';
    this.subtitleEl.style.display = options.subtitle ? 'block' : 'none';

    this.btnSubmit.textContent = options.submitLabel || 'CONFIRMAR';
    this.btnCancel.textContent = options.cancelLabel || 'CANCELAR';

    this.fieldsContainer.innerHTML = '';

    const fields = options.fields || [];
    fields.forEach((field, index) => {
      const group = document.createElement('div');
      group.className = 'dialog-field-group';

      if (field.label) {
        const label = document.createElement('label');
        label.className = 'dialog-field-label';
        label.textContent = field.label;
        group.appendChild(label);
      }

      const inputWrap = document.createElement('div');
      inputWrap.className = 'dialog-input-wrapper';

      let inputEl;

      if (field.type === 'textarea') {
        inputEl = document.createElement('textarea');
        inputEl.className = 'dialog-input dialog-textarea';
        inputEl.rows = field.rows || 3;
        inputEl.value = field.value || '';
        inputEl.placeholder = field.placeholder || '';
      } else if (field.type === 'select') {
        inputEl = document.createElement('select');
        inputEl.className = 'dialog-input dialog-select';
        (field.options || []).forEach(opt => {
          const optEl = document.createElement('option');
          optEl.value = typeof opt === 'object' ? opt.value : opt;
          optEl.textContent = typeof opt === 'object' ? opt.label : opt;
          if (optEl.value == field.value) optEl.selected = true;
          inputEl.appendChild(optEl);
        });
      } else {
        inputEl = document.createElement('input');
        inputEl.className = 'dialog-input';
        inputEl.placeholder = field.placeholder || '';

        if (field.type === 'currency') {
          inputEl.type = 'number';
          inputEl.step = field.step || '0.01';
          inputEl.min = field.min !== undefined ? field.min : '0.00';
          if (field.max !== undefined) inputEl.max = field.max;
          inputEl.value = field.value !== undefined ? field.value : '';
          inputEl.classList.add('has-prefix');

          const prefix = document.createElement('span');
          prefix.className = 'dialog-input-prefix';
          prefix.textContent = '$';
          inputWrap.appendChild(prefix);
        } else if (field.type === 'number') {
          inputEl.type = 'number';
          inputEl.step = field.step || '1';
          if (field.min !== undefined) inputEl.min = field.min;
          if (field.max !== undefined) inputEl.max = field.max;
          inputEl.value = field.value !== undefined ? field.value : '';
        } else {
          inputEl.type = 'text';
          inputEl.value = field.value || '';
        }
      }

      inputEl.dataset.fieldId = field.id || `field_${index}`;
      inputWrap.appendChild(inputEl);
      group.appendChild(inputWrap);

      if (field.description) {
        const desc = document.createElement('span');
        desc.className = 'dialog-field-desc';
        desc.textContent = field.description;
        group.appendChild(desc);
      }

      this.fieldsContainer.appendChild(group);
    });

    this.container.style.display = 'flex';
    this.isOpen = true;
    if (window.uiAudio) window.uiAudio.playNav();

    // Auto foco no primeiro input
    setTimeout(() => {
      const firstInput = this.fieldsContainer.querySelector('input, textarea, select');
      if (firstInput) {
        firstInput.focus();
        if (firstInput.select) firstInput.select();
      }
    }, 50);
  }

  submitDialog() {
    if (!this.isOpen) return;

    const values = {};
    const inputs = this.fieldsContainer.querySelectorAll('.dialog-input');
    inputs.forEach(input => {
      const id = input.dataset.fieldId;
      if (input.type === 'number') {
        values[id] = parseFloat(input.value) || 0;
      } else {
        values[id] = input.value;
      }
    });

    if (window.uiAudio) window.uiAudio.playSelect();
    this.container.style.display = 'none';
    this.isOpen = false;

    fetch('https://westrp_ui/dialogSubmit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: this.currentDialogId, values })
    }).catch(() => {});
  }

  closeDialog() {
    if (!this.isOpen) return;
    this.container.style.display = 'none';
    this.isOpen = false;

    fetch('https://westrp_ui/dialogCancel', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: this.currentDialogId })
    }).catch(() => {});
  }

  /* ==========================================================================
     CONFIRM MODAL
     ========================================================================== */
  openConfirm(options) {
    this.initEls();
    if (!this.confirmContainer) return;

    this.currentConfirmId = options.id || 'default_confirm';
    this.confirmTagEl.textContent = options.tag || 'CONFIRMAÇÃO';
    this.confirmTitleEl.textContent = options.title || 'DESEJA CONTINUAR?';
    this.confirmMsgEl.textContent = options.message || '';

    if (options.submessage) {
      this.confirmSubMsgEl.textContent = options.submessage;
      this.confirmSubMsgEl.style.display = 'block';
    } else {
      this.confirmSubMsgEl.style.display = 'none';
    }

    this.confirmBtnSubmit.textContent = options.confirmLabel || 'CONFIRMAR';
    this.confirmBtnCancel.textContent = options.cancelLabel || 'CANCELAR';

    if (options.danger) {
      this.confirmModal.classList.add('danger');
    } else {
      this.confirmModal.classList.remove('danger');
    }

    this.confirmContainer.style.display = 'flex';
    this.isConfirmOpen = true;
    if (window.uiAudio) window.uiAudio.playNav();
  }

  submitConfirm() {
    if (!this.isConfirmOpen) return;
    if (window.uiAudio) window.uiAudio.playSelect();
    this.confirmContainer.style.display = 'none';
    this.isConfirmOpen = false;

    fetch('https://westrp_ui/confirmSubmit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: this.currentConfirmId, confirmed: true })
    }).catch(() => {});
  }

  closeConfirm() {
    if (!this.isConfirmOpen) return;
    this.confirmContainer.style.display = 'none';
    this.isConfirmOpen = false;

    fetch('https://westrp_ui/confirmCancel', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: this.currentConfirmId })
    }).catch(() => {});
  }
}

window.uiDialog = new DialogComponent();
