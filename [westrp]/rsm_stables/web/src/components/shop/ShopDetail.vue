<script setup>
import { computed, ref, watch } from "vue";
import { useStable } from "../../state/stable.js";
import { CART_STATS, HORSE_STATS, RIDE_CLASS } from "../../lib/labels.js";
import { fmtCash } from "../../lib/format.js";
import { HoldPrompt, Icon, ProgressBar, Switch, Tag, TextInput } from "../kit";
import DetailHead from "../common/DetailHead.vue";
import SectionLabel from "../common/SectionLabel.vue";
import StatList from "../common/StatList.vue";
import PriceLine from "../common/PriceLine.vue";
import EmptyState from "../common/EmptyState.vue";

// Ficha do animal à venda + compra (nome, moeda e segurar para comprar)
const stable = useStable();
const d = computed(() => stable.state.data);
const item = computed(() => stable.shopItem.value);
const isHorse = computed(() => stable.state.shopKind === "horse");

const name = ref("");
const payCash = ref(true);
watch(
  () => item.value?.model,
  () => {
    name.value = "";
    payCash.value = true;
  },
);
// Nome: letras, espaço, hífen e apóstrofo, no tamanho que o servidor aceita
const rule = computed(() => stable.nameRule.value);
const nameModel = computed({
  get: () => name.value,
  set: (v) => {
    name.value = v.replace(/[^\p{L}\s'-]/gu, "").replace(/\s{2,}/g, " ").slice(0, rule.value.max);
  },
});

const free = computed(() => stable.slotsLeft(stable.state.shopKind));
const blocker = computed(() => {
  const it = item.value;
  if (!it) return null;
  if (free.value <= 0) return `Sem vaga para ${isHorse.value ? "cavalos" : "carroças"}: liberte um animal primeiro.`;
  if (payCash.value && d.value.player.cash < it.price) return `Dinheiro insuficiente: faltam ${fmtCash(it.price - d.value.player.cash)}.`;
  if (!payCash.value && d.value.player.gold < it.gold) return `Ouro insuficiente: faltam ${it.gold - d.value.player.gold}.`;
  return null;
});
const ready = computed(() => !blocker.value && name.value.trim().length >= rule.value.min && !stable.state.busy);

const buy = () => {
  if (!ready.value) return;
  stable.buy(item.value, name.value, payCash.value ? "cash" : "gold");
  name.value = "";
};
</script>

<template>
  <div v-if="item" class="flex min-h-0 flex-1 flex-col gap-6">
    <DetailHead
      :kicker="isHorse ? `Cavalo · ${RIDE_CLASS[item.cls]}` : `Carroça · ${RIDE_CLASS[item.cls]}`"
      :title="isHorse ? item.breed : item.label"
      :sub="isHorse ? item.coat : item.model"
    >
      <template #right>
        <Tag v-if="item.cls === 'elite'" kind="new">Elite</Tag>
      </template>
    </DetailHead>

    <div class="flex min-h-0 flex-1 flex-col gap-6 overflow-y-auto pr-2">
      <section class="flex flex-col gap-4">
        <SectionLabel label="Atributos" />
        <StatList :stats="item.stats" :rows="isHorse ? HORSE_STATS : CART_STATS" />
      </section>
      <section class="tx-help flex flex-col gap-2.5 px-6 py-4 text-[14px]">
        <div class="flex items-baseline justify-between gap-4">
          <span class="text-dim">{{ isHorse ? "Carga do alforje" : "Carga" }}</span>
          <span class="font-cat text-[16px] text-ink">{{ item.capacity }}</span>
        </div>
        <div v-if="!isHorse" class="flex items-baseline justify-between gap-4">
          <span class="text-dim">Assentos</span>
          <span class="font-cat text-[16px] text-ink">{{ item.seats }}</span>
        </div>
        <div class="flex items-baseline justify-between gap-4">
          <span class="text-dim">Vagas livres</span>
          <span :class="['font-cat text-[16px]', free > 0 ? 'text-ink' : 'text-accent']">{{ free }} de {{ d.limits[stable.state.shopKind] }}</span>
        </div>
      </section>
    </div>

    <div class="flex shrink-0 flex-col gap-4">
      <PriceLine :price="item.price" :gold="item.gold" />
      <TextInput v-model="nameModel" :placeholder="isHorse ? 'Dê um nome ao cavalo' : 'Dê um nome à carroça'" :max-length="rule.max" />
      <div v-if="item.gold != null" class="flex items-center justify-between gap-4">
        <span class="text-[13px] text-dim">Pagar com</span>
        <Switch v-model="payCash" :labels="['Dinheiro', 'Ouro']" />
      </div>
      <p v-if="blocker" class="flex items-center gap-2 text-[12px] text-accent">
        <Icon name="menu-icon-info-warning" :size="14" />
        {{ blocker }}
      </p>
      <ProgressBar v-if="stable.state.busy" />
      <HoldPrompt class="self-center" label="Segurar para comprar" :disabled="!ready" @complete="buy" />
    </div>
  </div>
  <EmptyState v-else icon="blip-shop-horse" title="Escolha um animal" body="Selecione um cavalo ou carroça na lista para ver a ficha." />
</template>
