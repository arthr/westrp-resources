import { computed, inject, onBeforeUnmount, onMounted, provide, reactive, ref, watch } from "vue";
import { MOCK } from "./mock.js";
import { applyTheme, isHex } from "../lib/theme.js";
import { TABS } from "../lib/labels.js";
import { fmtCash } from "../lib/format.js";

// Estado do estábulo. Quem manda nos dados é o servidor: no jogo eles chegam
// no "open" / "update"; na prévia do navegador vêm do mock.js e as ações são
// simuladas aqui mesmo, para a interface poder ser testada sem o RedM.

const KEY = Symbol("stable");
const clone = (v) => JSON.parse(JSON.stringify(v));
const tackKey = (cat, style, variant) => `${cat}:${style}:${variant}`;

export function useStable() {
  return inject(KEY);
}

export function provideStable() {
  // lido na hora (nunca no topo do módulo): na prévia não existe RedM
  const isGame = !!(window.rsmNui && window.rsmNui.isGame);
  const post = (name, data) => window.rsmNui.post(name, data);

  const state = reactive({
    open: !isGame,
    data: isGame ? null : clone(MOCK),
    receivedAt: Date.now(),
    tab: "shop",
    shopKind: "horse",
    shopSel: null,
    shopQuery: "",
    rideSel: null,
    tack: { rideId: null, cat: "saddles", style: null, variant: 1 },
    transferSel: null, // { kind: "offer" | "ride", id }
    dialog: null,
    toast: null,
    busy: false,
    demo: false, // true = aberto no jogo sem dados do servidor
  });

  // ── relógio (contagem de cavalo ferido) ─────────────────────────────────
  const now = ref(Date.now());
  let ticker = 0;
  onMounted(() => {
    ticker = setInterval(() => {
      if (state.open) now.value = Date.now();
    }, 1000);
  });
  onBeforeUnmount(() => clearInterval(ticker));
  const injuredLeft = (ride) => Math.max(0, (ride.injured || 0) - (now.value - state.receivedAt) / 1000);

  // ── dados derivados ─────────────────────────────────────────────────────
  const d = computed(() => state.data);
  const rides = computed(() => {
    const list = d.value ? [...d.value.rides] : [];
    return list.sort((a, b) => (a.type === b.type ? Number(b.active) - Number(a.active) : a.type === "horse" ? -1 : 1));
  });
  const horses = computed(() => rides.value.filter((r) => r.type === "horse"));
  const carts = computed(() => rides.value.filter((r) => r.type === "cart"));
  // Regras que o servidor manda junto (config.lua): tamanho do nome e preço máximo
  const nameRule = computed(() => d.value?.limits?.name ?? { min: 2, max: 20 });
  const transferMax = computed(() => d.value?.limits?.transferMax ?? 99999);
  const slotsLeft = (type) => {
    if (!d.value) return 0;
    const used = type === "horse" ? horses.value.length : carts.value.length;
    return Math.max(0, (d.value.limits[type] || 0) - used);
  };

  const shopList = computed(() => {
    if (!d.value) return [];
    const list = state.shopKind === "horse" ? d.value.shop.horses : d.value.shop.carts;
    const q = state.shopQuery.trim().toLowerCase();
    if (!q) return list;
    return list.filter((it) => `${it.breed ?? ""} ${it.coat ?? ""} ${it.label ?? ""}`.toLowerCase().includes(q));
  });
  const shopItem = computed(
    () => shopList.value.find((it) => it.model === state.shopSel) ?? shopList.value[0] ?? null,
  );

  const selectedRide = computed(() => rides.value.find((r) => r.id === state.rideSel) ?? rides.value[0] ?? null);

  const tackRide = computed(
    () => horses.value.find((r) => r.id === state.tack.rideId) ?? horses.value.find((r) => r.active) ?? horses.value[0] ?? null,
  );
  const tackCat = computed(() => d.value?.tack.find((c) => c.id === state.tack.cat) ?? d.value?.tack[0] ?? null);
  const tackStyle = computed(() => {
    const c = tackCat.value;
    if (!c) return null;
    return c.styles.find((s) => s.id === state.tack.style) ?? null;
  });
  const ownsTack = (cat, style, variant) => !!d.value?.ownedTack.includes(tackKey(cat, style, variant));
  const equippedOn = (ride, cat) => (ride && ride.gear ? ride.gear[cat] ?? null : null);

  const offers = computed(() => d.value?.incoming ?? []);
  const transferItem = computed(() => {
    const sel = state.transferSel;
    if (sel?.kind === "offer") {
      const o = offers.value.find((x) => x.id === sel.id);
      if (o) return { kind: "offer", item: o };
    }
    if (sel?.kind === "ride") {
      const r = rides.value.find((x) => x.id === sel.id);
      if (r) return { kind: "ride", item: r };
    }
    if (offers.value[0]) return { kind: "offer", item: offers.value[0] };
    return rides.value[0] ? { kind: "ride", item: rides.value[0] } : null;
  });

  // ── o que a câmera mostra ───────────────────────────────────────────────
  // O cliente cria o animal de exibição a partir disto; mandamos só quando muda.
  const stage = computed(() => {
    if (!d.value) return null;
    if (state.tab === "shop") return shopItem.value && { kind: "shop", type: state.shopKind, model: shopItem.value.model };
    if (state.tab === "stable") return selectedRide.value && { kind: "ride", id: selectedRide.value.id };
    if (state.tab === "tack") {
      const r = tackRide.value;
      if (!r) return null;
      const s = tackStyle.value;
      return { kind: "ride", id: r.id, tack: s ? { cat: tackCat.value.id, style: s.id, variant: state.tack.variant } : null };
    }
    const t = transferItem.value;
    if (!t) return null;
    return t.kind === "offer" ? { kind: "offer", id: t.item.id } : { kind: "ride", id: t.item.id };
  });
  let stageTimer = 0;
  watch(
    () => (state.open ? JSON.stringify(stage.value) : null),
    (key) => {
      clearTimeout(stageTimer);
      if (!key || key === "null") return;
      stageTimer = setTimeout(() => post("preview", stage.value), 160);
    },
  );
  onBeforeUnmount(() => clearTimeout(stageTimer));

  // ── avisos da prévia ────────────────────────────────────────────────────
  // No jogo o resultado de cada ação volta como notificação do rsm_nuikit
  // (exports.rsm_nuikit:Notify, disparada pelo servidor); aqui só simulamos.
  let toastTimer = 0;
  const toast = (kind, title, body) => {
    if (isGame) return;
    clearTimeout(toastTimer);
    state.toast = { kind, title, body, id: Date.now() };
    toastTimer = setTimeout(() => {
      state.toast = null;
    }, 3400);
  };
  onBeforeUnmount(() => clearTimeout(toastTimer));

  // No jogo cada ação espera a resposta do servidor ("update"); o limite
  // de tempo garante que a interface nunca fica travada esperando.
  let busyTimer = 0;
  const send = (name, payload) => {
    if (!isGame) return false;
    state.busy = true;
    clearTimeout(busyTimer);
    busyTimer = setTimeout(() => {
      state.busy = false;
    }, 8000);
    post(name, payload);
    return true;
  };
  onBeforeUnmount(() => clearTimeout(busyTimer));

  // ── ações ───────────────────────────────────────────────────────────────
  let nextId = 900;

  // currency: "cash" | "gold" (ouro só quando o servidor dá preço em ouro)
  const buy = (item, name, currency = "cash") => {
    const type = state.shopKind;
    const clean = name.trim();
    if (send("buy", { type, model: item.model, name: clean, currency })) return;
    const data = state.data;
    if (slotsLeft(type) <= 0) return toast("error", "Estábulo cheio", "Liberte um animal ou compre mais vagas.");
    if (currency === "gold") {
      if (data.player.gold < item.gold) return toast("error", "Ouro insuficiente", `A raça pede ${item.gold} de ouro.`);
      data.player.gold -= item.gold;
    } else {
      if (data.player.cash < item.price) return toast("error", "Dinheiro insuficiente", `Faltam ${fmtCash(item.price - data.player.cash)}.`);
      data.player.cash -= item.price;
    }
    const ride = {
      id: nextId++, type, name: clean, model: item.model, active: false, health: 100, injured: 0,
      stats: item.stats, capacity: item.capacity, gear: {},
      ...(type === "horse"
        ? { breed: item.breed, coat: item.coat, bond: 0, xp: 0, xpNext: 1000 }
        : { label: item.label, seats: item.seats }),
    };
    if (!data.rides.some((r) => r.type === type && r.active)) ride.active = true;
    data.rides.push(ride);
    toast("success", "Compra concluída", `${clean} agora está no seu estábulo.`);
    state.rideSel = ride.id;
    state.tab = "stable";
  };

  const setActive = (ride) => {
    if (send("setActive", { id: ride.id })) return;
    state.data.rides.forEach((r) => {
      if (r.type === ride.type) r.active = r.id === ride.id;
    });
    toast("success", "Animal ativo", `${ride.name} atende quando você chamar.`);
  };

  const rename = (ride, name) => {
    if (send("rename", { id: ride.id, name })) return;
    const r = state.data.rides.find((x) => x.id === ride.id);
    if (r) r.name = name;
    toast("info", "Nome alterado", `Agora ele se chama ${name}.`);
  };

  const release = (ride) => {
    if (send("release", { id: ride.id })) return;
    state.data.rides = state.data.rides.filter((r) => r.id !== ride.id);
    if (ride.active) {
      const next = state.data.rides.find((r) => r.type === ride.type);
      if (next) next.active = true;
    }
    state.rideSel = null;
    toast("warning", "Animal libertado", `${ride.name} não pertence mais a você.`);
  };

  const tackBuy = (ride, cat, style, variant) => {
    if (send("tackBuy", { id: ride.id, cat: cat.id, style: style.id, variant })) return;
    if (state.data.player.cash < style.price) return toast("error", "Dinheiro insuficiente", `Faltam ${fmtCash(style.price - state.data.player.cash)}.`);
    state.data.player.cash -= style.price;
    state.data.ownedTack.push(tackKey(cat.id, style.id, variant));
    tackEquip(ride, cat, style, variant, true);
    toast("success", "Arreio comprado", `${style.label} equipado em ${ride.name}.`);
  };

  const tackEquip = (ride, cat, style, variant, silent = false) => {
    if (!silent && send("tackEquip", { id: ride.id, cat: cat.id, style: style.id, variant })) return;
    const r = state.data.rides.find((x) => x.id === ride.id);
    if (r) r.gear = { ...r.gear, [cat.id]: { style: style.id, variant } };
    if (!silent) toast("info", "Arreio equipado", `${style.label} em ${ride.name}.`);
  };

  const tackRemove = (ride, catId) => {
    if (send("tackRemove", { id: ride.id, cat: catId })) return;
    const r = state.data.rides.find((x) => x.id === ride.id);
    if (!r) return;
    const gear = { ...r.gear };
    delete gear[catId];
    r.gear = gear;
  };

  const tackRemoveAll = (ride) => {
    if (send("tackRemoveAll", { id: ride.id })) return;
    const r = state.data.rides.find((x) => x.id === ride.id);
    if (r) r.gear = {};
    toast("info", "Arreios removidos", `${ride.name} está sem equipamento.`);
  };

  const transferSend = (ride, target, price) => {
    if (send("transferSend", { id: ride.id, target: target.id, price })) return;
    toast("success", "Proposta enviada", `${target.name} recebeu a proposta por ${ride.name}.`);
  };

  const transferAnswer = (offer, accept) => {
    if (send("transferAnswer", { id: offer.id, accept })) return;
    const data = state.data;
    if (accept) {
      if (slotsLeft(offer.type) <= 0) return toast("error", "Estábulo cheio", "Não há vaga para receber este animal.");
      if (data.player.cash < offer.price) return toast("error", "Dinheiro insuficiente", `A proposta pede ${fmtCash(offer.price)}.`);
      data.player.cash -= offer.price;
      const base = data.shop.horses.find((h) => h.breed === offer.breed) ?? data.shop.horses[0];
      data.rides.push({
        id: nextId++, type: offer.type, name: offer.rideName, model: base.model, breed: offer.breed, coat: offer.coat,
        active: false, bond: offer.bond ?? 0, xp: 0, xpNext: 1000, health: 100, injured: 0, stats: base.stats,
        capacity: base.capacity, gear: {},
      });
      toast("success", "Transferência aceita", `${offer.rideName} agora é seu.`);
    } else {
      toast("info", "Proposta recusada", `${offer.from} foi avisado.`);
    }
    data.incoming = data.incoming.filter((o) => o.id !== offer.id);
    state.transferSel = null;
  };

  // ── navegação ───────────────────────────────────────────────────────────
  const setTab = (tab) => {
    state.tab = tab;
    state.dialog = null;
  };
  const stepTab = (dir) => {
    const i = TABS.findIndex((t) => t.value === state.tab);
    setTab(TABS[(i + dir + TABS.length) % TABS.length].value);
  };
  const openTack = (ride) => {
    state.tack.rideId = ride.id;
    state.tack.style = null;
    setTab("tack");
  };
  const openTransfer = (ride) => {
    state.transferSel = { kind: "ride", id: ride.id };
    setTab("transfer");
  };

  const close = () => {
    state.dialog = null;
    state.open = false;
    window.rsmNui.close();
  };
  const reopen = () => {
    state.open = true;
  };

  // ── mensagens do cliente ────────────────────────────────────────────────
  const theme = (t) => {
    if (!t || !isHex(t.accent) || !isHex(t.surface) || !isHex(t.text)) return;
    applyTheme({ accent: t.accent, surface: t.surface, text: t.text, surfaceAlpha: Number(t.surfaceAlpha) || 93 });
  };
  const onMessage = (e) => {
    const msg = e && e.data;
    if (!msg || typeof msg !== "object") return;
    switch (msg.action) {
      case "open":
        // sem dados do servidor (etapa só de interface) a tela abre com a
        // demonstração, nunca vazia: foco sem painel visível trava o jogador
        state.demo = !msg.data;
        if (msg.data) state.data = msg.data;
        else if (!state.data) state.data = clone(MOCK);
        state.receivedAt = Date.now();
        state.tab = TABS.some((t) => t.value === msg.tab) ? msg.tab : "shop";
        state.shopSel = null;
        state.rideSel = null;
        state.transferSel = null;
        state.tack.rideId = null;
        state.tack.style = null;
        state.dialog = null;
        state.busy = false;
        state.open = true;
        theme(msg.theme);
        break;
      case "update":
        if (state.data && msg.data) Object.assign(state.data, msg.data);
        if (msg.data && msg.data.rides) state.receivedAt = Date.now();
        // animal recém-chegado (compra, transferência): abre a ficha dele
        if (msg.focus != null && state.data?.rides.some((r) => r.id === msg.focus)) {
          state.rideSel = msg.focus;
          setTab("stable");
        }
        state.busy = false;
        break;
      case "busy":
        state.busy = msg.busy === true;
        break;
      case "theme":
        theme(msg.theme);
        break;
      case "close":
        state.dialog = null;
        state.open = false;
        break;
    }
  };
  onMounted(() => window.addEventListener("message", onMessage));
  onBeforeUnmount(() => window.removeEventListener("message", onMessage));

  const api = {
    state,
    isGame,
    now,
    rides,
    horses,
    carts,
    shopList,
    shopItem,
    selectedRide,
    tackRide,
    tackCat,
    tackStyle,
    offers,
    transferItem,
    slotsLeft,
    nameRule,
    transferMax,
    injuredLeft,
    ownsTack,
    equippedOn,
    post,
    toast,
    buy,
    setActive,
    rename,
    release,
    tackBuy,
    tackEquip,
    tackRemove,
    tackRemoveAll,
    transferSend,
    transferAnswer,
    setTab,
    stepTab,
    openTack,
    openTransfer,
    close,
    reopen,
  };
  provide(KEY, api);
  return api;
}
