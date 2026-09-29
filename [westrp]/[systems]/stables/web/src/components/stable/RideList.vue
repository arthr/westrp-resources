<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { fmtClock } from "../../lib/format.js";
import { Icon, Tag } from "../kit";
import ListRow from "../common/ListRow.vue";
import GroupLabel from "../common/GroupLabel.vue";
import BondMeter from "../common/BondMeter.vue";

// Seus animais por tipo, com as vagas livres no fim de cada grupo
const stable = useStable();
const d = computed(() => stable.state.data);
const current = computed(() => stable.selectedRide.value?.id);

const groups = computed(() => [
  { type: "horse", label: "Cavalos", icon: "itemtype-horse", items: stable.horses.value, limit: d.value.limits.horse },
  { type: "cart", label: "Carroças", icon: "itemtype-coach", items: stable.carts.value, limit: d.value.limits.cart },
]);
const sub = (r) => (r.type === "horse" ? `${r.breed} · ${r.coat}` : r.label);
const goShop = (type) => {
  stable.state.shopKind = type;
  stable.state.shopSel = null;
  stable.setTab("shop");
};
</script>

<template>
  <div class="min-h-0 flex-1 overflow-y-auto pr-2">
    <template v-for="g in groups" :key="g.type">
      <GroupLabel :label="g.label" :hint="`${g.items.length} de ${g.limit}`" />
      <div class="flex flex-col gap-1">
        <ListRow
          v-for="r in g.items"
          :key="r.id"
          :title="r.name"
          :sub="sub(r)"
          :current="r.id === current"
          @click="stable.state.rideSel = r.id"
        >
          <template #lead>
            <Icon :name="g.icon" :size="20" :class="r.id === current ? '' : 'text-dim'" />
          </template>
          <template #trail>
            <Tag v-if="stable.injuredLeft(r) > 0" kind="warning">Ferido {{ fmtClock(stable.injuredLeft(r)) }}</Tag>
            <Tag v-else-if="r.active" kind="active">Ativo</Tag>
            <BondMeter v-if="r.type === 'horse'" :level="r.bond" :size="14" :on-accent="r.id === current" />
          </template>
        </ListRow>
        <ListRow
          v-for="n in Math.max(0, g.limit - g.items.length)"
          :key="`free-${g.type}-${n}`"
          inactive
          title="Vaga livre"
          :sub="g.type === 'horse' ? 'Compre um cavalo na loja' : 'Compre uma carroça na loja'"
          @click="goShop(g.type)"
        >
          <template #lead>
            <Icon :name="g.icon" :size="20" class="opacity-40" />
          </template>
        </ListRow>
      </div>
    </template>
  </div>
</template>
