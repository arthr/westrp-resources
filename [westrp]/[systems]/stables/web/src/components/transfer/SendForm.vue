<script setup>
import { computed, ref, watch } from "vue";
import { useStable } from "../../state/stable.js";
import { HoldPrompt, Icon, ProgressBar, Tag, TextInput } from "../kit";
import DetailHead from "../common/DetailHead.vue";
import SectionLabel from "../common/SectionLabel.vue";
import ListRow from "../common/ListRow.vue";

// Enviar um animal seu: para quem e por quanto (0 = presente)
const props = defineProps({ ride: { type: Object, required: true } });
const stable = useStable();

const query = ref("");
const targetId = ref(null);
const price = ref("");
watch(
  () => props.ride.id,
  () => {
    query.value = "";
    targetId.value = null;
    price.value = "";
  },
);

const people = computed(() => {
  const q = query.value.trim().toLowerCase();
  const list = stable.state.data.characters ?? [];
  return (q ? list.filter((c) => c.name.toLowerCase().includes(q)) : list)
    .slice()
    .sort((a, b) => Number(b.online) - Number(a.online) || a.name.localeCompare(b.name));
});
const target = computed(() => (stable.state.data.characters ?? []).find((c) => c.id === targetId.value) ?? null);

// Só dígitos, até o máximo que o servidor aceita
const priceModel = computed({
  get: () => price.value,
  set: (v) => {
    const max = stable.transferMax.value;
    const digits = v.replace(/\D/g, "").replace(/^0+(?=\d)/, "").slice(0, String(max).length);
    price.value = digits && Number(digits) > max ? String(max) : digits;
  },
});
const amount = computed(() => Number(price.value) || 0);

const send = () => {
  if (!target.value) return;
  stable.transferSend(props.ride, target.value, amount.value);
  targetId.value = null;
  price.value = "";
};
</script>

<template>
  <div class="flex min-h-0 flex-1 flex-col gap-6">
    <DetailHead kicker="Transferir" :title="ride.name" :sub="ride.type === 'horse' ? `${ride.breed} · ${ride.coat}` : ride.label" />

    <div class="flex min-h-0 flex-1 flex-col gap-3">
      <SectionLabel label="Para quem">
        <span v-if="target" class="text-ink">{{ target.name }}</span>
      </SectionLabel>
      <TextInput v-model="query" placeholder="Buscar pelo nome" :max-length="30" />
      <div class="flex min-h-0 flex-1 flex-col gap-1 overflow-y-auto pr-2">
        <ListRow
          v-for="c in people"
          :key="c.id"
          :title="c.name"
          :current="c.id === targetId"
          :inactive="!c.online && c.id !== targetId"
          @click="targetId = c.id"
        >
          <template #trail>
            <Tag v-if="c.online" :kind="c.id === targetId ? 'neutral' : 'active'">Online</Tag>
            <span v-else class="text-[12px]">Fora da cidade</span>
          </template>
        </ListRow>
        <p v-if="!people.length" class="px-1 py-2 text-[13px] text-faint">Ninguém encontrado com esse nome.</p>
      </div>
    </div>

    <div class="flex shrink-0 flex-col gap-3">
      <div class="flex items-center justify-between gap-4">
        <span class="text-[13px] text-dim">Valor pedido</span>
        <TextInput v-model="priceModel" class="w-40" prefix="$" placeholder="0" input-mode="numeric" :max-length="String(stable.transferMax.value).length" />
      </div>
      <p class="text-[12px] leading-relaxed text-faint">
        {{ amount > 0 ? "A pessoa paga ao aceitar." : "Sem valor, o animal vai de presente." }}
        O animal fica com você até a proposta ser aceita{{ ride.active ? "; ao sair, outro passa a ser o ativo" : "" }}.
      </p>
      <p v-if="!target" class="flex items-center gap-2 text-[12px] text-dim">
        <Icon name="menu-icon-info-warning" :size="14" />
        Escolha para quem enviar.
      </p>
      <ProgressBar v-if="stable.state.busy" />
      <HoldPrompt class="self-center" label="Segurar para enviar proposta" :disabled="!target || stable.state.busy" @complete="send" />
    </div>
  </div>
</template>
