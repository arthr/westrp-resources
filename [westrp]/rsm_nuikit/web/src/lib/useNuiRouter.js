import { useEffect, useRef } from "react";

const KINDS = ["info", "success", "warning", "error"];
const str = (v, max) => (v == null ? "" : String(v).slice(0, max));
const num = (v) => (typeof v === "number" && Number.isFinite(v) ? v : null);

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
export function useNuiRouter({ dispatch, notify }) {
  const notifyRef = useRef(notify);
  useEffect(() => {
    notifyRef.current = notify;
  }, [notify]);

  useEffect(() => {
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
          notifyRef.current(KINDS.includes(d.kind) ? d.kind : "info", str(d.title, 80), str(d.body, 240), {
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
        default:
          break;
      }
    };

    window.addEventListener("message", onMessage);
    // avisa o cliente que já dá para mandar mensagens (as anteriores ficaram na fila dele)
    if (window.rsmNui.isGame) window.rsmNui.post("ready");
    return () => window.removeEventListener("message", onMessage);
  }, [dispatch]);
}
