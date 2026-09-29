import { onBeforeUnmount, onMounted } from "vue";
import { HOST_PIECES, WIDGET_DIMS } from "../components/hud/dims.js";
import { PREVIEW_PLACEMENT } from "../state/mock.js";

const KINDS = ["info", "success", "warning", "error"];
const PIECES = Object.keys(PREVIEW_PLACEMENT);
const str = (v, max) => (v == null ? "" : String(v).slice(0, max));
const num = (v) => (typeof v === "number" && Number.isFinite(v) ? v : null);
const within = (v, lo, hi, fallback) => (num(v) == null ? fallback : Math.min(hi, Math.max(lo, v)));

// Recursos extras que o rsm_hud pode anunciar: tema, prévia com exemplos, espelho
const HOST_FEATURES = ["theme", "preview", "mirror"];

// Catálogo do rsm_hud (elementos, predefinições, estilos dos medidores). Vem
// de outro resource: ids conferidos e textos limitados.
export function toCatalog(c) {
  if (!c || typeof c !== "object") return null;
  const list = (arr, max) =>
    (Array.isArray(arr) ? arr : [])
      .filter((x) => x && typeof x === "object" && typeof x.id === "string" && /^[\w-]{1,32}$/.test(x.id))
      .slice(0, max)
      .map((x) => ({ id: x.id, label: str(x.label || x.id, 40), hint: x.hint ? str(x.hint, 80) : "" }));
  const widgets = list(c.widgets, 32);
  const features = Array.isArray(c.features) ? HOST_FEATURES.filter((f) => c.features.includes(f)) : [];
  return widgets.length ? { widgets, presets: list(c.presets, 8), meterStyles: list(c.meterStyles, 8), features } : null;
}

// Posições que chegam de fora (config.lua ou rsm_hud), presas às mesmas
// faixas do /hudlayout. Só os ids pedidos passam.
function toPlaces(obj, ids) {
  const out = {};
  if (!obj || typeof obj !== "object") return out;
  for (const id of ids) {
    const p = obj[id];
    if (!p || typeof p !== "object") continue;
    out[id] = {
      x: within(p.x, 0, 1, 0.5),
      y: within(p.y, 0, 1, 0.5),
      scale: within(p.scale, 0.5, 1.6, 1),
      opacity: within(p.opacity, 0.3, 1, 1),
      visible: p.visible !== false,
    };
  }
  return out;
}

// Converte o `opts` de um Confirm vindo de outro resource no diálogo da tela.
// Tudo vira texto com tamanho limitado: o conteúdo vem de fora do kit.
function toDialog(d) {
  const o = d.dialog && typeof d.dialog === "object" ? d.dialog : {};
  const lines = Array.isArray(o.lines)
    ? o.lines.filter(Array.isArray).slice(0, 8).map(([label, value]) => [str(label, 60), str(value, 40)])
    : null;
  return {
    requestId: String(d.id),
    kicker: o.kicker ? str(o.kicker, 60) : null,
    title: str(o.title || "Are you sure?", 80),
    body: o.body ? str(o.body, 400) : null,
    lines: lines && lines.length ? lines : null,
    confirm: o.confirm ? str(o.confirm, 24) : "Confirm",
    cancel: o.cancel ? str(o.cancel, 24) : "Cancel",
    danger: o.danger === true,
  };
}

// Tudo o que o cliente manda para a interface passa por aqui. No jogo chega
// por SendNUIMessage; no preview, a seção Service API manda as mesmas
// mensagens com window.postMessage, então o caminho testado é o mesmo.
export function useNuiRouter(kit) {
  const { dispatch, notify } = kit;

  // O HUD fica sempre visível no jogo (página transparente, sem foco).
  // Só o estúdio e os Confirms pegam o mouse, e quem decide isso é o cliente.
  const showHud = () => {
    if (window.rsmNui.isGame) document.documentElement.style.visibility = "visible";
  };

  const onMessage = (e) => {
    const d = e.data;
    if (!d || typeof d.action !== "string") return;
    switch (d.action) {
      case "config":
        showHud();
        dispatch({ type: "config/apply", config: d.config });
        break;
      case "studio:open":
        showHud();
        dispatch({ type: "studio/set", open: true });
        break;
      case "studio:close":
        dispatch({ type: "studio/set", open: false });
        break;
      case "notify":
        notify(KINDS.includes(d.kind) ? d.kind : "info", str(d.title, 80), str(d.body, 240), {
          duration: num(d.duration) ?? undefined,
        });
        break;
      case "confirm":
        showHud();
        dispatch({ type: "dialog/open", dialog: toDialog(d) });
        break;
      case "cores":
        dispatch({ type: "hud/cores", cores: d.cores && typeof d.cores === "object" ? d.cores : null });
        break;
      case "money":
        dispatch({
          type: "hud/set",
          patch: { money: num(d.cash) != null ? { cash: num(d.cash), gold: num(d.gold) } : null },
        });
        break;
      case "clock":
        if (num(d.h) != null && num(d.m) != null) dispatch({ type: "hud/set", patch: { clock: { h: d.h, m: d.m } } });
        break;
      case "objective":
        dispatch({ type: "hud/set", patch: { objective: d.text ? str(d.text, 160) : null } });
        break;
      case "help":
        dispatch({ type: "hud/set", patch: { help: d.text ? { text: str(d.text, 240), key: d.key ? str(d.key, 6) : null } : null } });
        break;
      case "hud:hidden":
        dispatch({ type: "hud/set", patch: { hidden: d.hidden === true } });
        break;
      // posição padrão de cada peça (Config.Layout)
      case "placement":
        dispatch({ type: "placement/defaults", defaults: toPlaces(d.defaults, PIECES) });
        break;
      // rsm_hud subiu ou parou
      case "host":
        dispatch({
          type: "host/present",
          present: d.present === true,
          name: d.name ? str(d.name, 48) : null,
          // página do rsm_hud (https://cfx-nui-<resource>/...), aberta no modo espelho
          page: typeof d.page === "string" && /^https:\/\/cfx-nui-[\w.-]+\/[\w./-]+\.html$/.test(d.page) ? d.page : null,
        });
        break;
      // layout do jogador; editing = /hudlayout aberto (mostra exemplos no lugar)
      case "host:layout":
        if (d.editing) showHud();
        dispatch({ type: "host/layout", widgets: toPlaces(d.widgets, HOST_PIECES), editing: d.editing === true });
        break;
      case "host:visible":
        dispatch({ type: "host/visible", visible: d.visible !== false });
        break;
      case "host:catalog":
        dispatch({ type: "host/catalog", catalog: toCatalog(d.catalog) });
        break;
      default:
        break;
    }
  };

  onMounted(() => {
    window.addEventListener("message", onMessage);
    // avisa o cliente que já dá para mandar mensagens (as anteriores ficaram na
    // fila dele) e informa a área de cada peça, que ele repassa ao rsm_hud
    if (window.rsmNui.isGame) {
      window.rsmNui.post("ready", { footprints: Object.fromEntries(HOST_PIECES.map((id) => [id, WIDGET_DIMS[id]])) });
    }
  });
  onBeforeUnmount(() => window.removeEventListener("message", onMessage));
}
