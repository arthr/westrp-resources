// Dados de exemplo e padrões da interface. No jogo, a lista de módulos (ids,
// ativo, travado) vem do config.lua pelo servidor e substitui a daqui; os
// nomes e descrições abaixo continuam sendo os que aparecem na tela.

export const SECTIONS = [
  { id: "layout", label: "Layout Manager", hint: "Anchor, offset and scale every HUD piece" },
  { id: "colors", label: "Color Manager", hint: "Theme roles, presets and a custom mixer" },
  { id: "states", label: "Active / Inactive", hint: "Switch modules on or off, see every state" },
  { id: "controls", label: "Controls", hint: "Buttons, selectors, sliders, inputs, slots" },
  { id: "feedback", label: "Feedback", hint: "Notifications, dialogs, help text, progress" },
  { id: "hud", label: "HUD Pieces", hint: "Core meters and hold-key prompts" },
  { id: "service", label: "Service API", hint: "Exports other resources call" },
];

// 9-point anchors, row-major (top → bottom, left → right)
export const ANCHORS = ["tl", "tc", "tr", "ml", "mc", "mr", "bl", "bc", "br"];
export const ANCHOR_NAMES = {
  tl: "Top Left", tc: "Top Centre", tr: "Top Right",
  ml: "Middle Left", mc: "Centre", mr: "Middle Right",
  bl: "Bottom Left", bc: "Bottom Centre", br: "Bottom Right",
};

// HUD widgets share their id with the module registry, so switching a module
// inactive also removes it from the layout preview.
const w = (anchor, x = 0, y = 0, scale = 100) => ({ anchor, x, y, scale });

export const LAYOUT_PRESETS = {
  classic: {
    label: "Classic",
    safeZone: 4,
    widgets: {
      cores: w("bl"), prompts: w("br"), toasts: w("tl", 0, 12), help: w("tl"),
      money: w("tr"), objective: w("bc", 0, -2), menus: w("ml"),
    },
  },
  streamer: {
    label: "Streamer",
    safeZone: 6,
    widgets: {
      cores: w("tl", 0, 0, 90), prompts: w("bc"), toasts: w("ml"), help: w("bl"),
      money: w("tr", 0, 0, 90), objective: w("tc", 0, 2), menus: w("mr"),
    },
  },
  compact: {
    label: "Compact",
    safeZone: 2,
    widgets: {
      cores: w("bl", 0, 0, 80), prompts: w("br", 0, 0, 85), toasts: w("tr", 0, 12, 85),
      help: w("tl", 0, 0, 85), money: w("tr", 0, 0, 80), objective: w("bc", 0, 0, 85),
      menus: w("ml", 0, 0, 90),
    },
  },
  cinematic: {
    label: "Cinematic",
    safeZone: 8,
    widgets: {
      cores: w("bl", 0, 0, 90), prompts: w("br", 0, 0, 90), toasts: w("tc"),
      help: w("tl", 0, 0, 90), money: w("tr", 0, 0, 90), objective: w("bc", 0, -4, 90),
      menus: w("mc"),
    },
  },
};

export const WIDGET_META = {
  cores: { label: "Core Meters", size: "Health · Stamina · Dead Eye" },
  prompts: { label: "Prompt Stack", size: "Hold-key prompts" },
  toasts: { label: "Notifications", size: "Feed toasts" },
  help: { label: "Help Text", size: "Context tips" },
  money: { label: "Money & Clock", size: "Wallet, gold, time" },
  objective: { label: "Objective Line", size: "Mission text" },
  menus: { label: "Menu Panel", size: "Interactive menus" },
};

export const MODULES = [
  { id: "menus", name: "Menu Panels", group: "Menus", desc: "The docked interactive menu every other screen opens in.", active: true, locked: true },
  { id: "prompts", name: "Prompt Stack", group: "HUD", desc: "Hold-key prompts for doors, shops and world interaction.", active: true, locked: true },
  { id: "cores", name: "Core Meters", group: "HUD", desc: "Health, stamina and Dead Eye rings with inner cores.", active: true },
  { id: "toasts", name: "Notifications", group: "Feedback", desc: "Feed toasts with icon, title and timer bar.", active: true },
  { id: "help", name: "Help Text", group: "Feedback", desc: "Contextual tips pinned to the top-left.", active: true },
  { id: "dialogs", name: "Confirm Dialogs", group: "Feedback", desc: "Two-choice dialogs other resources open with Confirm.", active: true, locked: true },
  { id: "money", name: "Money & Clock", group: "HUD", desc: "Wallet, gold bars and the in-world time.", active: false },
  { id: "objective", name: "Objective Line", group: "HUD", desc: "Bottom-centre mission and job objective text.", active: false },
  { id: "slots", name: "Item Slots", group: "Menus", desc: "Drag-and-drop item slots: move, stack, split and auto-sort.", active: true },
  { id: "selectors", name: "Arrow Selectors", group: "Controls", desc: "Left/right option pickers, the classic RDR menu row.", active: true },
  { id: "sliders", name: "Sliders", group: "Controls", desc: "Bar sliders for volume, amounts and offsets.", active: true },
  { id: "inputs", name: "Text Inputs", group: "Controls", desc: "Name, amount and search fields.", active: false },
];

// Every preset stays inside the Blood & Black family (reds + neutrals).
// Any other colour is the server owner's own pick in the custom mixer.
export const THEME_PRESETS = [
  { id: "blood", name: "Blood & Black", accent: "#CB0101", surface: "#0D0D0D", text: "#F5F3EE", surfaceAlpha: 93 },
  { id: "oxblood", name: "Oxblood", accent: "#8E0A0A", surface: "#120F0D", text: "#E6DFD2", surfaceAlpha: 95 },
  { id: "scarlet", name: "Scarlet", accent: "#E01B1B", surface: "#0A0A0A", text: "#FFFFFF", surfaceAlpha: 90 },
  { id: "bone", name: "Bone & Ash", accent: "#D8D2C4", surface: "#161513", text: "#F5F3EE", surfaceAlpha: 94 },
  { id: "iron", name: "Iron", accent: "#7A7672", surface: "#0B0B0B", text: "#E8E6E1", surfaceAlpha: 92 },
];

export const ROLE_SWATCHES = {
  accent: ["#CB0101", "#A50101", "#8E0A0A", "#E01B1B", "#6E0101", "#D8D2C4", "#9A948A", "#7A7672"],
  surface: ["#010101", "#0D0D0D", "#141414", "#1A1714", "#201C18", "#2A2724"],
  text: ["#FFFFFF", "#F5F3EE", "#E6DFD2", "#C9C6C0", "#9A948A"],
};

export const ROLES = [
  { id: "accent", label: "Accent", desc: "Primary buttons, selections, fills and active states." },
  { id: "surface", label: "Surface", desc: "The fill behind every panel, card and dialog." },
  { id: "text", label: "Text", desc: "Labels and values. Dim and faint tones derive from it." },
];

export const TOAST_SAMPLES = {
  info: { title: "Telegram Received", body: "A letter waits for you at the Valentine post office." },
  success: { title: "Purchase Complete", body: "Bought 2 Coffee for $1.50 at the general store." },
  warning: { title: "Wanted in New Hanover", body: "A $25.00 bounty has been placed on your head." },
  error: { title: "Cannot Afford", body: "You need $12.00 more to buy the Schofield Revolver." },
};
