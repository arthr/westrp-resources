import { AnimatePresence, motion } from "framer-motion";
import { useKit } from "../../state/KitStore.jsx";
import { Button, Divider, Icon, Tag } from "../kit";

// Two-choice dialog. The payload is plain data, so any resource can open one
// through Confirm: { kicker, title, body, lines: [[label, value]], confirm, cancel, danger }.
// Cancelar, ESC e clicar fora respondem "não"; a resposta sempre volta a quem perguntou.
export function ConfirmDialog() {
  const { state, answerDialog } = useKit();
  const d = state.dialog;
  const waiting = state.dialogQueue.length;
  const close = () => answerDialog(false);
  const confirm = () => answerDialog(true);

  return (
    <AnimatePresence>
      {d && (
        <motion.div
          key="dialog"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.16 }}
          onPointerDown={(e) => e.target === e.currentTarget && close()}
          className="fixed inset-0 z-50 grid place-items-center p-8"
          style={{ background: "rgba(0,0,0,0.38)" }}
        >
          <motion.div
            key={d.requestId ?? d.title}
            role="dialog"
            aria-modal="true"
            aria-label={d.title}
            initial={{ opacity: 0, y: 14, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 8 }}
            transition={{ type: "spring", stiffness: 360, damping: 30 }}
            className="tx-dialog flex w-[min(34rem,90vw)] flex-col gap-5 px-11 py-10"
          >
            <header className="flex items-start gap-4">
              <Icon name={d.danger ? "menu-icon-alert" : "menu-icon-tick"} size={34} className={d.danger ? "text-accent" : "text-ink"} />
              <div className="min-w-0 flex-1">
                {d.kicker && <p className="kit-heading text-[10px] text-faint">{d.kicker}</p>}
                <h2 className="kit-heading mt-1 text-[19px] leading-tight text-ink">{d.title}</h2>
              </div>
              {waiting > 0 && <Tag kind="neutral">+{waiting} waiting</Tag>}
            </header>
            <Divider />
            {d.body && <p className="text-[15px] leading-relaxed text-dim">{d.body}</p>}
            {d.lines && (
              <div className="tx-help flex flex-col gap-2 px-6 py-4">
                {d.lines.map(([label, value], i) => (
                  <div key={i} className="flex items-baseline justify-between gap-6 text-[14px]">
                    <span className="text-dim">{label}</span>
                    <span className="font-cat text-[16px] text-ink">{value}</span>
                  </div>
                ))}
              </div>
            )}
            <div className="mt-1 flex justify-end gap-3">
              <Button onClick={close}>{d.cancel ?? "Cancel"}</Button>
              <Button variant="primary" onClick={confirm} autoFocus>
                {d.confirm ?? "Confirm"}
              </Button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
