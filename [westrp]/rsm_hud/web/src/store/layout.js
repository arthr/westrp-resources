import { reactive, watch } from "vue";
import { t } from "../locale.js";
import { MIRROR } from "../mirror.js";

// Positions are anchor fractions: x = 0 sits flush left, x = 1 flush right,
// and any value in between keeps the element fully on screen at every
// resolution and scale (see HudWidget for the CSS that makes that true).
// Nomes e descrições ficam em locale.js, nas chaves "w.<id>" / "w.<id>.hint".
export const WIDGETS = [
  { id: "cores" },
  { id: "horse" },
  { id: "needs" },
  { id: "effects" },
  { id: "money" },
  { id: "clock" },
  { id: "location" },
  { id: "identity" },
  { id: "wanted" },
  { id: "weapon" },
  { id: "voice" },
];

// Estilos dos medidores (cores do jogador, do cavalo e necessidades).
export const METER_STYLES = ["ring", "half", "segmented", "bars-h", "bars-v", "numeric"];
const meterStyleOf = (v) => (METER_STYLES.includes(v) ? v : "ring");

const w = (x, y, scale = 1, visible = true, opacity = 1) => ({ x, y, scale, opacity, visible });

export const PRESETS = {
  frontier: {
    widgets: {
      identity: w(0.01, 0.025),
      location: w(0.5, 0.03),
      money: w(0.99, 0.025),
      clock: w(0.99, 0.16),
      wanted: w(0.99, 0.3),
      effects: w(0.2, 0.66),
      needs: w(0.2, 0.82),
      cores: w(0.2, 0.975),
      horse: w(0.37, 0.975),
      weapon: w(0.99, 0.84),
      voice: w(0.99, 0.975),
    },
  },
  compact: {
    widgets: {
      identity: w(0.01, 0.02, 0.85),
      location: w(0.01, 0.12, 0.85),
      money: w(0.99, 0.02, 0.85),
      clock: w(0.99, 0.13, 0.85),
      wanted: w(0.99, 0.25, 0.85),
      effects: w(0.5, 0.74, 0.85),
      needs: w(0.5, 0.86, 0.85),
      cores: w(0.43, 0.98, 0.9),
      horse: w(0.57, 0.98, 0.9),
      weapon: w(0.99, 0.98, 0.85),
      voice: w(0.01, 0.98, 0.85),
    },
  },
  minimal: {
    widgets: {
      identity: w(0.01, 0.025, 1, false),
      location: w(0.5, 0.03, 1, false),
      money: w(0.99, 0.025, 1, false),
      clock: w(0.99, 0.16, 1, false),
      wanted: w(0.99, 0.025),
      effects: w(0.2, 0.84, 1, false),
      needs: w(0.2, 0.84, 0.9),
      cores: w(0.2, 0.975),
      horse: w(0.37, 0.975),
      weapon: w(0.99, 0.975, 0.9, true, 0.85),
      voice: w(0.99, 0.84, 0.9, true, 0.85),
    },
  },
};

const STORAGE_KEY = "rsm_hud_layout_v1";
const clone = (v) => JSON.parse(JSON.stringify(v));
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

// Peças de outros resources (ex.: rsm_nuikit), registradas pelo client. O HUD
// não as desenha: no editor mostra a moldura com o tamanho real, e a posição
// vai para o layout do personagem e volta ao dono a cada mudança.
// id = "<resource>:<peça>", então nunca colide com os elementos do HUD.
export const external = reactive([]);
const EXTERNAL_ID = /^[\w.-]{1,48}:[\w-]{1,32}$/;
const MAX_EXTERNAL = 24; // posições guardadas de peças cujo dono não está rodando

// Valores fora da faixa (ou que nem são números) caem no padrão da peça.
const num = (v, fallback) => (typeof v === "number" && Number.isFinite(v) ? v : fallback);
function position(s, fb) {
  return {
    x: clamp(num(s.x, fb.x), 0, 1),
    y: clamp(num(s.y, fb.y), 0, 1),
    scale: clamp(num(s.scale, fb.scale), 0.5, 1.6),
    opacity: clamp(num(s.opacity, fb.opacity), 0.3, 1),
    visible: s.visible !== false,
  };
}

const externalDefaults = () => Object.fromEntries(external.map((s) => [s.id, { ...s.default }]));
// Padrões do servidor, publicados no estúdio do rsm_nuikit (quando ele roda).
// Valem para quem ainda não salvou layout e para o "Restaurar"; elementos
// desativados somem para todos, inclusive do editor. O resto é do jogador.
export const policy = reactive({ preset: "frontier", meterStyle: "ring", values: false, disabled: [] });
export const isDisabled = (id) => policy.disabled.includes(id);
const basePresetId = () => (PRESETS[policy.preset] ? policy.preset : "frontier");

const defaults = () => ({ ...clone(PRESETS[basePresetId()].widgets), ...externalDefaults() });

// localStorage throws in a sandboxed (null-origin) frame, so every access is
// guarded; the layout simply stays in memory there.
function readSaved() {
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}
function writeSaved(data) {
  if (MIRROR) return; // o espelho divide o armazenamento com o HUD de verdade
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch {
    /* preview sandbox: in-memory only */
  }
}

// Saved data is merged over the defaults so a widget added later still gets a
// position, and anything malformed falls back instead of breaking the HUD.
// Peças externas ficam mesmo se o dono ainda não registrou: o layout do
// personagem chega antes dele em muitos casos, e a posição não pode se perder.
function sanitize(widgets) {
  const base = defaults();
  if (!widgets || typeof widgets !== "object") return base;
  let extra = 0;
  for (const id of Object.keys(widgets)) {
    const s = widgets[id];
    if (!s || typeof s !== "object") continue;
    if (!(id in base)) {
      if (!EXTERNAL_ID.test(id) || extra >= MAX_EXTERNAL) continue;
      extra += 1;
    }
    base[id] = position(s, base[id] ?? { x: 0.5, y: 0.5, scale: 1, opacity: 1 });
  }
  return base;
}

const saved = readSaved();

export const layout = reactive({
  editing: false,
  selected: null,
  dragging: null,
  guides: { v: false, h: false },
  widgets: sanitize(saved && saved.widgets),
  prefs: {
    snap: saved?.prefs?.snap ?? true,
    values: saved?.prefs?.values ?? false,
    dock: saved?.prefs?.dock === "left" ? "left" : "right",
    meterStyle: meterStyleOf(saved?.prefs?.meterStyle),
  },
  preset: saved?.preset ?? "frontier",
  dirty: false,
  // true enquanto o personagem não tem layout salvo (segue os padrões do servidor)
  fresh: false,
});

let snapshot = null;

const post = (name, data) => window.rsmNui && window.rsmNui.post(name, data);

export function openLayout() {
  if (layout.editing) return;
  snapshot = clone({ widgets: layout.widgets, prefs: layout.prefs, preset: layout.preset });
  layout.editing = true;
  layout.dirty = false;
  if (!layout.selected || isDisabled(layout.selected)) layout.selected = allWidgetIds()[0] ?? null;
}

function closeLayout() {
  layout.editing = false;
  layout.dragging = null;
  layout.guides = { v: false, h: false };
  snapshot = null;
  post("layoutClose");
}

export function cancelLayout() {
  if (!layout.editing) return;
  if (snapshot) {
    // uma peça registrada com o editor aberto não está no snapshot: volta ao padrão dela
    layout.widgets = { ...externalDefaults(), ...snapshot.widgets };
    layout.prefs = snapshot.prefs;
    layout.preset = snapshot.preset;
  }
  closeLayout();
}

export function saveLayout() {
  if (!layout.editing) return;
  const data = { widgets: clone(layout.widgets), prefs: clone(layout.prefs), preset: layout.preset };
  writeSaved(data);
  post("layoutSave", data);
  layout.fresh = false;
  closeLayout();
}

function touch() {
  layout.dirty = true;
  layout.preset = "custom";
}

export function applyPreset(name) {
  const p = PRESETS[name];
  if (!p) return;
  // peças externas registradas voltam ao padrão delas; as de donos parados ficam como estão
  layout.widgets = { ...layout.widgets, ...clone(p.widgets), ...externalDefaults() };
  layout.preset = name;
  layout.dirty = true;
}

// Personagem sem layout salvo: tudo nos padrões do servidor.
function useServerDefaults() {
  layout.widgets = defaults();
  layout.prefs = { ...layout.prefs, meterStyle: meterStyleOf(policy.meterStyle), values: policy.values };
  layout.preset = basePresetId();
  layout.fresh = true;
}

// Layout salvo por personagem, enviado pelo client quando o personagem carrega
// (false = esse personagem ainda não salvou nenhum).
export function loadLayout(data) {
  if (layout.editing) return;
  if (!data || typeof data !== "object") {
    useServerDefaults();
    return;
  }
  layout.fresh = false;
  layout.widgets = sanitize(data.widgets);
  if (data.prefs && typeof data.prefs === "object") {
    layout.prefs = {
      snap: data.prefs.snap !== false,
      values: !!data.prefs.values,
      dock: data.prefs.dock === "left" ? "left" : "right",
      meterStyle: meterStyleOf(data.prefs.meterStyle),
    };
  }
  layout.preset = typeof data.preset === "string" ? data.preset : "custom";
  writeSaved({ widgets: layout.widgets, prefs: layout.prefs, preset: layout.preset });
}

export function setMeterStyle(style) {
  layout.prefs.meterStyle = meterStyleOf(style);
  layout.dirty = true;
}

export function cycleMeterStyle(step = 1) {
  const n = METER_STYLES.length;
  const i = METER_STYLES.indexOf(layout.prefs.meterStyle);
  setMeterStyle(METER_STYLES[(((i < 0 ? 0 : i) + step) % n + n) % n]);
}

export function resetAll() {
  applyPreset(basePresetId());
}

// Padrões do servidor recebidos pelo client. Ids desconhecidos são ignorados.
export function applyPolicy(p) {
  if (!p || typeof p !== "object") return;
  const known = new Set(WIDGETS.map((w) => w.id));
  policy.preset = PRESETS[p.preset] ? p.preset : "frontier";
  policy.meterStyle = meterStyleOf(p.meterStyle);
  policy.values = p.values === true;
  policy.disabled = Array.isArray(p.disabled) ? p.disabled.filter((id) => known.has(id)) : [];
  if (layout.fresh && !layout.editing) useServerDefaults();
  if (layout.selected && isDisabled(layout.selected)) layout.selected = allWidgetIds()[0] ?? null;
}

// O que este HUD tem, com os nomes já traduzidos. Vai para o client ao
// carregar, e de lá para quem quiser apresentar ou configurar o HUD.
export function catalog() {
  return {
    widgets: WIDGETS.map((w) => ({ id: w.id, label: t(`w.${w.id}`), hint: t(`w.${w.id}.hint`) })),
    presets: Object.keys(PRESETS).map((id) => ({ id, label: t(`preset.${id}`) })),
    meterStyles: METER_STYLES.map((id) => ({ id, label: t(`style.${id}`) })),
    // o que este HUD aceita de fora: tema (hud:theme), prévia com exemplos
    // (hud:preview) e o espelho (?mirror=1) para mostrar o HUD de verdade
    features: ["theme", "preview", "mirror"],
  };
}

export function resetWidget(id) {
  const ext = external.find((s) => s.id === id);
  if (ext) {
    layout.widgets[id] = { ...ext.default };
  } else {
    const base = PRESETS[layout.preset]?.widgets || PRESETS[basePresetId()].widgets;
    layout.widgets[id] = clone(base[id]);
  }
  touch();
}

export function setWidget(id, patch) {
  const cur = layout.widgets[id];
  if (!cur) return;
  if ("x" in patch) cur.x = clamp(patch.x, 0, 1);
  if ("y" in patch) cur.y = clamp(patch.y, 0, 1);
  if ("scale" in patch) cur.scale = clamp(Math.round(patch.scale * 100) / 100, 0.5, 1.6);
  if ("opacity" in patch) cur.opacity = clamp(Math.round(patch.opacity * 100) / 100, 0.3, 1);
  if ("visible" in patch) cur.visible = !!patch.visible;
  touch();
}

// Elementos do HUD primeiro, depois as peças de outros resources.
export const allWidgetIds = () => [
  ...WIDGETS.map((w) => w.id).filter((id) => !isDisabled(id)),
  ...external.map((s) => s.id),
];
export const externalSpec = (id) => external.find((s) => s.id === id) ?? null;
export const widgetLabel = (id) => externalSpec(id)?.label ?? t(`w.${id}`);
export const widgetHint = (id) => {
  const s = externalSpec(id);
  return s ? s.hint || s.owner : t(`w.${id}.hint`);
};

export function selectRelative(step) {
  const ids = allWidgetIds();
  const i = ids.indexOf(layout.selected);
  const n = ids.length;
  layout.selected = ids[(((i < 0 ? 0 : i) + step) % n + n) % n];
}

const GRID = 8;
const CENTER_SNAP = 12;

// Screen-space placement → anchor fraction. `L`/`T` are the element's desired
// visual left/top edge, `W`/`H` its visual (scaled) size.
export function placeWidget(id, L, T, W, H) {
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  let left = clamp(L, 0, Math.max(0, vw - W));
  let top = clamp(T, 0, Math.max(0, vh - H));
  let v = false;
  let h = false;
  if (layout.prefs.snap) {
    if (Math.abs(left + W / 2 - vw / 2) < CENTER_SNAP) {
      left = vw / 2 - W / 2;
      v = true;
    } else {
      left = Math.round(left / GRID) * GRID;
    }
    if (Math.abs(top + H / 2 - vh / 2) < CENTER_SNAP) {
      top = vh / 2 - H / 2;
      h = true;
    } else {
      top = Math.round(top / GRID) * GRID;
    }
    left = clamp(left, 0, Math.max(0, vw - W));
    top = clamp(top, 0, Math.max(0, vh - H));
  }
  layout.guides = { v, h };
  setWidget(id, {
    x: vw - W > 0 ? left / (vw - W) : 0,
    y: vh - H > 0 ? top / (vh - H) : 0,
  });
}

export function widgetRect(id) {
  const el = document.querySelector(`[data-widget="${id}"]`);
  return el ? el.getBoundingClientRect() : null;
}

export function nudgeWidget(id, dx, dy) {
  const r = widgetRect(id);
  if (!r) return;
  const snap = layout.prefs.snap;
  layout.prefs.snap = false; // arrow keys move by exact pixels
  placeWidget(id, r.left + dx, r.top + dy, r.width, r.height);
  layout.prefs.snap = snap;
  layout.guides = { v: false, h: false };
}

export function centerWidget(id, axis) {
  if (axis === "x") setWidget(id, { x: 0.5 });
  else setWidget(id, { y: 0.5 });
}

// ── peças de outros resources ───────────────────────────────────────────────

function cleanSpec(s) {
  if (!s || typeof s !== "object" || typeof s.id !== "string" || !EXTERNAL_ID.test(s.id)) return null;
  const width = num(s.width, 0);
  const height = num(s.height, 0);
  if (width < 8 || width > 1920 || height < 8 || height > 1080) return null;
  const d = s.default && typeof s.default === "object" ? s.default : {};
  return {
    id: s.id,
    owner: String(s.owner || s.id.split(":")[0]).slice(0, 48),
    label: String(s.label || s.id).slice(0, 40),
    hint: s.hint ? String(s.hint).slice(0, 80) : "",
    width,
    height,
    default: position(d, { x: 0.5, y: 0.5, scale: 1, opacity: 1 }),
  };
}

// Lista completa enviada pelo client (substitui a anterior). Peça nova sem
// posição salva começa no padrão que o dono mandou.
export function registerExternal(list) {
  const seen = new Set();
  const specs = (Array.isArray(list) ? list : [])
    .map(cleanSpec)
    .filter((s) => s && !seen.has(s.id) && seen.add(s.id))
    .slice(0, MAX_EXTERNAL);
  external.splice(0, external.length, ...specs);
  for (const s of specs) {
    if (!layout.widgets[s.id]) layout.widgets[s.id] = { ...s.default };
  }
  if (layout.selected && !allWidgetIds().includes(layout.selected)) layout.selected = WIDGETS[0].id;
}

// Posição das peças externas → client do HUD → resource dono. Um arraste gera
// dezenas de mudanças por segundo; elas saem agrupadas a cada ~30 ms.
function externalPayload() {
  const widgets = {};
  for (const s of external) {
    const w = layout.widgets[s.id];
    if (w) widgets[s.id] = { x: w.x, y: w.y, scale: w.scale, opacity: w.opacity, visible: w.visible };
  }
  return { widgets, editing: layout.editing };
}

let sendTimer = 0;
let pendingPayload = null;
watch(externalPayload, (payload) => {
  if (!external.length) return;
  pendingPayload = payload;
  if (sendTimer) return;
  sendTimer = setTimeout(() => {
    sendTimer = 0;
    post("layoutExternal", pendingPayload);
  }, 30);
});
