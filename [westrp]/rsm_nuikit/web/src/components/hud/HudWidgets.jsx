import { useKit } from "../../state/KitStore.jsx";
import { CoreMeter, Prompt, KeyCap, Divider, Icon, Counter, coreGroup } from "../kit";
import { Toast } from "./Toast.jsx";

const CORE_BASE = 64; // tamanho base de um core no HUD, em px a 1920×1080

// Real on-screen size of each HUD piece at 1920×1080. The Layout Manager
// scales these down onto its mini screen, so what you place is what you get.
export const WIDGET_DIMS = {
  prompts: [260, 96],
  toasts: [380, 96],
  help: [400, 96],
  money: [250, 56],
  objective: [480, 44],
  menus: [400, 520],
};

// O tamanho dos cores depende do estilo escolhido.
export function widgetDims(id, coreStyle) {
  if (id === "cores") {
    const g = coreGroup(coreStyle, CORE_BASE);
    return [g.width, g.height];
  }
  return WIDGET_DIMS[id];
}

const CORE_ORDER = ["health", "stamina", "deadeye"];

export const SAMPLE_CORES = [
  { icon: "core-health", ring: 82, core: 70 },
  { icon: "core-stamina", ring: 64, core: 92 },
  { icon: "core-deadeye", ring: 22, core: 40 },
];

// Sem dados (miniatura do Layout Manager) cada widget mostra um exemplo;
// no HUD de verdade recebe o que os outros resources mandaram.
function Cores({ cores }) {
  const { state } = useKit();
  const variant = state.hud.coreStyle;
  const g = coreGroup(variant, CORE_BASE);
  const list = cores ? CORE_ORDER.map((k) => ({ icon: `core-${k}`, ...cores[k] })) : SAMPLE_CORES;
  return (
    <div className={`flex items-start ${g.col ? "flex-col" : "flex-row"}`} style={{ width: g.width, height: g.height, gap: g.gap }}>
      {list.map((c) => (
        <CoreMeter key={c.icon} variant={variant} size={CORE_BASE} icon={c.icon} ring={c.ring} core={c.core} />
      ))}
    </div>
  );
}

function Prompts() {
  return (
    <div className="flex h-full flex-col items-end justify-between">
      <Prompt k="R" label="Open Ledger" />
      <Prompt k="G" label="Hold to Rob Register" fill={0.45} />
    </div>
  );
}

function Toasts() {
  return <Toast type="info" title="Telegram Received" body="A letter waits for you at the Valentine post office." />;
}

function Help({ text, k }) {
  return (
    <div className="tx-help flex h-full items-center gap-4 px-6">
      {(text ? k : "G") && <KeyCap k={text ? k : "G"} size={26} />}
      <p className="line-clamp-3 text-[14px] leading-snug text-ink">
        {text ?? (
          <>
            Hold near a register to rob it. Lawmen in town <span className="text-accent">will notice</span>.
          </>
        )}
      </p>
    </div>
  );
}

const clockText = ({ h, m }) => `${h % 12 || 12}:${String(m).padStart(2, "0")} ${h < 12 ? "AM" : "PM"}`;

function Money({ money, clock }) {
  const cash = money ? money.cash : 142.6;
  const gold = money ? money.gold : 2.5;
  const time = clock ? clockText(clock) : money ? null : "9:42 AM";
  return (
    <div className="tx-prompt flex h-full items-center justify-between gap-4 px-6">
      <span className="font-cat text-[22px] text-ink">${cash.toFixed(2)}</span>
      {gold != null && (
        <span className="flex items-center gap-2 font-cat text-[18px] text-dim">
          <Icon name="star" size={14} className="text-dim" />
          {gold.toFixed(2)}
        </span>
      )}
      {time && <span className="font-display text-[15px] text-dim">{time}</span>}
    </div>
  );
}

function Objective({ text }) {
  return (
    <p className="flex h-full items-center justify-center text-center text-[20px] text-ink [text-shadow:0_2px_8px_rgb(0_0_0/0.9)]">
      {text ?? (
        <>
          Ride to&nbsp;<span className="text-accent">Valentine</span>&nbsp;and meet the sheriff.
        </>
      )}
    </p>
  );
}

const MENU_ROWS = [
  { name: "Coffee", price: "$0.75", qty: 2 },
  { name: "Canned Beans", price: "$0.60", qty: 1, selected: true },
  { name: "Whiskey", price: "$1.20", qty: 3 },
  { name: "Horse Brush", price: "$4.00" },
  { name: "Health Tonic", price: "$2.50" },
];

function Menu() {
  return (
    <div className="tx-card-solid flex h-full flex-col gap-4 px-8 py-8">
      <div className="tx-header px-6 py-4 text-center">
        <p className="kit-heading text-[10px] text-faint">Valentine</p>
        <p className="font-title text-[34px] leading-none text-ink">General Store</p>
      </div>
      <div className="flex flex-col gap-1.5">
        {MENU_ROWS.map((r) => (
          <div
            key={r.name}
            className={`row tx-plate flex h-11 items-center justify-between gap-3 px-4 text-[15px] ${r.selected ? "is-current" : "text-ink"}`}
          >
            <span className="flex items-center gap-2.5">
              {r.name}
              {r.qty > 1 && <Counter size="sm" muted>{r.qty}</Counter>}
            </span>
            <span className="font-cat">{r.price}</span>
          </div>
        ))}
      </div>
      <Divider className="mt-auto" />
      <div className="flex items-center justify-between text-[14px] text-dim">
        <span className="kit-heading text-[11px]">Your Total</span>
        <span className="font-cat text-[20px] text-ink">$1.35</span>
      </div>
    </div>
  );
}

export const WIDGETS = {
  cores: Cores,
  prompts: Prompts,
  toasts: Toasts,
  help: Help,
  money: Money,
  objective: Objective,
  menus: Menu,
};
