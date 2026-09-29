import { AnimatePresence, motion } from "framer-motion";
import { useKit } from "../../state/KitStore.jsx";
import { anchorBox } from "./anchor.js";
import { WIDGETS, widgetDims } from "./HudWidgets.jsx";

// O HUD que os jogadores veem: só as peças que algum resource alimentou, cada
// uma onde o Layout Manager mandou. Não pega o mouse e some com o estúdio aberto
// (como o HUD do jogo some nos menus) ou quando um resource pede SetHudHidden.
export function HudLayer() {
  const { state, isActive } = useKit();
  const { hud, layout } = state;
  const hidden = state.studio.open || hud.hidden;

  const pieces = [];
  if (hud.cores && isActive("cores")) pieces.push(["cores", { cores: hud.cores }]);
  if (hud.help && isActive("help")) pieces.push(["help", { text: hud.help.text, k: hud.help.key }]);
  if (hud.money && isActive("money")) pieces.push(["money", { money: hud.money, clock: hud.clock }]);
  if (hud.objective && isActive("objective")) pieces.push(["objective", { text: hud.objective }]);

  return (
    <AnimatePresence>
      {!hidden &&
        pieces.map(([id, props]) => {
          const Widget = WIDGETS[id];
          const w = layout.widgets[id];
          const b = anchorBox(w.anchor, w.x, w.y, layout.safeZone);
          const [dw, dh] = widgetDims(id, hud.coreStyle);
          return (
            <motion.div
              key={id}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.25 }}
              className="pointer-events-none fixed z-30"
              style={{ left: `${b.left}%`, top: `${b.top}%` }}
            >
              {/* o transform fica num filho: o motion.div só anima a opacidade */}
              <div
                style={{
                  width: dw,
                  height: dh,
                  transform: `translate(${b.tx}%, ${b.ty}%) scale(${w.scale / 100})`,
                  transformOrigin: b.origin,
                }}
              >
                <Widget {...props} />
              </div>
            </motion.div>
          );
        })}
    </AnimatePresence>
  );
}
