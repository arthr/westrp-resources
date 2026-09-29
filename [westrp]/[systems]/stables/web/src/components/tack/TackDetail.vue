<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { fmtCash } from "../../lib/format.js";
import { ArrowSelector, Button, Divider, HoldPrompt, Icon, IconButton, ProgressBar, Tag } from "../kit";
import DetailHead from "../common/DetailHead.vue";
import SectionLabel from "../common/SectionLabel.vue";
import PriceLine from "../common/PriceLine.vue";
import EmptyState from "../common/EmptyState.vue";

// Peça escolhida: cor, situação (comprada / equipada) e o que está no cavalo
const stable = useStable();
const d = computed(() => stable.state.data);
const ride = computed(() => stable.tackRide.value);
const cat = computed(() => stable.tackCat.value);
const style = computed(() => stable.tackStyle.value);

const variant = computed({
  get: () => stable.state.tack.variant,
  set: (v) => {
    stable.state.tack.variant = v;
  },
});
const variants = computed(() =>
  style.value ? Array.from({ length: style.value.variants }, (_, i) => ({ value: i + 1, label: `Cor ${i + 1} de ${style.value.variants}` })) : [],
);

const owned = computed(() => !!style.value && stable.ownsTack(cat.value.id, style.value.id, variant.value));
const equipped = computed(() => {
  const eq = stable.equippedOn(ride.value, cat.value?.id);
  return !!eq && !!style.value && eq.style === style.value.id && eq.variant === variant.value;
});
const short = computed(() => (style.value && !owned.value ? Math.max(0, style.value.price - d.value.player.cash) : 0));

// Tudo o que está no cavalo agora, na ordem das categorias
const worn = computed(() => {
  const r = ride.value;
  if (!r) return [];
  return d.value.tack
    .filter((c) => r.gear && r.gear[c.id])
    .map((c) => {
      const g = r.gear[c.id];
      return { cat: c, label: c.styles.find((s) => s.id === g.style)?.label ?? g.style, variant: g.variant };
    });
});

const buy = () => stable.tackBuy(ride.value, cat.value, style.value, variant.value);
const equip = () => stable.tackEquip(ride.value, cat.value, style.value, variant.value);
const askRemoveAll = () => {
  const r = ride.value;
  stable.state.dialog = {
    kicker: "Arreios",
    title: `Tirar todos os arreios de ${r.name}?`,
    body: "As peças continuam compradas: dá para equipar de novo quando quiser, sem pagar.",
    confirm: "Tirar tudo",
    onConfirm: () => stable.tackRemoveAll(r),
  };
};
</script>

<template>
  <div v-if="ride && cat" class="flex min-h-0 flex-1 flex-col gap-6">
    <DetailHead
      :kicker="`${cat.label} · ${ride.name}`"
      :title="style ? style.label : cat.label"
      :sub="style ? (style.variants > 1 ? `${style.variants} cores disponíveis` : 'Cor única') : 'Escolha um estilo na lista'"
    >
      <template #right>
        <Tag v-if="equipped" kind="active">Equipado</Tag>
        <Tag v-else-if="owned">Adquirido</Tag>
      </template>
    </DetailHead>

    <div class="flex min-h-0 flex-1 flex-col gap-6 overflow-y-auto pr-2">
      <template v-if="style">
        <section v-if="style.variants > 1" class="flex flex-col gap-3">
          <SectionLabel label="Cor" />
          <div class="tx-help flex justify-center px-4 py-2.5">
            <ArrowSelector v-model="variant" :options="variants" width="11rem" />
          </div>
        </section>
        <p class="text-[13px] leading-relaxed text-faint">
          A peça aparece no cavalo enquanto você navega. Se sair sem comprar ou equipar, ele volta como estava.
        </p>
      </template>

      <section class="flex flex-col gap-3">
        <SectionLabel label="No cavalo agora">{{ worn.length }} de {{ d.tack.length }}</SectionLabel>
        <div v-if="worn.length" class="flex flex-col">
          <template v-for="(w, i) in worn" :key="w.cat.id">
            <Divider v-if="i > 0" class="opacity-50" />
            <div class="flex items-center gap-3 py-2">
              <span class="w-32 shrink-0 truncate text-[13px] text-dim">{{ w.cat.label }}</span>
              <span class="min-w-0 flex-1 truncate text-[13px] text-ink">{{ w.label }} <span class="text-faint">· cor {{ w.variant }}</span></span>
              <IconButton icon="cross" :label="`Tirar ${w.cat.label}`" :size="28" @click="stable.tackRemove(ride, w.cat.id)" />
            </div>
          </template>
        </div>
        <p v-else class="text-[13px] text-faint">Nenhum arreio equipado.</p>
      </section>
    </div>

    <div class="flex shrink-0 flex-col gap-3">
      <ProgressBar v-if="stable.state.busy" />
      <template v-if="style">
        <PriceLine v-if="!owned" :price="style.price" />
        <p v-if="short > 0" class="flex items-center gap-2 text-[12px] text-accent">
          <Icon name="menu-icon-info-warning" :size="14" />
          Dinheiro insuficiente: faltam {{ fmtCash(short) }}.
        </p>
        <Button v-if="equipped" @click="stable.tackRemove(ride, cat.id)">Tirar {{ cat.label.toLowerCase() }}</Button>
        <Button v-else-if="owned" variant="primary" :disabled="stable.state.busy" @click="equip">Equipar em {{ ride.name }}</Button>
        <HoldPrompt v-else class="self-center" label="Segurar para comprar e equipar" :disabled="short > 0 || stable.state.busy" @complete="buy" />
      </template>
      <Button v-if="worn.length" variant="ghost" size="sm" icon="cross" @click="askRemoveAll">Tirar todos os arreios</Button>
    </div>
  </div>
  <EmptyState v-else icon="itemtype-horse" title="Nada para equipar" body="Compre um cavalo para começar a escolher arreios." />
</template>
