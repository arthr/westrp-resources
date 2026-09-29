import { onBeforeUnmount, onMounted } from "vue";
import { SECTIONS } from "../state/mock.js";

const isTyping = (el) => el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.isContentEditable);

// ESC answers the open Confirm with "no" first, then closes the studio (the
// client drops NUI focus). Q / E step through the sections like RDR menu tabs.
// O estado é lido na hora da tecla, então nunca fica desatualizado.
export function useKeyNav(kit) {
  const onKey = (e) => {
    const { section, dialog } = kit.state;
    const open = kit.state.studio.open;
    if (e.key === "Escape") {
      if (dialog) {
        e.preventDefault();
        kit.answerDialog(false);
      } else if (open) {
        e.preventDefault();
        kit.closePanel();
      }
      return;
    }
    if (!open || dialog || e.repeat || isTyping(e.target)) return;
    const step = e.code === "KeyQ" ? -1 : e.code === "KeyE" ? 1 : 0;
    if (!step) return;
    const i = SECTIONS.findIndex((s) => s.id === section);
    const next = SECTIONS[(i + step + SECTIONS.length) % SECTIONS.length];
    kit.dispatch({ type: "section", id: next.id });
  };

  onMounted(() => window.addEventListener("keydown", onKey));
  onBeforeUnmount(() => window.removeEventListener("keydown", onKey));
}
