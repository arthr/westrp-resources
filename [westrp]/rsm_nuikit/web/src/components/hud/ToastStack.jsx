import { useCallback, useEffect } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { useKit } from "../../state/KitStore.jsx";
import { anchorBox } from "./anchor.js";
import { Toast } from "./Toast.jsx";

function ToastItem({ toast, ttl, onDismiss, fromBottom }) {
  useEffect(() => {
    const t = setTimeout(() => onDismiss(toast.id), ttl);
    return () => clearTimeout(t);
  }, [toast.id, ttl, onDismiss]);

  return (
    <motion.button
      type="button"
      layout
      initial={{ opacity: 0, y: fromBottom ? 16 : -16 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.96, transition: { duration: 0.18 } }}
      transition={{ type: "spring", stiffness: 380, damping: 30 }}
      onClick={() => onDismiss(toast.id)}
      className="pointer-events-auto block cursor-pointer outline-none"
    >
      <Toast type={toast.type} title={toast.title} body={toast.body} ttl={ttl} />
    </motion.button>
  );
}

// The live notification feed, placed wherever the Layout Manager anchors it.
export function ToastStack() {
  const { state, dispatch } = useKit();
  const w = state.layout.widgets.toasts;
  const box = anchorBox(w.anchor, w.x, w.y, state.layout.safeZone);
  const fromBottom = w.anchor[0] === "b";
  const dismiss = useCallback((id) => dispatch({ type: "toast/dismiss", id }), [dispatch]);
  // SetHudHidden também esconde o feed; as notificações esperam na fila
  if (state.hud.hidden) return null;

  return (
    <div
      className="pointer-events-none fixed z-40"
      style={{
        left: `${box.left}%`,
        top: `${box.top}%`,
        transform: `translate(${box.tx}%, ${box.ty}%) scale(${w.scale / 100})`,
        transformOrigin: box.origin,
      }}
    >
      <div className={`flex gap-2.5 ${fromBottom ? "flex-col-reverse" : "flex-col"}`}>
        <AnimatePresence initial={false}>
          {state.toasts.map((t) => (
            <ToastItem
              key={t.id}
              toast={t}
              ttl={Math.min(30000, Math.max(1500, t.duration ?? state.notifyDuration))}
              onDismiss={dismiss}
              fromBottom={fromBottom}
            />
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
}
