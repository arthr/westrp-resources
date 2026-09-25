/* ====================================================================
   WestRP Karma — Live Combat Telemetry HUD Script
   ==================================================================== */

const MAX_LOGS = 6;
let logCounter = 0;

const hudElement = document.getElementById('karma-hud');
const playerKarmaEl = document.getElementById('player-karma');
const playerTierEl = document.getElementById('player-tier');
const combatStateEl = document.getElementById('combat-state');
const statusDotEl = document.getElementById('hud-status-indicator');
const playerWeaponEl = document.getElementById('player-weapon');

const targetFsmBadgeEl = document.getElementById('target-fsm-badge');
const targetDetailsEl = document.getElementById('target-details');
const logsContainerEl = document.getElementById('logs-container');
const logCountEl = document.getElementById('log-count');

function padZero(n) {
  return n < 10 ? '0' + n : n;
}

function getFormattedTime() {
  const now = new Date();
  return `${padZero(now.getHours())}:${padZero(now.getMinutes())}:${padZero(now.getSeconds())}`;
}

// Notifica o cliente RedM que o script NUI está pronto para receber mensagens
function notifyNuiReady() {
  try {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'westrp_karma';
    fetch(`https://${resourceName}/nuiReady`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({})
    }).catch(() => {});
  } catch (e) {}
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', notifyNuiReady);
} else {
  notifyNuiReady();
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.action) return;

  switch (data.action) {
    case 'toggleHUD':
      if (data.visible) {
        hudElement.classList.remove('hidden');
      } else {
        hudElement.classList.add('hidden');
      }
      break;

    case 'updatePlayerStatus':
      if (data.karma !== undefined) {
        playerKarmaEl.textContent = (data.karma > 0 ? '+' : '') + data.karma;
        playerKarmaEl.className = 'stat-val ' + (data.karma > 0 ? 'positive' : data.karma < 0 ? 'negative' : 'neutral');
      }

      if (data.tierName) {
        playerTierEl.textContent = data.tierName;
      }

      if (data.combatState) {
        combatStateEl.textContent = data.combatState;
      }

      if (data.combatClass) {
        statusDotEl.className = 'status-dot ' + data.combatClass;
      }

      if (data.weaponLabel) {
        playerWeaponEl.textContent = data.weaponLabel;
      }
      break;

    case 'updateTarget':
      if (!data.hasTarget) {
        targetFsmBadgeEl.textContent = 'LIVRE';
        targetFsmBadgeEl.className = 'fsm-badge';
        targetDetailsEl.innerHTML = '<span class="target-none-hint">Nenhum Ped em combate direto ou mira próxima</span>';
      } else {
        targetFsmBadgeEl.textContent = data.fsmState || 'ACTIVE';
        const fsmClass = (data.fsmState || '').toLowerCase();
        let badgeStyle = 'active';
        if (fsmClass === 'knockout') badgeStyle = 'knockout';
        else if (fsmClass === 'kill' || fsmClass === 'dead') badgeStyle = 'kill';
        else if (fsmClass === 'engaged') badgeStyle = 'engaged';
        targetFsmBadgeEl.className = 'fsm-badge ' + badgeStyle;

        targetDetailsEl.innerHTML = `
          <div class="target-data-point">
            <span class="target-data-label">PED / ID</span>
            <span class="target-data-val">#${data.pedId} (${data.targetType || 'CIVILIAN'})</span>
          </div>
          <div class="target-data-point">
            <span class="target-data-label">DISTÂNCIA</span>
            <span class="target-data-val">${data.distance ? data.distance.toFixed(1) + 'm' : '—'}</span>
          </div>
          <div class="target-data-point">
            <span class="target-data-label">ESTADO FÍSICO</span>
            <span class="target-data-val">${data.isRagdoll ? 'Desacordado' : (data.isDead ? 'Morto' : 'Em pé')}</span>
          </div>
        `;
      }
      break;

    case 'addCombatLog':
      const emptyPlaceholder = logsContainerEl.querySelector('.log-empty-placeholder');
      if (emptyPlaceholder) {
        emptyPlaceholder.remove();
      }

      logCounter++;
      logCountEl.textContent = `${logCounter} evento${logCounter > 1 ? 's' : ''}`;

      const entry = document.createElement('div');
      entry.className = 'log-entry';

      let borderClass = 'var(--border-gold)';
      let badgeClass = data.badgeType || 'assault';
      let deltaClass = 'zero';

      if (data.delta < 0) deltaClass = 'neg';
      else if (data.delta > 0) deltaClass = 'pos';

      const timeStr = data.time || getFormattedTime();

      entry.innerHTML = `
        <div class="log-row-top">
          <div class="log-badge-wrapper">
            <span class="log-badge ${badgeClass}">${data.badgeLabel || 'AÇÃO'}</span>
            <span class="log-time">${timeStr}</span>
          </div>
          <span class="log-delta ${deltaClass}">${data.deltaFormatted || (data.delta ? data.delta + ' pts' : '—')}</span>
        </div>
        <div class="log-row-detail">${data.detail || ''}</div>
      `;

      logsContainerEl.insertBefore(entry, logsContainerEl.firstChild);

      // Limita a quantidade máxima de logs exibidos
      while (logsContainerEl.children.length > MAX_LOGS) {
        logsContainerEl.removeChild(logsContainerEl.lastChild);
      }
      break;

    default:
      break;
  }
});
