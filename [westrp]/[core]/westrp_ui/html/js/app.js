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
    ctaLabel: 'CONFIRMAR'
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
    tabsList: document.getElementById('panel-tabs-list'),
    gridView: document.getElementById('panel-grid-view'),
    tableView: document.getElementById('panel-table-view'),
    tableHead: document.getElementById('panel-table-head'),
    tableBody: document.getElementById('panel-table-body'),
    craftView: document.getElementById('panel-craft-view'),
    craftRecipeList: document.getElementById('craft-recipe-list'),
    craftDetailsTitle: document.getElementById('craft-details-title'),
    craftDetailsDesc: document.getElementById('craft-details-desc'),
    craftReqsList: document.getElementById('craft-reqs-list'),
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

    panelEl.tag.textContent = panelState.tag;
    panelEl.title.textContent = panelState.title;
    panelEl.searchInput.value = '';

    if (panelState.subtitle) {
      panelEl.metaPill.style.display = 'block';
      panelEl.metaText.textContent = panelState.subtitle;
    } else {
      panelEl.metaPill.style.display = 'none';
    }

    panelEl.container.style.display = 'flex';
    playUiTick('confirm');

    renderPanelTabs();
    renderPanelContent();
  }

  function closePanel(reason = 'escape') {
    if (!panelState.isOpen) return;
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
      
      const titleSpan = document.createElement('span');
      titleSpan.textContent = tab.label || `ABA ${index + 1}`;
      btn.appendChild(titleSpan);

      if (tab.badge) {
        const badge = document.createElement('span');
        badge.className = 'panel-tab-badge';
        badge.textContent = tab.badge;
        btn.appendChild(badge);
      }

      btn.addEventListener('click', () => {
        if (panelState.activeTab !== index) {
          panelState.activeTab = index;
          panelState.selectedItem = null;
          panelState.quantity = 1;
          panelState.searchQuery = '';
          panelEl.searchInput.value = '';
          playUiTick('nav');
          renderPanelTabs();
          renderPanelContent();
        }
      });

      panelEl.tabsList.appendChild(btn);
    });
  }

  function renderPanelContent() {
    const currentTab = panelState.tabs[panelState.activeTab];
    if (!currentTab) return;

    panelEl.gridView.style.display = 'none';
    panelEl.tableView.style.display = 'none';
    panelEl.craftView.style.display = 'none';

    updateFooter();

    if (currentTab.viewType === 'grid') {
      panelEl.gridView.style.display = 'grid';
      renderGridView(currentTab);
    } else if (currentTab.viewType === 'table') {
      panelEl.tableView.style.display = 'block';
      renderTableView(currentTab);
    } else if (currentTab.viewType === 'craft') {
      panelEl.craftView.style.display = 'flex';
      renderCraftView(currentTab);
    }
  }

  function renderGridView(tab) {
    panelEl.gridView.innerHTML = '';
    const items = (tab.items || []).filter(item => {
      if (!panelState.searchQuery) return true;
      const q = panelState.searchQuery.toLowerCase();
      return (item.title && item.title.toLowerCase().includes(q)) ||
             (item.subtitle && item.subtitle.toLowerCase().includes(q));
    });

    if (items.length === 0) {
      panelEl.gridView.innerHTML = '<div class="dock-empty-msg" style="grid-column: 1 / -1;">Nenhum item encontrado.</div>';
      return;
    }

    items.forEach(item => {
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

    const rows = (tab.rows || []).filter(row => {
      if (!panelState.searchQuery) return true;
      const q = panelState.searchQuery.toLowerCase();
      return Object.values(row).some(val => String(val).toLowerCase().includes(q));
    });

    if (rows.length === 0) {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td colspan="${cols.length}" style="text-align: center; padding: 30px; color: var(--text-muted);">Nenhum registro encontrado.</td>`;
      panelEl.tableBody.appendChild(tr);
      return;
    }

    rows.forEach(row => {
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
    panelEl.craftDetailsTitle.textContent = recipe.title || 'Receita';
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

      row.className = `craft-req-row ${isOk ? 'ok' : 'missing'}`;
      row.innerHTML = `<span>${req.label || req.item}</span> <span class="status-pill ${isOk ? 'on' : 'off'}">${current} / ${needed}</span>`;
      panelEl.craftReqsList.appendChild(row);
    });

    panelEl.ctaBtn.disabled = !hasAll;
  }

  function updateFooter() {
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

  function executePanelCta() {
    if (!panelState.selectedItem) return;
    playUiTick('confirm');

    const currentTab = panelState.tabs[panelState.activeTab];
    postData('westrp_ui:panelAction', {
      panelId: panelState.id,
      tabId: currentTab ? currentTab.id : 'default',
      action: 'confirm',
      item: panelState.selectedItem,
      quantity: panelState.quantity
    });
  }

  // Event Listeners do Panel
  panelEl.closeBtn.addEventListener('click', () => closePanel('btn'));
  panelEl.backdrop.addEventListener('click', () => closePanel('backdrop'));
  panelEl.btnMinus.addEventListener('click', () => setPanelQuantity(panelState.quantity - 1));
  panelEl.btnPlus.addEventListener('click', () => setPanelQuantity(panelState.quantity + 1));
  panelEl.ctaBtn.addEventListener('click', () => executePanelCta());

  panelEl.searchInput.addEventListener('input', (e) => {
    panelState.searchQuery = e.target.value.trim();
    const currentTab = panelState.tabs[panelState.activeTab];
    if (currentTab) {
      if (currentTab.viewType === 'grid') renderGridView(currentTab);
      else if (currentTab.viewType === 'table') renderTableView(currentTab);
      else if (currentTab.viewType === 'craft') renderCraftView(currentTab);
    }
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
    } else if (data.action === 'westrp_ui:closePanel') {
      closePanel('client_request');
    }

    // --- TOASTS ---
    else if (data.action === 'westrp_ui:toast') {
      showToast(data.title, data.message, data.type, data.duration);
    }
  });

})();
