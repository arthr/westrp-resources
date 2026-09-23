/**
 * WESTRP UI DOCK ENGINE — JAVASCRIPT MOTOR NUI
 * 100% Data-Driven | Web Audio Procedural Ticks | Keyboard & Mouse Friendly
 */

(function () {
  'use strict';

  // --- 1. SINTETIZADOR DE ÁUDIO PROCEDURAL (Web Audio API) ---
  let audioCtx = null;

  function playUiTick(type = 'nav') {
    try {
      if (!audioCtx) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      }
      if (audioCtx.state === 'suspended') {
        audioCtx.resume();
      }

      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      const now = audioCtx.currentTime;

      if (type === 'nav') {
        osc.frequency.setValueAtTime(650, now);
        osc.frequency.exponentialRampToValueAtTime(320, now + 0.02);
        gain.gain.setValueAtTime(0.04, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.02);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now);
        osc.stop(now + 0.02);
      } else if (type === 'confirm') {
        osc.frequency.setValueAtTime(880, now);
        osc.frequency.exponentialRampToValueAtTime(1320, now + 0.04);
        gain.gain.setValueAtTime(0.06, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now);
        osc.stop(now + 0.04);
      } else if (type === 'back') {
        osc.frequency.setValueAtTime(450, now);
        osc.frequency.exponentialRampToValueAtTime(200, now + 0.03);
        gain.gain.setValueAtTime(0.05, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now);
        osc.stop(now + 0.03);
      } else if (type === 'error') {
        osc.frequency.setValueAtTime(220, now);
        osc.frequency.exponentialRampToValueAtTime(110, now + 0.05);
        gain.gain.setValueAtTime(0.07, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now);
        osc.stop(now + 0.05);
      }
    } catch (e) {
      // Ignora silenciosamente se o navegador restringir áudio
    }
  }

  // --- 2. ESTADO DO MOTOR ---
  const state = {
    isOpen: false,
    menuId: '',
    title: 'REGISTRO',
    tag: 'FRONTIER',
    tabs: [], // Array de { id, name, items }
    activeTabIndex: 0,
    selectedIndex: 0,
    navigationStack: [] // Submenus hierárquicos: { title, items }
  };

  // --- 3. ELEMENTOS DO DOM ---
  const el = {
    container: document.getElementById('dock-container'),
    tag: document.getElementById('dock-tag'),
    title: document.getElementById('dock-title'),
    counter: document.getElementById('dock-item-counter'),
    tabsBar: document.getElementById('dock-tabs-bar'),
    tabIndex: document.getElementById('dock-tab-index'),
    tabName: document.getElementById('current-tab-name'),
    btnTabPrev: document.getElementById('btn-tab-prev'),
    btnTabNext: document.getElementById('btn-tab-next'),
    breadcrumb: document.getElementById('dock-breadcrumb'),
    breadcrumbTitle: document.getElementById('dock-breadcrumb-title'),
    viewport: document.getElementById('dock-viewport'),
    infoText: document.getElementById('dock-info-text'),
    toastContainer: document.getElementById('toast-container'),
    tabsLegend: document.getElementById('k-tabs-legend')
  };

  // --- 4. COMUNICAÇÃO NUI COM O REDM CLIENT LUA ---
  function postData(endpoint, data = {}) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'westrp_ui';
    fetch(`https://${resourceName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data)
    }).catch(() => {});
  }

  // --- 5. RENDERIZAÇÃO DE DADOS ---

  function getCurrentItems() {
    if (state.navigationStack.length > 0) {
      const currentSubmenu = state.navigationStack[state.navigationStack.length - 1];
      return currentSubmenu.items || [];
    }
    if (state.tabs.length > 0 && state.tabs[state.activeTabIndex]) {
      return state.tabs[state.activeTabIndex].items || [];
    }
    return [];
  }

  function getCurrentTabId() {
    if (state.tabs.length > 0 && state.tabs[state.activeTabIndex]) {
      return state.tabs[state.activeTabIndex].id;
    }
    return 'default';
  }

  function renderHeader() {
    el.tag.textContent = state.tag || 'FRONTIER';
    el.title.textContent = state.title || 'REGISTRO';
  }

  function renderTabsBar() {
    const hasTabs = state.tabs.length > 1;
    const isSubmenu = state.navigationStack.length > 0;

    if (hasTabs && !isSubmenu) {
      el.tabsBar.style.display = 'flex';
      el.tabsLegend.style.display = 'flex';
      el.tabIndex.textContent = `ABA ${state.activeTabIndex + 1} / ${state.tabs.length}`;
      el.tabName.textContent = state.tabs[state.activeTabIndex].name || 'GERAL';
    } else {
      el.tabsBar.style.display = 'none';
      el.tabsLegend.style.display = 'none';
    }
  }

  function renderBreadcrumb() {
    if (state.navigationStack.length > 0) {
      el.breadcrumb.style.display = 'flex';
      const currentSubmenu = state.navigationStack[state.navigationStack.length - 1];
      el.breadcrumbTitle.textContent = currentSubmenu.title || 'SUBMENU';
    } else {
      el.breadcrumb.style.display = 'none';
    }
  }

  function renderViewport() {
    const items = getCurrentItems();
    el.viewport.innerHTML = '';

    if (items.length === 0) {
      el.counter.textContent = '0 / 0';
      el.viewport.innerHTML = '<div class="dock-empty-msg">Nenhum registro disponível.</div>';
      el.infoText.textContent = 'Nenhuma opção configurada neste menu.';
      return;
    }

    if (state.selectedIndex >= items.length) {
      state.selectedIndex = Math.max(0, items.length - 1);
    }

    el.counter.textContent = `${state.selectedIndex + 1} / ${items.length}`;

    items.forEach((item, index) => {
      const row = document.createElement('div');
      row.className = 'dock-item';
      if (index === state.selectedIndex) row.classList.add('selected');
      if (item.danger) row.classList.add('danger');
      if (item.disabled) row.classList.add('disabled');
      row.dataset.index = index;

      // Coluna Esquerda: Label e Sublabel
      const mainCol = document.createElement('div');
      mainCol.className = 'dock-item-main';

      const labelSpan = document.createElement('span');
      labelSpan.className = 'dock-item-label';
      labelSpan.textContent = item.label || 'Opção';
      mainCol.appendChild(labelSpan);

      if (item.sublabel) {
        const subSpan = document.createElement('span');
        subSpan.className = 'dock-item-sublabel';
        subSpan.textContent = item.sublabel;
        mainCol.appendChild(subSpan);
      }

      row.appendChild(mainCol);

      // Coluna Direita: Controles e Badges
      const rightCol = document.createElement('div');
      rightCol.className = 'dock-item-right';

      if (item.type === 'toggle') {
        const pill = document.createElement('span');
        pill.className = `status-pill ${item.checked ? 'on' : 'off'}`;
        pill.textContent = item.checked ? 'LIGADO' : 'DESLIGADO';
        rightCol.appendChild(pill);
      } else if (item.type === 'slider') {
        const slider = document.createElement('div');
        slider.className = 'slider-wrapper';
        const displayVal = (item.options && item.options.length > 0)
          ? item.options[item.valueIndex || 0]
          : (item.value !== undefined ? item.value : (item.min || 0));
        slider.innerHTML = `<span class="slider-arrow">◄</span> <span>${displayVal}</span> <span class="slider-arrow">►</span>`;
        rightCol.appendChild(slider);
      } else if (item.type === 'submenu') {
        const arrow = document.createElement('span');
        arrow.className = 'submenu-arrow';
        arrow.textContent = '▸';
        rightCol.appendChild(arrow);
      } else if (item.badge) {
        const badge = document.createElement('span');
        badge.className = `status-pill ${item.badgeType || 'gold'}`;
        badge.textContent = item.badge;
        rightCol.appendChild(badge);
      }

      row.appendChild(rightCol);

      // Suporte a Clique do Mouse
      row.addEventListener('click', () => {
        if (item.disabled) return;
        state.selectedIndex = index;
        updateSelection(true);
        executeCurrentItem();
      });

      row.addEventListener('mouseenter', () => {
        if (state.selectedIndex !== index) {
          state.selectedIndex = index;
          updateSelection(false);
          playUiTick('nav');
        }
      });

      el.viewport.appendChild(row);
    });

    updateInfoText();
    ensureItemVisible();
  }

  function updateSelection(playAudio = false) {
    const items = getCurrentItems();
    if (items.length === 0) return;

    el.counter.textContent = `${state.selectedIndex + 1} / ${items.length}`;

    const rows = el.viewport.querySelectorAll('.dock-item');
    rows.forEach((row, idx) => {
      if (idx === state.selectedIndex) {
        row.classList.add('selected');
      } else {
        row.classList.remove('selected');
      }
    });

    updateInfoText();
    ensureItemVisible();

    if (playAudio) playUiTick('nav');
  }

  function updateInfoText() {
    const items = getCurrentItems();
    if (items.length === 0 || !items[state.selectedIndex]) {
      el.infoText.textContent = '';
      return;
    }
    const current = items[state.selectedIndex];
    el.infoText.textContent = current.description || 'Pressione [ENTER] para executar esta opção.';
  }

  function ensureItemVisible() {
    const rows = el.viewport.querySelectorAll('.dock-item');
    const selectedRow = rows[state.selectedIndex];
    if (selectedRow) {
      selectedRow.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }
  }

  // --- 6. EXECUÇÃO DE AÇÕES ---

  function executeCurrentItem() {
    const items = getCurrentItems();
    if (items.length === 0) return;

    const item = items[state.selectedIndex];
    if (!item || item.disabled) {
      playUiTick('error');
      return;
    }

    if (item.type === 'submenu') {
      if (item.subItems && item.subItems.length > 0) {
        state.navigationStack.push({
          title: item.label,
          items: item.subItems
        });
        state.selectedIndex = 0;
        playUiTick('confirm');
        renderBreadcrumb();
        renderTabsBar();
        renderViewport();
      } else {
        playUiTick('error');
      }
      return;
    }

    if (item.type === 'toggle') {
      item.checked = !item.checked;
      playUiTick('confirm');
      renderViewport();
      postData('westrp_ui:changeValue', {
        menuId: state.menuId,
        tabId: getCurrentTabId(),
        itemId: item.id,
        newValue: item.checked,
        item: item
      });
      return;
    }

    // Botão / Ação padrão
    playUiTick('confirm');
    postData('westrp_ui:selectItem', {
      menuId: state.menuId,
      tabId: getCurrentTabId(),
      itemId: item.id,
      item: item
    });
  }

  function handleSliderStep(direction) {
    const items = getCurrentItems();
    if (items.length === 0) return;

    const item = items[state.selectedIndex];
    if (!item || item.type !== 'slider' || item.disabled) return false;

    if (item.options && item.options.length > 0) {
      item.valueIndex = item.valueIndex || 0;
      if (direction === 'left') {
        item.valueIndex = (item.valueIndex - 1 + item.options.length) % item.options.length;
      } else {
        item.valueIndex = (item.valueIndex + 1) % item.options.length;
      }
      item.value = item.options[item.valueIndex];
    } else {
      const min = item.min !== undefined ? item.min : 0;
      const max = item.max !== undefined ? item.max : 100;
      const step = item.step || 1;
      item.value = item.value !== undefined ? item.value : min;

      if (direction === 'left') {
        item.value = Math.max(min, item.value - step);
      } else {
        item.value = Math.min(max, item.value + step);
      }
    }

    playUiTick('nav');
    renderViewport();
    postData('westrp_ui:changeValue', {
      menuId: state.menuId,
      tabId: getCurrentTabId(),
      itemId: item.id,
      newValue: item.value,
      item: item
    });
    return true;
  }

  function switchTab(direction) {
    if (state.navigationStack.length > 0 || state.tabs.length <= 1) return;

    if (direction === 'prev') {
      state.activeTabIndex = (state.activeTabIndex - 1 + state.tabs.length) % state.tabs.length;
    } else {
      state.activeTabIndex = (state.activeTabIndex + 1) % state.tabs.length;
    }

    state.selectedIndex = 0;
    playUiTick('nav');
    renderTabsBar();
    renderViewport();

    postData('westrp_ui:tabChanged', {
      menuId: state.menuId,
      tabIndex: state.activeTabIndex,
      tabId: getCurrentTabId()
    });
  }

  function goBackOrClose() {
    if (state.navigationStack.length > 0) {
      state.navigationStack.pop();
      state.selectedIndex = 0;
      playUiTick('back');
      renderBreadcrumb();
      renderTabsBar();
      renderViewport();
    } else {
      closeDock('backspace');
    }
  }

  function closeDock(reason = 'escape') {
    if (!state.isOpen) return;
    state.isOpen = false;
    el.container.style.display = 'none';
    playUiTick('back');
    postData('westrp_ui:closed', { menuId: state.menuId, reason: reason });
  }

  // --- 7. TECLADO NATIVO ROCKSTAR ---
  window.addEventListener('keydown', (e) => {
    if (!state.isOpen) return;

    switch (e.key) {
      case 'ArrowUp':
        e.preventDefault();
        {
          const items = getCurrentItems();
          if (items.length > 0) {
            state.selectedIndex = (state.selectedIndex - 1 + items.length) % items.length;
            updateSelection(true);
          }
        }
        break;

      case 'ArrowDown':
        e.preventDefault();
        {
          const items = getCurrentItems();
          if (items.length > 0) {
            state.selectedIndex = (state.selectedIndex + 1) % items.length;
            updateSelection(true);
          }
        }
        break;

      case 'ArrowLeft':
        e.preventDefault();
        if (!handleSliderStep('left')) {
          switchTab('prev');
        }
        break;

      case 'ArrowRight':
        e.preventDefault();
        if (!handleSliderStep('right')) {
          switchTab('next');
        }
        break;

      case 'Enter':
        e.preventDefault();
        executeCurrentItem();
        break;

      case 'Backspace':
        e.preventDefault();
        goBackOrClose();
        break;

      case 'Escape':
        e.preventDefault();
        closeDock('escape');
        break;
    }
  });

  // Botões de Abas do DOM
  el.btnTabPrev.addEventListener('click', () => switchTab('prev'));
  el.btnTabNext.addEventListener('click', () => switchTab('next'));

  // --- 8. SISTEMA DE TOASTS ---
  function showToast(title, message, type = 'info', duration = 3500) {
    const toast = document.createElement('div');
    toast.className = `toast-msg ${type}`;
    toast.innerHTML = `<strong>${title}</strong><br>${message}`;
    el.toastContainer.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(6px)';
      toast.style.transition = 'opacity 0.2s, transform 0.2s';
      setTimeout(() => toast.remove(), 250);
    }, duration);
  }

  // --- 9. LISTENER DE MENSAGENS NUI DO REDM CLIENT ---
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'westrp_ui:open') {
      const opts = data.options || {};
      state.isOpen = true;
      state.menuId = opts.id || 'default_menu';
      state.title = opts.title || 'REGISTRO';
      state.tag = opts.tag || 'FRONTIER';
      state.activeTabIndex = 0;
      state.selectedIndex = 0;
      state.navigationStack = [];

      // Suporta abas estruturadas ou lista direta de itens
      if (opts.tabs && opts.tabs.length > 0) {
        state.tabs = opts.tabs;
      } else if (opts.items && opts.items.length > 0) {
        state.tabs = [{ id: 'main', name: 'GERAL', items: opts.items }];
      } else {
        state.tabs = [{ id: 'main', name: 'GERAL', items: [] }];
      }

      el.container.style.display = 'flex';
      renderHeader();
      renderTabsBar();
      renderBreadcrumb();
      renderViewport();
      playUiTick('confirm');
    } else if (data.action === 'westrp_ui:close') {
      closeDock('client_request');
    } else if (data.action === 'westrp_ui:toast') {
      showToast(data.title, data.message, data.type, data.duration);
    } else if (data.action === 'westrp_ui:updateItem') {
      const { tabId, itemId, updates } = data;
      state.tabs.forEach(tab => {
        if (!tabId || tab.id === tabId) {
          tab.items.forEach(item => {
            if (item.id === itemId) {
              Object.assign(item, updates || {});
            }
          });
        }
      });
      renderViewport();
    }
  });

})();
