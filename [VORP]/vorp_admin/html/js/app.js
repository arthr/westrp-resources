/**
 * THE FRONTIER GAZETTE & ADMINISTRATIVE REGISTRY - 1899
 * Client-Side NUI Application Logic
 * Pure ES6+, Zero External Frameworks, Fast Debounce & Robust CEF Focus Management
 */

(function () {
  'use strict';

  // --- Estado Global da Aplicação ---
  const state = {
    isOpen: false,
    players: [],
    filteredPlayers: [],
    selectedPlayer: null,
    activeTab: 'tab-players',
    boosters: {
      godmode: false,
      noclip: false,
      goldencores: false,
      infiammo: false,
      invis: false,
      autotpm: false,
      devlaser: false
    },
    searchQuery: '',
    searchDebounceTimer: null
  };

  // --- Elementos do DOM ---
  const el = {
    app: document.getElementById('admin-newspaper-app'),
    btnClose: document.getElementById('btn-close-gazette'),
    tabButtons: document.querySelectorAll('.nav-tab-btn'),
    tabPanes: document.querySelectorAll('.tab-pane'),
    
    // Players Tab
    searchInput: document.getElementById('player-search-input'),
    playersTableBody: document.getElementById('players-table-body'),
    playersCountText: document.getElementById('players-count-text'),
    
    // Dossier Panel
    dossierName: document.getElementById('dossier-name'),
    dossierSubinfo: document.getElementById('dossier-subinfo'),
    dossierMetaSection: document.getElementById('dossier-meta-section'),
    dossierActionsContainer: document.getElementById('dossier-actions-container'),
    dossierEmptyHint: document.getElementById('dossier-empty-hint'),
    
    // Dossier Meta Fields
    metaServerId: document.getElementById('meta-server-id'),
    metaStaticId: document.getElementById('meta-static-id'),
    metaGroup: document.getElementById('meta-group'),
    metaWhitelist: document.getElementById('meta-whitelist'),
    metaMoney: document.getElementById('meta-money'),
    metaGold: document.getElementById('meta-gold'),
    
    // Dossier Actions
    actGoto: document.getElementById('act-goto'),
    actBring: document.getElementById('act-bring'),
    actHeal: document.getElementById('act-heal'),
    actRevive: document.getElementById('act-revive'),
    actFreeze: document.getElementById('act-freeze'),
    actSpectate: document.getElementById('act-spectate'),
    actSendback: document.getElementById('act-sendback'),
    actRespawn: document.getElementById('act-respawn'),
    actKick: document.getElementById('act-kick'),
    actBan: document.getElementById('act-ban'),
    actSetjob: document.getElementById('act-setjob'),
    actSetgroup: document.getElementById('act-setgroup'),
    actToggleWl: document.getElementById('act-toggle-wl'),
    
    // Troll Actions
    actTrollLightning: document.getElementById('act-troll-lightning'),
    actTrollFire: document.getElementById('act-troll-fire'),
    actTrollHeaven: document.getElementById('act-troll-heaven'),
    actTrollHandcuff: document.getElementById('act-troll-handcuff'),
    actTrollRagdoll: document.getElementById('act-troll-ragdoll'),
    actTrollStam: document.getElementById('act-troll-stam'),
    
    // Boosters
    statusGodmode: document.getElementById('status-godmode'),
    statusNoclip: document.getElementById('status-noclip'),
    statusGoldencores: document.getElementById('status-goldencores'),
    statusInfiammo: document.getElementById('status-infiammo'),
    statusInvis: document.getElementById('status-invis'),
    btnToggleGodmode: document.getElementById('btn-toggle-godmode'),
    btnToggleNoclip: document.getElementById('btn-toggle-noclip'),
    btnToggleGoldencores: document.getElementById('btn-toggle-goldencores'),
    btnToggleInfiammo: document.getElementById('btn-toggle-infiammo'),
    btnToggleInvis: document.getElementById('btn-toggle-invis'),
    btnSelfHeal: document.getElementById('btn-self-heal'),
    btnSelfRevive: document.getElementById('btn-self-revive'),
    btnSpawnHorse: document.getElementById('btn-spawn-horse'),
    
    // Treasury
    treasuryTargetName: document.getElementById('treasury-target-name'),
    inputMoneyAmount: document.getElementById('input-money-amount'),
    btnGiveMoney: document.getElementById('btn-give-money'),
    btnGiveGold: document.getElementById('btn-give-gold'),
    inputItemName: document.getElementById('input-item-name'),
    inputItemQty: document.getElementById('input-item-qty'),
    btnGiveItem: document.getElementById('btn-give-item'),
    inputWeaponHash: document.getElementById('input-weapon-hash'),
    btnGiveWeapon: document.getElementById('btn-give-weapon'),
    inputMountModel: document.getElementById('input-mount-model'),
    btnGiveHorse: document.getElementById('btn-give-horse'),
    btnGiveWagon: document.getElementById('btn-give-wagon'),
    btnClearInventory: document.getElementById('btn-clear-inventory'),
    btnClearMoney: document.getElementById('btn-clear-money'),
    btnClearGold: document.getElementById('btn-clear-gold'),
    
    // Teleports
    btnTpMarker: document.getElementById('btn-tp-marker'),
    btnToggleAutotpm: document.getElementById('btn-toggle-autotpm'),
    btnAdminGoback: document.getElementById('btn-admin-goback'),
    btnTpGuarma: document.getElementById('btn-tp-guarma'),
    inputCustomCoords: document.getElementById('input-custom-coords'),
    btnTpCustomCoords: document.getElementById('btn-tp-custom-coords'),
    inputAnnounceText: document.getElementById('input-announce-text'),
    btnSendAnnounce: document.getElementById('btn-send-announce'),
    
    // DevTools
    btnCopyVector3: document.getElementById('btn-copy-vector3'),
    btnCopyVector4: document.getElementById('btn-copy-vector4'),
    btnCopyHeading: document.getElementById('btn-copy-heading'),
    btnGetInterior: document.getElementById('btn-get-interior'),
    statusDevlaser: document.getElementById('status-devlaser'),
    btnToggleDevlaser: document.getElementById('btn-toggle-devlaser'),
    inputSpawnPedName: document.getElementById('input-spawn-ped-name'),
    btnSpawnPed: document.getElementById('btn-spawn-ped'),
    
    // Modal
    modalBackdrop: document.getElementById('gazette-modal-backdrop'),
    modalTitle: document.getElementById('modal-title'),
    modalBodyContent: document.getElementById('modal-body-content'),
    modalCancelBtn: document.getElementById('modal-cancel-btn'),
    modalConfirmBtn: document.getElementById('modal-confirm-btn'),
    
    // Toasts
    toastContainer: document.getElementById('toast-container')
  };

  // --- Função Utilitária para Chamadas ao Client Lua ---
  async function postNui(event, data = {}) {
    try {
      const response = await fetch(`https://vorp_admin/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
      });
      return await response.json();
    } catch (err) {
      // Ignora erro natural de fetch quando callback Lua não retorna json
      return null;
    }
  }

  // --- Cópia para Clipboard (Compatibilidade Legada) ---
  function copyToClipboard(str) {
    if (!str) return;
    const el = document.createElement('textarea');
    el.value = str;
    document.body.appendChild(el);
    el.select();
    try {
      document.execCommand('copy');
      showToast('Copiado para a Área de Transferência: ' + str);
    } catch (e) {
      console.error('Falha ao copiar:', e);
    }
    document.body.removeChild(el);
  }

  // --- Sistema de Notificações Toasts ---
  function showToast(message, isAlert = false) {
    if (!el.toastContainer) return;
    const toast = document.createElement('div');
    toast.className = isAlert ? 'toast-msg alert' : 'toast-msg';
    toast.textContent = message;
    el.toastContainer.appendChild(toast);
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast);
      }
    }, 3500);
  }

  // --- Gerenciador de Modais Customizados ---
  let activeModalCallback = null;

  function openPromptModal({ title, bodyHtml, confirmText = 'Confirmar', danger = false, onConfirm }) {
    el.modalTitle.textContent = title;
    el.modalBodyContent.innerHTML = bodyHtml;
    el.modalConfirmBtn.textContent = confirmText;
    
    if (danger) {
      el.modalConfirmBtn.classList.add('danger');
    } else {
      el.modalConfirmBtn.classList.remove('danger');
    }
    
    activeModalCallback = onConfirm;
    el.modalBackdrop.style.display = 'flex';
    
    const firstInput = el.modalBodyContent.querySelector('input, textarea');
    if (firstInput) firstInput.focus();
  }

  function closeModal() {
    el.modalBackdrop.style.display = 'none';
    activeModalCallback = null;
    el.modalBodyContent.innerHTML = '';
  }

  el.modalCancelBtn.addEventListener('click', closeModal);
  el.modalConfirmBtn.addEventListener('click', () => {
    if (typeof activeModalCallback === 'function') {
      activeModalCallback();
    }
    closeModal();
  });

  // --- Controle de Abertura / Fechamento do Jornal ---
  function openApp(data = {}) {
    state.isOpen = true;
    el.app.style.display = 'flex';
    
    if (data.players) {
      updatePlayersData(data.players);
    }
    
    if (data.boosters) {
      updateBoostersState(data.boosters);
    }

    if (data.staffRole) {
      const tag = document.getElementById('header-staff-tag');
      if (tag) tag.textContent = 'CARGO: ' + String(data.staffRole).toUpperCase();
    }
  }

  function closeApp() {
    state.isOpen = false;
    el.app.style.display = 'none';
    closeModal();
    postNui('closeMenu');
  }

  el.btnClose.addEventListener('click', closeApp);

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && state.isOpen) {
      e.preventDefault();
      closeApp();
    }
  });

  // --- Navegação por Abas ---
  el.tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetTab = btn.getAttribute('data-tab');
      switchTab(targetTab);
    });
  });

  function switchTab(tabId) {
    state.activeTab = tabId;
    el.tabButtons.forEach(b => b.classList.toggle('active', b.getAttribute('data-tab') === tabId));
    el.tabPanes.forEach(p => p.classList.toggle('active', p.id === tabId));
  }

  // --- Renderização da Tabela de Cidadãos & Live Search ---
  // --- Renderização da Tabela de Cidadãos & Live Search ---
  function updatePlayersData(playersList) {
    const rawList = Array.isArray(playersList) ? playersList : Object.values(playersList || {});
    // Higienização completa contra arrays esparsos gerados pelo JSON do CitizenFX
    state.players = rawList.filter(p => p && typeof p === 'object' && p.serverId != null);

    // Se o cidadão selecionado não estiver mais online, reseta dossiê
    if (state.selectedPlayer) {
      const stillOnline = state.players.some(p => p.serverId === state.selectedPlayer.serverId);
      if (!stillOnline) {
        state.selectedPlayer = null;
        if (el.dossierEmptyHint) el.dossierEmptyHint.style.display = 'block';
        if (el.dossierMetaSection) el.dossierMetaSection.style.display = 'none';
        if (el.dossierActionsContainer) el.dossierActionsContainer.style.display = 'none';
        if (el.treasuryTargetName) el.treasuryTargetName.textContent = 'Nenhum Selecionado';
      }
    }

    applySearchFilter();
  }

  function applySearchFilter() {
    const query = state.searchQuery.trim().toLowerCase();
    
    if (!query) {
      state.filteredPlayers = [...state.players];
    } else {
      state.filteredPlayers = state.players.filter(p => {
        if (!p) return false;
        const idStr = String(p.serverId ?? '');
        const rpName = String(p.PlayerName ?? '').toLowerCase();
        const steamName = String(p.name ?? '').toLowerCase();
        const job = String(p.Job ?? '').toLowerCase();
        const steamId = String(p.SteamId ?? '').toLowerCase();
        return idStr.includes(query) || rpName.includes(query) || steamName.includes(query) || job.includes(query) || steamId.includes(query);
      });
    }

    renderPlayersTable();
  }

  function renderPlayersTable() {
    el.playersTableBody.innerHTML = '';
    el.playersCountText.textContent = `Cidadãos em Registro: ${state.filteredPlayers.length} / ${state.players.length}`;

    if (state.filteredPlayers.length === 0) {
      const row = document.createElement('tr');
      row.innerHTML = `<td colspan="6" style="text-align: center; color: var(--text-muted); padding: 24px; font-style: italic;">Nenhum registro encontrado para a busca especificada.</td>`;
      el.playersTableBody.appendChild(row);
      return;
    }

    state.filteredPlayers.forEach(p => {
      if (!p) return;
      const tr = document.createElement('tr');
      if (state.selectedPlayer && state.selectedPlayer.serverId === p.serverId) {
        tr.classList.add('selected');
      }

      const wlVal = p.WLstatus;
      const isVerified = (wlVal === 'true' || wlVal === '1' || wlVal === true);
      const wlClass = isVerified ? 'stamp-verified' : 'stamp-wanted';
      const wlText = isVerified ? 'VERIFICADO' : 'PENDENTE';

      tr.innerHTML = `
        <td style="font-weight: 700;">#${p.serverId ?? 'N/A'}</td>
        <td><strong>${escapeHtml(p.PlayerName || 'Desconhecido')}</strong></td>
        <td style="color: var(--text-muted);">${escapeHtml(p.name || '')}</td>
        <td>${escapeHtml(p.Job || 'Desempregado')} <span style="font-size: 10px; color: var(--text-muted);">(${p.Grade ?? 0})</span></td>
        <td>$ ${(Number(p.Money || 0)).toFixed(2)} / <span style="color: var(--accent-gold); font-weight: 600;">${(Number(p.Gold || 0)).toFixed(2)}g</span></td>
        <td><span class="stamp ${wlClass}">${wlText}</span></td>
      `;

      tr.addEventListener('click', () => selectPlayer(p));
      el.playersTableBody.appendChild(tr);
    });
  }

  // Live Search com Debounce de 120ms
  el.searchInput.addEventListener('input', (e) => {
    state.searchQuery = e.target.value;
    clearTimeout(state.searchDebounceTimer);
    state.searchDebounceTimer = setTimeout(() => {
      applySearchFilter();
    }, 120);
  });

  // --- Seleção de Cidadão e Atualização do Dossiê ---
  function selectPlayer(player) {
    if (!player) return;
    state.selectedPlayer = player;
    
    // Atualiza destaque na tabela
    const rows = el.playersTableBody.querySelectorAll('tr');
    rows.forEach(r => r.classList.remove('selected'));
    const selectedRow = Array.from(rows).find(r => r.querySelector('td') && r.querySelector('td').textContent === `#${player.serverId}`);
    if (selectedRow) selectedRow.classList.add('selected');

    // Popula o Dossiê Lateral
    el.dossierEmptyHint.style.display = 'none';
    el.dossierMetaSection.style.display = 'grid';
    el.dossierActionsContainer.style.display = 'block';

    el.dossierName.textContent = player.PlayerName || 'Cidadão';
    el.dossierSubinfo.textContent = `Conta Steam: ${player.name || 'N/A'} | Ocupação: ${player.Job || 'N/A'}`;

    el.metaServerId.textContent = `#${player.serverId ?? 'N/A'}`;
    el.metaStaticId.textContent = player.staticID || 'N/A';
    el.metaGroup.textContent = player.Group || 'user';
    el.metaWhitelist.textContent = (player.WLstatus === 'true' || player.WLstatus === '1' || player.WLstatus === true) ? 'Sim' : 'Não';
    el.metaMoney.textContent = `$ ${(Number(player.Money || 0)).toFixed(2)}`;
    el.metaGold.textContent = `${(Number(player.Gold || 0)).toFixed(2)} Ouro`;

    // Atualiza alvo na aba Tesouro
    el.treasuryTargetName.textContent = `${player.PlayerName} (ID: ${player.serverId})`;
  }

  // --- Helper de Ações por Jogador ---
  function dispatchPlayerAction(type, extra = {}) {
    if (!state.selectedPlayer) {
      showToast('Selecione um cidadão no registro primeiro!', true);
      return;
    }

    const payload = {
      actionType: type,
      targetId: state.selectedPlayer.serverId,
      targetName: state.selectedPlayer.PlayerName,
      steam: state.selectedPlayer.SteamId,
      staticId: state.selectedPlayer.staticID,
      ...extra
    };

    postNui('triggerAction', payload);
    showToast(`Ordem enviada: ${type.toUpperCase()} para ${state.selectedPlayer.PlayerName}`);
  }

  // Ações de Patrulha
  el.actGoto.addEventListener('click', () => dispatchPlayerAction('goto'));
  el.actBring.addEventListener('click', () => dispatchPlayerAction('bring'));
  el.actHeal.addEventListener('click', () => dispatchPlayerAction('heal'));
  el.actRevive.addEventListener('click', () => dispatchPlayerAction('revive'));
  el.actFreeze.addEventListener('click', () => dispatchPlayerAction('freeze'));
  el.actSpectate.addEventListener('click', () => dispatchPlayerAction('spectate'));
  el.actSendback.addEventListener('click', () => dispatchPlayerAction('sendback'));
  el.actRespawn.addEventListener('click', () => dispatchPlayerAction('respawn'));

  // Sanções com Modal
  el.actKick.addEventListener('click', () => {
    if (!state.selectedPlayer) return;
    openPromptModal({
      title: `Expulsar ${state.selectedPlayer.PlayerName}`,
      bodyHtml: `
        <label style="display:block; font-size:12px; margin-bottom:4px; font-weight:700;">Motivo da Expulsão</label>
        <input type="text" id="modal-kick-reason" class="form-input" placeholder="ex: Violação de conduta territorial">
      `,
      confirmText: 'Executar Expulsão',
      danger: true,
      onConfirm: () => {
        const reason = document.getElementById('modal-kick-reason')?.value || 'Expulso pela Administração';
        dispatchPlayerAction('kick', { reason });
      }
    });
  });

  el.actBan.addEventListener('click', () => {
    if (!state.selectedPlayer) return;
    openPromptModal({
      title: `Mandado de Prisão (Ban) - ${state.selectedPlayer.PlayerName}`,
      bodyHtml: `
        <div style="margin-bottom: 8px;">
          <label style="display:block; font-size:11px; margin-bottom:4px; font-weight:700;">Duração em Horas (0 = Permanente)</label>
          <input type="number" id="modal-ban-time" class="form-input" value="24" min="0">
        </div>
        <div>
          <label style="display:block; font-size:11px; margin-bottom:4px; font-weight:700;">Motivo da Condenação</label>
          <input type="text" id="modal-ban-reason" class="form-input" placeholder="ex: Quebra severa das leis de fronteira">
        </div>
      `,
      confirmText: 'Emitir Mandado',
      danger: true,
      onConfirm: () => {
        const time = Number(document.getElementById('modal-ban-time')?.value || 0);
        const reason = document.getElementById('modal-ban-reason')?.value || 'Banido pela Administração';
        dispatchPlayerAction('ban', { time, reason });
      }
    });
  });

  el.actSetjob.addEventListener('click', () => {
    if (!state.selectedPlayer) return;
    openPromptModal({
      title: `Nomeação de Cargo - ${state.selectedPlayer.PlayerName}`,
      bodyHtml: `
        <div style="margin-bottom: 8px;">
          <label style="display:block; font-size:11px; margin-bottom:4px; font-weight:700;">Código do Emprego (Job)</label>
          <input type="text" id="modal-job-name" class="form-input" placeholder="ex: police, doctor">
        </div>
        <div style="margin-bottom: 8px;">
          <label style="display:block; font-size:11px; margin-bottom:4px; font-weight:700;">Grau Numérico (Grade)</label>
          <input type="number" id="modal-job-grade" class="form-input" value="0" min="0">
        </div>
        <div>
          <label style="display:block; font-size:11px; margin-bottom:4px; font-weight:700;">Rótulo Exibido (Job Label)</label>
          <input type="text" id="modal-job-label" class="form-input" placeholder="ex: Xerife, Médico">
        </div>
      `,
      confirmText: 'Confirmar Nomeação',
      onConfirm: () => {
        const job = document.getElementById('modal-job-name')?.value || 'unemployed';
        const grade = Number(document.getElementById('modal-job-grade')?.value || 0);
        const jobLabel = document.getElementById('modal-job-label')?.value || job;
        dispatchPlayerAction('setJob', { job, grade, jobLabel });
      }
    });
  });

  el.actSetgroup.addEventListener('click', () => {
    if (!state.selectedPlayer) return;
    openPromptModal({
      title: `Alterar Grupo Administrativo - ${state.selectedPlayer.PlayerName}`,
      bodyHtml: `
        <label style="display:block; font-size:11px; margin-bottom:4px; font-weight:700;">Nome do Grupo</label>
        <input type="text" id="modal-group-name" class="form-input" placeholder="ex: admin, moderator, user">
      `,
      confirmText: 'Atribuir Grupo',
      onConfirm: () => {
        const group = document.getElementById('modal-group-name')?.value || 'user';
        dispatchPlayerAction('setGroup', { group });
      }
    });
  });

  el.actToggleWl.addEventListener('click', () => {
    dispatchPlayerAction('whitelist');
  });

  // Trolls da Fronteira
  el.actTrollLightning.addEventListener('click', () => dispatchPlayerAction('troll_lightning'));
  el.actTrollFire.addEventListener('click', () => dispatchPlayerAction('troll_fire'));
  el.actTrollHeaven.addEventListener('click', () => dispatchPlayerAction('troll_heaven'));
  el.actTrollHandcuff.addEventListener('click', () => dispatchPlayerAction('troll_handcuff'));
  el.actTrollRagdoll.addEventListener('click', () => dispatchPlayerAction('troll_ragdoll'));
  el.actTrollStam.addEventListener('click', () => dispatchPlayerAction('troll_stam'));

  // --- Seção 2: Boosters & Poderes ---
  function updateBoostersState(boosters = {}) {
    Object.assign(state.boosters, boosters);
    renderBoosterSwitch('godmode', el.statusGodmode, el.btnToggleGodmode);
    renderBoosterSwitch('noclip', el.statusNoclip, el.btnToggleNoclip);
    renderBoosterSwitch('goldencores', el.statusGoldencores, el.btnToggleGoldencores);
    renderBoosterSwitch('infiammo', el.statusInfiammo, el.btnToggleInfiammo);
    renderBoosterSwitch('invis', el.statusInvis, el.btnToggleInvis);
    renderBoosterSwitch('devlaser', el.statusDevlaser, el.btnToggleDevlaser);
  }

  function renderBoosterSwitch(key, badgeEl, btnEl) {
    if (!badgeEl || !btnEl) return;
    const isActive = Boolean(state.boosters[key]);
    badgeEl.textContent = isActive ? 'ATIVADO' : 'INATIVO';
    badgeEl.className = isActive ? 'stamp stamp-verified' : 'stamp stamp-wanted';
    btnEl.classList.toggle('active', isActive);
  }

  function toggleBooster(boosterName) {
    state.boosters[boosterName] = !state.boosters[boosterName];
    postNui('toggleBooster', { booster: boosterName });
    updateBoostersState(state.boosters);
  }

  el.btnToggleGodmode.addEventListener('click', () => toggleBooster('godmode'));
  el.btnToggleNoclip.addEventListener('click', () => toggleBooster('noclip'));
  el.btnToggleGoldencores.addEventListener('click', () => toggleBooster('goldencores'));
  el.btnToggleInfiammo.addEventListener('click', () => toggleBooster('infiammo'));
  el.btnToggleInvis.addEventListener('click', () => toggleBooster('invis'));
  el.btnSelfHeal.addEventListener('click', () => postNui('toggleBooster', { booster: 'selfheal' }));
  el.btnSelfRevive.addEventListener('click', () => postNui('toggleBooster', { booster: 'selfrevive' }));
  el.btnSpawnHorse.addEventListener('click', () => postNui('toggleBooster', { booster: 'spawnhorse' }));

  // --- Seção 3: Tesouro & Cargas ---
  el.btnGiveMoney.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão no registro primeiro!', true);
    const amount = Number(el.inputMoneyAmount.value || 0);
    if (amount <= 0) return showToast('Digite uma quantia válida!', true);
    postNui('databaseAction', { type: 'giveCurrency', currencyType: 0, amount, targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Concedido $ ${amount.toFixed(2)} para ${state.selectedPlayer.PlayerName}`);
  });

  el.btnGiveGold.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão no registro primeiro!', true);
    const amount = Number(el.inputMoneyAmount.value || 0);
    if (amount <= 0) return showToast('Digite uma quantia válida!', true);
    postNui('databaseAction', { type: 'giveCurrency', currencyType: 1, amount, targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Concedido ${amount.toFixed(2)} de ouro para ${state.selectedPlayer.PlayerName}`);
  });

  el.btnGiveItem.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão no registro primeiro!', true);
    const item = el.inputItemName.value.trim();
    const qty = Number(el.inputItemQty.value || 1);
    if (!item) return showToast('Digite o código do item!', true);
    postNui('databaseAction', { type: 'giveItem', item, qty, targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Item ${item} (${qty}x) concedido a ${state.selectedPlayer.PlayerName}`);
  });

  el.btnGiveWeapon.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão no registro primeiro!', true);
    const weapon = el.inputWeaponHash.value.trim();
    if (!weapon) return showToast('Digite o código da arma!', true);
    postNui('databaseAction', { type: 'giveWeapon', weapon, targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Arma ${weapon} concedida a ${state.selectedPlayer.PlayerName}`);
  });

  el.btnGiveHorse.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão no registro primeiro!', true);
    const model = el.inputMountModel.value.trim();
    if (!model) return showToast('Digite o modelo do cavalo!', true);
    postNui('databaseAction', { type: 'giveMount', mountType: 'horse', model, targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Montaria ${model} cadastrada no estábulo de ${state.selectedPlayer.PlayerName}`);
  });

  el.btnGiveWagon.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão no registro primeiro!', true);
    const model = el.inputMountModel.value.trim();
    if (!model) return showToast('Digite o modelo da carroça!', true);
    postNui('databaseAction', { type: 'giveMount', mountType: 'wagon', model, targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Carroça ${model} cadastrada para ${state.selectedPlayer.PlayerName}`);
  });

  el.btnClearInventory.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão primeiro!', true);
    postNui('databaseAction', { type: 'clearInventory', targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Bolsa de ${state.selectedPlayer.PlayerName} esvaziada!`, true);
  });

  el.btnClearMoney.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão primeiro!', true);
    postNui('databaseAction', { type: 'clearCurrency', currencyType: 'money', targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Dinheiro de ${state.selectedPlayer.PlayerName} zerado!`, true);
  });

  el.btnClearGold.addEventListener('click', () => {
    if (!state.selectedPlayer) return showToast('Selecione um cidadão primeiro!', true);
    postNui('databaseAction', { type: 'clearCurrency', currencyType: 'gold', targetId: state.selectedPlayer.serverId, targetName: state.selectedPlayer.PlayerName });
    showToast(`Ouro de ${state.selectedPlayer.PlayerName} zerado!`, true);
  });

  // --- Seção 4: Rotas & Expedições ---
  el.btnTpMarker.addEventListener('click', () => {
    postNui('teleportAction', { type: 'tpm' });
  });

  el.btnToggleAutotpm.addEventListener('click', () => {
    state.boosters.autotpm = !state.boosters.autotpm;
    el.btnToggleAutotpm.textContent = state.boosters.autotpm ? 'Desligar Auto-TPM' : 'Ligar Auto-TPM';
    el.btnToggleAutotpm.classList.toggle('active', state.boosters.autotpm);
    postNui('teleportAction', { type: 'autotpm' });
  });

  el.btnAdminGoback.addEventListener('click', () => {
    postNui('teleportAction', { type: 'goback' });
  });

  el.btnTpGuarma.addEventListener('click', () => {
    postNui('teleportAction', { type: 'guarma' });
  });

  el.btnTpCustomCoords.addEventListener('click', () => {
    const coords = el.inputCustomCoords.value.trim();
    if (!coords) return showToast('Insira coordenadas válidas!', true);
    postNui('teleportAction', { type: 'customCoords', coords });
  });

  el.btnSendAnnounce.addEventListener('click', () => {
    const message = el.inputAnnounceText.value.trim();
    if (!message) return showToast('Insira o texto do comunicado!', true);
    postNui('teleportAction', { type: 'announce', message });
    el.inputAnnounceText.value = '';
    showToast('Telegrama Oficial transmitido ao condado!');
  });

  // --- Seção 5: DevTools & Medição ---
  el.btnCopyVector3.addEventListener('click', () => postNui('devtoolsAction', { type: 'copyVector3' }));
  el.btnCopyVector4.addEventListener('click', () => postNui('devtoolsAction', { type: 'copyVector4' }));
  el.btnCopyHeading.addEventListener('click', () => postNui('devtoolsAction', { type: 'copyHeading' }));
  el.btnGetInterior.addEventListener('click', () => postNui('devtoolsAction', { type: 'interiorId' }));

  el.btnToggleDevlaser.addEventListener('click', () => {
    toggleBooster('devlaser');
  });

  el.btnSpawnPed.addEventListener('click', () => {
    const model = el.inputSpawnPedName.value.trim();
    if (!model) return showToast('Insira o código do Ped!', true);
    postNui('devtoolsAction', { type: 'spawnPed', model });
  });

  // --- Listener Principal de Mensagens do CitizenFX ---
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    // Compatibilidade com clipboard legado
    if (data.string !== undefined) {
      copyToClipboard(data.string);
      return;
    }

    switch (data.action) {
      case 'open':
        openApp(data);
        break;
      case 'close':
        closeApp();
        break;
      case 'updatePlayers':
        updatePlayersData(data.players);
        break;
      case 'updateBoosters':
        updateBoostersState(data.boosters);
        break;
      case 'toast':
        showToast(data.message, data.isAlert);
        break;
      default:
        break;
    }
  });

  // Helper simples para escapar strings HTML
  function escapeHtml(string) {
    return String(string)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

})();
