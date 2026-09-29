<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { useWide } from "../../lib/useWide.js";
import { ArrowSelector, Button, ItemSlot, Tag } from "../kit";
import ListRow from "../common/ListRow.vue";
import GroupLabel from "../common/GroupLabel.vue";
import PriceLine from "../common/PriceLine.vue";
import EmptyState from "../common/EmptyState.vue";

// Qual cavalo vestir, a categoria (arte do jogo) e os estilos dela
const stable = useStable();
const wide = useWide();
const d = computed(() => stable.state.data);
const ride = computed(() => stable.tackRide.value);
const cat = computed(() => stable.tackCat.value);

const rideId = computed({
  get: () => ride.value?.id ?? null,
  set: (id) => {
    stable.state.tack.rideId = id;
    stable.state.tack.style = null;
  },
});
const rideOptions = computed(() => stable.horses.value.map((h) => ({ value: h.id, label: h.name })));

// Ao escolher um estilo, a variação começa na que está equipada (se estiver)
const pickCat = (c) => {
  stable.state.tack.cat = c.id;
  stable.state.tack.style = null;
};
const pickStyle = (s) => {
  const eq = stable.equippedOn(ride.value, cat.value.id);
  stable.state.tack.style = s.id;
  stable.state.tack.variant = eq && eq.style === s.id ? eq.variant : 1;
};

const equipped = computed(() => stable.equippedOn(ride.value, cat.value?.id));
const ownedAny = (s) => d.value.ownedTack.some((k) => k.startsWith(`${cat.value.id}:${s.id}:`));
const catSlots = computed(() => d.value.tack.map((c) => ({ ...c, item: { img: c.art, name: c.label } })));
</script>

<template>
  <div v-if="ride" class="flex min-h-0 flex-1 flex-col gap-4">
    <div class="flex items-center justify-between gap-4">
      <span class="kit-heading text-[11px] text-dim">Cavalo</span>
      <ArrowSelector v-model="rideId" :options="rideOptions" width="11rem" :disabled="rideOptions.length < 2" />
    </div>

    <div class="grid grid-cols-5 justify-items-center gap-2">
      <ItemSlot
        v-for="c in catSlots"
        :key="c.id"
        :item="c.item"
        :size="wide ? 68 : 56"
        :selected="c.id === cat.id"
        @click="pickCat(c)"
      />
    </div>

    <GroupLabel :label="cat.label">
      <span v-if="equipped" class="truncate">Equipado: {{ cat.styles.find((s) => s.id === equipped.style)?.label ?? equipped.style }}</span>
      <span v-else>Nada equipado</span>
    </GroupLabel>

    <div class="-mt-2 flex min-h-0 flex-1 flex-col gap-1 overflow-y-auto pr-2">
      <ListRow
        v-for="s in cat.styles"
        :key="s.id"
        :title="s.label"
        :sub="s.variants > 1 ? `${s.variants} cores` : 'Cor única'"
        :current="s.id === stable.state.tack.style"
        @click="pickStyle(s)"
      >
        <template #trail>
          <Tag v-if="equipped && equipped.style === s.id" kind="active">Equipado</Tag>
          <Tag v-else-if="ownedAny(s)">Adquirido</Tag>
          <PriceLine v-else :price="s.price" short />
        </template>
      </ListRow>
    </div>
  </div>
  <EmptyState v-else icon="itemtype-horse" title="Nenhum cavalo" body="Arreios são para cavalos. Compre um na loja para começar a equipá-lo.">
    <Button size="sm" variant="primary" @click="stable.setTab('shop')">Ir para a loja</Button>
  </EmptyState>
</template>
