// Dados de exemplo, usados SÓ na prévia do navegador. No jogo tudo isto chega
// do servidor no SendNUIMessage({ action = "open", data = ... }), no mesmo
// formato: preços, vagas e catálogo têm um único dono, o servidor.

const s = (health, stamina, speed, accel, handling) => ({ health, stamina, speed, accel, handling });

// Cavalos à venda, agrupados por raça. `gold` é opcional (raças de elite).
const BREEDS = [
  {
    breed: "Árabe", cls: "elite", stats: s(70, 74, 92, 90, 95), capacity: 110,
    coats: [
      ["A_C_Horse_Arabian_White", "Branco", 1250, 50],
      ["A_C_Horse_Arabian_RedChestnut", "Alazão Avermelhado", 1050, 42],
      ["A_C_Horse_Arabian_RoseGreyBay", "Baio Tordilho Rosado", 1100, 44],
    ],
  },
  {
    breed: "Missouri Fox Trotter", cls: "elite", stats: s(82, 90, 85, 80, 75), capacity: 120,
    coats: [
      ["A_C_Horse_MissouriFoxTrotter_AmberChampagne", "Champanhe Âmbar", 950, 38],
      ["A_C_Horse_MissouriFoxTrotter_SilverDapplePinto", "Pampa Tordilho Prateado", 1125, 45],
    ],
  },
  {
    breed: "Turcomano", cls: "war", stats: s(88, 80, 80, 78, 70), capacity: 125,
    coats: [
      ["A_C_Horse_Turkoman_Gold", "Dourado", 925, 37],
      ["A_C_Horse_Turkoman_Silver", "Prata", 950, 38],
      ["A_C_Horse_Turkoman_DarkBay", "Baio Escuro", 925, 37],
    ],
  },
  {
    breed: "American Standardbred", cls: "race", stats: s(55, 70, 78, 82, 60), capacity: 100,
    coats: [
      ["A_C_Horse_AmericanStandardbred_Black", "Preto", 130],
      ["A_C_Horse_AmericanStandardbred_Buckskin", "Camurça", 130],
      ["A_C_Horse_AmericanStandardbred_PalominoDapple", "Palomino Tordilho", 150],
      ["A_C_Horse_AmericanStandardbred_SilverTailBuckskin", "Camurça Cauda Prateada", 150],
    ],
  },
  {
    breed: "Ardennes", cls: "war", stats: s(90, 82, 60, 58, 55), capacity: 140,
    coats: [
      ["A_C_Horse_Ardennes_BayRoan", "Ruão Baio", 140],
      ["A_C_Horse_Ardennes_StrawberryRoan", "Ruão Morango", 150],
      ["A_C_Horse_Ardennes_IronGreyRoan", "Ruão Ferro", 150],
    ],
  },
  {
    breed: "Tennessee Walker", cls: "riding", stats: s(50, 56, 62, 60, 68), capacity: 100,
    coats: [
      ["A_C_Horse_TennesseeWalker_Chestnut", "Alazão", 60],
      ["A_C_Horse_TennesseeWalker_RedRoan", "Ruão Vermelho", 60],
      ["A_C_Horse_TennesseeWalker_MahoganyBay", "Baio Mogno", 60],
    ],
  },
  {
    breed: "Kentucky Saddler", cls: "riding", stats: s(48, 55, 58, 60, 65), capacity: 100,
    coats: [
      ["A_C_Horse_KentuckySaddle_Black", "Preto", 50],
      ["A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC", "Camurça Leitosa", 50],
      ["A_C_Horse_KentuckySaddle_ChestnutPinto", "Pampa Alazão", 50],
      ["A_C_Horse_KentuckySaddle_Grey", "Tordilho", 50],
      ["A_C_Horse_KentuckySaddle_SilverBay", "Baio Prateado", 50],
    ],
  },
  {
    breed: "Shire", cls: "draft", stats: s(95, 85, 40, 35, 40), capacity: 160,
    coats: [
      ["A_C_Horse_Shire_DarkBay", "Baio Escuro", 120],
      ["A_C_Horse_Shire_LightGrey", "Tordilho Claro", 120],
      ["A_C_Horse_Shire_RavenBlack", "Preto Corvo", 130],
    ],
  },
  {
    breed: "Mula", cls: "work", stats: s(45, 78, 32, 30, 52), capacity: 150,
    coats: [
      ["A_C_HorseMule_01", "Comum", 25],
      ["A_C_Donkey_01", "Burro", 20],
    ],
  },
];

const HORSES = BREEDS.flatMap((b) =>
  b.coats.map(([model, coat, price, gold]) => ({
    model,
    breed: b.breed,
    coat,
    cls: b.cls,
    price,
    gold: gold ?? null,
    stats: b.stats,
    capacity: b.capacity,
  })),
);

// Carroças: carga = peso do inventário da carroça, assentos = passageiros
const CARTS = [
  { model: "buggy01", label: "Charrete", cls: "light", price: 250, seats: 2, capacity: 15, stats: { speed: 88, durability: 40 } },
  { model: "huntercart01", label: "Carroça de Caçador", cls: "work", price: 50, seats: 2, capacity: 50, stats: { speed: 62, durability: 55 } },
  { model: "cart01", label: "Carroça Simples", cls: "work", price: 30, seats: 2, capacity: 50, stats: { speed: 58, durability: 50 } },
  { model: "wagon02x", label: "Carroção", cls: "work", price: 100, seats: 2, capacity: 100, stats: { speed: 45, durability: 72 } },
  { model: "chuckwagon002x", label: "Carroça de Cozinha", cls: "work", price: 110, seats: 2, capacity: 110, stats: { speed: 40, durability: 70 } },
  { model: "supplywagon", label: "Carroção de Suprimentos", cls: "work", price: 105, seats: 2, capacity: 105, stats: { speed: 42, durability: 78 } },
  { model: "coach2", label: "Coche Particular", cls: "passenger", price: 120, seats: 4, capacity: 120, stats: { speed: 60, durability: 64 } },
  { model: "stagecoach001x", label: "Diligência", cls: "passenger", price: 180, seats: 6, capacity: 80, stats: { speed: 55, durability: 80 } },
];

// Arreios: categoria → estilos, cada estilo com N variações de cor.
// `art` é a arte do item (mostrada como está, sem máscara).
const TACK = [
  {
    id: "saddles", label: "Selas", art: "generic_horse_equip_saddle",
    styles: [
      ["lumley_mcclelland", "Lumley McClelland", 18, 26],
      ["kneller_mother_hubbard", "Kneller Mother Hubbard", 18, 24],
      ["kneller_dakota", "Kneller Dakota", 17, 22],
      ["gerden_vaquero", "Gerden Vaquero", 22, 21.5],
      ["gerden_trail", "Gerden Trail", 18, 21],
      ["stenger_roping", "Stenger Roping", 18, 25],
      ["lumley_ranch_cutter", "Lumley Ranch Cutter", 18, 23],
      ["cougar_mcclelland", "McClelland de Puma", 1, 110],
      ["bear_dakota", "Dakota de Urso", 1, 140],
      ["panther_trail", "Trail de Pantera", 1, 150],
    ],
  },
  {
    id: "blankets", label: "Mantas", art: "generic_horse_equip_blanket",
    styles: [
      ["siltwater", "Siltwater", 5, 10],
      ["roanoke_ridge", "Roanoke Ridge", 5, 10],
      ["rio_bravo", "Rio Bravo", 5, 10],
      ["cholla_springs", "Cholla Springs", 5, 10],
      ["owanjila", "Owanjila", 7, 14],
      ["millesani", "Millesani", 5, 17.5],
      ["diablo", "Diablo", 3, 20],
      ["iron_cloud", "Iron Cloud", 5, 10.5],
    ],
  },
  {
    id: "horns", label: "Cabeças de Sela", art: "generic_horse_equip_horn",
    styles: [
      ["birch_dally", "Dally de Bétula", 2, 20],
      ["brass_eagle", "Águia de Latão", 1, 26.4],
      ["steel_diablo", "Diablo de Aço", 1, 30],
      ["pine_dally", "Dally de Pinho", 1, 25.5],
      ["steel_diez_corona", "Diez Corona de Aço", 1, 29],
    ],
  },
  { id: "bags", label: "Alforjes", art: "generic_horse_equip_saddlebag", styles: [["standard", "Alforje de Couro", 20, 10]] },
  {
    id: "stirrups", label: "Estribos", art: "generic_horse_equip_stirrup",
    styles: [
      ["safety", "Segurança", 1, 10],
      ["deep_roper", "Roper Fundo", 1, 6],
      ["tapaderos", "Tapaderos", 1, 15],
      ["barroque", "Barroco", 1, 13],
      ["hooded", "Encapuzado", 1, 10],
    ],
  },
  {
    id: "bedrolls", label: "Rolos de Dormir", art: "generic_horse_equip_bedroll",
    styles: [
      ["wool", "Lã", 11, 5],
      ["canvas", "Lona", 9, 3],
      ["padded_wool", "Lã Acolchoada", 10, 7.7],
    ],
  },
  {
    id: "manes", label: "Crinas", art: "generic_horse_equip_mane",
    styles: [
      ["mane_regular", "Comum", 16, 1],
      ["mane_short", "Curta", 17, 1],
      ["mane_long", "Longa", 17, 1],
      ["mane_braid", "Trançada", 17, 1],
      ["mane_dreads", "Dreads", 17, 1],
    ],
  },
  {
    id: "tails", label: "Caudas", art: "generic_horse_equip_tail",
    styles: [
      ["tail_regular", "Comum", 18, 1],
      ["tail_short", "Curta", 18, 1],
      ["tail_long", "Longa", 16, 1],
      ["tail_braid", "Trançada", 16, 1],
    ],
  },
  { id: "masks", label: "Máscaras", art: "generic_horse_equip_mask", styles: [["mask_all", "Máscara de Guerra", 40, 45]] },
  { id: "lanterns", label: "Lanternas", art: "generic_horse_equip_lantern", styles: [["lantern", "Lanterna de Sela", 1, 35]] },
].map((c) => ({
  ...c,
  styles: c.styles.map(([id, label, variants, price]) => ({ id, label, variants, price })),
}));

const arabian = HORSES.find((h) => h.model === "A_C_Horse_Arabian_White");
const kentucky = HORSES.find((h) => h.model === "A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC");
const wagon = CARTS.find((c) => c.model === "wagon02x");

export const MOCK = {
  stable: { id: "valentine", name: "Valentine", region: "Heartlands · New Hanover", keeper: "Cavalariço Abe Pruitt" },
  player: { cash: 1184.5, gold: 12, name: "Arthur Morgan" },
  limits: { horse: 3, cart: 1, name: { min: 2, max: 20 }, transferMax: 99999 },
  shop: { horses: HORSES, carts: CARTS },
  tack: TACK,
  rides: [
    {
      id: 11, type: "horse", name: "Tempestade", model: arabian.model, breed: arabian.breed, coat: arabian.coat,
      active: true, bond: 3, xp: 2140, xpNext: 3000, health: 92, injured: 0,
      stats: arabian.stats, capacity: arabian.capacity,
      gear: {
        saddles: { style: "kneller_dakota", variant: 2 },
        blankets: { style: "owanjila", variant: 4 },
        stirrups: { style: "tapaderos", variant: 1 },
        bags: { style: "standard", variant: 7 },
        manes: { style: "mane_braid", variant: 3 },
      },
    },
    {
      id: 12, type: "horse", name: "Poeira", model: kentucky.model, breed: kentucky.breed, coat: kentucky.coat,
      active: false, bond: 1, xp: 380, xpNext: 1000, health: 64, injured: 102,
      stats: kentucky.stats, capacity: kentucky.capacity,
      gear: { saddles: { style: "gerden_trail", variant: 5 } },
    },
    {
      id: 21, type: "cart", name: "Velha Rosa", model: wagon.model, label: wagon.label,
      active: true, health: 81, injured: 0, seats: wagon.seats, capacity: wagon.capacity, stats: wagon.stats, gear: {},
    },
  ],
  // Arreios que o personagem já comprou: "categoria:estilo:variação"
  ownedTack: [
    "saddles:kneller_dakota:2", "saddles:gerden_trail:5", "saddles:lumley_mcclelland:1",
    "blankets:owanjila:4", "blankets:siltwater:1", "stirrups:tapaderos:1",
    "bags:standard:7", "manes:mane_braid:3",
  ],
  // Propostas de transferência recebidas (o animal só muda de dono ao aceitar)
  incoming: [
    {
      id: "t-301", type: "horse", rideName: "Relâmpago", breed: "Turcomano", coat: "Dourado",
      from: "Sadie Adler", price: 400, bond: 2,
    },
  ],
  // Personagens para quem dá para transferir (o servidor decide quem aparece)
  characters: [
    { id: 4, name: "Sadie Adler", online: true },
    { id: 7, name: "Charles Smith", online: true },
    { id: 9, name: "John Marston", online: false },
    { id: 12, name: "Javier Escuella", online: true },
    { id: 15, name: "Hosea Matthews", online: false },
    { id: 18, name: "Lenny Summers", online: true },
    { id: 21, name: "Bill Williamson", online: false },
    { id: 26, name: "Mary-Beth Gaskill", online: true },
  ],
};

