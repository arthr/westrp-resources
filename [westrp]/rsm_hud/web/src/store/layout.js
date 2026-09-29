import { reactive } from "vue";

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
const defaults = () => clone(PRESETS.frontier.widgets);

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
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch {
    /* preview sandbox: in-memory only */
  }
}

// Saved data is merged over the defaults so a widget added later still gets a
// position, and anything malformed falls back instead of breaking the HUD.
function sanitize(widgets) {
  const base = defaults();
  if (!widgets || typeof widgets !== "object") return base;
  for (const id of Object.keys(base)) {
    const s = widgets[id];
    if (!s || typeof s !== "object") continue;
    base[id] = {
      x: clamp(Number(s.x) || 0, 0, 1),
      y: clamp(Number(s.y) || 0, 0, 1),
      scale: clamp(Number(s.scale) || 1, 0.5, 1.6),
      opacity: clamp(Number(s.opacity) || 1, 0.3, 1),
      visible: s.visible !== false,
    };
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
});

let snapshot = null;

const post = (name, data) => window.rsmNui && window.rsmNui.post(name, data);

export function openLayout() {
  if (layout.editing) return;
  snapshot = clone({ widgets: layout.widgets, prefs: layout.prefs, preset: layout.preset });
  layout.editing = true;
  layout.dirty = false;
  layout.selected = layout.selected || WIDGETS[0].id;
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
    layout.widgets = snapshot.widgets;
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
  closeLayout();
}

function touch() {
  layout.dirty = true;
  layout.preset = "custom";
}

export function applyPreset(name) {
  const p = PRESETS[name];
  if (!p) return;
  layout.widgets = clone(p.widgets);
  layout.preset = name;
  layout.dirty = true;
}

// Layout salvo por personagem, enviado pelo client quando o personagem carrega.
export function loadLayout(data) {
  if (!data || typeof data !== "object" || layout.editing) return;
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
  applyPreset("frontier");
}

export function resetWidget(id) {
  const base = PRESETS[layout.preset]?.widgets || PRESETS.frontier.widgets;
  layout.widgets[id] = clone(base[id]);
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

export function selectRelative(step) {
  const i = WIDGETS.findIndex((x) => x.id === layout.selected);
  const n = WIDGETS.length;
  layout.selected = WIDGETS[(((i < 0 ? 0 : i) + step) % n + n) % n].id;
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
