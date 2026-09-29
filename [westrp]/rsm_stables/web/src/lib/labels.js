// Textos fixos da interface do estábulo (nada aqui é regra de jogo: preço,
// vaga e catálogo vêm sempre do servidor).

export const TABS = [
  { value: "shop", label: "Loja" },
  { value: "stable", label: "Estábulo" },
  { value: "tack", label: "Arreios" },
  { value: "transfer", label: "Transferir" },
];

export const RIDE_CLASS = {
  elite: "Elite",
  war: "Guerra",
  race: "Corrida",
  riding: "Montaria",
  draft: "Tração",
  work: "Trabalho",
  light: "Leve",
  passenger: "Passageiros",
};

export const HORSE_STATS = [
  ["health", "Vida"],
  ["stamina", "Vigor"],
  ["speed", "Velocidade"],
  ["accel", "Aceleração"],
  ["handling", "Manobra"],
];

export const CART_STATS = [
  ["speed", "Velocidade"],
  ["durability", "Resistência"],
];

export const BOND_LABEL = ["Sem vínculo", "Vínculo 1", "Vínculo 2", "Vínculo 3", "Vínculo máximo"];
