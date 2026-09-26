/**
 * WestRP UI Engine — Panel Central Component (1440px Ultrawide / Free Cursor / Workspace)
 * 1:1 Red Dead Redemption 2 Native Design (Inspired by redm-vue-ui)
 */

class PanelComponent {
  constructor() {
    this.container = document.getElementById('panel-container');
    this.tagEl = document.getElementById('panel-tag');
    this.titleEl = document.getElementById('panel-title');
    this.searchInput = document.getElementById('panel-search-input');
    this.metaPillEl = document.getElementById('panel-meta-pill');
    this.metaTextEl = document.getElementById('panel-meta-text');
    this.closeBtn = document.getElementById('panel-close-btn');

    this.sidebarEl = document.getElementById('panel-sidebar');
    this.tabsListEl = document.getElementById('panel-tabs-list');

    this.gridView = document.getElementById('panel-grid-view');
    this.tableView = document.getElementById('panel-table-view');
    this.dataTableEl = document.getElementById('panel-data-table');
    this.tableHead = document.getElementById('panel-table-head');
    this.tableBody = document.getElementById('panel-table-body');
    this.controlsView = document.getElementById('panel-controls-view');
    this.craftView = document.getElementById('panel-craft-view');
    this.dashboardView = document.getElementById('panel-dashboard-view');
    this.settingsView = document.getElementById('panel-settings-view');

    this.footerEl = document.getElementById('panel-footer');
    this.selectedNameEl = document.getElementById('panel-selected-name');
    this.selectedDescEl = document.getElementById('panel-selected-desc');
    this.stepperValEl = document.getElementById('stepper-val');
    this.btnStepperMinus = document.getElementById('btn-stepper-minus');
    this.btnStepperPlus = document.getElementById('btn-stepper-plus');
    this.ctaBtn = document.getElementById('panel-cta-btn');

    this.isOpen = false;
    this.panelId = 'default_panel';
    this.tabs = [];
    this.activeTabIndex = 0;
    this.selectedItem = null;
    this.stepperQuantity = 1;
    this.searchQuery = '';

    this.setupEvents();
  }

  initEls() {
    if (!this.container) {
      this.container = document.getElementById('panel-container');
      this.tagEl = document.getElementById('panel-tag');
      this.titleEl = document.getElementById('panel-title');
      this.searchInput = document.getElementById('panel-search-input');
      this.metaPillEl = document.getElementById('panel-meta-pill');
      this.metaTextEl = document.getElementById('panel-meta-text');
      this.closeBtn = document.getElementById('panel-close-btn');
      this.tabsListEl = document.getElementById('panel-tabs-list');
      this.gridView = document.getElementById('panel-grid-view');
      this.tableView = document.getElementById('panel-table-view');
      this.dataTableEl = document.getElementById('panel-data-table');
      this.tableHead = document.getElementById('panel-table-head');
      this.tableBody = document.getElementById('panel-table-body');
      this.controlsView = document.getElementById('panel-controls-view');
      this.craftView = document.getElementById('panel-craft-view');
      this.dashboardView = document.getElementById('panel-dashboard-view');
      this.settingsView = document.getElementById('panel-settings-view');
      this.selectedNameEl = document.getElementById('panel-selected-name');
      this.selectedDescEl = document.getElementById('panel-selected-desc');
      this.stepperValEl = document.getElementById('stepper-val');
      this.btnStepperMinus = document.getElementById('btn-stepper-minus');
      this.btnStepperPlus = document.getElementById('btn-stepper-plus');
      this.ctaBtn = document.getElementById('panel-cta-btn');
    }
  }

  setupEvents() {
    if (this.closeBtn) {
      this.closeBtn.addEventListener('click', () => this.close());
    }

    if (this.searchInput) {
      this.searchInput.addEventListener('input', (e) => {
        this.searchQuery = e.target.value.toLowerCase().trim();
        this.renderContentView();
      });
    }

    if (this.btnStepperMinus) {
      this.btnStepperMinus.addEventListener('click', () => {
        if (this.stepperQuantity > 1) {
          this.stepperQuantity--;
          this.stepperValEl.textContent = this.stepperQuantity;
          if (window.uiAudio) window.uiAudio.playToggle();
        }
      });
    }

    if (this.btnStepperPlus) {
      this.btnStepperPlus.addEventListener('click', () => {
        this.stepperQuantity++;
        this.stepperValEl.textContent = this.stepperQuantity;
        if (window.uiAudio) window.uiAudio.playToggle();
      });
    }

    if (this.ctaBtn) {
      this.ctaBtn.addEventListener('click', () => this.executeCTA());
    }

    // Fechar dropdowns abertos ao clicar fora
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.rdr-dropdown')) {
        document.querySelectorAll('.rdr-dropdown--open').forEach(el => el.classList.remove('rdr-dropdown--open'));
        document.querySelectorAll('.has-open-dropdown').forEach(el => el.classList.remove('has-open-dropdown'));
      }
    });
  }

  open(options) {
    this.initEls();
    if (!this.container) return;

    this.panelId = options.id || 'default_panel';
    this.tagEl.textContent = options.tag || 'FRONTEIRA DE NEW HANOVER';
    this.titleEl.textContent = options.title || 'WORKPLACE';
    this.ctaBtn.textContent = options.ctaLabel || 'CONFIRMAR';

    if (options.metaText) {
      this.metaTextEl.textContent = options.metaText;
      this.metaPillEl.style.display = 'block';
    } else {
      this.metaPillEl.style.display = 'none';
    }

    this.tabs = options.tabs || [];
    this.activeTabIndex = 0;
    this.selectedItem = null;
    this.stepperQuantity = 1;
    if (this.stepperValEl) this.stepperValEl.textContent = '1';
    this.searchQuery = '';
    if (this.searchInput) this.searchInput.value = '';

    if (this.selectedNameEl) this.selectedNameEl.textContent = 'Nenhum item selecionado';
    if (this.selectedDescEl) this.selectedDescEl.textContent = '';

    this.renderTabs();
    this.renderContentView();

    this.container.style.display = 'flex';
    this.isOpen = true;
    if (window.uiAudio) window.uiAudio.playNav();
  }

  close() {
    if (!this.isOpen) return;
    this.container.style.display = 'none';
    this.isOpen = false;
    this.selectedItem = null;

    fetch('https://westrp_ui/closePanel', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: this.panelId })
    }).catch(() => {});
  }

  renderTabs() {
    if (!this.tabsListEl) return;
    this.tabsListEl.innerHTML = '';
    this.tabs.forEach((tab, index) => {
      const btn = document.createElement('button');
      btn.className = `panel-tab-btn ${index === this.activeTabIndex ? 'active' : ''}`;
      btn.textContent = tab.label || tab.title || tab.id;

      btn.addEventListener('click', () => {
        this.activeTabIndex = index;
        this.selectedItem = null;
        this.stepperQuantity = 1;
        if (this.stepperValEl) this.stepperValEl.textContent = '1';
        this.renderTabs();
        this.renderContentView();
        if (window.uiAudio) window.uiAudio.playNav();
      });

      this.tabsListEl.appendChild(btn);
    });
  }

  hideAllViews() {
    if (this.gridView) this.gridView.style.display = 'none';
    if (this.tableView) this.tableView.style.display = 'none';
    if (this.controlsView) this.controlsView.style.display = 'none';
    if (this.craftView) this.craftView.style.display = 'none';
    if (this.dashboardView) this.dashboardView.style.display = 'none';
    if (this.settingsView) this.settingsView.style.display = 'none';
  }

  renderContentView() {
    this.hideAllViews();
    const curTab = this.tabs[this.activeTabIndex];
    if (!curTab) return;

    const viewType = curTab.view || curTab.viewType || 'grid';

    if (viewType === 'table') {
      this.renderTableView(curTab);
    } else if (viewType === 'controls' || viewType === 'form' || viewType === 'playground') {
      this.renderControlsView(curTab);
    } else {
      this.renderGridView(curTab);
    }
  }

  /* ==========================================================================
     VISÃO 1: GRID VIEW (VITRINE / CARDS)
     ========================================================================== */
  renderGridView(tab) {
    if (!this.gridView) return;
    this.gridView.innerHTML = '';
    this.gridView.style.display = 'grid';

    let items = tab.items || [];
    if (this.searchQuery) {
      items = items.filter(it => (it.label || it.name || it.id || '').toLowerCase().includes(this.searchQuery));
    }

    if (items.length === 0) {
      this.gridView.innerHTML = `<div style="grid-column: 1 / -1; padding: 40px; text-align: center; color: var(--rdr-color-text-muted);">Nenhum item encontrado.</div>`;
      return;
    }

    items.forEach(item => {
      const card = document.createElement('div');
      card.className = `grid-card ${this.selectedItem && this.selectedItem.id === item.id ? 'selected' : ''}`;

      let iconHtml = '';
      if (item.image) {
        iconHtml = `<img src="${item.image}" class="grid-card-icon" alt="">`;
      } else {
        iconHtml = `<div class="grid-card-icon" style="display:flex;align-items:center;justify-content:center;color:var(--color-gold-light);">
          <svg viewBox="0 0 24 24" width="32" height="32"><path fill="currentColor" d="M12 2l9 4.9v10.2L12 22l-9-4.9V6.9L12 2zm0 2.2L5.2 7.9 12 11.6l6.8-3.7L12 4.2z"/></svg>
        </div>`;
      }

      card.innerHTML = `
        ${iconHtml}
        <span class="grid-card-title truncate" style="max-width: 100%;">${item.label || item.name || item.id}</span>
        ${item.badge ? `<span class="grid-card-badge">${item.badge}</span>` : ''}
      `;

      card.addEventListener('click', () => {
        this.selectedItem = item;
        this.selectedNameEl.textContent = item.label || item.name || item.id;
        this.selectedDescEl.textContent = item.description || (item.badge ? `Preço: ${item.badge}` : '');
        this.renderGridView(tab);
        if (window.uiAudio) window.uiAudio.playSelect();
      });

      this.gridView.appendChild(card);
    });
  }

  /* ==========================================================================
     VISÃO 2: TABELA ORDENÁVEL AUTÊNTICA (RDRTABLE REDM-VUE-UI)
     ========================================================================== */
  renderTableView(tab) {
    if (!this.tableView) return;
    this.tableView.style.display = 'block';
    this.tableHead.innerHTML = '';
    this.tableBody.innerHTML = '';

    // Configurar classes de densidade e ordenação
    if (this.dataTableEl) {
      this.dataTableEl.className = `rdr-table rdr-table--sortable rdr-table--${tab.density || 'default'}`;
    }

    const columns = tab.columns || [
      { key: 'id', label: 'ID' },
      { key: 'label', label: 'ITEM' },
      { key: 'category', label: 'CATEGORIA' },
      { key: 'stock', label: 'ESTOQUE' },
      { key: 'price', label: 'VALOR' }
    ];

    // Inicializar estado de ordenação da aba
    if (!tab.sortBy && columns[0]) {
      tab.sortBy = columns[0].key;
      tab.sortDir = 'asc';
    }

    // Montar Cabeçalho
    const headerRow = document.createElement('tr');
    columns.forEach(col => {
      const th = document.createElement('th');
      th.textContent = col.label;

      if (tab.sortable !== false) {
        th.setAttribute('data-sort-key', col.key);
        if (tab.sortBy === col.key) {
          th.setAttribute('data-sort-active', '');
          th.setAttribute('data-sort-dir', tab.sortDir);
        }

        th.addEventListener('click', () => {
          if (tab.sortBy === col.key) {
            tab.sortDir = tab.sortDir === 'asc' ? 'desc' : 'asc';
          } else {
            tab.sortBy = col.key;
            tab.sortDir = 'asc';
          }
          if (window.uiAudio) window.uiAudio.playToggle();
          this.renderTableView(tab);
        });
      }

      headerRow.appendChild(th);
    });
    this.tableHead.appendChild(headerRow);

    // Filtrar e Ordenar Linhas
    let rows = [...(tab.rows || tab.items || [])];
    if (this.searchQuery) {
      rows = rows.filter(r => JSON.stringify(r).toLowerCase().includes(this.searchQuery));
    }

    if (tab.sortBy) {
      const sortKey = tab.sortBy;
      const dirMult = tab.sortDir === 'desc' ? -1 : 1;
      rows.sort((a, b) => {
        let valA = a[sortKey] !== undefined ? a[sortKey] : '';
        let valB = b[sortKey] !== undefined ? b[sortKey] : '';

        // Comparação numérica de moeda ou números
        const numA = typeof valA === 'string' ? parseFloat(valA.replace(/[^0-9.-]+/g, '')) : valA;
        const numB = typeof valB === 'string' ? parseFloat(valB.replace(/[^0-9.-]+/g, '')) : valB;

        if (!isNaN(numA) && !isNaN(numB) && typeof valA !== 'string' && typeof valB !== 'string') {
          return (numA - numB) * dirMult;
        }
        return String(valA).localeCompare(String(valB)) * dirMult;
      });
    }

    if (rows.length === 0) {
      const emptyTr = document.createElement('tr');
      const emptyTd = document.createElement('td');
      emptyTd.colSpan = columns.length;
      emptyTd.style.textAlign = 'center';
      emptyTd.style.padding = '30px';
      emptyTd.style.color = 'var(--rdr-color-text-muted)';
      emptyTd.textContent = 'Nenhum registro encontrado.';
      emptyTr.appendChild(emptyTd);
      this.tableBody.appendChild(emptyTr);
      return;
    }

    rows.forEach(row => {
      const tr = document.createElement('tr');
      if (this.selectedItem && (this.selectedItem.id === row.id || this.selectedItem.name === row.name)) {
        tr.style.background = 'rgba(182, 42, 42, 0.2)';
      }

      columns.forEach(col => {
        const td = document.createElement('td');
        td.textContent = row[col.key] !== undefined ? row[col.key] : '—';
        tr.appendChild(td);
      });

      tr.addEventListener('click', () => {
        this.selectedItem = row;
        this.selectedNameEl.textContent = row.label || row.name || row.item || row.title || 'Item Selecionado';
        this.selectedDescEl.textContent = row.description || (row.price ? `Preço: ${row.price}` : '');
        this.renderTableView(tab);
        if (window.uiAudio) window.uiAudio.playSelect();
      });

      this.tableBody.appendChild(tr);
    });

    // Rodapé de Tabela (Opcional - RdrTable Footer)
    let tfootEl = this.dataTableEl.querySelector('tfoot');
    if (tab.footerText) {
      if (!tfootEl) {
        tfootEl = document.createElement('tfoot');
        this.dataTableEl.appendChild(tfootEl);
      }
      tfootEl.innerHTML = `<tr><td colspan="${columns.length}" style="padding: 10px 14px; font-size: 13px; color: var(--rdr-color-text-muted);">${tab.footerText}</td></tr>`;
    } else if (tfootEl) {
      tfootEl.remove();
    }
  }

  /* ==========================================================================
     VISÃO 3: CONTROLES, FORMULÁRIOS & PLAYGROUND (SLIDERS, CHECKS, DROPDOWNS)
     ========================================================================== */
  renderControlsView(tab) {
    if (!this.controlsView) return;
    this.controlsView.innerHTML = '';
    this.controlsView.style.display = 'flex';

    const sections = tab.sections || this.getDefaultControlsDemo();

    sections.forEach(sec => {
      const secEl = document.createElement('div');
      secEl.className = 'controls-section';

      if (sec.title) {
        const titleEl = document.createElement('h3');
        titleEl.className = 'controls-section-title';
        titleEl.textContent = sec.title;
        secEl.appendChild(titleEl);
      }

      if (sec.description) {
        const descEl = document.createElement('p');
        descEl.style.cssText = 'color: var(--rdr-color-text-muted); font-size: 14px; margin-bottom: 8px;';
        descEl.textContent = sec.description;
        secEl.appendChild(descEl);
      }

      const gridEl = document.createElement('div');
      gridEl.className = sec.layout === 'grid-3' ? 'controls-grid-3' : (sec.layout === 'grid-2' ? 'controls-grid-2' : '');
      if (!sec.layout) {
        gridEl.style.cssText = 'display: flex; flex-direction: column; gap: 14px;';
      }

      (sec.items || []).forEach(item => {
        const itemWrap = this.createControlItem(item);
        gridEl.appendChild(itemWrap);
      });

      secEl.appendChild(gridEl);
      this.controlsView.appendChild(secEl);
    });
  }

  createControlItem(item) {
    const wrap = document.createElement('div');
    wrap.className = 'control-item';

    switch (item.type) {
      case 'slider': {
        const min = item.min !== undefined ? item.min : 0;
        const max = item.max !== undefined ? item.max : 100;
        const step = item.step !== undefined ? item.step : 5;
        let val = item.value !== undefined ? item.value : 50;

        wrap.innerHTML = `
          <span class="control-label">${item.label || 'Ajuste'}</span>
          <div class="rdr-slider-input">
            <button class="rdr-slider-input__arrow" data-action="dec" title="Diminuir">
              <img src="assets/textures/nav_decrease.png" alt="◄">
            </button>
            <div class="rdr-slider-input__container">
              <div class="rdr-slider-input__tooltip">${val}</div>
              <input type="range" class="rdr-slider-input__input" min="${min}" max="${max}" step="${step}" value="${val}">
            </div>
            <button class="rdr-slider-input__arrow" data-action="inc" title="Aumentar">
              <img src="assets/textures/nav_increase.png" alt="►">
            </button>
          </div>
          <span class="control-value-display">Valor Atual: <strong>${val}</strong></span>
        `;

        const input = wrap.querySelector('.rdr-slider-input__input');
        const tooltip = wrap.querySelector('.rdr-slider-input__tooltip');
        const valDisplay = wrap.querySelector('.control-value-display strong');
        const decBtn = wrap.querySelector('[data-action="dec"]');
        const incBtn = wrap.querySelector('[data-action="inc"]');

        const updateSlider = (newVal) => {
          val = Math.max(min, Math.min(max, newVal));
          input.value = val;
          const pct = ((val - min) / (max - min)) * 100;
          input.style.setProperty('--rdr-slider-progress', `${pct}%`);
          tooltip.textContent = val;
          tooltip.style.left = `${pct}%`;
          valDisplay.textContent = val;
          if (item.onChange) item.onChange(val);
        };

        // Inicializar progresso inicial
        updateSlider(val);

        input.addEventListener('input', (e) => {
          updateSlider(parseFloat(e.target.value));
          tooltip.classList.add('visible');
        });

        input.addEventListener('mouseenter', () => tooltip.classList.add('visible'));
        input.addEventListener('mouseleave', () => tooltip.classList.remove('visible'));

        decBtn.addEventListener('click', () => {
          updateSlider(val - step);
          if (window.uiAudio) window.uiAudio.playToggle();
        });

        incBtn.addEventListener('click', () => {
          updateSlider(val + step);
          if (window.uiAudio) window.uiAudio.playToggle();
        });
        break;
      }

      case 'number': {
        const min = item.min !== undefined ? item.min : 0;
        const max = item.max !== undefined ? item.max : 999;
        const step = item.step !== undefined ? item.step : 1;
        let val = item.value !== undefined ? item.value : 10;

        wrap.innerHTML = `
          <span class="control-label">${item.label || 'Quantidade'}</span>
          <div class="rdr-number-input">
            <button class="rdr-number-input__button" data-action="dec" title="Diminuir">
              <img src="assets/textures/nav_decrease.png" alt="◄">
            </button>
            <div class="rdr-number-input__wrap">
              <input type="number" class="rdr-number-input__field" value="${val}" min="${min}" max="${max}" step="${step}">
            </div>
            <button class="rdr-number-input__button" data-action="inc" title="Aumentar">
              <img src="assets/textures/nav_increase.png" alt="►">
            </button>
          </div>
        `;

        const field = wrap.querySelector('.rdr-number-input__field');
        const decBtn = wrap.querySelector('[data-action="dec"]');
        const incBtn = wrap.querySelector('[data-action="inc"]');

        const updateNumber = (newVal) => {
          val = Math.max(min, Math.min(max, newVal));
          field.value = val;
          if (item.onChange) item.onChange(val);
        };

        field.addEventListener('change', (e) => updateNumber(parseFloat(e.target.value) || min));

        decBtn.addEventListener('click', () => {
          updateNumber(val - step);
          if (window.uiAudio) window.uiAudio.playToggle();
        });

        incBtn.addEventListener('click', () => {
          updateNumber(val + step);
          if (window.uiAudio) window.uiAudio.playToggle();
        });
        break;
      }

      case 'checkbox': {
        const isChecked = !!item.checked;
        const isDisabled = !!item.disabled;

        wrap.innerHTML = `
          <label class="rdr-checkbox ${isChecked ? 'is-checked' : ''}">
            <input type="checkbox" class="rdr-checkbox__input" ${isChecked ? 'checked' : ''} ${isDisabled ? 'disabled' : ''}>
            <span class="rdr-checkbox__box">
              <img src="assets/textures/tick.png" class="rdr-checkbox__tick" alt="✓">
            </span>
            <span class="rdr-checkbox__label">${item.label || 'Opção de Verificação'}</span>
          </label>
        `;

        const checkInput = wrap.querySelector('.rdr-checkbox__input');
        const checkLabel = wrap.querySelector('.rdr-checkbox');

        checkInput.addEventListener('change', (e) => {
          if (e.target.checked) {
            checkLabel.classList.add('is-checked');
          } else {
            checkLabel.classList.remove('is-checked');
          }
          if (window.uiAudio) window.uiAudio.playToggle();
          if (item.onChange) item.onChange(e.target.checked);
        });
        break;
      }

      case 'dropdown': {
        const options = item.options || ['Opção 1', 'Opção 2', 'Opção 3'];
        let selected = item.value || options[0] || '';
        const isDisabled = !!item.disabled;

        const optionsHtml = options.map(opt => {
          const optVal = typeof opt === 'object' ? opt.value : opt;
          const optLabel = typeof opt === 'object' ? opt.label : opt;
          const isSel = optVal === selected;
          return `<li class="rdr-dropdown__option ${isSel ? 'rdr-dropdown__option--selected' : ''}" data-value="${optVal}">
            <span class="rdr-dropdown__option-label">${optLabel}</span>
          </li>`;
        }).join('');

        wrap.innerHTML = `
          <div class="rdr-dropdown ${isDisabled ? 'is-disabled' : ''}">
            ${item.label ? `<span class="rdr-dropdown__label">${item.label}</span>` : ''}
            <div class="rdr-dropdown__wrap">
              <button class="rdr-dropdown__trigger" type="button" ${isDisabled ? 'disabled' : ''}>
                <span class="rdr-dropdown__value">${selected}</span>
                <span class="rdr-dropdown__chevron">▼</span>
              </button>
              <div class="rdr-dropdown__panel">
                <ul class="rdr-dropdown__list">
                  ${optionsHtml}
                </ul>
              </div>
            </div>
          </div>
        `;

        const dropdownEl = wrap.querySelector('.rdr-dropdown');
        const trigger = wrap.querySelector('.rdr-dropdown__trigger');
        const valSpan = wrap.querySelector('.rdr-dropdown__value');

        trigger.addEventListener('click', (e) => {
          e.stopPropagation();
          const isOpen = dropdownEl.classList.contains('rdr-dropdown--open');
          document.querySelectorAll('.rdr-dropdown--open').forEach(el => el.classList.remove('rdr-dropdown--open'));
          document.querySelectorAll('.has-open-dropdown').forEach(el => el.classList.remove('has-open-dropdown'));

          if (!isOpen && !isDisabled) {
            dropdownEl.classList.add('rdr-dropdown--open');
            wrap.classList.add('has-open-dropdown');
            dropdownEl.closest('.control-item')?.classList.add('has-open-dropdown');
            dropdownEl.closest('.controls-section')?.classList.add('has-open-dropdown');
            if (window.uiAudio) window.uiAudio.playNav();
          }
        });

        wrap.querySelectorAll('.rdr-dropdown__option').forEach(optEl => {
          optEl.addEventListener('click', (e) => {
            e.stopPropagation();
            const optVal = optEl.getAttribute('data-value');
            selected = optVal;
            valSpan.textContent = optEl.textContent.trim();
            wrap.querySelectorAll('.rdr-dropdown__option').forEach(o => o.classList.remove('rdr-dropdown__option--selected'));
            optEl.classList.add('rdr-dropdown__option--selected');
            dropdownEl.classList.remove('rdr-dropdown--open');
            wrap.classList.remove('has-open-dropdown');
            dropdownEl.closest('.control-item')?.classList.remove('has-open-dropdown');
            dropdownEl.closest('.controls-section')?.classList.remove('has-open-dropdown');
            if (window.uiAudio) window.uiAudio.playSelect();
            if (item.onChange) item.onChange(optVal);
          });
        });
        break;
      }

      case 'button': {
        const variant = item.variant || 'default';
        const sizeClass = item.size ? `rdr-button--size-${item.size}` : '';
        wrap.innerHTML = `
          <button class="rdr-button rdr-button--${variant} ${sizeClass}">
            <span class="rdr-button__label">${item.label || 'Botão de Ação'}</span>
          </button>
        `;
        const btn = wrap.querySelector('button');
        btn.addEventListener('click', () => {
          if (window.uiAudio) window.uiAudio.playSelect();
          if (item.onClick) item.onClick();
        });
        break;
      }

      case 'card': {
        wrap.innerHTML = `
          <div class="rdr-card rdr-card--padding-${item.padding || 'md'}">
            <h4 style="font-family: var(--rdr-font-title); font-size: var(--rdr-font-size-md); margin-bottom: 8px; color: var(--rdr-color-text);">${item.title || 'Cartão RDR2'}</h4>
            <p style="color: var(--rdr-color-text-muted); font-size: var(--rdr-font-size-xs); line-height: 1.4;">${item.content || 'Este é um card temático com a textura oficial de papel rústico e caixa de madeira.'}</p>
          </div>
        `;
        break;
      }

      case 'input': {
        const val = item.value || '';
        wrap.innerHTML = `
          ${item.label ? `<span class="control-label">${item.label}</span>` : ''}
          <div class="rdr-input__wrap">
            <input type="text" class="rdr-input" placeholder="${item.placeholder || 'Enter text here...'}" value="${val}" ${item.disabled ? 'disabled' : ''}>
          </div>
          <p class="control-value-display">Value: <strong>${val || 'empty'}</strong></p>
        `;
        const inp = wrap.querySelector('.rdr-input');
        const valDisplay = wrap.querySelector('.control-value-display strong');
        inp.addEventListener('input', (e) => {
          valDisplay.textContent = e.target.value || 'empty';
          if (item.onChange) item.onChange(e.target.value);
        });
        break;
      }

      case 'textarea': {
        const val = item.value || '';
        const rows = item.rows || 4;
        wrap.innerHTML = `
          ${item.label ? `<span class="control-label">${item.label}</span>` : ''}
          <div class="rdr-textarea__wrap">
            <textarea class="rdr-textarea" rows="${rows}" placeholder="${item.placeholder || 'Enter long text here...'}" ${item.disabled ? 'disabled' : ''}>${val}</textarea>
          </div>
          <p class="control-value-display">Characters: <strong>${val.length}</strong></p>
        `;
        const ta = wrap.querySelector('.rdr-textarea');
        const countDisplay = wrap.querySelector('.control-value-display strong');
        ta.addEventListener('input', (e) => {
          countDisplay.textContent = e.target.value.length;
          if (item.onChange) item.onChange(e.target.value);
        });
        break;
      }

      case 'divider': {
        wrap.innerHTML = `<hr class="rdr-divider" style="margin: ${item.margin || '14px 0'};">`;
        break;
      }

      case 'header': {
        const level = item.level || 2;
        const tag = `h${level}`;
        wrap.innerHTML = `
          <div class="rdr-header" style="margin: ${item.margin || '6px 0 12px 0'};">
            <${tag}>${item.title || item.label || 'Cabeçalho'}</${tag}>
            <hr class="rdr-divider">
          </div>
        `;
        break;
      }

      case 'panel': {
        const pad = item.padding || 'md';
        const isRed = item.variant === 'red' ? 'rdr-panel--red' : '';
        wrap.innerHTML = `
          <div class="rdr-panel ${isRed} rdr-panel--padding-${pad}" style="border: 1px solid var(--rdr-color-border);">
            ${item.title ? `<div class="rdr-header" style="margin-bottom: 12px;"><h3>${item.title}</h3><hr class="rdr-divider"></div>` : ''}
            <p style="color: var(--rdr-color-text-muted); font-size: var(--rdr-font-size-xs); line-height: 1.5; margin-bottom: 14px;">${item.content || 'Este é um painel texturizado nativo (RdrPanel).'}</p>
            ${item.buttonLabel ? `<button class="rdr-button rdr-button--default" style="align-self: flex-start;"><span class="rdr-button__label">${item.buttonLabel}</span></button>` : ''}
          </div>
        `;
        if (item.buttonLabel) {
          const btn = wrap.querySelector('button');
          btn.addEventListener('click', () => {
            if (window.uiAudio) window.uiAudio.playSelect();
            if (item.onButtonClick) item.onButtonClick();
          });
        }
        break;
      }

      case 'transition_test': {
        wrap.innerHTML = `
          <div style="display: flex; flex-direction: column; gap: 12px;">
            <button class="rdr-button rdr-button--default toggle-transition-btn">
              <span class="rdr-button__label">Alternar Caixa Animada (Zoom-In)</span>
            </button>
            <div class="transition-test-box animate-zoom-in" style="background: var(--rdr-texture-box); padding: 18px; border: 1px solid var(--rdr-color-border); display: block;">
              <h4 style="font-family: var(--rdr-font-title); font-size: 18px; color: var(--rdr-color-text); margin-bottom: 6px;">Caixa com Transição Zoom-In</h4>
              <p style="color: var(--rdr-color-text-muted); font-size: 14px;">A animação nativa utiliza curva cúbica Rockstar bezier(0.25, 0.8, 0.25, 1) com transição de opacidade e escala.</p>
            </div>
          </div>
        `;
        const tBtn = wrap.querySelector('.toggle-transition-btn');
        const tBox = wrap.querySelector('.transition-test-box');
        let isVisible = true;
        tBtn.addEventListener('click', () => {
          isVisible = !isVisible;
          if (isVisible) {
            tBox.style.display = 'block';
            tBox.className = 'transition-test-box animate-zoom-in';
          } else {
            tBox.style.display = 'none';
          }
          if (window.uiAudio) window.uiAudio.playToggle();
        });
        break;
      }

      case 'modal_trigger': {
        wrap.innerHTML = `
          <button class="rdr-button rdr-button--default">
            <span class="rdr-button__label">${item.label || 'ABRIR MODAL (RDRMODAL)'}</span>
          </button>
        `;
        wrap.querySelector('button').addEventListener('click', () => {
          if (window.uiModal) {
            window.uiModal.open({
              title: item.modalTitle || 'MODAL OFICIAL RDR2',
              subtitle: item.modalSubtitle || 'Dialog flutuante central com textura e animação zoom-in',
              content: item.modalContent || 'Este modal representa fielmente o componente RdrModal do RedM Vue UI, com backdrop sombreado, fechar com ESC ou clique externo, e botão nativo X.',
              buttons: [
                { label: 'CANCELAR', variant: 'subtle', action: 'close' },
                { label: 'CONFIRMAR AÇÃO', variant: 'default', onClick: () => {
                  if (window.uiToast) window.uiToast.show('MODAL CONFIRMADO', 'Ação confirmada através do RdrModal!', 'success');
                }, action: 'close' }
              ]
            });
          }
        });
        break;
      }

      case 'slider_panel_trigger': {
        wrap.innerHTML = `
          <button class="rdr-button rdr-button--subtle rdr-button--size-lg">
            <span class="rdr-button__label">${item.label || 'ABRIR GAVETA LATERAL (RDRSLIDER)'}</span>
          </button>
        `;
        wrap.querySelector('button').addEventListener('click', () => {
          if (window.uiSliderPanel) {
            window.uiSliderPanel.open({
              side: item.side || 'right',
              width: item.width || '360px',
              title: item.sliderTitle || 'GAVETA LATERAL',
              content: item.sliderContent || 'Painel deslizante nativo ancorado à borda da tela. Ideal para inventários complementares, detalhes de registros, logs e ferramentas de suporte.',
              html: `
                <p style="color: var(--rdr-color-text-muted); font-size: 14px; margin-bottom: 16px;">
                  Desliza suavemente pela lateral com curva cúbica e textura oficial de pergaminho.
                </p>
                <hr class="rdr-divider">
                <div class="rdr-card rdr-card--padding-sm" style="margin-top: 14px;">
                  <span style="font-size: 12px; color: var(--color-gold-light); letter-spacing: 1px;">STATUS DO OPERADOR</span>
                  <p style="font-size: 14px; color: #fff; margin-top: 4px;">Patrulha ativa em Valentine</p>
                </div>
              `
            });
          }
        });
        break;
      }

      default:
        break;
    }

    return wrap;
  }

  getDefaultControlsDemo() {
    return [
      {
        title: 'CABEÇALHOS & DIVISORES (RDRHEADER & RDRDIVIDER)',
        description: 'Títulos temáticos com separador de diamante nativo e divisores horizontais.',
        layout: 'grid-2',
        items: [
          { type: 'header', level: 1, title: 'Título Nível 1 (H1)' },
          { type: 'header', level: 2, title: 'Título Nível 2 (H2)' },
          { type: 'header', level: 3, title: 'Título Nível 3 (H3)' },
          { type: 'divider' }
        ]
      },
      {
        title: 'CAMPOS DE ENTRADA (RDRINPUT)',
        description: 'Campo de texto envolto em crafting_outline com exibição reativa de valor.',
        layout: 'grid-2',
        items: [
          { type: 'input', label: 'Nome do Cidadão', placeholder: 'Digite seu nome completo...', value: 'Arthur Morgan' },
          { type: 'input', label: 'Alcunha / Apelido', placeholder: 'Digite o apelido de procurado...' }
        ]
      },
      {
        title: 'ÁREAS DE TEXTO (RDRTEXTAREA)',
        description: 'Entrada multilinhas com altura configurável em linhas e contador de caracteres em tempo real.',
        layout: 'grid-2',
        items: [
          { type: 'textarea', label: 'Relatório de Ocorrência Policial', placeholder: 'Descreva os fatos ocorridos, horários e testemunhas presentes...', rows: 4, value: 'Incidente registrado no Saloon Smithfield após discussão sobre jogo de pôquer.' },
          { type: 'textarea', label: 'Termos de Contrato de Trabalho', placeholder: 'Insira as cláusulas de prestação de serviços...', rows: 4 }
        ]
      },
      {
        title: 'SLIDERS INTERATIVOS (RDRSLIDERINPUT)',
        description: 'Barras de ajuste com suporte a setas laterais, thumb com textura nativa e preenchimento de progresso.',
        layout: 'grid-2',
        items: [
          { type: 'slider', label: 'Sensibilidade de Mira', min: 0, max: 100, step: 5, value: 65 },
          { type: 'slider', label: 'Volume de Efeitos Sonoros', min: 0, max: 100, step: 10, value: 80 }
        ]
      },
      {
        title: 'ENTRADA NUMÉRICA (RDRNUMBERINPUT)',
        description: 'Controle de incremento/decremento com bordas texturizadas border-image.',
        layout: 'grid-2',
        items: [
          { type: 'number', label: 'Munição por Pacote', min: 1, max: 100, step: 5, value: 25 },
          { type: 'number', label: 'Cargas de Dinamite', min: 0, max: 20, step: 1, value: 3 }
        ]
      },
      {
        title: 'CAIXAS DE VERIFICAÇÃO (RDRCHECKBOX)',
        description: 'Checkboxes autênticos de 24x24px com tick nativo extraído da biblioteca RDR2.',
        layout: 'grid-3',
        items: [
          { type: 'checkbox', label: 'Aceitar Termos da Fronteira', checked: true },
          { type: 'checkbox', label: 'Despachos por Telegrama', checked: true },
          { type: 'checkbox', label: 'Bloqueado por Segurança', checked: false, disabled: true }
        ]
      },
      {
        title: 'MENUS SUSPENSOS (RDRDROPDOWN)',
        description: 'Seletores com chevron animado em 180 graus e painel texturizado.',
        layout: 'grid-2',
        items: [
          {
            type: 'dropdown',
            label: 'Ofício / Especialidade',
            options: ['Caçador de Recompensas', 'Armeiro de Saint Denis', 'Médico Cirurgião', 'Comerciante de Peles'],
            value: 'Caçador de Recompensas'
          },
          {
            type: 'dropdown',
            label: 'Armamento de Porte',
            options: ['Revólver Schofield', 'Pistola Volcanic', 'Carabina de Repetição', 'Espingarda de Cano Duplo'],
            value: 'Revólver Schofield'
          }
        ]
      },
      {
        title: 'BOTÕES UNIVERSAIS (RDRBUTTON)',
        description: 'Botão primário 80px com textura box.png / box-red.png e botões sutis refinados.',
        layout: 'grid-2',
        items: [
          { type: 'button', label: 'BOTÃO PRIMÁRIO NATIVO', variant: 'default' },
          { type: 'button', label: 'SUBTLE LARGE (18PX)', variant: 'subtle', size: 'lg' }
        ]
      },
      {
        title: 'PAINÉIS DE CONTEÚDO (RDRPANEL)',
        description: 'Superfícies de conteúdo amplas com texturas bg.png e bg-red.png.',
        layout: 'grid-2',
        items: [
          {
            type: 'panel',
            padding: 'md',
            title: 'Painel Padrão (bg.png)',
            content: 'Superfície com textura de pergaminho escuro, ideal para agrupar informações e fluxos complexos.',
            buttonLabel: 'AÇÃO DO PAINEL'
          },
          {
            type: 'panel',
            variant: 'red',
            padding: 'md',
            title: 'Painel Carmesim (bg-red.png)',
            content: 'Variante vermelha rústica de alta notoriedade, ideal para áreas de perigo, procurados e avisos urgentes.',
            buttonLabel: 'CONFIRMAR RISCO'
          }
        ]
      },
      {
        title: 'CARTÕES TEXTURIZADOS (RDRCARD)',
        description: 'Contêineres com textura box.png e diferentes níveis de padding.',
        layout: 'grid-2',
        items: [
          {
            type: 'card',
            padding: 'md',
            title: 'Despacho da Xerifaria',
            content: 'Todas as atividades comerciais em Valentine estão sob vigilância estrita das autoridades federais.'
          },
          {
            type: 'card',
            padding: 'lg',
            title: 'Registro de Caça',
            content: 'Peles perfeitas de bisão e cervo-do-canadá devem ser entregues diretamente ao armazém do acampamento.'
          }
        ]
      },
      {
        title: 'MODAIS & GAVETAS LATERAIS (RDRMODAL & RDRSLIDER)',
        description: 'Janelas modais com animação zoom-in e gavetas laterais deslizantes (slide-in).',
        layout: 'grid-2',
        items: [
          {
            type: 'modal_trigger',
            label: 'ABRIR MODAL (RDRMODAL ZOOM-IN)',
            modalTitle: 'DESPACHO OFICIAL DO TRIBUNAL',
            modalSubtitle: 'Notificação judicial da Comarca de New Hanover',
            modalContent: 'Este diálogo modal utiliza a transição nativa zoomAndFadeIn com curva cúbica bezier(0.25, 0.8, 0.25, 1), textura bg.png de alta resolução e botão de fechamento nav_close.png.'
          },
          {
            type: 'slider_panel_trigger',
            label: 'ABRIR GAVETA LATERAL (RDRSLIDER)',
            side: 'right',
            sliderTitle: 'INSPEÇÃO LATERAL',
            sliderContent: 'Gaveta lateral que desliza pela borda direita da tela, preservando o contexto principal enquanto exibe detalhes complementares.'
          }
        ]
      },
      {
        title: 'TRANSIÇÕES NATIVAS (ZOOM-IN & CURVAS CÚBICAS)',
        description: 'Teste de transições nativas puras sem dependências externas de compilação.',
        layout: 'grid-2',
        items: [
          { type: 'transition_test' }
        ]
      }
    ];
  }

  executeCTA() {
    if (!this.selectedItem) {
      if (window.uiAudio) window.uiAudio.playError();
      return;
    }

    if (window.uiAudio) window.uiAudio.playSelect();
    const curTab = this.tabs[this.activeTabIndex];

    fetch('https://westrp_ui/panelAction', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tabId: curTab ? curTab.id : 'main',
        item: this.selectedItem,
        quantity: this.stepperQuantity
      })
    }).catch(() => {});
  }
}

window.uiPanel = new PanelComponent();
