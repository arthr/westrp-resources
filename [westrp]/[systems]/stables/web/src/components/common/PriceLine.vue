<script setup>
import { computed } from "vue";
import { fmtCash, fmtGold } from "../../lib/format.js";

// Preço em dólares (e em ouro, quando o servidor oferece) no plate de ajuda
const props = defineProps({
  price: { type: Number, required: true },
  gold: { type: Number, default: null },
  label: { type: String, default: "Preço" },
  short: { type: Boolean, default: false },
});
const cash = computed(() => fmtCash(props.price));
</script>

<template>
  <span v-if="short" class="font-cat text-[15px] leading-none">{{ cash }}</span>
  <div v-else class="tx-help flex items-center justify-between gap-4 px-6 py-3.5">
    <span class="kit-heading text-[10px] text-dim">{{ label }}</span>
    <span class="flex items-baseline gap-3">
      <span class="font-cat text-[24px] leading-none text-ink">{{ cash }}</span>
      <span v-if="gold != null" class="text-[12px] text-faint">ou {{ fmtGold(gold) }} ouro</span>
    </span>
  </div>
</template>
