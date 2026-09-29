// ── STUDIO-MANAGED: asset base-path bridge + NUI gate, do NOT remove ────────
// Every public asset (texture, backdrop, font, item art) MUST resolve to an
// ABSOLUTE url through ABS_BASE. A RELATIVE url() stored in a CSS variable does
// NOT resolve once substituted via var() into mask-image / background: it
// renders blank in Chrome AND the in-game CEF. Root-absolute "/tex/…" paths are
// equally wrong: they ignore the preview's per-session base and 404. ABS_BASE
// is correct in every context — the studio preview proxy, the exported dist
// (relative "./" base) and in game (nui://).
const BASE = import.meta.env.BASE_URL;
const ABS_BASE = new URL(BASE, document.baseURI).href;
export const tex = (p) => `url("${ABS_BASE}${p}")`;
// Item art shown AS-IS in <img src> (never masked): src={rsmAsset("tex/items/x.png")}.
// @font-face url() must also use ABS_BASE (it cannot read a CSS var).
export const rsmAsset = (p) => ABS_BASE + p;
window.rsmAsset = rsmAsset;
const rootStyle = document.documentElement.style;
rootStyle.setProperty("--rsm-backdrop", tex("img/backdrop.jpg"));
// Arte de menu do RDR2 (branca sobre transparente, sempre usada como máscara),
// a mesma do rsm_nuikit: tex/<pasta>/<nome>.png → --tex-<nome-com-hifens>
[
  ["chrome", [
    "selection_box_bg_1a", "selection_box_bg_1d", "menu_header_1a", "crafting_outline", "help_text_1c",
    "toast_notification_1a", "menu_bar", "divider_line", "vertical_divider_line", "list_item_h_line_wide",
    "hud_menu_4a", "hud_menu_5a", "translate_bg_1a", "selection_box_square", "tick_box", "tick",
    "swatch_bg_1a", "counter_bg_1a", "selection_arrow_left", "selection_arrow_right", "weapon_stats_bar",
    "crafting_highlight_tl", "crafting_highlight_tr", "crafting_highlight_bl", "crafting_highlight_br",
    "lock", "cross", "diamond", "star", "menu_icon_circle", "menu_icon_alert", "menu_icon_tick",
    "menu_icon_info_warning", "menu_icon_info_new", "menu_icon_info_lock", "menu_icon_invite_sent",
  ]],
  ["hud", ["core_health", "core_stamina", "core_deadeye", "ring_full", "ring_track", "prompt_bar"]],
  ["icons", [
    "itemtype_horse", "itemtype_coach",
    "horse_health", "blip_horseshoe_0", "blip_horseshoe_4", "blip_stable", "blip_shop_horse",
  ]],
].forEach(([dir, names]) =>
  names.forEach((n) => rootStyle.setProperty(`--tex-${n.replace(/_/g, "-")}`, tex(`tex/${dir}/${n}.png`))),
);
// Fontes oficiais do RDR (o @font-face também precisa da base absoluta)
const fontStyle = document.createElement("style");
fontStyle.textContent = [
  ["RDR Lino", "fonts/RDRLino-Regular.woff2"],
  ["Hapna Slab", "fonts/HapnaSlabSerif-DemiBold.woff2"],
  ["Redemption", "fonts/Redemption.woff2"],
  ["RDR Catalogue", "fonts/RDRCatalogueBold-Bold.woff2"],
]
  .map(([family, p]) => `@font-face{font-family:"${family}";src:url("${ABS_BASE}${p}") format("woff2");font-display:block;}`)
  .join("");
document.head.appendChild(fontStyle);

// NUI GATE. In game the UI starts HIDDEN and only appears when the client sends
// SendNUIMessage({ action: "open" }); in the studio preview / a normal browser
// it shows immediately. Wire client.lua to this: open → SetNuiFocus(true,true)
// + SendNUIMessage open; the UI closes via window.rsmNui.close(), which posts
// the "close" NUI callback so the client can SetNuiFocus(false,false).
export const IS_GAME =
  typeof window.invokeNative !== "undefined" || /CitizenFX/i.test(navigator.userAgent);
if (IS_GAME) {
  // rsm-ingame keeps the page TRANSPARENT in game (the game shows through)
  // and only paints the full backdrop while a panel is open (rsm-open), so
  // the resource can never black out the game on start.
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
