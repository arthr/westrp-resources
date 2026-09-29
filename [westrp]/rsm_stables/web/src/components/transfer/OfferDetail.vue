<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { fmtCash } from "../../lib/format.js";
import { Button, HoldPrompt, Icon, ProgressBar } from "../kit";
import DetailHead from "../common/DetailHead.vue";
import BondMeter from "../common/BondMeter.vue";

// Proposta recebida: o animal só muda de dono se você aceitar e pagar
const props = defineProps({ offer: { type: Object, required: true } });
const stable = useStable();
const d = computed(() => stable.state.data);
const free = computed(() => stable.slotsLeft(props.offer.type));
const blocker = computed(() => {
  if (free.value <= 0) return "Sem vaga no estábulo para receber este animal.";
  if (d.value.player.cash < props.offer.price) return `Dinheiro insuficiente: faltam ${fmtCash(props.offer.price - d.value.player.cash)}.`;
  return null;
});
</script>

<template>
  <div class="flex min-h-0 flex-1 flex-col gap-6">
    <DetailHead :kicker="`Proposta de ${offer.from}`" :title="offer.rideName" :sub="`${offer.breed} · ${offer.coat}`">
      <template #right>
        <BondMeter v-if="offer.type === 'horse'" :level="offer.bond ?? 0" :size="16" />
      </template>
    </DetailHead>

    <div class="flex min-h-0 flex-1 flex-col gap-5 overflow-y-auto pr-2">
      <div class="tx-help flex flex-col gap-2.5 px-6 py-4 text-[14px]">
        <div class="flex items-baseline justify-between gap-4">
          <span class="text-dim">Valor pedido</span>
          <span class="font-cat text-[18px] text-ink">{{ offer.price > 0 ? fmtCash(offer.price) : "Presente" }}</span>
        </div>
        <div class="flex items-baseline justify-between gap-4">
          <span class="text-dim">Seu dinheiro</span>
          <span class="font-cat text-[16px] text-ink">{{ fmtCash(d.player.cash) }}</span>
        </div>
        <div class="flex items-baseline justify-between gap-4">
          <span class="text-dim">Vagas livres</span>
          <span :class="['font-cat text-[16px]', free > 0 ? 'text-ink' : 'text-accent']">{{ free }} de {{ d.limits[offer.type] }}</span>
        </div>
      </div>
      <p class="text-[14px] leading-relaxed text-dim">
        Ao aceitar, o valor sai da sua carteira e vai direto para {{ offer.from }}. O animal chega com o vínculo que já
        tinha e sem arreios.
      </p>
    </div>

    <div class="flex shrink-0 flex-col gap-3">
      <p v-if="blocker" class="flex items-center gap-2 text-[12px] text-accent">
        <Icon name="menu-icon-info-warning" :size="14" />
        {{ blocker }}
      </p>
      <ProgressBar v-if="stable.state.busy" />
      <HoldPrompt class="self-center" label="Segurar para aceitar" :disabled="!!blocker || stable.state.busy" @complete="stable.transferAnswer(offer, true)" />
      <Button variant="ghost" size="sm" icon="cross" :disabled="stable.state.busy" @click="stable.transferAnswer(offer, false)">Recusar proposta</Button>
    </div>
  </div>
</template>
