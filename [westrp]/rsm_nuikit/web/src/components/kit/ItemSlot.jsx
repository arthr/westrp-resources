import { Brackets } from "./Surface.jsx";
import { Counter } from "./Badges.jsx";

// Framed item slot. Item art is shown as-is: never masked, tinted or cropped.
// qty: quantidade exibida (durante um arraste parcial, o que sobrou na origem).
// drop: null | "valid" | "invalid" enquanto um arraste passa por cima.
// lifted: a pilha inteira está na mão; o slot mostra só a sombra do item.
// popDelay: ms; toca a animação de entrada (usada depois do auto-ordenar).
export function ItemSlot({
  item,
  qty = item ? item.qty : 0,
  selected = false,
  drop = null,
  lifted = false,
  popDelay,
  size = 76,
  disabled = false,
  className = "",
  style,
  ...rest
}) {
  const frame =
    drop === "valid" || selected ? "var(--kit-accent)" : drop === "invalid" ? "rgb(var(--kit-text-rgb) / 0.12)" : "rgb(var(--kit-text-rgb) / 0.22)";
  return (
    <button
      type="button"
      disabled={disabled}
      title={item ? `${item.name}${qty > 1 ? ` ×${qty}` : ""}` : "Empty slot"}
      className={`tx-frame group relative grid shrink-0 place-items-center p-3 outline-none transition-opacity ${
        disabled ? "cursor-not-allowed opacity-40" : drop === "invalid" ? "cursor-not-allowed opacity-45" : ""
      } ${className}`}
      style={{ width: size, height: size, "--frame": frame, ...style }}
      {...rest}
    >
      {item && (
        <img
          src={window.rsmAsset(`tex/items/${item.img}.png`)}
          alt={item.name}
          draggable={false}
          className={`pointer-events-none h-full w-full object-contain transition-opacity ${lifted ? "opacity-20" : ""}`}
          style={popDelay != null ? { animation: `kit-pop 0.32s ease-out ${popDelay}ms both` } : undefined}
        />
      )}
      {item && !lifted && qty > 1 && (
        <span className="pointer-events-none absolute right-1.5 bottom-1.5">
          <Counter size="sm">{qty}</Counter>
        </span>
      )}
      {(selected || drop === "valid") && <Brackets size={14} fill={drop === "valid" ? "var(--kit-accent)" : "var(--kit-text)"} />}
    </button>
  );
}
