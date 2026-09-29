import { computed, inject, provide, shallowRef, watch } from "vue";
import { LAYOUT_PRESETS, MODULES, THEME_PRESETS } from "./mock.js";
import { initialSlots } from "./inventory.js";
import { applyTheme } from "../lib/theme.js";

const KIT = Symbol("rsm-kit");

const clone = (o) => JSON.parse(JSON.stringify(o));
const pct = (v, fallback) => (typeof v === "number" && Number.isFinite(v) ? Math.min(100, Math.max(0, v)) : fallback);
let toastSeq = 0;

const CORE_KEYS = ["health", "stamina", "deadeye"];
const FULL_CORES = { health: { ring: 100, core: 100 }, stamina: { ring: 100, core: 100 }, deadeye: { ring: 100, core: 100 } };
const MODULE_META = Object.fromEntries(MODULES.map((m) => [m.id, m]));

// O que o estúdio publica para o servidor. Sempre montado do mesmo jeito,
// então comparar o JSON de dois snapshots diz se há mudança não publicada.
export function studioSnapshot(s) {
  return {
    layout: { preset: s.layout.preset, safeZone: s.layout.safeZone, widgets: s.layout.widgets },
    theme: {
      preset: s.theme.preset,
      accent: s.theme.accent,
      surface: s.theme.surface,
      text: s.theme.text,
      surfaceAlpha: s.theme.surfaceAlpha,
    },
    modules: s.modules.map((m) => ({ id: m.id, active: m.active })),
    hud: { coreStyle: s.hud.coreStyle },
  };
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
  const preset = LAYOUT_PRESETS.classic;
  const theme = THEME_PRESETS[0];
  const state = {
    section: "layout",
    // no jogo o estúdio começa fechado (só o HUD aparece); no preview, aberto
    studio: { open: !window.rsmNui.isGame },
    layout: {
      preset: "classic",
      safeZone: preset.safeZone,
      snap: true,
      grid: true,
      selected: "cores",
      widgets: clone(preset.widgets),
    },
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
    hud: { coreStyle: "ring", cores: null, money: null, clock: null, objective: null, help: null, hidden: false },
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
      return { ...state, studio: { ...state.studio, open: action.open } };

    // ── configuração publicada (vinda do servidor, ou "descartar mudanças") ──
    case "config/apply": {
      const c = action.config || {};
      const next = { ...state };
      if (c.layout && c.layout.widgets) {
        const widgets = { ...state.layout.widgets };
        for (const id of Object.keys(widgets)) if (c.layout.widgets[id]) widgets[id] = { ...c.layout.widgets[id] };
        next.layout = { ...state.layout, preset: c.layout.preset ?? "custom", safeZone: c.layout.safeZone ?? state.layout.safeZone, widgets };
      }
      if (c.theme && c.theme.accent) {
        const { preset, accent, surface, text, surfaceAlpha } = c.theme;
        next.theme = { ...state.theme, preset: preset ?? "custom", accent, surface, text, surfaceAlpha };
      }
      if (Array.isArray(c.modules) && c.modules.length) next.modules = mergeModules(state.modules, c.modules);
      if (c.hud && c.hud.coreStyle) next.hud = { ...state.hud, coreStyle: c.hud.coreStyle };
      if (typeof c.notifyDuration === "number") next.notifyDuration = c.notifyDuration;
      next.published = studioSnapshot(next);
      return next;
    }

    // ── layout ──
    case "layout/select":
      return { ...state, layout: { ...state.layout, selected: action.id } };
    case "layout/widget": {
      const widgets = { ...state.layout.widgets, [action.id]: { ...state.layout.widgets[action.id], ...action.patch } };
      return { ...state, layout: { ...state.layout, widgets, preset: "custom" } };
    }
    case "layout/set":
      return { ...state, layout: { ...state.layout, ...action.patch } };
    case "layout/preset": {
      const p = LAYOUT_PRESETS[action.id];
      return {
        ...state,
        layout: { ...state.layout, preset: action.id, safeZone: p.safeZone, widgets: clone(p.widgets) },
      };
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
      return { ...state, toasts: [...state.toasts, action.toast].slice(-4) };
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

  const isActive = (id) => {
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
    notify,
    closePanel,
    answerDialog,
    publish,
    discard,
  };
  provide(KIT, kit);
  return kit;
}

export function useKit() {
  const kit = inject(KIT, null);
  if (!kit) throw new Error("useKit must be called below the component that ran provideKit()");
  return kit;
}
