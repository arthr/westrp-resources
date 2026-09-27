/**
 * WestRP UI Engine — Dock Lateral Component (350px / Teclado)
 */

class DockComponent {
  constructor() {
    this.container = document.getElementById('dock-container');
    this.tagEl = document.getElementById('dock-tag');
    this.titleEl = document.getElementById('dock-title');
    this.counterEl = document.getElementById('dock-item-counter');
    this.tabsBarEl = document.getElementById('dock-tabs-bar');
    this.tabIndexEl = document.getElementById('dock-tab-index');
    this.tabNameEl = document.getElementById('current-tab-name');
    this.viewportEl = document.getElementById('dock-viewport');
    this.infoBoxEl = document.getElementById('dock-info-box');
    this.infoTextEl = document.getElementById('dock-info-text');
    this.breadcrumbEl = document.getElementById('dock-breadcrumb');
    this.breadcrumbTitleEl = document.getElementById('dock-breadcrumb-title');
    this.kCursorBox = document.getElementById('dock-k-cursor-box');
    this.kCursorLabel = document.getElementById('dock-k-cursor-label');

    this.isOpen = false;
    this.hasCursor = false;
    this.menuId = 'default_menu';
    this.tabs = [];
    this.activeTabIndex = 0;
    this.activeItemIndex = 0;
    this.submenuStack = []; // Pilha de submenus

    this.setupButtons();
  }

  initEls() {
    if (!this.container) {
      this.container = document.getElementById('dock-container');
      this.tagEl = document.getElementById('dock-tag');
      this.titleEl = document.getElementById('dock-title');
      this.counterEl = document.getElementById('dock-item-counter');
      this.tabsBarEl = document.getElementById('dock-tabs-bar');
      this.tabIndexEl = document.getElementById('dock-tab-index');
      this.tabNameEl = document.getElementById('current-tab-name');
      this.viewportEl = document.getElementById('dock-viewport');
      this.infoBoxEl = document.getElementById('dock-info-box');
      this.infoTextEl = document.getElementById('dock-info-text');
      this.breadcrumbEl = document.getElementById('dock-breadcrumb');
      this.breadcrumbTitleEl = document.getElementById('dock-breadcrumb-title');
      this.kCursorBox = document.getElementById('dock-k-cursor-box');
      this.kCursorLabel = document.getElementById('dock-k-cursor-label');
    }
  }

  setupButtons() {
    const btnPrev = document.getElementById('btn-tab-prev');
    const btnNext = document.getElementById('btn-tab-next');
    if (btnPrev) btnPrev.addEventListener('click', () => this.prevTab());
    if (btnNext) btnNext.addEventListener('click', () => this.nextTab());

    const cursorGroup = document.getElementById('dock-k-cursor-group');
    if (cursorGroup) {
      cursorGroup.addEventListener('click', () => this.toggleCursor());
    }
  }

  open(options) {
    this.initEls();
    if (!this.container) return;

    this.menuId = options.id || 'default_menu';
    this.tagEl.textContent = options.tag || 'FRONTIER';
    this.titleEl.textContent = options.title || 'REGISTRO';

    if (options.width) {
      this.container.style.width = typeof options.width === 'number' ? `${options.width}px` : options.width;
    } else {
      this.container.style.width = '';
    }

    // Normaliza abas / itens
    if (options.tabs && options.tabs.length > 0) {
      this.tabs = options.tabs;
    } else if (options.items) {
      this.tabs = [{ id: 'main', label: 'PRINCIPAL', items: options.items }];
    } else {
      this.tabs = [{ id: 'empty', label: 'GERAL', items: [] }];
    }

    this.activeTabIndex = 0;
    this.activeItemIndex = 0;
    this.submenuStack = [];

    this.renderTabs();
    this.renderItems();

    this.hasCursor = false;
    this.updateCursorIndicator();

    this.container.style.display = 'flex';
    this.isOpen = true;
    if (window.uiAudio) window.uiAudio.playNav();
  }

  close() {
    if (!this.isOpen) return;
    this.container.style.display = 'none';
    this.container.style.width = '';
    this.isOpen = false;
    this.hasCursor = false;
    this.updateCursorIndicator();
    this.submenuStack = [];

    fetch('https://westrp_ui/close', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: this.menuId })
    }).catch(() => {});
  }

  getCurrentItems() {
    if (this.submenuStack.length > 0) {
      return this.submenuStack[this.submenuStack.length - 1].items || [];
    }
    const currentTab = this.tabs[this.activeTabIndex];
    return currentTab ? currentTab.items || [] : [];
  }

  renderTabs() {
    if (this.tabs.length > 1 && this.submenuStack.length === 0) {
      this.tabsBarEl.style.display = 'flex';
      const cur = this.tabs[this.activeTabIndex];
      this.tabIndexEl.textContent = `ABA ${this.activeTabIndex + 1} / ${this.tabs.length}`;
      this.tabNameEl.textContent = cur ? (cur.name || cur.label || 'ABA') : '';
    } else {
      this.tabsBarEl.style.display = 'none';
    }

    // Breadcrumb
    if (this.submenuStack.length > 0) {
      this.breadcrumbEl.style.display = 'flex';
      this.breadcrumbTitleEl.textContent = this.submenuStack[this.submenuStack.length - 1].title || 'SUBMENU';
    } else {
      this.breadcrumbEl.style.display = 'none';
    }
  }

  renderItems() {
    this.viewportEl.innerHTML = '';
    const items = this.getCurrentItems();

    if (items.length === 0) {
      this.counterEl.textContent = '0 / 0';
      this.infoTextEl.textContent = 'Nenhuma opção disponível nesta categoria.';
      const empty = document.createElement('div');
      empty.className = 'dock-item empty';
      empty.innerHTML = `<span class="dock-item-label" style="color: var(--color-text-muted);">Vazio</span>`;
      this.viewportEl.appendChild(empty);
      return;
    }

    if (this.activeItemIndex >= items.length) {
      this.activeItemIndex = items.length - 1;
    }
    if (this.activeItemIndex < 0) {
      this.activeItemIndex = 0;
    }

    this.counterEl.textContent = `${this.activeItemIndex + 1} / ${items.length}`;

    items.forEach((item, index) => {
      const el = document.createElement('div');
      el.className = `dock-item ${index === this.activeItemIndex ? 'active' : ''} ${item.disabled ? 'disabled' : ''}`;
      el.dataset.index = index;

      const left = document.createElement('div');
      left.className = 'dock-item-left';

      const label = document.createElement('span');
      label.className = 'dock-item-label';
      label.textContent = item.label || item.title || item.id;
      left.appendChild(label);

      if (item.sublabel) {
        const sub = document.createElement('span');
        sub.className = 'dock-item-sublabel';
        sub.textContent = item.sublabel;
        left.appendChild(sub);
      }

      const right = document.createElement('div');
      right.className = 'dock-item-right';

      // Slider
      if (item.type === 'slider') {
        const sliderWrap = document.createElement('div');
        sliderWrap.className = 'dock-slider-wrap';
        let displayVal = item.value;
        if (item.options && item.options.length > 0) {
          const vIdx = item.valueIndex !== undefined ? item.valueIndex : 0;
          displayVal = item.options[vIdx] || item.options[0];
        }
        sliderWrap.innerHTML = `<span class="slider-arrow prev" style="cursor:pointer;padding:2px 6px;">◄</span> <strong>${displayVal}</strong> <span class="slider-arrow next" style="cursor:pointer;padding:2px 6px;">►</span>`;

        const prevBtn = sliderWrap.querySelector('.slider-arrow.prev');
        const nextBtn = sliderWrap.querySelector('.slider-arrow.next');
        if (prevBtn) {
          prevBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            this.activeItemIndex = index;
            this.adjustSlider('left');
          });
        }
        if (nextBtn) {
          nextBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            this.activeItemIndex = index;
            this.adjustSlider('right');
          });
        }

        right.appendChild(sliderWrap);
      }
      // Toggle
      else if (item.type === 'toggle') {
        const dot = document.createElement('div');
        dot.className = `dock-toggle-box ${item.checked ? 'checked' : ''}`;
        right.appendChild(dot);
      }
      // Submenu
      else if (item.type === 'submenu') {
        const arrow = document.createElement('span');
        arrow.className = 'dock-submenu-arrow';
        arrow.textContent = '►';
        right.appendChild(arrow);
      }
      // Badge / Preço
      else if (item.badge) {
        const pill = document.createElement('span');
        pill.className = `status-pill ${item.badgeType || 'gold'}`;
        pill.textContent = item.badge;
        right.appendChild(pill);
      }

      el.appendChild(left);
      el.appendChild(right);

      el.addEventListener('click', () => {
        this.selectItem(index);
        this.executeCurrentItem();
      });

      this.viewportEl.appendChild(el);
    });

    // Atualiza info box
    const currentItem = items[this.activeItemIndex];
    if (currentItem && currentItem.description) {
      this.infoTextEl.textContent = currentItem.description;
    } else {
      this.infoTextEl.textContent = 'Pressione [ENTER] para executar esta opção.';
    }

    // Scroll suave para manter o item visível
    const activeEl = this.viewportEl.children[this.activeItemIndex];
    if (activeEl) {
      activeEl.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }
  }

  selectItem(index) {
    const items = this.getCurrentItems();
    if (index >= 0 && index < items.length) {
      this.activeItemIndex = index;
      this.renderItems();
      if (window.uiAudio) window.uiAudio.playNav();
    }
  }

  navigate(direction) {
    const items = this.getCurrentItems();
    if (items.length === 0) return;

    if (direction === 'up') {
      this.activeItemIndex = (this.activeItemIndex - 1 + items.length) % items.length;
    } else if (direction === 'down') {
      this.activeItemIndex = (this.activeItemIndex + 1) % items.length;
    }

    this.renderItems();
    if (window.uiAudio) window.uiAudio.playNav();
  }

  adjustSlider(direction) {
    const items = this.getCurrentItems();
    const item = items[this.activeItemIndex];

    if (item && !item.disabled && item.type === 'slider') {
      if (item.options && item.options.length > 0) {
        let vIdx = item.valueIndex !== undefined ? item.valueIndex : 0;
        if (direction === 'left') {
          vIdx = (vIdx - 1 + item.options.length) % item.options.length;
        } else {
          vIdx = (vIdx + 1) % item.options.length;
        }
        item.valueIndex = vIdx;
        item.value = item.options[vIdx];
      } else {
        const step = item.step || 1;
        const min = item.min !== undefined ? item.min : 0;
        const max = item.max !== undefined ? item.max : 100;
        let val = (item.value !== undefined ? item.value : min);
        if (direction === 'left') {
          val = Math.max(min, val - step);
        } else {
          val = Math.min(max, val + step);
        }
        item.value = val;
      }

      this.renderItems();
      if (window.uiAudio) window.uiAudio.playToggle();
      this.postChange(item, item.value);
    } else if (this.tabs && this.tabs.length > 1 && this.submenuStack.length === 0) {
      if (direction === 'left') {
        this.prevTab();
      } else {
        this.nextTab();
      }
    }
  }

  toggleCurrentItem() {
    const items = this.getCurrentItems();
    const item = items[this.activeItemIndex];
    if (!item || item.disabled) return;

    if (item.type === 'toggle') {
      item.checked = !item.checked;
      this.renderItems();
      if (window.uiAudio) window.uiAudio.playToggle();
      this.postChange(item, item.checked);
    }
  }

  executeCurrentItem() {
    const items = this.getCurrentItems();
    const item = items[this.activeItemIndex];
    if (!item || item.disabled) {
      if (window.uiAudio) window.uiAudio.playError();
      return;
    }

    if (item.type === 'toggle') {
      this.toggleCurrentItem();
      return;
    }

    if (item.type === 'submenu' && item.subItems) {
      if (window.uiAudio) window.uiAudio.playSelect();
      this.submenuStack.push({
        title: item.label || 'SUBMENU',
        items: item.subItems
      });
      this.activeItemIndex = 0;
      this.renderTabs();
      this.renderItems();
      return;
    }

    if (window.uiAudio) window.uiAudio.playSelect();
    const curTab = this.tabs[this.activeTabIndex];
    fetch('https://westrp_ui/itemSelect', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tabId: curTab ? curTab.id : 'main',
        item: item
      })
    }).catch(() => {});
  }

  goBack() {
    if (this.submenuStack.length > 0) {
      if (window.uiAudio) window.uiAudio.playNav();
      this.submenuStack.pop();
      this.activeItemIndex = 0;
      this.renderTabs();
      this.renderItems();
      return;
    }
    this.close();
  }

  prevTab() {
    if (this.tabs.length <= 1 || this.submenuStack.length > 0) return;
    this.activeTabIndex = (this.activeTabIndex - 1 + this.tabs.length) % this.tabs.length;
    this.activeItemIndex = 0;
    this.renderTabs();
    this.renderItems();
    if (window.uiAudio) window.uiAudio.playNav();
  }

  nextTab() {
    if (this.tabs.length <= 1 || this.submenuStack.length > 0) return;
    this.activeTabIndex = (this.activeTabIndex + 1) % this.tabs.length;
    this.activeItemIndex = 0;
    this.renderTabs();
    this.renderItems();
    if (window.uiAudio) window.uiAudio.playNav();
  }

  postChange(item, value) {
    const curTab = this.tabs[this.activeTabIndex];
    fetch('https://westrp_ui/itemChange', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tabId: curTab ? curTab.id : 'main',
        item: item,
        value: value
      })
    }).catch(() => {});
  }

  toggleCursor() {
    this.setCursorState(!this.hasCursor, true);
  }

  setCursorState(hasCursor, notifyServer = false) {
    this.hasCursor = !!hasCursor;
    this.updateCursorIndicator();

    if (notifyServer) {
      fetch('https://westrp_ui/toggleDockCursor', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ hasCursor: this.hasCursor })
      }).catch(() => {});
    }

    if (window.uiAudio) window.uiAudio.playToggle();
  }

  updateCursorIndicator() {
    if (!this.kCursorBox) this.kCursorBox = document.getElementById('dock-k-cursor-box');
    if (!this.kCursorLabel) this.kCursorLabel = document.getElementById('dock-k-cursor-label');

    if (this.kCursorBox) {
      this.kCursorBox.classList.toggle('active', this.hasCursor);
    }
    if (this.kCursorLabel) {
      this.kCursorLabel.classList.toggle('active', this.hasCursor);
      this.kCursorLabel.textContent = this.hasCursor ? 'Mouse [ON]' : 'Mouse [OFF]';
    }
  }
}

window.uiDock = new DockComponent();
