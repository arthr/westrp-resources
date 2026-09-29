import { useKit } from "../../state/KitStore.jsx";
import { Button, KeyCap } from "../kit";

const HINTS = [
  { keys: ["Q", "E"], label: "Switch Section" },
  { keys: ["R", "G"], label: "Prompts (HUD Pieces)" },
  { keys: ["Esc"], label: "Close" },
];

// Footer bar: the key legend RDR menus carry along their bottom edge.
export function KeyHints() {
  const { closePanel } = useKit();
  return (
    <footer className="flex items-center justify-between gap-6">
      <div className="flex flex-wrap items-center gap-7">
        {HINTS.map((h) => (
          <span key={h.label} className="flex items-center gap-2.5 text-[13px] text-dim">
            {h.keys.map((k) => (
              <KeyCap key={k} k={k} size={k.length > 1 ? 34 : 26} />
            ))}
            {h.label}
          </span>
        ))}
        <span className="text-[13px] text-faint">Drag widgets on the mini screen to place them</span>
      </div>
      <Button variant="ghost" size="sm" icon="cross" onClick={closePanel}>
        Close
      </Button>
    </footer>
  );
}
