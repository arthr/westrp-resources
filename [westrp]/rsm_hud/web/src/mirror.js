// Espelho: a mesma interface aberta com ?mirror=1 dentro de um iframe (a prévia
// do rsm_nuikit). Ela só desenha: não fala com o client (nada de catálogo,
// layout ou posição de peças), não grava layout e mostra dados de exemplo.
// Quem alimenta o espelho é a página que o contém, por postMessage, com as
// mesmas mensagens que o client manda (hud:setLayout, hud:policy, hud:theme…).
import "./nui.js";

export const MIRROR = new URLSearchParams(window.location.search).has("mirror");

if (MIRROR) {
  window.rsmNui.post = () => Promise.resolve();
  const root = document.documentElement;
  root.classList.add("rsm-mirror");
  root.style.visibility = "visible";
}
