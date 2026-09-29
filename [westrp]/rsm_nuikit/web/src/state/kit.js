import { computed, inject, provide, shallowRef, watch } from "vue";
import { MODULES, PREVIEW_HOST_CATALOG, PREVIEW_HOST_PAGE, PREVIEW_PLACEMENT, THEME_PRESETS } from "./mock.js";
import { initialSlots } from "./inventory.js";
import { applyTheme } from "../lib/theme.js";
import { HOST_OWNED, HOST_PIECES, TOAST_MAX } from "../components/hud/dims.js";

const KIT = Symbol("rsm-kit");

const clone = (o) => JSON.parse(JSON.stringify(o));
const pct = (v, fallback) => (typeof v === "number" && Number.isFinite(v) ? Math.min(100, Math.max(0, v)) : fallback);
let toastSeq = 0;

const CORE_KEYS = ["health", "stamina", "deadeye"];
const FULL_CORES = { health: { ring: 100, core: 100 }, stamina: { ring: 100, core: 100 }, deadeye: { ring: 100, core: 100 } };
const MODULE_META = Object.fromEntries(MODULES.map((m) => [m.id, m]));

// O que o estúdio publica para o servidor. Sempre montado do mesmo jeito,
// então comparar o JSON de dois snapshots diz se há mudança não publicada.
// A posição das peças do HUD não entra: ela vem do config.lua ou do /hudlayout.
export function studioSnapshot(s) {
  return {
    theme: {
      preset: s.theme.preset,
      accent: s.theme.accent,
      surface: s.theme.surface,
      text: s.theme.text,
      surfaceAlpha: s.theme.surfaceAlpha,
    },
    modules: s.modules.map((m) => ({ id: m.id, active: m.active })),
    hud: { coreStyle: s.hud.coreStyle },
    hostHud: {
      preset: s.hostHud.preset,
      meterStyle: s.hostHud.meterStyle,
      values: s.hostHud.values,
      disabled: [...s.hostHud.disabled].sort(),
    },
  };
}

const HOST_HUD_DEFAULTS = { preset: "frontier", meterStyle: "ring", values: false, disabled: [] };

// Onde cada peça do HUD fica: a posição do jogador no /hudlayout (com o rsm_hud
// rodando) por cima do padrão do config.lua.
// Tema e padrões do rsm_hud no formato que ele recebe (rsm_hud:client:theme e
// :policy). O rascunho do estúdio vai assim para a prévia; publicado, pelo client.
export const hostTheme = (s) => ({
  accent: s.theme.accent,
  surface: s.theme.surface,
  text: s.theme.text,
  surfaceAlpha: s.theme.surfaceAlpha,
});
export const hostPolicy = (s) => ({
  preset: s.hostHud.preset,
  meterStyle: s.hostHud.meterStyle,
  values: s.hostHud.values,
  disabled: [...s.hostHud.disabled],
});
export const hostCan = (s, feature) => !!(s.host.present && s.host.catalog?.features?.includes(feature));

// Quanto dura o Preview Placement (exemplos no lugar de cada peça)
export const PREVIEW_MS = 8000;

export function placementOf(s, id) {
  const base = s.placement.defaults[id] ?? { x: 0.5, y: 0.5, scale: 1 };
  const player = s.host.present && HOST_PIECES.includes(id) ? s.placement.host[id] : null;
  return { opacity: 1, visible: true, ...base, ...(player ?? {}) };
}

// Módulos: a lista e o travado vêm do servidor (config.lua); nome e descrição
// são da interface. Um id que a interface não conhece aparece com o próprio id.
function mergeModules(current, incoming) {
  const byId = Object.fromEntries(current.map((m) => [m.id, m]));
  return incoming.map((s) => {
    const base = byId[s.id] ?? MODULE_META[s.id] ?? { id: s.id, name: s.id, group: "Custom", desc: "" };
    const locked = s.locked ?? base.locked ?? false;
    return { ...base, active: locked || s.active === true, locked };
  });
}

function initialState() {
  const theme = THEME_PRESETS[0];
  const state = {
    section: "colors",
    // no jogo o estúdio começa fechado (só o HUD aparece); no preview, aberto
    studio: { open: !window.rsmNui.isGame },
    // defaults: config.lua (no preview, os mesmos valores de exemplo);
    // host: o que o rsm_hud mandou do layout do jogador
    placement: { defaults: clone(PREVIEW_PLACEMENT), host: {} },
    // rsm_hud: rodando? com o /hudlayout aberto? visível (/hud, pausa)? e o
    // catálogo dele (elementos, predefinições, estilos). O preview simula o HUD
    // rodando, com uma amostra do catálogo, porque é assim que o servidor usa.
    host: {
      present: !window.rsmNui.isGame,
      name: "rsm_hud",
      editing: false,
      visible: true,
      catalog: window.rsmNui.isGame ? null : PREVIEW_HOST_CATALOG,
      // página do rsm_hud para o modo espelho (a prévia com o HUD de verdade)
      page: window.rsmNui.isGame ? null : PREVIEW_HOST_PAGE,
    },
    // padrões do rsm_hud publicados daqui: predefinição inicial, estilo dos
    // medidores, números nos medidores e elementos desligados para todos
    hostHud: { ...HOST_HUD_DEFAULTS, disabled: [] },
    theme: {
      preset: theme.id,
      role: "accent",
      accent: theme.accent,
      surface: theme.surface,
      text: theme.text,
      surfaceAlpha: theme.surfaceAlpha,
    },
    modules: MODULES.map((m) => ({ ...m })),
    inventory: { slots: initialSlots(), sortBy: "category" },
    // dados que os outros resources mandam para o HUD (null = não mostrar)
    // samples: exemplos no lugar de cada peça (botão Preview Placement)
    hud: { coreStyle: "ring", cores: null, money: null, clock: null, objective: null, help: null, hidden: false, samples: false },
    notifyDuration: 5200,
    toasts: [],
    dialog: null,
    dialogQueue: [],
  };
  state.published = studioSnapshot(state);
  return state;
}

// Função pura: recebe o estado e a ação, devolve um estado NOVO. Nada é
// alterado no lugar, então trocar a referência basta para a tela atualizar.
function reducer(state, action) {
  switch (action.type) {
    case "section":
      return { ...state, section: action.id };
    case "studio/set":
      return {
        ...state,
        studio: { ...state.studio, open: action.open },
        hud: action.open ? { ...state.hud, samples: false } : state.hud,
      };

    // ── configuração publicada (vinda do servidor, ou "descartar mudanças") ──
    case "config/apply": {
      const c = action.config || {};
      const next = { ...state };
      if (c.theme && c.theme.accent) {
        const { preset, accent, surface, text, surfaceAlpha } = c.theme;
        next.theme = { ...state.theme, preset: preset ?? "custom", accent, surface, text, surfaceAlpha };
      }
      if (Array.isArray(c.modules) && c.modules.length) next.modules = mergeModules(state.modules, c.modules);
      if (c.hud && c.hud.coreStyle) next.hud = { ...state.hud, coreStyle: c.hud.coreStyle };
      if (c.hostHud && typeof c.hostHud === "object") {
        next.hostHud = {
          preset: typeof c.hostHud.preset === "string" ? c.hostHud.preset : HOST_HUD_DEFAULTS.preset,
          meterStyle: typeof c.hostHud.meterStyle === "string" ? c.hostHud.meterStyle : HOST_HUD_DEFAULTS.meterStyle,
          values: c.hostHud.values === true,
          // uma lista vazia pode chegar do Lua como objeto
          disabled: Array.isArray(c.hostHud.disabled) ? c.hostHud.disabled.filter((id) => typeof id === "string") : [],
        };
      }
      if (typeof c.notifyDuration === "number") next.notifyDuration = c.notifyDuration;
      next.published = studioSnapshot(next);
      return next;
    }

    // ── posição das peças (config.lua e rsm_hud) ──
    case "placement/defaults":
      return { ...state, placement: { ...state.placement, defaults: { ...state.placement.defaults, ...action.defaults } } };
    case "host/present":
      return {
        ...state,
        host: action.present
          ? { ...state.host, present: true, name: action.name || state.host.name, page: action.page ?? state.host.page }
          : { ...state.host, present: false, editing: false, visible: true },
      };
    case "host/layout":
      return {
        ...state,
        placement: { ...state.placement, host: action.widgets },
        host: { ...state.host, editing: action.editing },
      };
    case "host/visible":
      return { ...state, host: { ...state.host, visible: action.visible } };
    case "host/catalog":
      return { ...state, host: { ...state.host, catalog: action.catalog } };

    // ── padrões do rsm_hud ──
    case "hostHud/set":
      return { ...state, hostHud: { ...state.hostHud, ...action.patch } };
    case "hostHud/toggle": {
      const d = state.hostHud.disabled;
      const disabled = d.includes(action.id) ? d.filter((id) => id !== action.id) : [...d, action.id];
      return { ...state, hostHud: { ...state.hostHud, disabled } };
    }

    // ── theme ──
    case "theme/set":
      return { ...state, theme: { ...state.theme, ...action.patch, preset: action.keepPreset ? state.theme.preset : "custom" } };
    case "theme/role":
      return { ...state, theme: { ...state.theme, role: action.role } };
    case "theme/preset": {
      const p = THEME_PRESETS.find((t) => t.id === action.id);
      return {
        ...state,
        theme: { ...state.theme, preset: p.id, accent: p.accent, surface: p.surface, text: p.text, surfaceAlpha: p.surfaceAlpha },
      };
    }

    // ── modules (active / inactive) ──
    case "module/toggle":
      return {
        ...state,
        modules: state.modules.map((m) => (m.id === action.id && !m.locked ? { ...m, active: !m.active } : m)),
      };
    case "module/all":
      return {
        ...state,
        modules: state.modules.map((m) => (m.locked ? m : { ...m, active: action.active })),
      };

    // ── inventário (as regras ficam em inventory.js; aqui só o resultado) ──
    case "inventory/slots":
      return { ...state, inventory: { ...state.inventory, slots: action.slots } };
    case "inventory/sortBy":
      return { ...state, inventory: { ...state.inventory, sortBy: action.by } };

    // ── HUD ──
    case "hud/coreStyle":
      return { ...state, hud: { ...state.hud, coreStyle: action.style } };
    case "hud/cores": {
      // atualização parcial; nil/null esconde os cores
      if (action.cores == null) return { ...state, hud: { ...state.hud, cores: null } };
      const cur = state.hud.cores ?? FULL_CORES;
      const cores = { ...cur };
      for (const k of CORE_KEYS) {
        const v = action.cores[k];
        if (v && typeof v === "object") cores[k] = { ring: pct(v.ring, cur[k].ring), core: pct(v.core, cur[k].core) };
      }
      return { ...state, hud: { ...state.hud, cores } };
    }
    case "hud/set":
      return { ...state, hud: { ...state.hud, ...action.patch } };

    // ── feedback ──
    case "toast/push":
      return { ...state, toasts: [...state.toasts, action.toast].slice(-TOAST_MAX) };
    case "toast/dismiss":
      return { ...state, toasts: state.toasts.filter((t) => t.id !== action.id) };
    // Confirms chegam em fila: um na tela por vez, os outros esperam a vez
    case "dialog/open":
      return state.dialog
        ? { ...state, dialogQueue: [...state.dialogQueue, action.dialog] }
        : { ...state, dialog: action.dialog };
    case "dialog/close":
      return { ...state, dialog: state.dialogQueue[0] ?? null, dialogQueue: state.dialogQueue.slice(1) };

    default:
      return state;
  }
}

// Cria a loja do kit e a entrega para toda a árvore (chamar uma vez, no App).
// O estado fica num shallowRef imutável: cada dispatch troca a referência e
// tudo o que leu `kit.state` durante a renderização atualiza sozinho.
export function provideKit() {
  const store = shallowRef(initialState());
  const dispatch = (action) => {
    store.value = reducer(store.value, action);
  };

  // Color Manager → variáveis CSS no <html>
  watch(() => store.value.theme, (theme) => applyTheme(theme), { immediate: true });

  // Cores e dinheiro são do rsm_hud enquanto ele roda: o kit não desenha os dele
  const hostOwns = (id) => store.value.host.present && HOST_OWNED.includes(id);

  const isActive = (id) => {
    if (hostOwns(id)) return false;
    const m = store.value.modules.find((x) => x.id === id);
    return m ? m.active : true;
  };

  // Notifications inativo = nenhum toast, venha de onde vier.
  // opts.force só anuncia a troca do próprio módulo; opts.duration em ms.
  const notify = (type, title, body, opts = {}) => {
    if (!opts.force && !isActive("toasts")) return;
    toastSeq += 1;
    dispatch({ type: "toast/push", toast: { id: `t${toastSeq}`, type, title, body, duration: opts.duration } });
  };

  // ESC / Close: esconde o estúdio. No jogo, o cliente solta o foco.
  const closePanel = () => {
    dispatch({ type: "studio/set", open: false });
    if (window.rsmNui.isGame) window.rsmNui.post("studio:close");
  };

  // Responde o Confirm da tela. Os que vieram de outro resource (requestId)
  // voltam para ele pelo cliente; os de demonstração só mostram o resultado.
  const answerDialog = (accepted) => {
    const d = store.value.dialog;
    if (!d) return;
    if (d.requestId) {
      if (window.rsmNui.isGame) window.rsmNui.post("confirm:result", { id: d.requestId, accepted });
      else notify("info", accepted ? "Confirmed" : "Declined", "In game this answer goes back to the resource that asked.");
    } else if (accepted && d.result) {
      notify(d.result.type, d.result.title, d.result.body);
    }
    dispatch({ type: "dialog/close" });
  };

  // Publicar: no jogo vai para o servidor, que valida, salva e manda para todos.
  const publish = () => {
    const s = store.value;
    const snap = studioSnapshot(s);
    if (window.rsmNui.isGame) {
      window.rsmNui.post("studio:publish", snap);
    } else {
      dispatch({ type: "config/apply", config: { ...snap, modules: s.modules } });
      notify("success", "Published (Preview)", "In game this goes to the server, is saved, and reaches every player.");
    }
  };

  const discard = () => dispatch({ type: "config/apply", config: store.value.published });

  // Fecha o estúdio e mostra um exemplo de cada peça no lugar dela por alguns
  // segundos, junto com o rsm_hud de verdade: no jogo ele mesmo mostra os
  // exemplos dele, com o tema e os padrões ainda não publicados; no preview do
  // navegador, a interface dele aparece no modo espelho (App.vue).
  let sampleTimer = 0;
  const previewPlacement = () => {
    const s = store.value;
    clearTimeout(sampleTimer);
    dispatch({ type: "hud/set", patch: { samples: true } });
    closePanel();
    if (window.rsmNui.isGame && hostCan(s, "preview")) {
      window.rsmNui.post("host:preview", { ms: PREVIEW_MS, theme: hostTheme(s), policy: hostPolicy(s) });
    }
    sampleTimer = setTimeout(() => dispatch({ type: "hud/set", patch: { samples: false } }), PREVIEW_MS);
  };

  const dirty = computed(() => JSON.stringify(studioSnapshot(store.value)) !== JSON.stringify(store.value.published));

  // `state` e `dirty` são getters: leia sempre `kit.state.x` (nunca
  // desestruture `state`), senão a leitura perde a reatividade.
  const kit = {
    get state() {
      return store.value;
    },
    get dirty() {
      return dirty.value;
    },
    dispatch,
    isActive,
    hostOwns,
    notify,
    closePanel,
    answerDialog,
    publish,
    discard,
    previewPlacement,
  };
  provide(KIT, kit);
  return kit;
}

export function useKit() {
  const kit = inject(KIT, null);
  if (!kit) throw new Error("useKit must be called below the component that ran provideKit()");
  return kit;
}
