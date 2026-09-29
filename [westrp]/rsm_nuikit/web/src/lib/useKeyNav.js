import { useEffect } from "react";
import { SECTIONS } from "../state/mock.js";

const isTyping = (el) => el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.isContentEditable);

// ESC answers the open Confirm with "no" first, then closes the studio (the
// client drops NUI focus). Q / E step through the sections like RDR menu tabs.
export function useKeyNav({ state, dispatch, closePanel, answerDialog }) {
  const { section, dialog } = state;
  const open = state.studio.open;

  useEffect(() => {
    const onKey = (e) => {
      if (e.key === "Escape") {
        if (dialog) {
          e.preventDefault();
          answerDialog(false);
        } else if (open) {
          e.preventDefault();
          closePanel();
        }
        return;
      }
      if (!open || dialog || e.repeat || isTyping(e.target)) return;
      const step = e.code === "KeyQ" ? -1 : e.code === "KeyE" ? 1 : 0;
      if (!step) return;
      const i = SECTIONS.findIndex((s) => s.id === section);
      const next = SECTIONS[(i + step + SECTIONS.length) % SECTIONS.length];
      dispatch({ type: "section", id: next.id });
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [section, dialog, open, dispatch, closePanel, answerDialog]);
}
