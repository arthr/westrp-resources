// Surfaces, icons, lines and selection brackets. Every piece is RDR2 art
// tinted through a mask (see the .tx-* / .ico / .ln-* rules in styles.css).

// Vue não põe "px" em números de :style (o React punha), então todo tamanho
// em pixels passa por aqui.
export const px = (n) => `${n}px`;

export const texMask = (name, fit = "contain") => ({
  WebkitMask: `var(--tex-${name}) center / ${fit} no-repeat`,
  mask: `var(--tex-${name}) center / ${fit} no-repeat`,
});
