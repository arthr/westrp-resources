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
document.documentElement.style.setProperty("--rsm-backdrop", tex("img/backdrop.jpg"));

// Official RDR font faces, copied into web/public/fonts/ (ABS_BASE-safe).
{
  const faces = [
    ["RDR Lino", "fonts/RDRLino-Regular.woff2", 400],
    ["Hapna Slab", "fonts/HapnaSlabSerif-DemiBold.woff2", 600],
    ["RDR Catalogue", "fonts/RDRCatalogueBold-Bold.woff2", 700],
    ["Redemption", "fonts/Redemption.woff2", 400],
  ];
  const css = faces
    .map(([family, file, weight]) =>
      `@font-face{font-family:"${family}";src:url("${ABS_BASE}${file}") format("woff2");font-weight:${weight};font-style:normal;font-display:block;}`)
    .join("\n");
  const el = document.createElement("style");
  el.setAttribute("data-rsm", "fonts");
  el.textContent = css;
  document.head.appendChild(el);
}

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
