/**
 * WESTRP UI ENGINE — JAVASCRIPT MASTER MOTOR (DOCK & PANEL)
 * 100% Data-Driven | Web Audio Procedural Ticks | Full Keyboard & Mouse Support
 */

(function () {
  'use strict';

  // ==========================================================================
  // 1. SINTETIZADOR DE ÁUDIO PROCEDURAL (Web Audio API)
  // ==========================================================================
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

  // Helper para comunicação NUI com RedM Client
  function postData(endpoint, data = {}) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'westrp_ui';
    fetch(`https://${resourceName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data)
    }).catch(() => {});
  }

  // --- ÍNDICE CENTRAL DE ASSETS (westrp_assets) ---
  let iconIndex = null;

  async function loadIconIndex() {
    try {
      const res = await fetch('https://cfx-nui-westrp_assets/html/index.json');
      if (res.ok) {
        iconIndex = await res.json();
      }
    } catch (e) {
      // Ignora silenciosamente se o resource de assets não estiver iniciado
    }
  }
  loadIconIndex();

  function resolveItemIcon(item) {
    if (!item) return null;
    if (item.icon && (item.icon.startsWith('http') || item.icon.startsWith('nui://'))) {
      return item.icon;
    }
    const idKey = (item.icon || item.id || '').toLowerCase();
    if (iconIndex && iconIndex[idKey]) {
      return `https://cfx-nui-westrp_assets/html/${iconIndex[idKey]}`;
    }
    return null;
  }


  // ==========================================================================
  // 2. MÓDULO A: DOCK LATERAL (ROCKSTAR 350px / TECLADO & CÂMERA LIVRE)
  // ==========================================================================
  const dockState = {
    isOpen: false,
    menuId: '',
    title: 'REGISTRO',
    tag: 'FRONTIER',
    tabs: [],
    activeTabIndex: 0,
    selectedIndex: 0,
    navigationStack: []
  };

  const dockEl = {
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
    tabsLegend: document.getElementById('k-tabs-legend')
  };

  function getDockCurrentItems() {
    if (dockState.navigationStack.length > 0) {
      const currentSubmenu = dockState.navigationStack[dockState.navigationStack.length - 1];
      return currentSubmenu.items || [];
    }
    if (dockState.tabs.length > 0 && dockState.tabs[dockState.activeTabIndex]) {
      return dockState.tabs[dockState.activeTabIndex].items || [];
    }
    return [];
  }

  function getDockCurrentTabId() {
    if (dockState.tabs.length > 0 && dockState.tabs[dockState.activeTabIndex]) {
      return dockState.tabs[dockState.activeTabIndex].id;
    }
    return 'default';
  }

  function renderDockHeader() {
    dockEl.tag.textContent = dockState.tag || 'FRONTIER';
    dockEl.title.textContent = dockState.title || 'REGISTRO';
  }

  function renderDockTabsBar() {
    const hasTabs = dockState.tabs.length > 1;
    const isSubmenu = dockState.navigationStack.length > 0;

    if (hasTabs && !isSubmenu) {
      dockEl.tabsBar.style.display = 'flex';
      dockEl.tabsLegend.style.display = 'flex';
      dockEl.tabIndex.textContent = `ABA ${dockState.activeTabIndex + 1} / ${dockState.tabs.length}`;
      dockEl.tabName.textContent = dockState.tabs[dockState.activeTabIndex].name || 'GERAL';
    } else {
      dockEl.tabsBar.style.display = 'none';
      dockEl.tabsLegend.style.display = 'none';
    }
  }

  function renderDockBreadcrumb() {
    if (dockState.navigationStack.length > 0) {
      dockEl.breadcrumb.style.display = 'flex';
      const currentSubmenu = dockState.navigationStack[dockState.navigationStack.length - 1];
      dockEl.breadcrumbTitle.textContent = currentSubmenu.title || 'SUBMENU';
    } else {
      dockEl.breadcrumb.style.display = 'none';
    }
  }

  function renderDockViewport() {
    const items = getDockCurrentItems();
    dockEl.viewport.innerHTML = '';

    if (items.length === 0) {
      dockEl.counter.textContent = '0 / 0';
      dockEl.viewport.innerHTML = '<div class="dock-empty-msg">Nenhum registro disponível.</div>';
      dockEl.infoText.textContent = 'Nenhuma opção configurada neste menu.';
      return;
    }

    if (dockState.selectedIndex >= items.length) {
      dockState.selectedIndex = Math.max(0, items.length - 1);
    }

    dockEl.counter.textContent = `${dockState.selectedIndex + 1} / ${items.length}`;

    items.forEach((item, index) => {
      const row = document.createElement('div');
      row.className = 'dock-item';
      if (index === dockState.selectedIndex) row.classList.add('selected');
      if (item.danger) row.classList.add('danger');
      if (item.disabled) row.classList.add('disabled');
      row.dataset.index = index;

      const leftCol = document.createElement('div');
      leftCol.className = 'dock-item-left';

      const iconUrl = resolveItemIcon(item);
      if (iconUrl) {
        const iconWrap = document.createElement('div');
        iconWrap.className = 'dock-item-icon-wrap';
        const img = document.createElement('img');
        img.className = 'dock-item-icon';
        img.src = iconUrl;
        img.alt = '';
        img.onerror = () => { iconWrap.style.display = 'none'; };
        iconWrap.appendChild(img);
        leftCol.appendChild(iconWrap);
      }

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

      leftCol.appendChild(mainCol);
      row.appendChild(leftCol);

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

      row.addEventListener('click', () => {
        if (item.disabled) return;
        dockState.selectedIndex = index;
        updateDockSelection(true);
        executeDockCurrentItem();
      });

      row.addEventListener('mouseenter', () => {
        if (dockState.selectedIndex !== index) {
          dockState.selectedIndex = index;
          updateDockSelection(false);
          playUiTick('nav');
        }
      });

      dockEl.viewport.appendChild(row);
    });

    updateDockInfoText();
    ensureDockItemVisible();
  }

  function updateDockSelection(playAudio = false) {
    const items = getDockCurrentItems();
    if (items.length === 0) return;

    dockEl.counter.textContent = `${dockState.selectedIndex + 1} / ${items.length}`;

    const rows = dockEl.viewport.querySelectorAll('.dock-item');
    rows.forEach((row, idx) => {
      if (idx === dockState.selectedIndex) {
        row.classList.add('selected');
      } else {
        row.classList.remove('selected');
      }
    });

    updateDockInfoText();
    ensureDockItemVisible();

    if (playAudio) playUiTick('nav');
  }

  function updateDockInfoText() {
    const items = getDockCurrentItems();
    if (items.length === 0 || !items[dockState.selectedIndex]) {
      dockEl.infoText.textContent = '';
      return;
    }
    const current = items[dockState.selectedIndex];
    dockEl.infoText.textContent = current.description || 'Pressione [ENTER] para executar esta opção.';
  }

  function ensureDockItemVisible() {
    const rows = dockEl.viewport.querySelectorAll('.dock-item');
    const selectedRow = rows[dockState.selectedIndex];
    if (selectedRow) {
      selectedRow.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }
  }

  function executeDockCurrentItem() {
    const items = getDockCurrentItems();
    if (items.length === 0) return;

    const item = items[dockState.selectedIndex];
    if (!item || item.disabled) {
      playUiTick('error');
      return;
    }

    if (item.type === 'submenu') {
      if (item.subItems && item.subItems.length > 0) {
        dockState.navigationStack.push({
          title: item.label,
          items: item.subItems
        });
        dockState.selectedIndex = 0;
        playUiTick('confirm');
        renderDockBreadcrumb();
        renderDockTabsBar();
        renderDockViewport();
      } else {
        playUiTick('error');
      }
      return;
    }

    if (item.type === 'toggle') {
      item.checked = !item.checked;
      playUiTick('confirm');
      renderDockViewport();
      postData('westrp_ui:changeValue', {
        menuId: dockState.menuId,
        tabId: getDockCurrentTabId(),
        itemId: item.id,
        newValue: item.checked,
        item: item
      });
      return;
    }

    playUiTick('confirm');
    postData('westrp_ui:selectItem', {
      menuId: dockState.menuId,
      tabId: getDockCurrentTabId(),
      itemId: item.id,
      item: item
    });
  }

  function handleDockSliderStep(direction) {
    const items = getDockCurrentItems();
    if (items.length === 0) return;

    const item = items[dockState.selectedIndex];
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
    renderDockViewport();
    postData('westrp_ui:changeValue', {
      menuId: dockState.menuId,
      tabId: getDockCurrentTabId(),
      itemId: item.id,
      newValue: item.value,
      item: item
    });
    return true;
  }

  function switchDockTab(direction) {
    if (dockState.navigationStack.length > 0 || dockState.tabs.length <= 1) return;

    if (direction === 'prev') {
      dockState.activeTabIndex = (dockState.activeTabIndex - 1 + dockState.tabs.length) % dockState.tabs.length;
    } else {
      dockState.activeTabIndex = (dockState.activeTabIndex + 1) % dockState.tabs.length;
    }

    dockState.selectedIndex = 0;
    playUiTick('nav');
    renderDockTabsBar();
    renderDockViewport();

    postData('westrp_ui:tabChanged', {
      menuId: dockState.menuId,
      tabIndex: dockState.activeTabIndex,
      tabId: getDockCurrentTabId()
    });
  }

  function goBackDockOrClose() {
    if (dockState.navigationStack.length > 0) {
      dockState.navigationStack.pop();
      dockState.selectedIndex = 0;
      playUiTick('back');
      renderDockBreadcrumb();
      renderDockTabsBar();
      renderDockViewport();
    } else {
      closeDock('backspace');
    }
  }

  function closeDock(reason = 'escape') {
    if (!dockState.isOpen) return;
    dockState.isOpen = false;
    dockEl.container.style.display = 'none';
    playUiTick('back');
    postData('westrp_ui:closed', { menuId: dockState.menuId, reason: reason });
  }

  dockEl.btnTabPrev.addEventListener('click', () => switchDockTab('prev'));
  dockEl.btnTabNext.addEventListener('click', () => switchDockTab('next'));


  // ==========================================================================
  // 3. MÓDULO B: PANEL / WORKSPACE (MODAL CENTRAL / CURSOR LIVRE)
  // ==========================================================================
  const panelState = {
    isOpen: false,
    id: '',
    title: 'BANCADA DE CRIAÇÃO',
    tag: 'ESTABELECIMENTO',
    subtitle: '',
    tabs: [],
    activeTab: 0,
    searchQuery: '',
    selectedItem: null,
    quantity: 1,
    ctaLabel: 'CONFIRMAR',
    activeFilter: 'all',
    currentPage: 1
  };

  const panelEl = {
    container: document.getElementById('panel-container'),
    backdrop: document.getElementById('panel-backdrop'),
    tag: document.getElementById('panel-tag'),
    title: document.getElementById('panel-title'),
    metaPill: document.getElementById('panel-meta-pill'),
    metaText: document.getElementById('panel-meta-text'),
    searchInput: document.getElementById('panel-search-input'),
    searchWrap: document.getElementById('panel-search-wrap'),
    closeBtn: document.getElementById('panel-close-btn'),
    sidebarBrand: document.getElementById('panel-sidebar-brand'),
    sidebarName: document.getElementById('panel-sidebar-name'),
    sidebarBadge: document.getElementById('panel-sidebar-badge'),
    sidebarOperator: document.getElementById('panel-sidebar-operator'),
    operatorInitials: document.getElementById('operator-initials'),
    operatorName: document.getElementById('operator-name'),
    operatorStatusBtn: document.getElementById('operator-status-btn'),
    operatorStatusDot: document.getElementById('operator-status-dot'),
    operatorStatusText: document.getElementById('operator-status-text'),
    tabsList: document.getElementById('panel-tabs-list'),
    filterBar: document.getElementById('panel-filter-bar'),
    paginationBar: document.getElementById('panel-pagination-bar'),
    paginationSummary: document.getElementById('pagination-summary'),
    btnPagePrev: document.getElementById('btn-page-prev'),
    btnPageNext: document.getElementById('btn-page-next'),
    pageIndicator: document.getElementById('pagination-page-indicator'),
    dashboardView: document.getElementById('panel-dashboard-view'),
    overviewGrid: document.getElementById('dashboard-overview-grid'),
    actionsContainer: document.getElementById('dashboard-actions-container'),
    settingsView: document.getElementById('panel-settings-view'),
    positionsGrid: document.getElementById('settings-positions-grid'),
    actionsList: document.getElementById('settings-actions-list'),
    gridView: document.getElementById('panel-grid-view'),
    tableView: document.getElementById('panel-table-view'),
    tableHead: document.getElementById('panel-table-head'),
    tableBody: document.getElementById('panel-table-body'),
    craftView: document.getElementById('panel-craft-view'),
    craftRecipeList: document.getElementById('craft-recipe-list'),
    craftDetailsTitle: document.getElementById('craft-details-title'),
    craftDetailsDesc: document.getElementById('craft-details-desc'),
    craftReqsList: document.getElementById('craft-reqs-list'),
    queueView: document.getElementById('panel-queue-view'),
    queueList: document.getElementById('queue-items-list'),
    footerInfo: document.getElementById('panel-footer-info'),
    selectedName: document.getElementById('panel-selected-name'),
    selectedDesc: document.getElementById('panel-selected-desc'),
    stepper: document.getElementById('panel-stepper'),
    btnMinus: document.getElementById('btn-stepper-minus'),
    btnPlus: document.getElementById('btn-stepper-plus'),
    stepperVal: document.getElementById('stepper-val'),
    ctaBtn: document.getElementById('panel-cta-btn')
  };

  function openPanel(options = {}) {
    panelState.isOpen = true;
    panelState.id = options.id || 'default_panel';
    panelState.title = options.title || 'PAINEL';
    panelState.tag = options.tag || 'FRONTIER';
    panelState.subtitle = options.subtitle || '';
    panelState.tabs = options.tabs || [];
    panelState.activeTab = 0;
    panelState.searchQuery = '';
    panelState.selectedItem = null;
    panelState.quantity = 1;
    panelState.ctaLabel = options.ctaLabel || 'CONFIRMAR';
    panelState.activeFilter = 'all';
    panelState.currentPage = 1;

    panelEl.tag.textContent = panelState.tag;
    panelEl.title.textContent = panelState.title;
    panelEl.searchInput.value = '';

    if (panelState.subtitle) {
      panelEl.metaPill.style.display = 'block';
      panelEl.metaText.textContent = panelState.subtitle;
    } else {
      panelEl.metaPill.style.display = 'none';
    }

    // Configuração de Marca da Sidebar (Logo & Título)
    if (options.brand) {
      if (panelEl.sidebarBrand) panelEl.sidebarBrand.style.display = 'flex';
      if (panelEl.sidebarName) panelEl.sidebarName.textContent = options.brand.name || 'WESTRP SERVER';
      if (panelEl.sidebarBadge) panelEl.sidebarBadge.textContent = options.brand.badge || 'ADMIN MENU';
    } else if (panelEl.sidebarBrand) {
      panelEl.sidebarBrand.style.display = 'none';
    }

    // Configuração do Perfil do Operador
    if (options.operator) {
      if (panelEl.sidebarOperator) panelEl.sidebarOperator.style.display = 'flex';
      if (panelEl.operatorName) panelEl.operatorName.textContent = options.operator.name || 'Operador';
      const initials = (options.operator.name || 'AD').substring(0, 2).toUpperCase();
      if (panelEl.operatorInitials) panelEl.operatorInitials.textContent = initials;
      const onDuty = options.operator.onDuty !== false;
      if (panelEl.operatorStatusDot) panelEl.operatorStatusDot.className = 'status-dot ' + (onDuty ? 'on' : 'off');
      if (panelEl.operatorStatusText) panelEl.operatorStatusText.textContent = onDuty ? 'Em Serviço' : 'Fora de Serviço';
      panelState.operator = options.operator;
    } else if (panelEl.sidebarOperator) {
      panelEl.sidebarOperator.style.display = 'none';
    }

    panelEl.container.style.display = 'flex';
    playUiTick('confirm');

    renderPanelTabs();
    renderPanelContent();
  }

  function closePanel(reason = 'escape') {
    if (!panelState.isOpen) return;
    stopQueueTicker();
    panelState.isOpen = false;
    panelEl.container.style.display = 'none';
    playUiTick('back');
    postData('westrp_ui:panelClosed', { panelId: panelState.id, reason: reason });
  }

  function renderPanelTabs() {
    panelEl.tabsList.innerHTML = '';
    panelState.tabs.forEach((tab, index) => {
      const btn = document.createElement('button');
      btn.className = `panel-tab-btn ${index === panelState.activeTab ? 'active' : ''}`;
      
      const mainWrap = document.createElement('div');
      mainWrap.className = 'panel-tab-btn-main';

      if (tab.icon) {
        const iconSpan = document.createElement('span');
        iconSpan.className = 'panel-tab-icon';
        if (tab.icon.startsWith('fa-') || tab.icon.includes(' ')) {
          iconSpan.innerHTML = `<i class="${tab.icon}"></i>`;
        } else {
          iconSpan.textContent = tab.icon;
        }
        mainWrap.appendChild(iconSpan);
      }

      const titleSpan = document.createElement('span');
      titleSpan.textContent = tab.label || `ABA ${index + 1}`;
      mainWrap.appendChild(titleSpan);
      btn.appendChild(mainWrap);

      if (tab.badge !== undefined && tab.badge !== null) {
        const badge = document.createElement('span');
        let badgeCls = 'panel-tab-badge';
        if (tab.badgeType === 'count-blue') badgeCls += ' count-blue';
        else if (tab.badgeType === 'count-orange') badgeCls += ' count-orange';
        badge.className = badgeCls;
        badge.textContent = tab.badge;
        btn.appendChild(badge);
      }

      btn.addEventListener('click', () => {
        if (panelState.activeTab !== index) {
          panelState.activeTab = index;
          panelState.selectedItem = null;
          panelState.quantity = 1;
          panelState.searchQuery = '';
          panelState.activeFilter = 'all';
          panelState.currentPage = 1;
          panelEl.searchInput.value = '';
          playUiTick('nav');
          renderPanelTabs();
          renderPanelContent();
        }
      });

      panelEl.tabsList.appendChild(btn);
    });
  }

  function matchItemFilter(item, filter) {
    if (!filter || filter.id === 'all') return true;
    const key = filter.key || 'category';
    const targetVal = filter.value !== undefined ? filter.value : filter.id;
    const itemVal = item[key];
    if (Array.isArray(targetVal)) {
      return targetVal.some(tv => String(tv).toLowerCase() === String(itemVal).toLowerCase());
    }
    if (typeof itemVal === 'string' && typeof targetVal === 'string') {
      return itemVal.toLowerCase() === targetVal.toLowerCase();
    }
    return itemVal == targetVal;
  }

  function getTabFilterOptions(tab) {
    const rawItems = (tab.viewType === 'table') ? (tab.rows || []) : (tab.items || []);
    if (tab.filters && Array.isArray(tab.filters) && tab.filters.length > 0) {
      return tab.filters.map(f => {
        const badge = f.badge !== undefined ? f.badge : (f.id === 'all' ? rawItems.length : rawItems.filter(it => matchItemFilter(it, f)).length);
        return {
          id: f.id,
          label: f.label || f.id,
          key: f.key || 'category',
          value: f.value,
          badge: badge
        };
      });
    }

    if (tab.filterCategory) {
      const counts = {};
      rawItems.forEach(it => {
        const cat = it.category || 'Geral';
        counts[cat] = (counts[cat] || 0) + 1;
      });
      const categories = Object.keys(counts).sort();
      const options = [{ id: 'all', label: 'Todos', badge: rawItems.length }];
      categories.forEach(cat => {
        options.push({
          id: cat,
          label: cat,
          key: 'category',
          value: cat,
          badge: counts[cat]
        });
      });
      return options;
    }

    return null;
  }

  function renderPanelFilters(tab) {
    const filterOptions = getTabFilterOptions(tab);
    if (!filterOptions || filterOptions.length === 0) {
      panelEl.filterBar.style.display = 'none';
      panelEl.filterBar.innerHTML = '';
      return null;
    }

    if (panelState.activeFilter !== 'all' && !filterOptions.some(f => f.id === panelState.activeFilter)) {
      panelState.activeFilter = 'all';
    }

    panelEl.filterBar.innerHTML = '';
    filterOptions.forEach(f => {
      const btn = document.createElement('button');
      btn.className = `filter-chip ${panelState.activeFilter === f.id ? 'active' : ''}`;

      const lbl = document.createElement('span');
      lbl.textContent = f.label;
      btn.appendChild(lbl);

      if (f.badge !== undefined && f.badge !== null) {
        const badge = document.createElement('span');
        badge.className = 'filter-chip-badge';
        badge.textContent = f.badge;
        btn.appendChild(badge);
      }

      btn.addEventListener('click', () => {
        if (panelState.activeFilter !== f.id) {
          panelState.activeFilter = f.id;
          panelState.currentPage = 1;
          playUiTick('nav');
          renderPanelContent();
        }
      });

      panelEl.filterBar.appendChild(btn);
    });

    panelEl.filterBar.style.display = 'flex';
    return filterOptions;
  }

  function getFilteredItems(tab, filterOptions) {
    const rawItems = (tab.viewType === 'table') ? (tab.rows || []) : (tab.items || []);
    const q = panelState.searchQuery ? panelState.searchQuery.toLowerCase() : '';

    return rawItems.filter(item => {
      // 1. Filtro textual
      if (q) {
        let match = false;
        if (tab.viewType === 'table') {
          match = Object.values(item).some(val => String(val).toLowerCase().includes(q));
        } else {
          match = (item.title && item.title.toLowerCase().includes(q)) ||
                  (item.subtitle && item.subtitle.toLowerCase().includes(q)) ||
                  (item.id && item.id.toLowerCase().includes(q)) ||
                  (item.category && item.category.toLowerCase().includes(q));
        }
        if (!match) return false;
      }

      // 2. Filtro por chip categórico
      if (filterOptions && panelState.activeFilter !== 'all') {
        const activeOpt = filterOptions.find(f => f.id === panelState.activeFilter);
        if (activeOpt && !matchItemFilter(item, activeOpt)) {
          return false;
        }
      }

      return true;
    });
  }

  function paginateItems(tab, filteredItems) {
    const pageSize = tab.pageSize || (tab.pagination && tab.pagination.pageSize);
    if (!pageSize || pageSize <= 0) {
      panelEl.paginationBar.style.display = 'none';
      return filteredItems;
    }

    const total = filteredItems.length;
    const totalPages = Math.max(1, Math.ceil(total / pageSize));

    if (panelState.currentPage > totalPages) {
      panelState.currentPage = totalPages;
    }
    if (panelState.currentPage < 1) {
      panelState.currentPage = 1;
    }

    const start = (panelState.currentPage - 1) * pageSize;
    const end = start + pageSize;
    const paged = filteredItems.slice(start, end);

    panelEl.paginationBar.style.display = 'flex';
    const startDisplay = total === 0 ? 0 : start + 1;
    const endDisplay = Math.min(end, total);
    panelEl.paginationSummary.textContent = `Exibindo ${startDisplay}-${endDisplay} de ${total} registros`;
    panelEl.pageIndicator.textContent = `Página ${panelState.currentPage} / ${totalPages}`;

    panelEl.btnPagePrev.disabled = (panelState.currentPage <= 1);
    panelEl.btnPageNext.disabled = (panelState.currentPage >= totalPages);

    return paged;
  }

  function renderPanelContent() {
    const currentTab = panelState.tabs[panelState.activeTab];
    if (!currentTab) return;

    panelEl.gridView.style.display = 'none';
    panelEl.tableView.style.display = 'none';
    panelEl.craftView.style.display = 'none';
    panelEl.queueView.style.display = 'none';
    if (panelEl.dashboardView) panelEl.dashboardView.style.display = 'none';
    if (panelEl.settingsView) panelEl.settingsView.style.display = 'none';

    stopQueueTicker();
    updateFooter();

    try {
      if (currentTab.viewType === 'dashboard') {
        if (panelEl.searchWrap) panelEl.searchWrap.style.display = 'none';
        panelEl.filterBar.style.display = 'none';
        panelEl.paginationBar.style.display = 'none';
        if (panelEl.footerInfo && panelEl.footerInfo.parentElement) {
          panelEl.footerInfo.parentElement.style.display = 'none';
        }
        if (panelEl.dashboardView) {
          panelEl.dashboardView.style.display = 'flex';
          renderDashboardView(currentTab);
        }
      } else if (currentTab.viewType === 'settings') {
        if (panelEl.searchWrap) panelEl.searchWrap.style.display = 'none';
        panelEl.filterBar.style.display = 'none';
        panelEl.paginationBar.style.display = 'none';
        if (panelEl.footerInfo && panelEl.footerInfo.parentElement) {
          panelEl.footerInfo.parentElement.style.display = 'none';
        }
        if (panelEl.settingsView) {
          panelEl.settingsView.style.display = 'flex';
          renderSettingsView(currentTab);
        }
      } else {
        if (panelEl.searchWrap) panelEl.searchWrap.style.display = 'flex';
        if (panelEl.footerInfo && panelEl.footerInfo.parentElement) {
          panelEl.footerInfo.parentElement.style.display = 'flex';
        }
        if (currentTab.viewType === 'grid') {
          panelEl.gridView.style.display = 'grid';
          renderPanelFilters(currentTab);
          renderGridView(currentTab);
        } else if (currentTab.viewType === 'table') {
          panelEl.tableView.style.display = 'block';
          renderPanelFilters(currentTab);
          renderTableView(currentTab);
        } else if (currentTab.viewType === 'craft') {
          panelEl.filterBar.style.display = 'none';
          panelEl.paginationBar.style.display = 'none';
          panelEl.craftView.style.display = 'flex';
          renderCraftView(currentTab);
        } else if (currentTab.viewType === 'queue') {
          panelEl.filterBar.style.display = 'none';
          panelEl.paginationBar.style.display = 'none';
          panelEl.queueView.style.display = 'flex';
          renderQueueView(currentTab);
          startQueueTicker(currentTab);
        }
      }
    } catch (err) {
      console.error('Erro na renderização do conteúdo da aba:', err);
    }
  }

  function renderDashboardView(tab) {
    if (!panelEl.overviewGrid || !panelEl.actionsContainer) return;

    try {
      // 1. Renderiza os cartões de KPI (Server Overview)
      panelEl.overviewGrid.innerHTML = '';
      let overview = [];
      if (Array.isArray(tab.overview) && tab.overview.length > 0) {
        overview = tab.overview;
      } else if (tab.overview && typeof tab.overview === 'object' && !tab.overview.stats && Object.keys(tab.overview).length > 0) {
        overview = Object.values(tab.overview);
      } else {
        const stats = tab.stats || (tab.overview && tab.overview.stats) || {};
        const online = stats.online !== undefined ? stats.online : 1;
        const maxClients = stats.maxClients || 48;
        const uptime = stats.uptime || '0H 00M';
        const peak24 = stats.peak24h !== undefined ? stats.peak24h : 1;
        const peakAll = stats.peakAllTime !== undefined ? stats.peakAllTime : 1;

        overview = [
          { id: 'players', icon: 'fas fa-users', label: 'PLAYERS COUNT', value: `${online}`, subvalue: `/ ${maxClients}` },
          { id: 'uptime', icon: 'fas fa-stopwatch', label: 'UP TIME', value: `${uptime}`.toUpperCase() },
          { id: 'peak_24h', icon: 'fas fa-chart-line', label: '24H PEAK PLAYERS', value: `${peak24}` },
          { id: 'peak_all', icon: 'fas fa-trophy', label: 'ALL-TIME PEAK', value: `${peakAll}` }
        ];
      }

      overview.forEach(stat => {
        const card = document.createElement('div');
        card.className = 'kpi-card';

        const iconWrap = document.createElement('div');
        iconWrap.className = 'kpi-icon-wrap';
        if (stat.icon && (stat.icon.includes('fa-') || stat.icon.includes(' '))) {
          iconWrap.innerHTML = `<i class="${stat.icon}"></i>`;
        } else {
          iconWrap.textContent = stat.icon || '📊';
        }
        card.appendChild(iconWrap);

        const content = document.createElement('div');
        content.className = 'kpi-content';

        const lbl = document.createElement('span');
        lbl.className = 'kpi-label';
        lbl.textContent = stat.label || stat.id;
        content.appendChild(lbl);

        const valWrap = document.createElement('div');
        valWrap.style.display = 'flex';
        valWrap.style.alignItems = 'baseline';
        valWrap.style.gap = '4px';

        const val = document.createElement('span');
        val.className = 'kpi-value';
        val.textContent = stat.value !== undefined ? stat.value : '0';
        valWrap.appendChild(val);

        if (stat.subvalue) {
          const sub = document.createElement('span');
          sub.className = 'kpi-subvalue';
          sub.textContent = stat.subvalue;
          valWrap.appendChild(sub);
        }

        content.appendChild(valWrap);
        card.appendChild(content);
        panelEl.overviewGrid.appendChild(card);
      });

      // 2. Renderiza os blocos de Ações Administrativas Categorizadas
      panelEl.actionsContainer.innerHTML = '';
      let groups = [];
      if (Array.isArray(tab.actionGroups)) {
        groups = tab.actionGroups;
      } else if (tab.actionGroups && typeof tab.actionGroups === 'object') {
        groups = Object.values(tab.actionGroups);
      }

      groups.forEach(group => {
        const groupEl = document.createElement('div');
        groupEl.className = 'dashboard-actions-group';

        const header = document.createElement('div');
        header.className = 'actions-group-header';
        let gIcon = group.icon || '▪';
        if (gIcon.includes('fa-') || gIcon.includes(' ')) {
          gIcon = `<i class="${gIcon}"></i>`;
        }
        header.innerHTML = `<span>${gIcon}</span> <span>${group.title || group.id}</span>`;
        groupEl.appendChild(header);

        const grid = document.createElement('div');
        grid.className = 'actions-group-grid';

        let actions = [];
        if (Array.isArray(group.actions)) {
          actions = group.actions;
        } else if (group.actions && typeof group.actions === 'object') {
          actions = Object.values(group.actions);
        }

        actions.forEach(act => {
          const tile = document.createElement('button');
          tile.className = `admin-action-tile ${act.active ? 'active' : ''}`;
          tile.title = act.description || act.label;

          const iconSpan = document.createElement('span');
          iconSpan.className = 'action-tile-icon';
          if (act.icon && (act.icon.includes('fa-') || act.icon.includes(' '))) {
            iconSpan.innerHTML = `<i class="${act.icon}"></i>`;
          } else {
            iconSpan.textContent = act.icon || '⚡';
          }
          tile.appendChild(iconSpan);

          const lblSpan = document.createElement('span');
          lblSpan.textContent = act.label || act.id;
          tile.appendChild(lblSpan);

          tile.addEventListener('click', () => {
            playUiTick('confirm');
            if (act.type === 'toggle') {
              act.active = !act.active;
              tile.classList.toggle('active', act.active);
            }
            postData('westrp_ui:panelAction', {
              action: 'dashboard_action',
              groupId: group.id || group.title,
              actionId: act.id,
              active: act.active,
              item: act
            });
          });

          grid.appendChild(tile);
        });

        groupEl.appendChild(grid);
        panelEl.actionsContainer.appendChild(groupEl);
      });
    } catch (err) {
      console.error('Erro na renderização do Dashboard:', err);
    }
  }

  function renderSettingsView(tab) {
    if (!panelEl.positionsGrid || !panelEl.actionsList) return;

    try {
      // 1. Grid de Posições do Dock
      panelEl.positionsGrid.innerHTML = '';
      let positions = [];
      if (Array.isArray(tab.positions) && tab.positions.length > 0) {
        positions = tab.positions;
      } else if (tab.positions && typeof tab.positions === 'object' && Object.keys(tab.positions).length > 0) {
        positions = Object.values(tab.positions);
      } else {
        positions = [
          { id: 'top_left', label: 'Top Left' },
          { id: 'top_right', label: 'Top Right' },
          { id: 'mid_left', label: 'Mid Left' },
          { id: 'mid_right', label: 'Mid Right' },
          { id: 'bottom_left', label: 'Bottom Left' },
          { id: 'bottom_right', label: 'Bottom Right' }
        ];
      }

      const currentPos = tab.currentPosition || 'mid_left';

      positions.forEach(pos => {
        const chip = document.createElement('div');
        chip.className = `position-chip ${currentPos === pos.id ? 'selected' : ''}`;

        const dot = document.createElement('span');
        dot.className = 'position-dot';
        chip.appendChild(dot);

        const lbl = document.createElement('span');
        lbl.textContent = pos.label;
        chip.appendChild(lbl);

        chip.addEventListener('click', () => {
          tab.currentPosition = pos.id;
          playUiTick('nav');
          renderSettingsView(tab);
          postData('westrp_ui:panelAction', {
            action: 'set_menu_position',
            position: pos.id
          });
        });

        panelEl.positionsGrid.appendChild(chip);
      });

      // 2. Lista de Ações do Quick Actions com Toggles
      panelEl.actionsList.innerHTML = '';
      let quickActions = [];
      if (Array.isArray(tab.quickActions)) {
        quickActions = tab.quickActions;
      } else if (tab.quickActions && typeof tab.quickActions === 'object') {
        quickActions = Object.values(tab.quickActions);
      }

      quickActions.forEach(act => {
        const row = document.createElement('div');
        row.className = 'action-order-row';

        const left = document.createElement('div');
        left.className = 'action-row-left';

        const handle = document.createElement('span');
        handle.className = 'action-drag-handle';
        handle.textContent = '≡';
        left.appendChild(handle);

        const iconSpan = document.createElement('span');
        iconSpan.className = 'action-row-icon';
        if (act.icon && (act.icon.includes('fa-') || act.icon.includes(' '))) {
          iconSpan.innerHTML = `<i class="${act.icon}"></i>`;
        } else {
          iconSpan.textContent = act.icon || '⚡';
        }
        left.appendChild(iconSpan);

        const nameSpan = document.createElement('span');
        nameSpan.className = 'action-row-name';
        nameSpan.textContent = act.label || act.id;
        left.appendChild(nameSpan);

        row.appendChild(left);

        // Switch Toggle
        const switchLabel = document.createElement('label');
        switchLabel.className = 'ui-switch';

        const input = document.createElement('input');
        input.type = 'checkbox';
        input.checked = act.enabled !== false;

        input.addEventListener('change', () => {
          act.enabled = input.checked;
          playUiTick('nav');
          postData('westrp_ui:panelAction', {
            action: 'toggle_quick_action',
            actionId: act.id,
            enabled: act.enabled
          });
        });

        const slider = document.createElement('span');
        slider.className = 'ui-switch-slider';

        switchLabel.appendChild(input);
        switchLabel.appendChild(slider);
        row.appendChild(switchLabel);

        panelEl.actionsList.appendChild(row);
      });
    } catch (err) {
      console.error('Erro na renderização das Configurações:', err);
    }
  }

  function renderGridView(tab) {
    panelEl.gridView.innerHTML = '';
    const filterOptions = getTabFilterOptions(tab);
    const filtered = getFilteredItems(tab, filterOptions);
    const paged = paginateItems(tab, filtered);

    if (paged.length === 0) {
      panelEl.gridView.innerHTML = '<div class="dock-empty-msg" style="grid-column: 1 / -1;">Nenhum item encontrado.</div>';
      return;
    }

    paged.forEach(item => {
      const card = document.createElement('div');
      card.className = `grid-card ${panelState.selectedItem && panelState.selectedItem.id === item.id ? 'selected' : ''}`;

      const header = document.createElement('div');
      header.className = 'grid-card-header';

      const title = document.createElement('span');
      title.className = 'grid-card-title';
      title.textContent = item.title || 'Item';
      header.appendChild(title);

      if (item.badge) {
        const badge = document.createElement('span');
        badge.className = `status-pill ${item.badgeType || 'gold'}`;
        badge.textContent = item.badge;
        header.appendChild(badge);
      }
      card.appendChild(header);

      const iconUrl = resolveItemIcon(item);
      if (iconUrl) {
        const iconWrap = document.createElement('div');
        iconWrap.className = 'grid-card-icon-wrap';
        const img = document.createElement('img');
        img.className = 'grid-card-img';
        img.src = iconUrl;
        img.alt = item.title || '';
        img.onerror = () => { iconWrap.style.display = 'none'; };
        iconWrap.appendChild(img);
        card.appendChild(iconWrap);
      }

      if (item.subtitle) {
        const desc = document.createElement('span');
        desc.className = 'grid-card-desc';
        desc.textContent = item.subtitle;
        card.appendChild(desc);
      }

      const footer = document.createElement('div');
      footer.className = 'grid-card-footer';

      if (item.price !== undefined) {
        const price = document.createElement('span');
        price.className = 'grid-card-price';
        price.textContent = `$ ${item.price.toFixed(2)}`;
        footer.appendChild(price);
      }

      if (item.stock !== undefined) {
        const stock = document.createElement('span');
        stock.className = 'status-pill off';
        stock.textContent = `Estoque: ${item.stock}`;
        footer.appendChild(stock);
      }

      card.appendChild(footer);

      card.addEventListener('click', () => {
        panelState.selectedItem = item;
        playUiTick('nav');
        updateFooter();
        renderGridView(tab);
      });

      panelEl.gridView.appendChild(card);
    });
  }

  function renderTableView(tab) {
    panelEl.tableHead.innerHTML = '';
    panelEl.tableBody.innerHTML = '';

    const cols = tab.columns || [];
    const headerRow = document.createElement('tr');
    cols.forEach(col => {
      const th = document.createElement('th');
      th.textContent = col.label;
      if (col.width) th.style.width = col.width;
      if (col.align) th.style.textAlign = col.align;
      headerRow.appendChild(th);
    });
    panelEl.tableHead.appendChild(headerRow);

    const filterOptions = getTabFilterOptions(tab);
    const filtered = getFilteredItems(tab, filterOptions);
    const paged = paginateItems(tab, filtered);

    if (paged.length === 0) {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td colspan="${cols.length}" style="text-align: center; padding: 30px; color: var(--text-muted);">Nenhum registro encontrado.</td>`;
      panelEl.tableBody.appendChild(tr);
      return;
    }

    paged.forEach(row => {
      const tr = document.createElement('tr');
      if (panelState.selectedItem && panelState.selectedItem.id === row.id) {
        tr.classList.add('selected');
      }

      cols.forEach(col => {
        const td = document.createElement('td');
        const val = row[col.key] !== undefined ? row[col.key] : '';
        if (col.align) td.style.textAlign = col.align;

        if (col.type === 'pill') {
          const pill = document.createElement('span');
          pill.className = `status-pill ${row[col.key + '_type'] || 'action'}`;
          pill.textContent = val;
          td.appendChild(pill);
        } else {
          td.textContent = val;
        }
        tr.appendChild(td);
      });

      tr.addEventListener('click', () => {
        panelState.selectedItem = row;
        playUiTick('nav');
        updateFooter();
        renderTableView(tab);
      });

      panelEl.tableBody.appendChild(tr);
    });
  }

  function renderCraftView(tab) {
    panelEl.craftRecipeList.innerHTML = '';
    const recipes = (tab.items || []).filter(recipe => {
      if (!panelState.searchQuery) return true;
      const q = panelState.searchQuery.toLowerCase();
      return (recipe.title && recipe.title.toLowerCase().includes(q));
    });

    if (recipes.length === 0) {
      panelEl.craftRecipeList.innerHTML = '<div class="dock-empty-msg">Nenhuma receita encontrada.</div>';
      return;
    }

    // Auto-seleciona a primeira receita se nada selecionado
    if (!panelState.selectedItem && recipes.length > 0) {
      panelState.selectedItem = recipes[0];
    }

    recipes.forEach(recipe => {
      const itemEl = document.createElement('div');
      itemEl.className = `craft-recipe-item ${panelState.selectedItem && panelState.selectedItem.id === recipe.id ? 'selected' : ''}`;

      const iconUrl = resolveItemIcon(recipe);
      if (iconUrl) {
        const img = document.createElement('img');
        img.className = 'craft-recipe-img';
        img.src = iconUrl;
        img.alt = '';
        itemEl.appendChild(img);
      }

      const title = document.createElement('span');
      title.className = 'craft-recipe-title';
      title.textContent = recipe.title;
      itemEl.appendChild(title);

      itemEl.addEventListener('click', () => {
        panelState.selectedItem = recipe;
        playUiTick('nav');
        updateCraftDetails(recipe);
        updateFooter();
        renderCraftView(tab);
      });

      panelEl.craftRecipeList.appendChild(itemEl);
    });

    if (panelState.selectedItem) {
      updateCraftDetails(panelState.selectedItem);
    }
  }

  function updateCraftDetails(recipe) {
    const iconUrl = resolveItemIcon(recipe);
    if (iconUrl) {
      panelEl.craftDetailsTitle.innerHTML = `<div class="craft-details-header"><img class="craft-details-img" src="${iconUrl}" alt=""> <span>${recipe.title || 'Receita'}</span></div>`;
    } else {
      panelEl.craftDetailsTitle.textContent = recipe.title || 'Receita';
    }
    panelEl.craftDetailsDesc.textContent = recipe.subtitle || 'Fabricação manual de ferramenta ou consumível.';
    panelEl.craftReqsList.innerHTML = '';

    const reqs = recipe.requirements || [];
    let hasAll = true;

    reqs.forEach(req => {
      const row = document.createElement('div');
      const needed = (req.required || 1) * panelState.quantity;
      const current = req.current || 0;
      const isOk = current >= needed;
      if (!isOk) hasAll = false;

      const reqIconUrl = resolveItemIcon({ id: req.item, icon: req.icon });
      const iconHtml = reqIconUrl ? `<img class="craft-req-icon" src="${reqIconUrl}" alt="" onerror="this.style.display='none'"> ` : '';

      row.className = `craft-req-row ${isOk ? 'ok' : 'missing'}`;
      row.innerHTML = `<div class="craft-req-label-wrap">${iconHtml}<span>${req.label || req.item}</span></div> <span class="status-pill ${isOk ? 'on' : 'off'}">${current} / ${needed}</span>`;
      panelEl.craftReqsList.appendChild(row);
    });

    panelEl.ctaBtn.disabled = !hasAll;
  }

  function updateFooter() {
    const currentTab = panelState.tabs[panelState.activeTab];
    if (currentTab && currentTab.viewType === 'queue') {
      const activeCount = (currentTab.items || []).filter(j => j.status === 'in_progress' || j.status === 'queued').length;
      const readyCount = (currentTab.items || []).filter(j => j.status === 'completed').length;
      panelEl.selectedName.textContent = 'Fila de Manufatura da Bancada';
      panelEl.selectedDesc.textContent = `${activeCount} lote(s) em produção • ${readyCount} pronto(s) para retirada`;
      panelEl.ctaBtn.disabled = true;
      panelEl.ctaBtn.textContent = 'ACOMPANHAMENTO';
      panelEl.stepper.style.display = 'none';
      return;
    }

    const sel = panelState.selectedItem;
    if (sel) {
      panelEl.selectedName.textContent = sel.title || sel.label || sel.name || 'Item Selecionado';
      panelEl.selectedDesc.textContent = sel.subtitle || sel.desc || (sel.price ? `Preço Unitário: $ ${sel.price.toFixed(2)}` : '');
      panelEl.ctaBtn.disabled = false;
      panelEl.stepper.style.display = 'flex';
      panelEl.stepperVal.textContent = panelState.quantity;
    } else {
      panelEl.selectedName.textContent = 'Nenhum item selecionado';
      panelEl.selectedDesc.textContent = 'Selecione uma opção acima para interagir.';
      panelEl.ctaBtn.disabled = true;
      panelEl.stepper.style.display = 'none';
    }
    panelEl.ctaBtn.textContent = panelState.ctaLabel || 'CONFIRMAR';
  }

  function setPanelQuantity(newQty) {
    panelState.quantity = Math.max(1, Math.min(999, newQty));
    panelEl.stepperVal.textContent = panelState.quantity;
    playUiTick('nav');

    const currentTab = panelState.tabs[panelState.activeTab];
    if (currentTab && currentTab.viewType === 'craft' && panelState.selectedItem) {
      updateCraftDetails(panelState.selectedItem);
    }
  }

  // --- MÓDULO FILA DE PRODUÇÃO (QUEUE TRACKER) ---
  let queueTimer = null;

  function stopQueueTicker() {
    if (queueTimer) {
      clearInterval(queueTimer);
      queueTimer = null;
    }
  }

  function startQueueTicker(tab) {
    stopQueueTicker();
    queueTimer = setInterval(() => {
      if (!panelState.isOpen) {
        stopQueueTicker();
        return;
      }
      const currentTab = panelState.tabs[panelState.activeTab];
      if (!currentTab || currentTab.viewType !== 'queue') {
        stopQueueTicker();
        return;
      }

      const items = currentTab.items || [];
      let activeJob = items.find(j => j.status === 'in_progress');

      if (!activeJob) {
        // Se não há nenhum em progresso, inicia o próximo na fila
        const nextJob = items.find(j => j.status === 'queued');
        if (nextJob) {
          nextJob.status = 'in_progress';
          activeJob = nextJob;
          playUiTick('nav');
        }
      }

      if (activeJob) {
        const totalQty = activeJob.totalQty || 1;
        const durPerUnit = activeJob.durationPerUnit || 10;
        const totalDur = activeJob.totalDuration || (durPerUnit * totalQty);

        if (activeJob.remainingTime === undefined) {
          activeJob.totalDuration = totalDur;
          activeJob.remainingTime = totalDur;
        }

        activeJob.remainingTime = Math.max(0, activeJob.remainingTime - 1);
        const elapsed = totalDur - activeJob.remainingTime;
        activeJob.completedQty = Math.min(totalQty, Math.floor(elapsed / durPerUnit));

        if (activeJob.remainingTime <= 0) {
          activeJob.status = 'completed';
          activeJob.completedQty = totalQty;
          playUiTick('confirm');
        }

        renderQueueView(currentTab, false);
      }
    }, 1000);
  }

  function renderQueueView(tab) {
    panelEl.queueList.innerHTML = '';
    const jobs = (tab.items || []).filter(job => {
      if (!panelState.searchQuery) return true;
      const q = panelState.searchQuery.toLowerCase();
      return (job.title && job.title.toLowerCase().includes(q)) ||
             (job.subtitle && job.subtitle.toLowerCase().includes(q));
    });

    if (jobs.length === 0) {
      panelEl.queueList.innerHTML = '<div class="dock-empty-msg" style="padding: 40px; text-align: center;">Nenhum item na fila de produção no momento.</div>';
      return;
    }

    jobs.forEach(job => {
      const card = document.createElement('div');
      const st = job.status || 'in_progress';
      card.className = `queue-item-card status-${st}`;

      const totalQty = job.totalQty || 1;
      const durPerUnit = job.durationPerUnit || 10;
      const totalDur = job.totalDuration || (durPerUnit * totalQty);
      const remaining = job.remainingTime !== undefined ? job.remainingTime : (st === 'completed' ? 0 : totalDur);
      const elapsed = Math.max(0, totalDur - remaining);
      const pct = Math.min(100, Math.max(0, (elapsed / totalDur) * 100));
      const completedQty = st === 'completed' ? totalQty : (job.completedQty || 0);

      // Header
      const header = document.createElement('div');
      header.className = 'queue-item-header';

      const main = document.createElement('div');
      main.className = 'queue-item-main';

      const iconUrl = resolveItemIcon(job);
      if (iconUrl) {
        const iconWrap = document.createElement('div');
        iconWrap.className = 'queue-item-icon-wrap';
        const img = document.createElement('img');
        img.className = 'queue-item-icon';
        img.src = iconUrl;
        img.alt = '';
        iconWrap.appendChild(img);
        main.appendChild(iconWrap);
      }

      const info = document.createElement('div');
      info.className = 'queue-item-info';

      const title = document.createElement('span');
      title.className = 'queue-item-title';
      title.textContent = job.title || 'Manufatura';
      info.appendChild(title);

      if (job.subtitle) {
        const sub = document.createElement('span');
        sub.className = 'queue-item-subtitle';
        sub.textContent = job.subtitle;
        info.appendChild(sub);
      }
      main.appendChild(info);
      header.appendChild(main);

      const meta = document.createElement('div');
      meta.className = 'queue-item-meta';

      const counter = document.createElement('span');
      counter.className = 'queue-item-counter';
      counter.textContent = `${completedQty} / ${totalQty} UNIDADES`;
      meta.appendChild(counter);

      const pill = document.createElement('span');
      if (st === 'in_progress') {
        pill.className = 'status-pill gold';
        pill.textContent = 'EM ANDAMENTO';
      } else if (st === 'completed') {
        pill.className = 'status-pill on';
        pill.textContent = 'CONCLUÍDO';
      } else if (st === 'queued') {
        pill.className = 'status-pill off';
        pill.textContent = 'NA FILA';
      } else {
        pill.className = 'status-pill danger';
        pill.textContent = 'CANCELADO';
      }
      meta.appendChild(pill);
      header.appendChild(meta);
      card.appendChild(header);

      // Barra de Progresso e Stats
      const progressSec = document.createElement('div');
      progressSec.className = 'queue-progress-section';

      const barBg = document.createElement('div');
      barBg.className = 'queue-progress-bar-bg';
      const barFill = document.createElement('div');
      barFill.className = 'queue-progress-bar-fill';
      barFill.style.width = `${pct}%`;
      barBg.appendChild(barFill);
      progressSec.appendChild(barBg);

      const stats = document.createElement('div');
      stats.className = 'queue-progress-stats';

      const timeText = document.createElement('span');
      timeText.className = 'queue-time-remaining';
      if (st === 'completed') {
        timeText.textContent = `✓ Produção concluída (${totalQty} unidades prontas)`;
      } else if (st === 'queued') {
        timeText.textContent = `Aguardando liberação da bancada...`;
      } else if (st === 'in_progress') {
        timeText.textContent = `⏳ Restam ${remaining}s (Unidade ${Math.min(totalQty, completedQty + 1)} de ${totalQty})`;
      } else {
        timeText.textContent = `Lote cancelado`;
      }
      stats.appendChild(timeText);

      const pctText = document.createElement('span');
      pctText.className = 'queue-percentage';
      pctText.textContent = `${Math.round(pct)}%`;
      stats.appendChild(pctText);

      progressSec.appendChild(stats);
      card.appendChild(progressSec);

      // Ações do Job
      const actions = document.createElement('div');
      actions.className = 'queue-item-actions';

      if (st === 'completed') {
        const btnCollect = document.createElement('button');
        btnCollect.className = 'queue-btn collect';
        btnCollect.textContent = `COLETAR (${totalQty} UNIDADES)`;
        btnCollect.addEventListener('click', (e) => {
          e.stopPropagation();
          playUiTick('confirm');
          tab.items = (tab.items || []).filter(j => j.id !== job.id);
          renderQueueView(tab);
          updateFooter();
          postData('westrp_ui:panelAction', {
            panelId: panelState.id,
            tabId: tab.id,
            action: 'collect_job',
            item: job,
            quantity: totalQty
          });
        });
        actions.appendChild(btnCollect);
      } else if (st === 'in_progress' || st === 'queued') {
        const btnCancel = document.createElement('button');
        btnCancel.className = 'queue-btn cancel';
        btnCancel.textContent = 'CANCELAR LOTE';
        btnCancel.addEventListener('click', (e) => {
          e.stopPropagation();
          playUiTick('back');
          job.status = 'cancelled';
          renderQueueView(tab);
          updateFooter();
          postData('westrp_ui:panelAction', {
            panelId: panelState.id,
            tabId: tab.id,
            action: 'cancel_job',
            item: job,
            quantity: totalQty
          });
        });
        actions.appendChild(btnCancel);
      }

      card.appendChild(actions);
      panelEl.queueList.appendChild(card);
    });
  }

  function executePanelCta() {
    if (!panelState.selectedItem) return;
    playUiTick('confirm');

    const currentTab = panelState.tabs[panelState.activeTab];
    const qty = panelState.quantity;
    const selected = panelState.selectedItem;

    // Se estiver na bancada de forja (craft), enfileira automaticamente na aba de produção
    if (currentTab && currentTab.viewType === 'craft') {
      const queueTab = panelState.tabs.find(t => t.viewType === 'queue');
      if (queueTab) {
        if (!queueTab.items) queueTab.items = [];
        const hasInProgress = queueTab.items.some(j => j.status === 'in_progress');
        const durPerUnit = 8;
        const totalDur = durPerUnit * qty;
        const newJob = {
          id: 'job_' + Date.now(),
          item: selected.id,
          title: selected.title || 'Manufatura',
          subtitle: selected.subtitle || 'Lote enviado da forja',
          totalQty: qty,
          completedQty: 0,
          durationPerUnit: durPerUnit,
          totalDuration: totalDur,
          remainingTime: totalDur,
          status: hasInProgress ? 'queued' : 'in_progress'
        };
        queueTab.items.push(newJob);
      }
    }

    postData('westrp_ui:panelAction', {
      panelId: panelState.id,
      tabId: currentTab ? currentTab.id : 'default',
      action: (currentTab && currentTab.viewType === 'craft') ? 'craft' : 'confirm',
      item: selected,
      quantity: qty
    });
  }

  // Event Listeners do Panel
  panelEl.closeBtn.addEventListener('click', () => closePanel('btn'));
  panelEl.backdrop.addEventListener('click', () => closePanel('backdrop'));
  panelEl.btnMinus.addEventListener('click', () => setPanelQuantity(panelState.quantity - 1));
  panelEl.btnPlus.addEventListener('click', () => setPanelQuantity(panelState.quantity + 1));
  panelEl.ctaBtn.addEventListener('click', () => executePanelCta());

  if (panelEl.operatorStatusBtn) {
    panelEl.operatorStatusBtn.addEventListener('click', () => {
      if (!panelState.operator) return;
      panelState.operator.onDuty = !panelState.operator.onDuty;
      const onDuty = panelState.operator.onDuty;
      if (panelEl.operatorStatusDot) panelEl.operatorStatusDot.className = 'status-dot ' + (onDuty ? 'on' : 'off');
      if (panelEl.operatorStatusText) panelEl.operatorStatusText.textContent = onDuty ? 'Em Serviço' : 'Fora de Serviço';
      playUiTick('confirm');
      postData('westrp_ui:panelAction', {
        action: 'toggle_duty',
        onDuty: onDuty
      });
    });
  }

  panelEl.btnPagePrev.addEventListener('click', () => {
    if (panelState.currentPage > 1) {
      panelState.currentPage--;
      playUiTick('nav');
      renderPanelContent();
    }
  });

  panelEl.btnPageNext.addEventListener('click', () => {
    panelState.currentPage++;
    playUiTick('nav');
    renderPanelContent();
  });

  panelEl.searchInput.addEventListener('input', (e) => {
    panelState.searchQuery = e.target.value.trim();
    panelState.currentPage = 1;
    renderPanelContent();
  });


  // ==========================================================================
  // 4. TECLADO NATIVO ROCKSTAR (DISPATCHER GLOBAL)
  // ==========================================================================
  window.addEventListener('keydown', (e) => {
    // Se o Panel estiver aberto, ele consome o ESC para fechar
    if (panelState.isOpen) {
      if (e.key === 'Escape') {
        e.preventDefault();
        closePanel('escape');
      }
      return;
    }

    // Se o Dock estiver aberto, processa a navegação por teclado
    if (dockState.isOpen) {
      switch (e.key) {
        case 'ArrowUp':
          e.preventDefault();
          {
            const items = getDockCurrentItems();
            if (items.length > 0) {
              dockState.selectedIndex = (dockState.selectedIndex - 1 + items.length) % items.length;
              updateDockSelection(true);
            }
          }
          break;

        case 'ArrowDown':
          e.preventDefault();
          {
            const items = getDockCurrentItems();
            if (items.length > 0) {
              dockState.selectedIndex = (dockState.selectedIndex + 1) % items.length;
              updateDockSelection(true);
            }
          }
          break;

        case 'ArrowLeft':
          e.preventDefault();
          if (!handleDockSliderStep('left')) {
            switchDockTab('prev');
          }
          break;

        case 'ArrowRight':
          e.preventDefault();
          if (!handleDockSliderStep('right')) {
            switchDockTab('next');
          }
          break;

        case 'Enter':
          e.preventDefault();
          executeDockCurrentItem();
          break;

        case 'Backspace':
          e.preventDefault();
          goBackDockOrClose();
          break;

        case 'Escape':
          e.preventDefault();
          closeDock('escape');
          break;
      }
    }
  });


  // ==========================================================================
  // 5. SISTEMA DE TOASTS
  // ==========================================================================
  const toastContainer = document.getElementById('toast-container');

  function showToast(title, message, type = 'info', duration = 3500) {
    try {
      playUiTick(type === 'error' || type === 'alert' ? 'error' : 'confirm');
    } catch (e) {}

    const toast = document.createElement('div');
    toast.className = `toast-msg ${type}`;
    toast.innerHTML = `<strong>${title}</strong><br>${message}`;
    toastContainer.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(6px)';
      toast.style.transition = 'opacity 0.2s, transform 0.2s';
      setTimeout(() => toast.remove(), 250);
    }, duration);
  }


  // ==========================================================================
  // 6. LISTENER DE MENSAGENS NUI DO REDM CLIENT
  // ==========================================================================
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    // --- MENSAGENS DO DOCK ---
    if (data.action === 'westrp_ui:open') {
      const opts = data.options || {};
      dockState.isOpen = true;
      dockState.menuId = opts.id || 'default_menu';
      dockState.title = opts.title || 'REGISTRO';
      dockState.tag = opts.tag || 'FRONTIER';
      dockState.activeTabIndex = 0;
      dockState.selectedIndex = 0;
      dockState.navigationStack = [];

      if (opts.tabs && opts.tabs.length > 0) {
        dockState.tabs = opts.tabs;
      } else if (opts.items && opts.items.length > 0) {
        dockState.tabs = [{ id: 'main', name: 'GERAL', items: opts.items }];
      } else {
        dockState.tabs = [{ id: 'main', name: 'GERAL', items: [] }];
      }

      // Aplica classes de posicionamento se fornecido (ex: 'mid_left', 'top_left', etc.)
      const validPositions = ['pos-top-left', 'pos-mid-left', 'pos-bottom-left', 'pos-top-right', 'pos-mid-right', 'pos-bottom-right'];
      validPositions.forEach(p => dockEl.container.classList.remove(p));
      if (opts.position) {
        const cls = 'pos-' + String(opts.position).replace('_', '-');
        dockEl.container.classList.add(cls);
      }

      dockEl.container.style.display = 'flex';
      renderDockHeader();
      renderDockTabsBar();
      renderDockBreadcrumb();
      renderDockViewport();
      playUiTick('confirm');
    } else if (data.action === 'westrp_ui:close') {
      closeDock('client_request');
    } else if (data.action === 'westrp_ui:updateItem') {
      const { tabId, itemId, updates } = data;
      dockState.tabs.forEach(tab => {
        if (!tabId || tab.id === tabId) {
          tab.items.forEach(item => {
            if (item.id === itemId) {
              Object.assign(item, updates || {});
            }
          });
        }
      });
      renderDockViewport();
    }

    // --- MENSAGENS DO PANEL ---
    else if (data.action === 'westrp_ui:openPanel') {
      openPanel(data.options);
    } else if (data.action === 'westrp_ui:updatePanel') {
      if (panelState.isOpen && data.options) {
        if (data.options.tabs) panelState.tabs = data.options.tabs;
        if (data.options.operator) {
          panelState.operator = Object.assign(panelState.operator || {}, data.options.operator);
          const onDuty = panelState.operator.onDuty;
          if (panelEl.operatorStatusDot) panelEl.operatorStatusDot.className = 'status-dot ' + (onDuty ? 'on' : 'off');
          if (panelEl.operatorStatusText) panelEl.operatorStatusText.textContent = onDuty ? 'Em Serviço' : 'Fora de Serviço';
        }
        renderPanelTabs();
        renderPanelContent();
      }
    } else if (data.action === 'westrp_ui:closePanel') {
      closePanel('client_request');
    }

    // --- TOASTS ---
    else if (data.action === 'westrp_ui:toast') {
      showToast(data.title, data.message, data.type, data.duration);
    }

    // --- DIALOG MODAL / FORMULÁRIO TIPADO ---
    else if (data.action === 'westrp_ui:openDialog') {
      openDialog(data.options);
    } else if (data.action === 'westrp_ui:closeDialog') {
      closeDialog('client_request');
    }
  });


  // ==========================================================================
  // 7. SISTEMA DE DIALOG MODAL / FORMULÁRIO TIPADO (ROCKSTAR STYLE)
  // ==========================================================================
  const dialogEl = {
    container: document.getElementById('dialog-container'),
    backdrop: document.getElementById('dialog-backdrop'),
    tag: document.getElementById('dialog-tag'),
    title: document.getElementById('dialog-title'),
    subtitle: document.getElementById('dialog-subtitle'),
    form: document.getElementById('dialog-form'),
    fieldsList: document.getElementById('dialog-form-fields'),
    closeBtn: document.getElementById('dialog-close-btn'),
    cancelBtn: document.getElementById('dialog-btn-cancel'),
    submitBtn: document.getElementById('dialog-btn-submit'),
  };

  const dialogState = {
    isOpen: false,
    dialogId: 'default_dialog',
    fields: []
  };

  function openDialog(options = {}) {
    dialogState.isOpen = true;
    dialogState.dialogId = options.id || 'default_dialog';
    dialogState.fields = options.fields || [];

    if (dialogEl.tag) dialogEl.tag.textContent = options.tag || 'ADMINISTRAÇÃO';
    if (dialogEl.title) dialogEl.title.textContent = options.title || 'FORMULÁRIO';
    if (dialogEl.subtitle) {
      if (options.subtitle) {
        dialogEl.subtitle.textContent = options.subtitle;
        dialogEl.subtitle.style.display = 'block';
      } else {
        dialogEl.subtitle.style.display = 'none';
      }
    }
    if (dialogEl.submitBtn) {
      dialogEl.submitBtn.textContent = options.submitLabel || 'CONFIRMAR';
    }
    if (dialogEl.cancelBtn) {
      dialogEl.cancelBtn.textContent = options.cancelLabel || 'CANCELAR';
    }

    renderDialogFields();

    if (dialogEl.container) dialogEl.container.style.display = 'flex';
    playUiTick('confirm');

    // Foca no primeiro input editável
    setTimeout(() => {
      if (dialogEl.fieldsList) {
        const firstInput = dialogEl.fieldsList.querySelector('input, select, textarea');
        if (firstInput) firstInput.focus();
      }
    }, 50);
  }

  function renderDialogFields() {
    if (!dialogEl.fieldsList) return;
    dialogEl.fieldsList.innerHTML = '';

    dialogState.fields.forEach(field => {
      const wrap = document.createElement('div');
      wrap.className = 'dialog-field';

      const label = document.createElement('label');
      label.className = 'dialog-label';
      label.textContent = field.label || field.id;
      if (field.required) {
        const star = document.createElement('span');
        star.className = 'req-star';
        star.textContent = ' *';
        label.appendChild(star);
      }
      wrap.appendChild(label);

      let inputEl;
      if (field.type === 'select') {
        inputEl = document.createElement('select');
        inputEl.className = 'dialog-select';
        (field.options || []).forEach(opt => {
          const optEl = document.createElement('option');
          optEl.value = opt.value;
          optEl.textContent = opt.label;
          if (opt.selected || opt.value === field.default) {
            optEl.selected = true;
          }
          inputEl.appendChild(optEl);
        });
      } else if (field.type === 'textarea') {
        inputEl = document.createElement('textarea');
        inputEl.className = 'dialog-textarea';
        inputEl.placeholder = field.placeholder || '';
        inputEl.rows = field.rows || 3;
        if (field.default !== undefined) inputEl.value = field.default;
      } else if (field.type === 'number') {
        inputEl = document.createElement('input');
        inputEl.type = 'number';
        inputEl.className = 'dialog-input';
        if (field.min !== undefined) inputEl.min = field.min;
        if (field.max !== undefined) inputEl.max = field.max;
        inputEl.step = field.step || 'any';
        inputEl.placeholder = field.placeholder || '';
        if (field.default !== undefined) inputEl.value = field.default;
      } else {
        inputEl = document.createElement('input');
        inputEl.type = 'text';
        inputEl.className = 'dialog-input';
        inputEl.placeholder = field.placeholder || '';
        if (field.default !== undefined) inputEl.value = field.default;
      }

      inputEl.dataset.fieldId = field.id;
      inputEl.addEventListener('input', () => {
        inputEl.classList.remove('field-error');
      });

      wrap.appendChild(inputEl);
      dialogEl.fieldsList.appendChild(wrap);
    });
  }

  function closeDialog(reason = 'cancel') {
    if (!dialogState.isOpen) return;
    dialogState.isOpen = false;
    if (dialogEl.container) dialogEl.container.style.display = 'none';
    if (dialogEl.fieldsList) dialogEl.fieldsList.innerHTML = '';

    if (reason !== 'submit') {
      playUiTick('back');
      postData('westrp_ui:dialogCancel', { dialogId: dialogState.dialogId });
    }
  }

  function submitDialog() {
    if (!dialogState.isOpen) return;

    const values = {};
    let hasError = false;
    let firstErrorEl = null;

    dialogState.fields.forEach(field => {
      const el = dialogEl.fieldsList.querySelector(`[data-field-id="${field.id}"]`);
      if (!el) return;

      let val = el.value ? el.value.trim() : '';

      if (field.required && val === '') {
        el.classList.add('field-error');
        hasError = true;
        if (!firstErrorEl) firstErrorEl = el;
        return;
      }

      if (field.type === 'number') {
        const numVal = parseFloat(val);
        if (isNaN(numVal) && field.required) {
          el.classList.add('field-error');
          hasError = true;
          if (!firstErrorEl) firstErrorEl = el;
          return;
        }
        values[field.id] = isNaN(numVal) ? null : numVal;
      } else {
        values[field.id] = val;
      }
    });

    if (hasError) {
      playUiTick('error');
      if (firstErrorEl) firstErrorEl.focus();
      return;
    }

    dialogState.isOpen = false;
    if (dialogEl.container) dialogEl.container.style.display = 'none';
    playUiTick('confirm');

    postData('westrp_ui:dialogSubmit', {
      dialogId: dialogState.dialogId,
      values: values
    });
  }

  if (dialogEl.closeBtn) {
    dialogEl.closeBtn.addEventListener('click', () => closeDialog('close'));
  }
  if (dialogEl.cancelBtn) {
    dialogEl.cancelBtn.addEventListener('click', () => closeDialog('cancel'));
  }
  if (dialogEl.submitBtn) {
    dialogEl.submitBtn.addEventListener('click', () => submitDialog());
  }
  if (dialogEl.backdrop) {
    dialogEl.backdrop.addEventListener('click', () => closeDialog('backdrop'));
  }

  window.addEventListener('keydown', (e) => {
    if (dialogState.isOpen) {
      if (e.key === 'Escape') {
        e.preventDefault();
        closeDialog('esc');
      } else if (e.key === 'Enter' && e.target && e.target.tagName !== 'TEXTAREA') {
        e.preventDefault();
        submitDialog();
      }
    }
  });

})();

