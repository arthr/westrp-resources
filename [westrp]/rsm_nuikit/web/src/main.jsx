import { createApp } from "vue";
import App from "./App.vue";
import "./styles.css";

// ── STUDIO-MANAGED: asset base-path bridge, do NOT remove ──────────────────
// Every public asset (texture, backdrop, font, item art) MUST be resolved to an
// ABSOLUTE url through ABS_BASE below, then exposed as a CSS custom property.
// WHY absolute: a RELATIVE url() (e.g. "./tex/x.png") stored in a CSS variable
// does NOT resolve once it is substituted via var() into mask-image /
// background, it renders BLANK in Chrome AND the in-game CEF, even though the
// exact same relative path works in a plain <img src> or an @font-face rule
// (the classic "fonts + item <img> load but textures/parchment stay empty"
// bug). Also never hardcode ROOT-ABSOLUTE "/tex/…" paths: they ignore the
// preview's per-session base and 404. ABS_BASE (BASE resolved against
// document.baseURI) is correct in EVERY context: the studio preview proxy, the
// exported dist (relative "./" base) and in-game (nui://). ADD a tex() /
// rsmAsset() line here for every asset you pull into web/public/.
const BASE = import.meta.env.BASE_URL;
const ABS_BASE = new URL(BASE, document.baseURI).href;
const tex = (p) => `url("${ABS_BASE}${p}")`;
// Item art shown AS-IS in <img src> (never masked): src={rsmAsset("tex/items/x.png")}.
// @font-face url() must also use ABS_BASE (it cannot read a CSS var).
const rsmAsset = (p) => ABS_BASE + p;
window.rsmAsset = rsmAsset;
const root = document.documentElement.style;
// Cinematic scene backdrop (the studio drops a fitting scene here).
root.setProperty("--rsm-backdrop", tex("img/backdrop.jpg"));
// RDR2 menu chrome (white-on-transparent, always used as a CSS mask):
// tex/chrome/<name>.png → --tex-<name-with-dashes>
[
  "selection_box_bg_1a", "selection_box_bg_1d", "menu_header_1a", "crafting_outline", "help_text_1c",
  "toast_notification_1a", "menu_bar", "divider_line", "vertical_divider_line", "list_item_h_line_wide",
  "hud_menu_4a", "hud_menu_5a", "translate_bg_1a", "selection_box_square", "tick_box", "tick",
  "swatch_bg_1a", "counter_bg_1a", "selection_arrow_left", "selection_arrow_right", "weapon_stats_bar",
  "crafting_highlight_tl", "crafting_highlight_tr", "crafting_highlight_bl", "crafting_highlight_br",
  "lock", "cross", "diamond", "star", "menu_icon_circle", "menu_icon_alert", "menu_icon_tick",
  "menu_icon_info_warning", "menu_icon_info_new", "menu_icon_info_lock", "menu_icon_invite_sent",
].forEach((n) => root.setProperty(`--tex-${n.replace(/_/g, "-")}`, tex(`tex/chrome/${n}.png`)));
// HUD art: core rings, core icons, prompt strip
[
  "core_health", "core_stamina", "core_deadeye", "ring_full", "ring_track", "prompt_bar",
].forEach((n) => root.setProperty(`--tex-${n.replace(/_/g, "-")}`, tex(`tex/hud/${n}.png`)));
// Official RDR font faces (@font-face needs the absolute base too)
const fontFaces = [
  ["RDR Lino", "fonts/RDRLino-Regular.woff2"],
  ["Hapna Slab", "fonts/HapnaSlabSerif-DemiBold.woff2"],
  ["Redemption", "fonts/Redemption.woff2"],
  ["RDR Catalogue", "fonts/RDRCatalogueBold-Bold.woff2"],
]
  .map(([family, p]) => `@font-face{font-family:"${family}";src:url("${ABS_BASE}${p}") format("woff2");font-display:block;}`)
  .join("");
const fontStyle = document.createElement("style");
fontStyle.textContent = fontFaces;
document.head.appendChild(fontStyle);

// NUI GATE, in-game the UI starts HIDDEN and only appears when the client
// sends SendNUIMessage({ action: "open" }); in the studio preview / a normal
// browser it shows immediately (env-browser detection). Wire client.lua to
// this: open → SetNuiFocus(true,true) + SendNUIMessage open; the UI closes
// via window.rsmNui.close() which posts the "close" NUI callback so the
// client can SetNuiFocus(false,false).
const IS_GAME =
  typeof window.invokeNative !== "undefined" ||
  /CitizenFX/i.test(navigator.userAgent);
if (IS_GAME) {
  // rsm-ingame: the CSS keeps the page TRANSPARENT in-game (game shows
  // through) and only paints the full backdrop while a panel is open
  // (rsm-open), so the resource can never black out the game on start.
  document.documentElement.classList.add("rsm-ingame");
  document.documentElement.style.visibility = "hidden";
  window.addEventListener("message", (e) => {
    const a = e && e.data && e.data.action;
    if (a === "open" || a === "show") {
      document.documentElement.style.visibility = "visible";
      document.documentElement.classList.add("rsm-open");
    }
    if (a === "close" || a === "hide") {
      document.documentElement.style.visibility = "hidden";
      document.documentElement.classList.remove("rsm-open");
    }
  });
}
window.rsmNui = {
  isGame: IS_GAME,
  post(name, data) {
    if (!IS_GAME) return Promise.resolve();
    const res =
      typeof GetParentResourceName === "function" ? GetParentResourceName() : "nui-resource";
    return fetch("https://" + res + "/" + name, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data || {}),
    }).catch(() => {});
  },
  close() {
    if (IS_GAME) {
      document.documentElement.style.visibility = "hidden";
      document.documentElement.classList.remove("rsm-open");
    }
    return window.rsmNui.post("close");
  },
};
// ── end STUDIO-MANAGED ──────────────────────────────────────────────────────

createApp(App).mount("#root");
