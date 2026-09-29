// Regras do inventário (dados de exemplo + funções puras). Tudo aqui recebe
// um array de slots e devolve um array NOVO; nada é alterado no lugar.
// Slot = null | { uid, id, qty }. Quando o backend entrar, o servidor é quem
// decide; estas regras viram a pré-visualização do lado da UI.

export const ITEM_DEFS = {
  cattleman: { name: "Cattleman Revolver", img: "weapon_revolver_cattleman", max: 1, cat: "weapons", meta: "Sidearm · .45 calibre" },
  tonic: { name: "Health Tonic", img: "consumable_tonic", max: 5, cat: "medicine", meta: "Fortifies the health core" },
  whiskey: { name: "Whiskey", img: "consumable_whiskey", max: 10, cat: "provisions", meta: "Restores Dead Eye core" },
  coffee: { name: "Coffee", img: "consumable_coffee", max: 10, cat: "provisions", meta: "Warms, fills stamina core" },
  apple: { name: "Apple", img: "consumable_apple", max: 20, cat: "provisions", meta: "Small health core refill" },
  cigar: { name: "Cigar", img: "consumable_cigar", max: 20, cat: "provisions", meta: "Calms the nerves" },
  brush: { name: "Horse Brush", img: "kit_horse_brush", max: 1, cat: "kit", meta: "Cleans your horse" },
  watch: { name: "Pocket Watch", img: "kit_player_pocketwatch", max: 1, cat: "valuables", meta: "Tells the time" },
  moneyclip: { name: "Money Clip", img: "money_moneyclip", max: 1, cat: "valuables", meta: "Holds $142.60" },
  map: { name: "Treasure Map", img: "generic_treasure_map", max: 1, cat: "documents", meta: "Marked near Flat Iron Lake" },
};

export const CATEGORIES = {
  weapons: "Weapons",
  medicine: "Medicine",
  provisions: "Provisions",
  kit: "Kit",
  valuables: "Valuables",
  documents: "Documents",
};
const CAT_ORDER = Object.keys(CATEGORIES);

export const SLOT_COUNT = 24;

let seq = 0;
const newUid = () => `s${++seq}`;
const stack = (id, qty) => ({ uid: newUid(), id, qty });

// Espalhado de propósito: pilhas repetidas e buracos para mostrar
// empilhar, dividir e o auto-ordenar.
export function initialSlots() {
  return [
    stack("whiskey", 3), null, stack("apple", 12), stack("coffee", 2), null, stack("cigar", 6), stack("tonic", 2), null,
    stack("cattleman", 1), stack("whiskey", 4), null, stack("apple", 5), stack("watch", 1), null, stack("map", 1), stack("cigar", 4),
    null, stack("brush", 1), stack("moneyclip", 1), null, stack("tonic", 1), null, null, stack("coffee", 3),
  ];
}

export const firstEmpty = (slots) => slots.findIndex((s) => s === null);

// Quanto um arraste pega da pilha, conforme o modo.
export function grabQty(mode, qty, amount) {
  if (mode === "half") return Math.max(1, Math.floor(qty / 2));
  if (mode === "one") return 1;
  if (mode === "amount") return Math.max(1, Math.min(qty, amount));
  return qty;
}

// O que acontece se `qty` itens de `from` forem soltos em `to`.
// kind: move | stack | swap | full | blocked | same
export function planDrop(slots, from, to, qty) {
  const src = slots[from];
  const dst = slots[to];
  const def = ITEM_DEFS[src.id];
  const whole = qty >= src.qty;
  if (to === from) return { kind: "same", ok: false, hint: "Release to put it back" };
  if (!dst) {
    return {
      kind: "move",
      ok: true,
      hint: `Move ${qty} ${def.name} to slot ${to + 1}`,
      done: `Moved ${qty} ${def.name} to slot ${to + 1}.`,
    };
  }
  if (dst.id === src.id) {
    const room = def.max - dst.qty;
    if (room <= 0) return { kind: "full", ok: false, hint: `${def.name} in slot ${to + 1} is already full (${def.max}/${def.max})` };
    const add = Math.min(room, qty);
    const rest = qty - add;
    return {
      kind: "stack",
      ok: true,
      add,
      hint: `Stack ${add} ${def.name} into slot ${to + 1} (${dst.qty} → ${dst.qty + add}/${def.max})${rest ? `, ${rest} stay behind` : ""}`,
      done: `Stacked ${add} ${def.name} into slot ${to + 1} (${dst.qty + add}/${def.max})${rest ? `; ${rest} stayed in slot ${from + 1}` : ""}.`,
    };
  }
  const other = ITEM_DEFS[dst.id].name;
  if (!whole) return { kind: "blocked", ok: false, hint: `Only a whole stack can swap with ${other}` };
  return { kind: "swap", ok: true, hint: `Swap ${def.name} with ${other}`, done: `Swapped ${def.name} and ${other}.` };
}

export function applyDrop(slots, from, to, qty) {
  const plan = planDrop(slots, from, to, qty);
  if (!plan.ok) return { slots, plan };
  const next = slots.slice();
  const src = slots[from];
  const dst = slots[to];
  if (plan.kind === "move") {
    const whole = qty >= src.qty;
    next[to] = whole ? src : { uid: newUid(), id: src.id, qty };
    next[from] = whole ? null : { ...src, qty: src.qty - qty };
  } else if (plan.kind === "stack") {
    next[to] = { ...dst, qty: dst.qty + plan.add };
    const left = src.qty - plan.add;
    next[from] = left > 0 ? { ...src, qty: left } : null;
  } else if (plan.kind === "swap") {
    next[to] = src;
    next[from] = dst;
  }
  return { slots: next, plan };
}

// Tira `qty` da pilha `from` (largar no chão ou usar). Zerou, o slot esvazia.
export function takeFrom(slots, from, qty) {
  const src = slots[from];
  const next = slots.slice();
  const left = src.qty - qty;
  next[from] = left > 0 ? { ...src, qty: left } : null;
  return next;
}

// Divide `qty` da pilha `from` para o primeiro slot vazio.
export function splitOff(slots, from, qty) {
  const src = slots[from];
  const def = ITEM_DEFS[src.id];
  if (src.qty < 2) return { slots, error: `A single ${def.name} can't be split.` };
  const n = Math.min(qty, src.qty - 1);
  const to = firstEmpty(slots);
  if (to < 0) return { slots, error: "No empty slot to split into." };
  const next = slots.slice();
  next[from] = { ...src, qty: src.qty - n };
  next[to] = { uid: newUid(), id: src.id, qty: n };
  return { slots: next, to, text: `Split ${n} ${def.name} into slot ${to + 1}.` };
}

export const SORTS = [
  { value: "category", label: "Category" },
  { value: "name", label: "Name" },
  { value: "quantity", label: "Quantity" },
];

const byName = (a, b) => ITEM_DEFS[a.id].name.localeCompare(ITEM_DEFS[b.id].name);
const COMPARE = {
  category: (a, b) =>
    CAT_ORDER.indexOf(ITEM_DEFS[a.id].cat) - CAT_ORDER.indexOf(ITEM_DEFS[b.id].cat) || byName(a, b) || b.qty - a.qty,
  name: (a, b) => byName(a, b) || b.qty - a.qty,
  quantity: (a, b) => b.qty - a.qty || byName(a, b),
};

// Junta pilhas iguais até o máximo, ordena e compacta no começo.
export function autoSort(slots, by) {
  const groups = new Map();
  for (const s of slots) {
    if (!s) continue;
    const g = groups.get(s.id) ?? { id: s.id, total: 0, uids: [] };
    g.total += s.qty;
    g.uids.push(s.uid);
    groups.set(s.id, g);
  }
  const stacks = [];
  for (const g of groups.values()) {
    const max = ITEM_DEFS[g.id].max;
    let left = g.total;
    let k = 0;
    while (left > 0) {
      const q = Math.min(max, left);
      stacks.push({ uid: g.uids[k] ?? newUid(), id: g.id, qty: q });
      left -= q;
      k += 1;
    }
  }
  stacks.sort(COMPARE[by]);
  const before = slots.filter(Boolean).length;
  return { slots: slots.map((_, i) => stacks[i] ?? null), merged: before - stacks.length };
}
