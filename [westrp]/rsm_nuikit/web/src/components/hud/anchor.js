// Anchor maths shared by the Layout Manager canvas and the live HUD overlay.
// anchor = "<v><h>": v ∈ t/m/b, h ∈ l/c/r. x / y / safe are % of the screen.
export function anchorBox(anchor, x, y, safe) {
  const v = anchor[0];
  const h = anchor[1];
  return {
    left: h === "l" ? safe + x : h === "c" ? 50 + x : 100 - safe + x,
    top: v === "t" ? safe + y : v === "m" ? 50 + y : 100 - safe + y,
    tx: h === "l" ? 0 : h === "c" ? -50 : -100,
    ty: v === "t" ? 0 : v === "m" ? -50 : -100,
    origin: `${h === "l" ? "left" : h === "c" ? "center" : "right"} ${v === "t" ? "top" : v === "m" ? "center" : "bottom"}`,
  };
}

// Nearest anchor for a point given as 0-1 fractions of the screen
export function nearestAnchor(fx, fy) {
  const v = fy < 1 / 3 ? "t" : fy < 2 / 3 ? "m" : "b";
  const h = fx < 1 / 3 ? "l" : fx < 2 / 3 ? "c" : "r";
  return v + h;
}
