/**
 * HUD DOCK LATERAL - NATIVE ROCKSTAR STYLE (RDR2 / GTA V INTERACTION MENU)
 * 100% Keyboard-Driven | 100% Free Camera & Aim | Western Frontier 1899-1910
 * Pure ES6+, Zero External Frameworks, Web Audio Procedural Feedback
 */

(function () {
  'use strict';

  // --- Audio Procedural Ticks (Web Audio API) ---
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
      }
    } catch (e) {
      // Ignora silenciosamente se o navegador bloquear autoplay de áudio
    }
  }

  // --- Estado Global ---
  const state = {
    isOpen: false,
    staffRole: 'Staff',
    players: [],
    selectedPlayer: null,
    activeTabIndex: 0,
    selectedIndex: 0,
    navigationStack: [], // Para submenus hierárquicos (ex: Dossiê de Ações do Jogador)
    boosters: {
      godmode: false,
      noclip: false,
      goldencores: false,
      infiammo: false,
      invis: false,
      autotpm: false,
      devlaser: false
    }
  };

  // --- Definição das 5 Abas Principais ---
  const TABS = [
    { id: 'utilitarios', name: 'UTILITÁRIOS' },
    { id: 'cidadaos', name: 'CIDADÃOS' },
    { id: 'teleporte', name: 'TELEPORTE' },
    { id: 'patrimonio', name: 'PATRIMÔNIO' },
    { id: 'oficina', name: 'OFICINA' }
  ];

  // --- Elementos do DOM ---
  const el = {
    app: document.getElementById('admin-dock'),
    staffRole: document.getElementById('dock-staff-role'),
    itemCounter: document.getElementById('dock-item-counter'),
    tabIndexBadge: document.getElementById('dock-tab-index'),
    currentTabName: document.getElementById('current-tab-name'),
    btnTabPrev: document.getElementById('btn-tab-prev'),
    btnTabNext: document.getElementById('btn-tab-next'),
    breadcrumb: document.getElementById('dock-breadcrumb'),
    breadcrumbTitle: document.getElementById('dock-breadcrumb-title'),
    viewport: document.getElementById('dock-viewport'),
    infoText: document.getElementById('dock-info-text'),
    toastContainer: document.getElementById('toast-container')
  };

  // --- Utilitário de Comunicação NUI ---
  async function postNui(event, data = {}) {
    try {
      const res = await fetch(`https://vorp_admin/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
      });
      return await res.json();
    } catch (e) {
      return null;
    }
  }

  // --- Sistema de Notificações Toasts ---
  function showToast(message, isAlert = false) {
    if (!el.toastContainer) return;
    const toast = document.createElement('div');
    toast.className = isAlert ? 'toast-msg alert' : 'toast-msg';
    toast.textContent = message;
    el.toastContainer.appendChild(toast);
    setTimeout(() => {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 3200);
  }

  function copyToClipboard(str) {
    if (!str) return;
    const ta = document.createElement('textarea');
    ta.value = String(str);
    ta.style.position = 'fixed';
    ta.style.left = '-9999px';
    document.body.appendChild(ta);
    ta.select();
    try {
      document.execCommand('copy');
      showToast('Copiado para Área de Transferência: ' + str);
    } catch (e) {
      console.error(e);
    }
    document.body.removeChild(ta);
  }

  // --- Construtores de Itens para Cada Aba ---

  function getUtilitariosItems() {
    return [
      {
        label: 'Modo Deus (GodMode)',
        desc: 'Torna o operador imune a todos os tipos de dano e disparos.',
        type: 'toggle',
        key: 'godmode',
        action: () => toggleBoosterAction('godmode')
      },
      {
        label: 'Voo Livre (NoClip)',
        desc: 'Permite voar e atravessar qualquer estrutura territorial.',
        type: 'toggle',
        key: 'noclip',
        action: () => toggleBoosterAction('noclip')
      },
      {
        label: 'Núcleos de Ouro',
        desc: 'Fortifica os núcleos de vida, estamina e Dead Eye.',
        type: 'toggle',
        key: 'goldencores',
        action: () => toggleBoosterAction('goldencores')
      },
      {
        label: 'Munição Infinita',
        desc: 'Disparos sem necessidade de recarga de cartuchos.',
        type: 'toggle',
        key: 'infiammo',
        action: () => toggleBoosterAction('infiammo')
      },
      {
        label: 'Invisibilidade',
        desc: 'Oculta o operador de todos os jogadores na fronteira.',
        type: 'toggle',
        key: 'invis',
        action: () => toggleBoosterAction('invis')
      },
      {
        label: 'Mira Laser Dev',
        desc: 'Ativa raio laser para identificação e inspeção de entidades.',
        type: 'toggle',
        key: 'devlaser',
        action: () => {
          state.boosters.devlaser = !state.boosters.devlaser;
          postNui('devtoolsAction', { type: 'laser' });
          renderCurrentList();
        }
      },
      {
        label: 'Restaurar Vida & Estamina',
        desc: 'Cura imediatamente todas as enfermidades e ferimentos.',
        type: 'action',
        action: () => {
          postNui('toggleBooster', { booster: 'selfheal' });
          showToast('Vida e estamina restauradas.');
        }
      },
      {
        label: 'Reviver a Si Mesmo',
        desc: 'Retorna do estado incapacitado/morto instantaneamente.',
        type: 'action',
        action: () => {
          postNui('toggleBooster', { booster: 'selfrevive' });
          showToast('Auto-ressurreição executada.');
        }
      },
      {
        label: 'Ir ao Marcador (TPM)',
        desc: 'Teleporta imediatamente ao marcador definido no mapa.',
        type: 'action',
        action: () => {
          postNui('teleportAction', { type: 'tpm' });
          showToast('Teleportando ao marcador...');
        }
      },
      {
        label: 'Invocar Cavalo de Montaria',
        desc: 'Faz surgir um cavalo confiável para locomoção imediata.',
        type: 'action',
        action: () => {
          postNui('toggleBooster', { booster: 'spawnhorse' });
          showToast('Cavalo convocado.');
        }
      },
      {
        label: 'Invocar Carroça de Carga',
        desc: 'Gera uma carroça para transporte rápido de provisões.',
        type: 'action',
        action: () => {
          postNui('databaseAction', {
            type: 'giveMount',
            mountType: 'wagon',
            model: 'cart01',
            targetId: 0,
            targetName: 'Self'
          });
          showToast('Carroça invocada nas proximidades.');
        }
      }
    ];
  }

  function getCidadaosItems() {
    if (!state.players || state.players.length === 0) {
      return [
        {
          label: 'Nenhum cidadão na fronteira',
          desc: 'Aguardando sincronização ou jogadores conectados.',
          type: 'info',
          action: () => { }
        }
      ];
    }

    return state.players.map(p => {
      const isWl = (p.WLstatus === 'true' || p.WLstatus === '1' || p.WLstatus === true);
      const moneyStr = `$ ${Number(p.Money || 0).toFixed(0)}`;
      return {
        label: `#${p.serverId} - ${p.PlayerName || 'Desconhecido'}`,
        sublabel: `${p.Job || 'Desempregado'} | ${moneyStr}`,
        badge: isWl ? 'VERIF' : 'PEND',
        badgeClass: isWl ? 'verified' : 'wanted',
        desc: `ID Estático: ${p.staticID || 'N/A'} | Steam: ${p.name || 'N/A'} | Dinheiro: ${moneyStr}`,
        type: 'submenu',
        player: p,
        action: () => openPlayerSubmenu(p)
      };
    });
  }

  function getPlayerSubmenuItems(player) {
    if (!player) return [];
    const pId = player.serverId;
    const pName = player.PlayerName || 'Cidadão';
    const staticId = player.staticID;
    const steam = player.SteamId;

    return [
      {
        label: 'Ir Até o Cidadão (Goto)',
        desc: `Teleporta seu personagem imediatamente até ${pName}.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'goto', targetId: pId, targetName: pName });
          showToast(`Indo até ${pName}...`);
        }
      },
      {
        label: 'Trazer Cidadão (Bring)',
        desc: `Puxa ${pName} até as suas coordenadas atuais.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'bring', targetId: pId, targetName: pName });
          showToast(`Trazendo ${pName}...`);
        }
      },
      {
        label: 'Curar Cidadão (Heal)',
        desc: `Restaura a vida e os núcleos de ${pName}.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'heal', targetId: pId, targetName: pName });
          showToast(`Curando ${pName}...`);
        }
      },
      {
        label: 'Reviver Cidadão (Revive)',
        desc: `Ressuscita ${pName} do estado de morte.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'revive', targetId: pId, targetName: pName });
          showToast(`Revivendo ${pName}...`);
        }
      },
      {
        label: 'Congelar Movimento (Freeze)',
        desc: `Imobiliza totalmente o jogador no local atual.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'freeze', targetId: pId, targetName: pName });
          showToast(`Alternando congelamento de ${pName}.`);
        }
      },
      {
        label: 'Espectar Jogador (Spectate)',
        desc: `Fixa a câmera oculta para vigiar as ações de ${pName}.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'spectate', targetId: pId, targetName: pName });
          showToast(`Modo espectador acionado.`);
        }
      },
      {
        label: 'Devolver à Posição Anterior',
        desc: `Envia ${pName} de volta ao ponto antes do último teleporte.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'sendback', targetId: pId, targetName: pName });
          showToast(`Retornando ${pName} ao local prévio.`);
        }
      },
      {
        label: 'Forçar Respawn no Hospital',
        desc: `Envia o jogador para a clínica médica mais próxima.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'respawn', targetId: pId, targetName: pName });
          showToast(`Respawn forçado para ${pName}.`);
        }
      },
      {
        label: 'Alternar Whitelist (Acesso)',
        desc: `Concede ou revoga permissão de acesso ao condado.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'whitelist', targetId: pId, targetName: pName, steam, staticId });
          showToast(`Whitelist alternada para ${pName}.`);
        }
      },
      {
        label: 'Conceder $100 Dólares',
        desc: `Deposita $100 na carteira de ${pName}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 0, amount: 100, targetId: pId, targetName: pName });
          showToast(`Concedido $100 para ${pName}.`);
        }
      },
      {
        label: 'Conceder $500 Dólares',
        desc: `Deposita $500 na carteira de ${pName}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 0, amount: 500, targetId: pId, targetName: pName });
          showToast(`Concedido $500 para ${pName}.`);
        }
      },
      {
        label: 'Conceder 5 Ouro',
        desc: `Deposita 5 barras de ouro com ${pName}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 1, amount: 5, targetId: pId, targetName: pName });
          showToast(`Concedido 5 ouro para ${pName}.`);
        }
      },
      {
        label: 'Expulsar do Condado (Kick)',
        desc: `Desconecta o jogador da sessão imediatamente.`,
        type: 'danger',
        action: () => {
          postNui('triggerAction', { actionType: 'kick', targetId: pId, targetName: pName, reason: 'Expulso pelo Administrador' });
          showToast(`Expulsão aplicada a ${pName}.`, true);
          popSubmenu();
        }
      },
      {
        label: 'Mandado de Prisão 24h (Ban)',
        desc: `Bane temporariamente o cidadão por 24 horas.`,
        type: 'danger',
        action: () => {
          postNui('triggerAction', { actionType: 'ban', targetId: pId, targetName: pName, time: 24, reason: 'Banimento 24h' });
          showToast(`Mandado de prisão (24h) emitido para ${pName}.`, true);
          popSubmenu();
        }
      },
      {
        label: 'Confiscar Todo o Inventário',
        desc: `Esvazia completamente todos os itens da bolsa do cidadão.`,
        type: 'danger',
        action: () => {
          postNui('databaseAction', { type: 'clearInventory', targetId: pId, targetName: pName });
          showToast(`Inventário de ${pName} confiscado e zerado.`);
        }
      },
      {
        label: 'Zerar Dinheiro e Ouro',
        desc: `Zera tanto dólares quanto barras de ouro do jogador.`,
        type: 'danger',
        action: () => {
          postNui('databaseAction', { type: 'clearCurrency', currencyType: '0', targetId: pId, targetName: pName });
          postNui('databaseAction', { type: 'clearCurrency', currencyType: '1', targetId: pId, targetName: pName });
          showToast(`Patrimônio financeiro de ${pName} zerado.`);
        }
      },
      {
        label: 'Medida Disciplinar: Raio dos Céus',
        desc: `Atinge o cidadão com uma descarga elétrica de advertência.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'troll_lightning', targetId: pId, targetName: pName });
          showToast(`Relâmpago enviado sobre ${pName}.`);
        }
      },
      {
        label: 'Medida Disciplinar: Incêndio',
        desc: `Cria chamas ao redor do infrator.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'troll_fire', targetId: pId, targetName: pName });
          showToast(`Fogo aceso em ${pName}.`);
        }
      },
      {
        label: 'Medida Disciplinar: Queda das Nuvens',
        desc: `Teleporta o jogador para o céu para queda livre segura.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'troll_heaven', targetId: pId, targetName: pName });
          showToast(`Queda das nuvens iniciada.`);
        }
      },
      {
        label: 'Medida Disciplinar: Algemar',
        desc: `Coloca algemas de ferro no jogador.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'troll_handcuff', targetId: pId, targetName: pName });
          showToast(`Algemas aplicadas a ${pName}.`);
        }
      },
      {
        label: 'Medida Disciplinar: Desmaiar (Ragdoll)',
        desc: `Faz o personagem tropeçar e cair inconsciente no solo.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'troll_ragdoll', targetId: pId, targetName: pName });
          showToast(`Desmaio aplicado a ${pName}.`);
        }
      },
      {
        label: 'Medida Disciplinar: Esgotar Estamina',
        desc: `Zera a resistência física imediata do jogador.`,
        type: 'action',
        action: () => {
          postNui('triggerAction', { actionType: 'troll_stam', targetId: pId, targetName: pName });
          showToast(`Estamina de ${pName} drenada.`);
        }
      }
    ];
  }

  function getTeleporteItems() {
    const locations = [
      { name: 'Valentine', coords: '-180.5, 629.7, 114.1', desc: 'A próspera e barrenta cidade do gado em New Hanover.' },
      { name: 'Saint Denis', coords: '2508.8, -1306.9, 48.9', desc: 'A metrópole industrial e moderna de Lemoyne.' },
      { name: 'Blackwater', coords: '-813.6, -1325.2, 5.3', desc: 'A cidade portuária e comercial de West Elizabeth.' },
      { name: 'Rhodes', coords: '1293.4, -1300.9, 77.0', desc: 'Cidade de terra vermelha no sul de Lemoyne.' },
      { name: 'Strawberry', coords: '-1763.5, -384.3, 156.8', desc: 'Tranquilo refúgio montanhoso de West Elizabeth.' },
      { name: 'Annesburg', coords: '2940.6, 1318.5, 44.8', desc: 'Vila mineira de carvão em Roanoke Ridge.' },
      { name: 'Armadillo', coords: '-3623.7, -2600.3, -13.5', desc: 'Cidade assolada pelo calor árido de New Austin.' },
      { name: 'Tumbleweed', coords: '-5525.7, -2928.8, -1.9', desc: 'Último posto avançado de lei no extremo oeste.' },
      { name: 'Colter', coords: '-1364.5, 2397.9, 307.4', desc: 'Vila abandonada na neve rigorosa de Ambarino.' },
      { name: 'Reserva Indígena Wapiti', coords: '566.2, 2217.3, 238.9', desc: 'Terras sagradas e reserva nativa nas montanhas.' }
    ];

    const items = [
      {
        label: 'Ir ao Marcador (TPM)',
        desc: 'Teleporta imediatamente ao ponto marcado no mapa pelo operador.',
        type: 'action',
        action: () => {
          postNui('teleportAction', { type: 'tpm' });
          showToast('Teleportando ao marcador...');
        }
      },
      {
        label: 'Auto-TPM ao Marcar Mapa',
        desc: 'Teleporte automático instantâneo assim que fixar um waypoint.',
        type: 'toggle',
        key: 'autotpm',
        action: () => {
          state.boosters.autotpm = !state.boosters.autotpm;
          postNui('teleportAction', { type: 'autotpm' });
          renderCurrentList();
        }
      },
      {
        label: 'Retornar à Posição Anterior',
        desc: 'Desfaz o último teleporte retornando ao ponto de origem.',
        type: 'action',
        action: () => {
          postNui('teleportAction', { type: 'goback' });
          showToast('Retornando à posição anterior...');
        }
      },
      {
        label: 'Expedição a Guarma',
        desc: 'Transporta o personagem para a ilha tropical de Guarma.',
        type: 'action',
        action: () => {
          postNui('teleportAction', { type: 'guarma' });
          showToast('Viajando a Guarma...');
        }
      }
    ];

    locations.forEach(loc => {
      items.push({
        label: `Viajar para ${loc.name}`,
        desc: loc.desc,
        type: 'action',
        action: () => {
          postNui('teleportAction', { type: 'customCoords', coords: loc.coords });
          showToast(`Teleportando para ${loc.name}...`);
        }
      });
    });

    return items;
  }

  function getPatrimonioItems() {
    const isSelf = !state.selectedPlayer;
    const targetDisplay = state.selectedPlayer
      ? `${state.selectedPlayer.PlayerName} (#${state.selectedPlayer.serverId})`
      : (state.myPlayerName ? `${state.myPlayerName} (Você)` : 'Operador Atual (Você)');
    const targetId = state.selectedPlayer ? state.selectedPlayer.serverId : (state.myServerId || 0);
    const targetName = state.selectedPlayer ? state.selectedPlayer.PlayerName : (state.myPlayerName || 'Operador Atual');

    const items = [
      {
        label: `Alvo Selecionado: ${targetDisplay}`,
        desc: isSelf
          ? 'As transações de tesouraria serão creditadas diretamente no seu próprio inventário.'
          : `As transações de tesouraria serão creditadas no cidadão ${targetDisplay}.`,
        type: 'info',
        action: () => { }
      }
    ];

    if (!isSelf) {
      items.push({
        label: '↩ Focar em Mim Mesmo (Desmarcar)',
        desc: 'Limpa a seleção do cidadão externo para focar as operações em si mesmo.',
        type: 'action',
        action: () => {
          state.selectedPlayer = null;
          showToast('Alvo redefinido para o seu próprio personagem.');
          renderCurrentList();
        }
      });
    }

    items.push(
      {
        label: 'Conceder $100 Dólares',
        desc: `Adiciona $100 na posse de ${targetDisplay}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 0, amount: 100, targetId, targetName });
          showToast(`Concedido $100 para ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder $500 Dólares',
        desc: `Adiciona $500 na posse de ${targetDisplay}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 0, amount: 500, targetId, targetName });
          showToast(`Concedido $500 para ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder $1,000 Dólares',
        desc: `Adiciona $1,000 na posse de ${targetDisplay}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 0, amount: 1000, targetId, targetName });
          showToast(`Concedido $1,000 para ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder $5,000 Dólares',
        desc: `Adiciona $5,000 na posse de ${targetDisplay}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 0, amount: 5000, targetId, targetName });
          showToast(`Concedido $5,000 para ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder $10,000 Dólares',
        desc: `Adiciona $10,000 na posse de ${targetDisplay}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 0, amount: 10000, targetId, targetName });
          showToast(`Concedido $10,000 para ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder 1 Barra de Ouro',
        desc: `Adiciona 1 barra de ouro a ${targetDisplay}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 1, amount: 1, targetId, targetName });
          showToast(`Concedido 1 ouro para ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder 5 Barras de Ouro',
        desc: `Adiciona 5 barras de ouro a ${targetDisplay}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 1, amount: 5, targetId, targetName });
          showToast(`Concedido 5 ouro para ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder 10 Barras de Ouro',
        desc: `Adiciona 10 barras de ouro a ${targetDisplay}.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveCurrency', currencyType: 1, amount: 10, targetId, targetName });
          showToast(`Concedido 10 ouro para ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder Revólver Cattleman',
        desc: `Arma clássica de tambor padrão da fronteira.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveWeapon', weapon: 'WEAPON_REVOLVER_CATTLEMAN', targetId, targetName });
          showToast(`Revólver Cattleman concedido a ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder Rifle Lancaster Repeater',
        desc: `Rifle de repetição de alta precisão e cadência.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveWeapon', weapon: 'WEAPON_REPEATER_LANCASTER', targetId, targetName });
          showToast(`Lancaster Repeater concedido a ${targetDisplay}.`);
        }
      },
      {
        label: 'Conceder Shotgun Pump-Action',
        desc: `Escopeta de ação por bombeamento de alto impacto.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveWeapon', weapon: 'WEAPON_SHOTGUN_PUMP', targetId, targetName });
          showToast(`Shotgun Pump concedida a ${targetDisplay}.`);
        }
      },
      {
        label: 'Invocar Montaria de Trabalho',
        desc: `Faz surgir um cavalo forte para trabalho de campo.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveMount', mountType: 'horse', model: 'A_C_Horse_AmericanPaint_Overo', targetId, targetName });
          showToast(`Cavalo convocado.`);
        }
      },
      {
        label: 'Invocar Carroça de Suprimentos',
        desc: `Faz surgir uma carroça de carga média nas proximidades.`,
        type: 'action',
        action: () => {
          postNui('databaseAction', { type: 'giveMount', mountType: 'wagon', model: 'cart01', targetId, targetName });
          showToast(`Carroça gerada.`);
        }
      },
      {
        label: 'Confiscar Todo o Inventário',
        desc: `Apreende todos os itens e armas da posse de ${targetDisplay}.`,
        type: 'danger',
        action: () => {
          postNui('databaseAction', { type: 'clearInventory', targetId, targetName });
          showToast(`Inventário de ${targetDisplay} confiscado.`);
        }
      },
      {
        label: 'Zerar Carteira de Dólares',
        desc: `Recolhe todos os dólares na posse de ${targetDisplay}.`,
        type: 'danger',
        action: () => {
          postNui('databaseAction', { type: 'clearCurrency', currencyType: '0', targetId, targetName });
          showToast(`Dólares de ${targetDisplay} zerados.`);
        }
      },
      {
        label: 'Zerar Pepitas de Ouro',
        desc: `Recolhe todo o ouro armazenado por ${targetDisplay}.`,
        type: 'danger',
        action: () => {
          postNui('databaseAction', { type: 'clearCurrency', currencyType: '1', targetId, targetName });
          showToast(`Ouro de ${targetDisplay} zerado.`);
        }
      }
    );

    return items;
  }

  function getOficinaItems() {
    return [
      {
        label: 'Copiar Coordenadas [Vector3]',
        desc: 'Copia X, Y, Z da posição atual para a área de transferência.',
        type: 'action',
        action: () => postNui('devtoolsAction', { type: 'copyVector3' })
      },
      {
        label: 'Copiar Coordenadas + Direção [Vector4]',
        desc: 'Copia X, Y, Z e Ângulo (Heading) no formato vector4.',
        type: 'action',
        action: () => postNui('devtoolsAction', { type: 'copyVector4' })
      },
      {
        label: 'Copiar Apenas Heading (Ângulo)',
        desc: 'Copia o ângulo de visão atual do operador.',
        type: 'action',
        action: () => postNui('devtoolsAction', { type: 'copyHeading' })
      },
      {
        label: 'Inspecionar ID do Interior Atual',
        desc: 'Identifica o código hash do interior ou imóvel atual.',
        type: 'action',
        action: () => postNui('devtoolsAction', { type: 'interiorId' })
      },
      {
        label: 'Mira Laser Dev',
        desc: 'Linha de raio laser para inspecionar entidades no cenário.',
        type: 'toggle',
        key: 'devlaser',
        action: () => {
          state.boosters.devlaser = !state.boosters.devlaser;
          postNui('devtoolsAction', { type: 'laser' });
          renderCurrentList();
        }
      },
      {
        label: 'Invocar Ped: Fazendeiro de Valentine',
        desc: 'Gera um NPC civil fazendeiro (A_M_M_ValFarmer_01).',
        type: 'action',
        action: () => {
          postNui('devtoolsAction', { type: 'spawnPed', model: 'A_M_M_ValFarmer_01' });
          showToast('Fazendeiro invocado.');
        }
      },
      {
        label: 'Invocar Ped: Xerife Local',
        desc: 'Gera a autoridade da cidade (CS_ValSheriff).',
        type: 'action',
        action: () => {
          postNui('devtoolsAction', { type: 'spawnPed', model: 'CS_ValSheriff' });
          showToast('Xerife convocado.');
        }
      },
      {
        label: 'Invocar Ped: Fora da Lei (Bandito)',
        desc: 'Gera um pistoleiro foragido (G_M_M_UniBanditos_01).',
        type: 'action',
        action: () => {
          postNui('devtoolsAction', { type: 'spawnPed', model: 'G_M_M_UniBanditos_01' });
          showToast('Bandito gerado.');
        }
      }
    ];
  }

  // --- Recuperação dos Itens da Camada Ativa ---
  function getCurrentItems() {
    if (state.navigationStack.length > 0) {
      const currentSub = state.navigationStack[state.navigationStack.length - 1];
      return currentSub.items;
    }

    const currentTab = TABS[state.activeTabIndex];
    switch (currentTab.id) {
      case 'utilitarios':
        return getUtilitariosItems();
      case 'cidadaos':
        return getCidadaosItems();
      case 'teleporte':
        return getTeleporteItems();
      case 'patrimonio':
        return getPatrimonioItems();
      case 'oficina':
        return getOficinaItems();
      default:
        return [];
    }
  }

  // --- Submenus (Hierarquia / Pilha de Navegação) ---
  function openPlayerSubmenu(player) {
    playUiTick('confirm');
    state.selectedPlayer = player;
    const items = getPlayerSubmenuItems(player);

    state.navigationStack.push({
      title: `#${player.serverId} - ${player.PlayerName || 'Cidadão'}`,
      previousIndex: state.selectedIndex,
      items
    });

    state.selectedIndex = 0;
    renderCurrentList();
  }

  function popSubmenu() {
    if (state.navigationStack.length > 0) {
      playUiTick('back');
      const popped = state.navigationStack.pop();
      state.selectedIndex = popped.previousIndex || 0;
      renderCurrentList();
      return true;
    }
    return false;
  }

  // --- Renderização da Lista no Viewport ---
  function renderCurrentList() {
    const items = getCurrentItems();
    el.viewport.innerHTML = '';

    // Atualiza cabeçalho de abas ou breadcrumb
    if (state.navigationStack.length > 0) {
      const currentSub = state.navigationStack[state.navigationStack.length - 1];
      el.breadcrumb.style.display = 'flex';
      el.breadcrumbTitle.textContent = currentSub.title;
      el.tabIndexBadge.textContent = 'SUBMENU';
      el.currentTabName.textContent = 'AÇÕES';
      el.btnTabPrev.style.visibility = 'hidden';
      el.btnTabNext.style.visibility = 'hidden';
    } else {
      el.breadcrumb.style.display = 'none';
      const curTab = TABS[state.activeTabIndex];
      el.tabIndexBadge.textContent = `ABA ${state.activeTabIndex + 1} / ${TABS.length}`;
      el.currentTabName.textContent = curTab.name;
      el.btnTabPrev.style.visibility = 'visible';
      el.btnTabNext.style.visibility = 'visible';
    }

    if (!items || items.length === 0) {
      const empty = document.createElement('div');
      empty.className = 'dock-empty-msg';
      empty.textContent = 'Nenhum item disponível neste registro.';
      el.viewport.appendChild(empty);
      el.itemCounter.textContent = '0 / 0';
      el.infoText.textContent = '';
      return;
    }

    // Garante que selectedIndex esteja dentro dos limites
    if (state.selectedIndex >= items.length) {
      state.selectedIndex = items.length - 1;
    }
    if (state.selectedIndex < 0) {
      state.selectedIndex = 0;
    }

    items.forEach((item, idx) => {
      const row = document.createElement('div');
      row.className = 'dock-item';
      if (item.type === 'danger') row.classList.add('danger');
      if (idx === state.selectedIndex) row.classList.add('selected');

      const mainCol = document.createElement('div');
      mainCol.className = 'dock-item-main';

      const label = document.createElement('span');
      label.className = 'dock-item-label';
      label.textContent = item.label;
      mainCol.appendChild(label);

      if (item.sublabel) {
        const sub = document.createElement('span');
        sub.className = 'dock-item-sublabel';
        sub.textContent = item.sublabel;
        mainCol.appendChild(sub);
      }

      row.appendChild(mainCol);

      const rightCol = document.createElement('div');
      rightCol.className = 'dock-item-right';

      if (item.type === 'toggle') {
        const isOn = Boolean(state.boosters[item.key]);
        const pill = document.createElement('span');
        pill.className = isOn ? 'status-pill on' : 'status-pill off';
        pill.textContent = isOn ? 'LIGADO' : 'DESLIGADO';
        rightCol.appendChild(pill);
      } else if (item.type === 'submenu') {
        if (item.badge) {
          const badge = document.createElement('span');
          badge.className = `status-pill ${item.badgeClass || ''}`;
          badge.textContent = item.badge;
          rightCol.appendChild(badge);
        }
        const arrow = document.createElement('span');
        arrow.className = 'submenu-arrow';
        arrow.textContent = '▸';
        rightCol.appendChild(arrow);
      } else if (item.type === 'danger') {
        const pill = document.createElement('span');
        pill.className = 'status-pill off';
        pill.style.color = '#ff8888';
        pill.textContent = 'EXECUTAR';
        rightCol.appendChild(pill);
      } else if (item.type === 'action') {
        const pill = document.createElement('span');
        pill.className = 'status-pill action';
        pill.textContent = '↵';
        rightCol.appendChild(pill);
      }

      row.appendChild(rightCol);

      // Clique com mouse também permite selecionar e acionar
      row.addEventListener('click', () => {
        state.selectedIndex = idx;
        updateSelectionHighlight();
        executeCurrentItem();
      });

      el.viewport.appendChild(row);
    });

    updateSelectionHighlight();
  }

  // --- Atualização de Destaque Sem Re-renderizar o DOM Inteiro ---
  function updateSelectionHighlight() {
    const items = getCurrentItems();
    const rows = el.viewport.querySelectorAll('.dock-item');

    rows.forEach((row, idx) => {
      row.classList.toggle('selected', idx === state.selectedIndex);
    });

    if (items.length > 0 && state.selectedIndex < items.length) {
      const cur = items[state.selectedIndex];
      el.itemCounter.textContent = `${state.selectedIndex + 1} / ${items.length}`;
      el.infoText.textContent = cur.desc || cur.label || '';

      const selectedEl = rows[state.selectedIndex];
      if (selectedEl) {
        selectedEl.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
      }
    } else {
      el.itemCounter.textContent = '0 / 0';
      el.infoText.textContent = '';
    }
  }

  // --- Execução da Ação do Item Selecionado ---
  function executeCurrentItem() {
    const items = getCurrentItems();
    if (!items || items.length === 0) return;
    const item = items[state.selectedIndex];
    if (!item) return;

    if (typeof item.action === 'function') {
      playUiTick(item.type === 'submenu' ? 'confirm' : 'confirm');
      item.action();
    }
  }

  // --- Alternância de Booster Genérico ---
  function toggleBoosterAction(boosterKey) {
    state.boosters[boosterKey] = !state.boosters[boosterKey];
    postNui('toggleBooster', { booster: boosterKey });
    renderCurrentList();
  }

  // --- Navegação por Teclado (Rockstar Interaction Menu Engine) ---
  window.addEventListener('keydown', (e) => {
    if (!state.isOpen) return;

    const items = getCurrentItems();
    const itemCount = items.length;

    switch (e.key) {
      case 'ArrowUp':
      case 'Up':
        e.preventDefault();
        if (itemCount === 0) return;
        playUiTick('nav');
        state.selectedIndex = (state.selectedIndex - 1 + itemCount) % itemCount;
        updateSelectionHighlight();
        break;

      case 'ArrowDown':
      case 'Down':
        e.preventDefault();
        if (itemCount === 0) return;
        playUiTick('nav');
        state.selectedIndex = (state.selectedIndex + 1) % itemCount;
        updateSelectionHighlight();
        break;

      case 'ArrowLeft':
      case 'Left':
        e.preventDefault();
        // Apenas troca de aba se estiver no nível raiz (fora de submenus)
        if (state.navigationStack.length === 0) {
          playUiTick('nav');
          state.activeTabIndex = (state.activeTabIndex - 1 + TABS.length) % TABS.length;
          state.selectedIndex = 0;
          renderCurrentList();
        }
        break;

      case 'ArrowRight':
      case 'Right':
        e.preventDefault();
        if (state.navigationStack.length === 0) {
          playUiTick('nav');
          state.activeTabIndex = (state.activeTabIndex + 1) % TABS.length;
          state.selectedIndex = 0;
          renderCurrentList();
        }
        break;

      case 'Enter':
      case ' ':
        e.preventDefault();
        executeCurrentItem();
        break;

      case 'Backspace':
        e.preventDefault();
        if (!popSubmenu()) {
          // Se estiver na raiz, fecha o dock
          closeDock();
        }
        break;

      case 'Escape':
        e.preventDefault();
        closeDock();
        break;

      default:
        break;
    }
  });

  // --- Cliques nas Setas da Aba ---
  el.btnTabPrev.addEventListener('click', () => {
    if (state.navigationStack.length === 0) {
      playUiTick('nav');
      state.activeTabIndex = (state.activeTabIndex - 1 + TABS.length) % TABS.length;
      state.selectedIndex = 0;
      renderCurrentList();
    }
  });

  el.btnTabNext.addEventListener('click', () => {
    if (state.navigationStack.length === 0) {
      playUiTick('nav');
      state.activeTabIndex = (state.activeTabIndex + 1) % TABS.length;
      state.selectedIndex = 0;
      renderCurrentList();
    }
  });

  // --- Abertura e Fechamento do Dock ---
  function openDock(data = {}) {
    state.isOpen = true;
    el.app.style.display = 'flex';

    if (data.myServerId) state.myServerId = data.myServerId;
    if (data.myPlayerName) state.myPlayerName = data.myPlayerName;

    if (data.staffRole) {
      state.staffRole = data.staffRole;
      if (el.staffRole) {
        el.staffRole.textContent = `COMANDO: ${String(data.staffRole).toUpperCase()}`;
      }
    }

    if (data.boosters) {
      Object.assign(state.boosters, data.boosters);
    }

    if (data.players) {
      updatePlayersData(data.players);
    }

    renderCurrentList();
  }

  function closeDock() {
    playUiTick('back');
    state.isOpen = false;
    el.app.style.display = 'none';
    state.navigationStack = [];
    postNui('closeMenu');
  }

  function updatePlayersData(playersList) {
    const raw = Array.isArray(playersList) ? playersList : Object.values(playersList || {});
    state.players = raw.filter(p => p && typeof p === 'object' && p.serverId != null);

    // Se estivermos vendo cidadãos, re-renderiza a lista
    if (TABS[state.activeTabIndex].id === 'cidadaos' && state.navigationStack.length === 0) {
      renderCurrentList();
    }
  }

  // --- Listener Principal do CitizenFX (NUI Message) ---
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.string !== undefined) {
      copyToClipboard(data.string);
      return;
    }

    switch (data.action) {
      case 'open':
      case 'openDock':
        openDock(data);
        break;
      case 'close':
      case 'closeDock':
        closeDock();
        break;
      case 'updatePlayers':
        updatePlayersData(data.players);
        break;
      case 'updateBoosters':
        if (data.boosters) {
          Object.assign(state.boosters, data.boosters);
          renderCurrentList();
        }
        break;
      case 'toast':
        showToast(data.message, data.isAlert);
        break;
      default:
        break;
    }
  });

})();
