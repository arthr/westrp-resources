// Formatação de valores exibidos no estábulo.

const money = new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const gold = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 1 });

export const fmtCash = (v) => `$${money.format(Number(v) || 0)}`;
export const fmtGold = (v) => gold.format(Number(v) || 0);

// Segundos restantes → "1:42"
export const fmtClock = (secs) => {
  const t = Math.max(0, Math.ceil(secs));
  return `${Math.floor(t / 60)}:${String(t % 60).padStart(2, "0")}`;
};
