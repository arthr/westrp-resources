import { reactive } from "vue";
import { IS_GAME } from "../nui.js";
import { MIRROR } from "../mirror.js";

// Everything the HUD displays. The client pushes partial updates with
// SendNUIMessage({ action = "hud:update", data = { ... } }) and they are merged
// in here; until then these placeholder values keep the preview alive.
export const hud = reactive({
  visible: true,
  player: {
    id: 27,
    name: "Silas Whitlock",
    job: "Delegado",
    employer: "Grau 2",
  },
  // Every core has an inner core (0-100) and an outer ring (0-100), like RDR2.
  cores: {
    // goldCore / goldRing: núcleo / atributo fortificado (Golden Core, lido das natives);
    // *Ending: o efeito está nos últimos segundos. Na prévia, a vida mostra o núcleo
    // dourado e o Olho Morto o anel dourado.
    health: { core: 82, ring: 64, goldCore: true, goldRing: false, goldCoreEnding: false, goldRingEnding: false },
    stamina: { core: 70, ring: 46, goldCore: false, goldRing: false, goldCoreEnding: false, goldRingEnding: false },
    deadeye: { core: 91, ring: 28, goldCore: false, goldRing: true, goldCoreEnding: false, goldRingEnding: false },
  },
  horse: {
    mounted: true,
    name: "Juniper",
    breed: "Kentucky Saddler",
    bond: 3,
    health: { core: 88, ring: 74 },
    stamina: { core: 61, ring: 52 },
  },
  // 0-100, ou false quando a necessidade está desligada no servidor.
  // Fome / sede / higiene se esgotam; estresse / embriaguez se acumulam.
  needs: {
    hunger: 18,
    thirst: 41,
    stress: 22,
    hygiene: 76,
    alcohol: 12,
  },
  money: { cash: 142.35, gold: 3.4 },
  world: {
    time: "07:42",
    day: "Terça-feira",
    weather: "Neblina",
    temperature: 11,
    unit: "C",
  },
  location: { town: "Valentine", region: "New Hanover" },
  // range: 1 whisper, 2 normal, 3 shout
  voice: { range: 2, talking: false },
  weapon: {
    drawn: true,
    name: "Revólver Cattleman",
    icon: "weapon_revolver_cattleman",
    clip: 5,
    clipSize: 6,
    reserve: 48,
  },
  wanted: { bounty: 25, region: "New Hanover" },
  effects: ["cold", "wounded"],
});

const isObj = (v) => v !== null && typeof v === "object" && !Array.isArray(v);

function merge(target, patch) {
  for (const key of Object.keys(patch)) {
    const next = patch[key];
    if (isObj(next) && isObj(target[key])) merge(target[key], next);
    else target[key] = next;
  }
}

const clone = (v) => JSON.parse(JSON.stringify(v));
// Os valores de exemplo acima, guardados antes de o jogo limpar tudo. Servem à
// prévia do rsm_nuikit (showSamples) e ao espelho. `visible` fica de fora: quem
// manda nele é o client (hud:show / hud:hide).
const SAMPLE = clone(hud);
delete SAMPLE.visible;

// Durante a prévia o que o client mandar vai para esta cópia dos dados reais.
let live = null;

export function applyHudUpdate(patch) {
  if (isObj(patch)) merge(live ?? hud, patch);
}

// Prévia do rsm_nuikit ("Preview Placement"): por alguns segundos todos os
// elementos mostram os exemplos (cavalo, arma, recompensa…), para ver cada um no
// lugar. No fim os dados reais voltam, inclusive o que mudou nesse meio-tempo.
export function showSamples(on) {
  if (on && !live) {
    live = clone(hud);
    delete live.visible;
    merge(hud, clone(SAMPLE));
  } else if (!on && live) {
    const real = live;
    live = null;
    merge(hud, real);
  }
}

// Dentro do jogo nenhum dado de exemplo pode aparecer: tudo começa vazio e é
// preenchido pelo primeiro "hud:update" do client. O espelho é só exemplo.
if (IS_GAME && !MIRROR) {
  applyHudUpdate({
    player: { id: "", name: "", job: "", employer: "" },
    cores: {
      health: { goldCore: false, goldRing: false, goldCoreEnding: false, goldRingEnding: false },
      stamina: { goldCore: false, goldRing: false, goldCoreEnding: false, goldRingEnding: false },
      deadeye: { goldCore: false, goldRing: false, goldCoreEnding: false, goldRingEnding: false },
    },
    horse: { mounted: false, name: "", bond: 0 },
    needs: { hunger: false, thirst: false, stress: false, hygiene: false, alcohol: false },
    money: { cash: 0, gold: 0 },
    world: { time: "", day: "", weather: "", temperature: 0 },
    location: { town: "", region: "" },
    voice: { range: 2, talking: false },
    weapon: { drawn: false, name: "", icon: "", clip: 0, clipSize: 0, reserve: 0 },
    wanted: { bounty: 0, region: "" },
    effects: [],
  });
}

// Browser-preview only: keeps the placeholder HUD moving so every state is
// visible without a server. Returns a stop function.
export function startPreviewSimulation() {
  let t = 0;
  const id = setInterval(() => {
    t += 1;
    const [h, m] = hud.world.time.split(":").map(Number);
    const total = (h * 60 + m + 1) % 1440;
    hud.world.time = `${String(Math.floor(total / 60)).padStart(2, "0")}:${String(total % 60).padStart(2, "0")}`;

    hud.cores.stamina.ring = Math.round(52 + 44 * Math.sin(t / 5));
    hud.horse.stamina.ring = Math.round(56 + 38 * Math.cos(t / 4));
    hud.cores.deadeye.ring = hud.cores.deadeye.ring >= 100 ? 12 : hud.cores.deadeye.ring + 4;
    hud.cores.health.ring = Math.round(60 + 18 * Math.sin(t / 9));
    hud.voice.talking = t % 8 < 3;
    hud.needs.thirst = hud.needs.thirst <= 4 ? 64 : hud.needs.thirst - 1;
  }, 1000);
  return () => clearInterval(id);
}
