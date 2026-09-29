import { useEffect } from "react";
import { AnimatePresence } from "framer-motion";
import { KitProvider, useKit } from "./state/KitStore.jsx";
import { useKeyNav } from "./lib/useKeyNav.js";
import { useNuiRouter } from "./lib/useNuiRouter.js";
import { Shell } from "./components/shell/Shell.jsx";
import { HudLayer } from "./components/hud/HudLayer.jsx";
import { ToastStack } from "./components/hud/ToastStack.jsx";
import { ConfirmDialog } from "./components/hud/ConfirmDialog.jsx";
import { Button } from "./components/kit";

// Só no preview: com o estúdio fechado sobra o HUD, como o jogador vê.
// No jogo quem reabre é o /nuikit.
function PreviewReopen() {
  const { dispatch } = useKit();
  return (
    <div className="pointer-events-none fixed inset-x-0 top-[3vh] z-20 flex justify-center">
      <div className="tx-prompt pointer-events-auto flex items-center gap-5 py-2 pr-2 pl-6">
        <span className="text-[13px] text-dim">This is what players see. In game, staff reopen the studio with /nuikit.</span>
        <Button size="sm" variant="primary" onClick={() => dispatch({ type: "studio/set", open: true })}>
          Open Studio
        </Button>
      </div>
    </div>
  );
}

// rsm_nuikit: a UI service. The HUD, notifications and Confirm dialogs are
// always available to other resources; the studio opens on top for staff.
function Service() {
  const kit = useKit();
  useKeyNav(kit);
  useNuiRouter(kit);
  const open = kit.state.studio.open;

  // no jogo, o estúdio aberto escurece levemente o mundo (a camada da página
  // continua transparente; com ele fechado não há véu nenhum)
  useEffect(() => {
    if (window.rsmNui.isGame) document.documentElement.classList.toggle("rsm-open", open);
  }, [open]);

  return (
    <>
      <HudLayer />
      <AnimatePresence>{open && <Shell key="studio" />}</AnimatePresence>
      {!open && !window.rsmNui.isGame && <PreviewReopen />}
      <ToastStack />
      <ConfirmDialog />
    </>
  );
}

export default function App() {
  return (
    <KitProvider>
      <Service />
    </KitProvider>
  );
}
