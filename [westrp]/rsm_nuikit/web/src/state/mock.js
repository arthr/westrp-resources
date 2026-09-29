// Dados de exemplo e padrões da interface. No jogo, a lista de módulos (ids,
// ativo, travado) vem do config.lua pelo servidor e substitui a daqui; os
// nomes e descrições abaixo continuam sendo os que aparecem na tela.

export const SECTIONS = [
  { id: "colors", label: "Color Manager", hint: "Theme roles, presets and a custom mixer" },
  { id: "states", label: "Active / Inactive", hint: "Switch modules on or off, see every state" },
  { id: "controls", label: "Controls", hint: "Buttons, selectors, sliders, inputs, slots" },
  { id: "feedback", label: "Feedback", hint: "Notifications, dialogs, help text, progress" },
  { id: "hud", label: "HUD Pieces", hint: "rsm_hud defaults, placement, prompts" },
  { id: "service", label: "Service API", hint: "Exports other resources call" },
];

// Só para o preview: no jogo, a posição padrão de cada peça vem do
// Config.Layout (config.lua) e, com o rsm_hud rodando, do /hudlayout do jogador.
export const PREVIEW_PLACEMENT = {
  toasts: { x: 0.99, y: 0.58, scale: 1 },
  help: { x: 0.01, y: 0.25, scale: 1 },
  objective: { x: 0.5, y: 0.12, scale: 1 },
  cores: { x: 0.2, y: 0.975, scale: 1 },
  money: { x: 0.99, y: 0.025, scale: 1 },
};

// Só para o preview: amostra do catálogo que o rsm_hud informa no jogo (os
// nomes vêm em português porque são os mesmos do /hudlayout dele).
export const PREVIEW_HOST_CATALOG = {
  widgets: [
    { id: "cores", label: "Cores do Jogador", hint: "Vida · Vigor · Olho Morto" },
    { id: "horse", label: "Cores do Cavalo", hint: "Aparece quando montado" },
    { id: "needs", label: "Necessidades", hint: "Fome · Sede · Estresse · Higiene · Bebida" },
    { id: "effects", label: "Efeitos de Status", hint: "Frio, ferimentos, doenças" },
    { id: "money", label: "Dinheiro", hint: "Dólares e ouro" },
    { id: "clock", label: "Relógio e Clima", hint: "Hora, dia e temperatura" },
    { id: "location", label: "Localização", hint: "Cidade e região" },
    { id: "identity", label: "Identidade", hint: "ID, nome e emprego" },
    { id: "wanted", label: "Recompensa", hint: "Aparece quando procurado" },
    { id: "weapon", label: "Arma e Munição", hint: "Aparece com arma em mãos" },
    { id: "voice", label: "Voz", hint: "Alcance e fala" },
  ],
  presets: [
    { id: "frontier", label: "Fronteira" },
    { id: "compact", label: "Compacto" },
    { id: "minimal", label: "Mínimo" },
  ],
  meterStyles: ["ring", "half", "segmented", "bars-h", "bars-v", "numeric"].map((id) => ({ id, label: id })),
  features: ["theme", "preview", "mirror"],
};

// No preview do navegador, a interface compilada do rsm_hud servida pelo vite
// (web/tools/hud-mirror.js). No jogo é a página do próprio rsm_hud.
export const PREVIEW_HOST_PAGE = `${import.meta.env.BASE_URL}hud-mirror/index.html`;

// Nome de cada peça do HUD no estúdio
export const PIECE_NAMES = {
  toasts: "Notifications",
  help: "Help Text",
  objective: "Objective Line",
  cores: "Core Meters",
  money: "Money & Clock",
};

export const MODULES = [
  { id: "menus", name: "Menu Panels", group: "Menus", desc: "The docked interactive menu every other screen opens in.", active: true, locked: true },
  { id: "prompts", name: "Prompt Stack", group: "HUD", desc: "Hold-key prompts for doors, shops and world interaction.", active: true, locked: true },
  { id: "cores", name: "Core Meters", group: "HUD", desc: "Health, stamina and Dead Eye rings with inner cores.", active: true },
  { id: "toasts", name: "Notifications", group: "Feedback", desc: "Feed toasts with icon, title and timer bar.", active: true },
  { id: "help", name: "Help Text", group: "Feedback", desc: "Contextual tips with an optional keycap.", active: true },
  { id: "dialogs", name: "Confirm Dialogs", group: "Feedback", desc: "Two-choice dialogs other resources open with Confirm.", active: true, locked: true },
  { id: "money", name: "Money & Clock", group: "HUD", desc: "Wallet, gold bars and the in-world time.", active: false },
  { id: "objective", name: "Objective Line", group: "HUD", desc: "The current mission or job objective line.", active: false },
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
