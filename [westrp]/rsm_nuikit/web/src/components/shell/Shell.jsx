import { motion } from "framer-motion";
import { useKit } from "../../state/KitStore.jsx";
import { Divider, VDivider } from "../kit";
import { Sidebar } from "./Sidebar.jsx";
import { KeyHints } from "./KeyHints.jsx";
import { LayoutManager } from "../sections/LayoutManager.jsx";
import { ColorManager } from "../sections/ColorManager.jsx";
import { StatesSection } from "../sections/StatesSection.jsx";
import { ControlsSection } from "../sections/ControlsSection.jsx";
import { FeedbackSection } from "../sections/FeedbackSection.jsx";
import { HudSection } from "../sections/HudSection.jsx";
import { ServiceSection } from "../sections/ServiceSection.jsx";

const VIEWS = {
  layout: LayoutManager,
  colors: ColorManager,
  states: StatesSection,
  controls: ControlsSection,
  feedback: FeedbackSection,
  hud: HudSection,
  service: ServiceSection,
};

export function Shell() {
  const { state } = useKit();
  const View = VIEWS[state.section];
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, transition: { duration: 0.15 } }}
      className="relative z-20 flex h-screen w-screen items-center justify-center p-[3vh]"
    >
      <motion.main
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 260, damping: 28 }}
        className="tx-shell flex h-[min(92vh,1000px)] w-[min(95vw,1760px)] min-w-0 flex-col px-12 pt-11 pb-10"
      >
        <div className="grid min-h-0 flex-1 grid-cols-[clamp(230px,15vw,280px)_4px_minmax(0,1fr)] gap-8">
          <Sidebar />
          <VDivider />
          <motion.div
            key={state.section}
            initial={{ opacity: 0, x: 10 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.2 }}
            className="flex min-h-0 min-w-0 flex-col"
          >
            <View />
          </motion.div>
        </div>
        <Divider className="mt-6 mb-5" />
        <KeyHints />
      </motion.main>
    </motion.div>
  );
}
