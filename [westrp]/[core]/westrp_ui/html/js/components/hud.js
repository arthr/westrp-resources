/**
 * WestRP UI Engine — Player Status HUD Component
 * Target: Chromium CEF (RedM / Standalone Browser)
 * Standards: Modern Web Guidance, High-Performance SVG Rendering
 */

(function () {
  'use strict';

  // Constante de circunferência para r = 18.5 (2 * PI * 18.5)
  const CIRCUMFERENCE = 116.24;

  // Limiares para pulso de alerta crítico
  const CRITICAL_THRESHOLDS = {
    health: 25.0,
    stamina: 20.0,
    hunger: 15.0,
    thirst: 15.0,
    mountHealth: 25.0,
    mountStamina: 20.0
  };

  class HudComponent {
    constructor() {
      this.container = null;
      this.rings = {};
      this.tempBadge = null;
      this.tempValue = null;
      this.voiceDots = [];
      this.mountCluster = null;

      this.isVisible = true;
      this.isCinematic = false;
      this.isMenuOpen = false;

      // Inicializa quando o DOM estiver pronto
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => this.init());
      } else {
        this.init();
      }
    }

    init() {
      this.container = document.getElementById('player-hud-container');
      if (!this.container) return;

      // Cache de elementos de preenchimento dos anéis
      this.rings = {
        health: {
          item: document.getElementById('hud-item-health'),
          fill: document.getElementById('hud-fill-health')
        },
        stamina: {
          item: document.getElementById('hud-item-stamina'),
          fill: document.getElementById('hud-fill-stamina')
        },
        hunger: {
          item: document.getElementById('hud-item-hunger'),
          fill: document.getElementById('hud-fill-hunger')
        },
        thirst: {
          item: document.getElementById('hud-item-thirst'),
          fill: document.getElementById('hud-fill-thirst')
        },
        voice: {
          item: document.getElementById('hud-item-voice'),
          fill: document.getElementById('hud-fill-voice')
        },
        mountHealth: {
          item: document.getElementById('hud-item-mount-health'),
          fill: document.getElementById('hud-fill-mount-health')
        },
        mountStamina: {
          item: document.getElementById('hud-item-mount-stamina'),
          fill: document.getElementById('hud-fill-mount-stamina')
        }
      };

      this.tempBadge = document.getElementById('hud-temp-badge');
      this.tempValue = document.getElementById('hud-temp-value');
      this.mountCluster = document.getElementById('hud-mount-cluster');

      this.voiceDots = [
        document.getElementById('hud-voice-dot-1'),
        document.getElementById('hud-voice-dot-2'),
        document.getElementById('hud-voice-dot-3')
      ];

      // Inicializa com 100%
      this.updateRing('health', 100.0);
      this.updateRing('stamina', 100.0);
      this.updateRing('hunger', 100.0);
      this.updateRing('thirst', 100.0);
      this.updateRing('mountHealth', 100.0);
      this.updateRing('mountStamina', 100.0);
    }

    /**
     * Calcula o stroke-dashoffset a partir da porcentagem (0 a 100)
     * @param {number} percentage
     * @returns {number}
     */
    calculateOffset(percentage) {
      const clamped = Math.max(0, Math.min(100, (typeof percentage === 'number' && !isNaN(percentage)) ? percentage : (Number(percentage) || 0)));
      return CIRCUMFERENCE - (clamped / 100) * CIRCUMFERENCE;
    }

    /**
     * Atualiza um anel específico com tratamento de pulso de alerta
     * @param {string} key
     * @param {number} value
     */
    updateRing(key, value) {
      const ring = this.rings[key];
      if (!ring || !ring.fill) return;

      const numVal = (typeof value === 'number' && !isNaN(value)) ? value : (Number(value) || 0);
      const offset = this.calculateOffset(numVal);
      ring.fill.style.strokeDashoffset = offset.toFixed(2);

      // Controle de pulso de alerta crítico
      const threshold = CRITICAL_THRESHOLDS[key];
      if (threshold !== undefined && ring.item) {
        if (numVal <= threshold) {
          ring.item.classList.add('hud-alert-pulse');
        } else {
          ring.item.classList.remove('hud-alert-pulse');
        }
      }
    }

    /**
     * Atualiza o estado completo da HUD a partir do payload recebido do client Lua
     * @param {Object} data
     */
    update(data) {
      if (!data) return;

      // 1. Visibilidade e Modos
      if (data.visible !== undefined) {
        this.setVisible(data.visible);
      }

      if (data.isCinematic !== undefined) {
        this.setCinematicMode(data.isCinematic);
      }

      if (data.isUIMenuOpen !== undefined) {
        this.setMenuOpen(data.isUIMenuOpen);
      }

      // 2. Vitals do Jogador
      if (data.health !== undefined) {
        this.updateRing('health', data.health);
      }
      if (data.stamina !== undefined) {
        this.updateRing('stamina', data.stamina);
      }
      if (data.hunger !== undefined) {
        this.updateRing('hunger', data.hunger);
      }
      if (data.thirst !== undefined) {
        this.updateRing('thirst', data.thirst);
      }

      // 3. Sistema de Voz
      if (data.voice) {
        this.updateVoice(data.voice);
      }

      // 4. Temperatura Ambiental
      if (data.temperature !== undefined) {
        this.updateTemperature(data.temperature, data.tempStatus);
      }

      // 5. Montaria (Cavalo)
      if (data.mount) {
        this.updateMount(data.mount);
      }
    }

    /**
     * Atualiza o status de voz e proximidade
     * @param {Object} voiceData
     */
    updateVoice(voiceData) {
      const isTalking = voiceData.isTalking === true;
      const level = Number(voiceData.level) || 2;
      const voiceItem = this.rings.voice ? this.rings.voice.item : null;

      if (voiceItem) {
        if (isTalking) {
          voiceItem.classList.add('is-talking');
        } else {
          voiceItem.classList.remove('is-talking');
        }
      }

      // Níveis de proximidade (1: Sussurro, 2: Normal, 3: Grito)
      this.voiceDots.forEach((dot, index) => {
        if (!dot) return;
        if (index < level) {
          dot.classList.add('is-active');
        } else {
          dot.classList.remove('is-active');
        }
      });
    }

    /**
     * Atualiza o badge dinâmico de temperatura
     * @param {number} temp
     * @param {string} status
     */
    updateTemperature(temp, status) {
      if (!this.tempBadge || !this.tempValue) return;

      const rounded = Math.round(Number(temp) || 0);
      this.tempValue.textContent = `${rounded}°C`;

      this.tempBadge.classList.remove('temp--freezing', 'temp--heat');
      if (status === 'freezing' || rounded < 2) {
        this.tempBadge.classList.add('temp--freezing');
      } else if (status === 'heat' || rounded > 36) {
        this.tempBadge.classList.add('temp--heat');
      }
    }

    /**
     * Atualiza o cluster contextual da montaria
     * @param {Object} mountData
     */
    updateMount(mountData) {
      const active = mountData.active === true;

      if (this.mountCluster) {
        if (active) {
          this.mountCluster.classList.add('is-mounted');
          if (mountData.health !== undefined) {
            this.updateRing('mountHealth', mountData.health);
          }
          if (mountData.stamina !== undefined) {
            this.updateRing('mountStamina', mountData.stamina);
          }
        } else {
          this.mountCluster.classList.remove('is-mounted');
        }
      }
    }

    /**
     * Define a visibilidade geral do HUD
     * @param {boolean} visible
     */
    setVisible(visible) {
      this.isVisible = visible === true;
      if (!this.container) return;
      if (this.isVisible) {
        this.container.classList.remove('is-hidden');
      } else {
        this.container.classList.add('is-hidden');
      }
    }

    /**
     * Define o modo cinemático
     * @param {boolean} active
     */
    setCinematicMode(active) {
      this.isCinematic = active === true;
      if (!this.container) return;
      if (this.isCinematic) {
        this.container.classList.add('is-cinematic');
      } else {
        this.container.classList.remove('is-cinematic');
      }
    }

    /**
     * Atenua a opacidade quando algum menu ou modal da UI estiver aberto
     * @param {boolean} isOpen
     */
    setMenuOpen(isOpen) {
      this.isMenuOpen = isOpen === true;
      if (!this.container) return;
      if (this.isMenuOpen) {
        this.container.classList.add('is-menu-open');
      } else {
        this.container.classList.remove('is-menu-open');
      }
    }
  }

  // Instancia e expõe globalmente para integração com app.js e sandbox
  window.uiPlayerHud = new HudComponent();
})();
