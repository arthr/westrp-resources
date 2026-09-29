<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { Icon, Tag } from "../kit";
import ListRow from "../common/ListRow.vue";
import GroupLabel from "../common/GroupLabel.vue";
import PriceLine from "../common/PriceLine.vue";

// Propostas que chegaram para você e os seus animais que podem ser enviados
const stable = useStable();
const sel = computed(() => stable.transferItem.value);
const isCurrent = (kind, id) => sel.value?.kind === kind && sel.value.item.id === id;
const sub = (r) => (r.type === "horse" ? `${r.breed} · ${r.coat}` : r.label);
</script>

<template>
  <div class="min-h-0 flex-1 overflow-y-auto pr-2">
    <GroupLabel label="Propostas recebidas" :hint="String(stable.offers.value.length)" />
    <div class="flex flex-col gap-1">
      <ListRow
        v-for="o in stable.offers.value"
        :key="o.id"
        :title="o.rideName"
        :sub="`De ${o.from} · ${o.breed}`"
        :current="isCurrent('offer', o.id)"
        @click="stable.state.transferSel = { kind: 'offer', id: o.id }"
      >
        <template #lead>
          <Icon name="menu-icon-invite-sent" :size="20" :class="isCurrent('offer', o.id) ? '' : 'text-accent'" />
        </template>
        <template #trail>
          <PriceLine :price="o.price" short />
        </template>
      </ListRow>
      <p v-if="!stable.offers.value.length" class="px-1 py-2 text-[13px] text-faint">Nenhuma proposta no momento.</p>
    </div>

    <GroupLabel label="Enviar um animal" :hint="`${stable.rides.value.length}`" />
    <div class="flex flex-col gap-1">
      <ListRow
        v-for="r in stable.rides.value"
        :key="r.id"
        :title="r.name"
        :sub="sub(r)"
        :current="isCurrent('ride', r.id)"
        @click="stable.state.transferSel = { kind: 'ride', id: r.id }"
      >
        <template #lead>
          <Icon :name="r.type === 'horse' ? 'itemtype-horse' : 'itemtype-coach'" :size="20" :class="isCurrent('ride', r.id) ? '' : 'text-dim'" />
        </template>
        <template #trail>
          <Tag v-if="r.active" kind="active">Ativo</Tag>
        </template>
      </ListRow>
      <p v-if="!stable.rides.value.length" class="px-1 py-2 text-[13px] text-faint">Você não tem animais para enviar.</p>
    </div>
  </div>
</template>
