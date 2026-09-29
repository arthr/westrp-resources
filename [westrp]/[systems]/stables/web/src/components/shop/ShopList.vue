<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { RIDE_CLASS } from "../../lib/labels.js";
import { Tabs, Tag, TextInput } from "../kit";
import ListRow from "../common/ListRow.vue";
import GroupLabel from "../common/GroupLabel.vue";
import PriceLine from "../common/PriceLine.vue";
import EmptyState from "../common/EmptyState.vue";

// Catálogo deste estábulo: cavalos agrupados por raça, carroças numa lista só
const stable = useStable();
const d = computed(() => stable.state.data);

const kind = computed({
  get: () => stable.state.shopKind,
  set: (v) => {
    stable.state.shopKind = v;
    stable.state.shopSel = null;
  },
});
const kinds = computed(() => [
  { value: "horse", label: "Cavalos", count: d.value.shop.horses.length },
  { value: "cart", label: "Carroças", count: d.value.shop.carts.length },
]);
const query = computed({
  get: () => stable.state.shopQuery,
  set: (v) => {
    stable.state.shopQuery = v;
  },
});

const groups = computed(() => {
  const list = stable.shopList.value;
  if (!list.length) return [];
  if (stable.state.shopKind !== "horse") return [{ key: "carts", label: "Carroças e coches", cls: null, items: list }];
  const map = new Map();
  for (const h of list) {
    if (!map.has(h.breed)) map.set(h.breed, { key: h.breed, label: h.breed, cls: h.cls, items: [] });
    map.get(h.breed).items.push(h);
  }
  return [...map.values()];
});
const current = computed(() => stable.shopItem.value?.model);
const sub = (it) => (it.label ? `${RIDE_CLASS[it.cls] ?? ""} · ${it.seats} assentos · carga ${it.capacity}` : null);
</script>

<template>
  <div class="flex min-h-0 flex-1 flex-col gap-4">
    <Tabs v-model="kind" :items="kinds" size="sm" />
    <TextInput v-model="query" placeholder="Buscar raça, pelagem ou modelo" :max-length="30" />
    <div class="min-h-0 flex-1 overflow-y-auto pr-2">
      <template v-for="g in groups" :key="g.key">
        <GroupLabel :label="g.label">
          <Tag v-if="g.cls">{{ RIDE_CLASS[g.cls] }}</Tag>
        </GroupLabel>
        <div class="flex flex-col gap-1">
          <ListRow
            v-for="it in g.items"
            :key="it.model"
            :title="it.coat ?? it.label"
            :sub="sub(it)"
            :current="it.model === current"
            @click="stable.state.shopSel = it.model"
          >
            <template #trail>
              <PriceLine :price="it.price" short />
            </template>
          </ListRow>
        </div>
      </template>
      <EmptyState v-if="!groups.length" icon="blip-shop-horse" title="Nada encontrado" body="Nenhum animal deste estábulo combina com a busca." />
    </div>
  </div>
</template>
