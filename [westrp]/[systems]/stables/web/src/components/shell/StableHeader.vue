<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { fmtCash, fmtGold } from "../../lib/format.js";
import { Counter, Icon, Tag, VDivider } from "../kit";

// Placa do estábulo + carteira e vagas do personagem
const stable = useStable();
const d = computed(() => stable.state.data);
const used = computed(() => ({ horse: stable.horses.value.length, cart: stable.carts.value.length }));
</script>

<template>
  <div class="flex shrink-0 flex-col gap-5">
    <header class="tx-header px-6 pt-6 pb-5 text-center">
      <p class="kit-heading truncate text-[10px] text-faint">{{ d.stable.region }}</p>
      <h1 class="mt-2 font-title text-[clamp(38px,2.8vw,50px)] leading-[0.9] text-ink">{{ d.stable.name }}</h1>
      <p class="kit-heading mt-2 truncate text-[10px] text-dim">Estábulo · {{ d.stable.keeper }}</p>
      <Tag v-if="stable.state.demo" kind="warning" class="mt-3">Dados de demonstração</Tag>
    </header>

    <div class="grid grid-cols-[minmax(0,1fr)_4px_minmax(0,1fr)_4px_minmax(0,1.25fr)] items-center gap-4 px-2">
      <div class="min-w-0">
        <p class="kit-heading text-[9.5px] text-faint">Dinheiro</p>
        <p class="mt-1.5 truncate font-cat text-[19px] leading-none text-ink">{{ fmtCash(d.player.cash) }}</p>
      </div>
      <VDivider />
      <div class="min-w-0">
        <p class="kit-heading text-[9.5px] text-faint">Ouro</p>
        <p class="mt-1.5 truncate font-cat text-[19px] leading-none text-ink">{{ fmtGold(d.player.gold) }}</p>
      </div>
      <VDivider />
      <div class="flex min-w-0 flex-col gap-1.5">
        <p class="kit-heading text-[9.5px] text-faint">Vagas</p>
        <div class="flex items-center gap-3">
          <span class="flex items-center gap-1.5" title="Cavalos">
            <Icon name="itemtype-horse" :size="16" class="text-dim" />
            <Counter size="sm" :muted="used.horse < d.limits.horse">{{ used.horse }}/{{ d.limits.horse }}</Counter>
          </span>
          <span class="flex items-center gap-1.5" title="Carroças">
            <Icon name="itemtype-coach" :size="16" class="text-dim" />
            <Counter size="sm" :muted="used.cart < d.limits.cart">{{ used.cart }}/{{ d.limits.cart }}</Counter>
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
