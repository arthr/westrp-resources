<script setup>
import { computed } from "vue";
import { Icon } from "../../kit";
import { clockText } from "../dims.js";

const props = defineProps({
  money: { type: Object, default: null },
  clock: { type: Object, default: null },
});

const cash = computed(() => (props.money ? props.money.cash : 142.6));
const gold = computed(() => (props.money ? props.money.gold : 2.5));
const time = computed(() => (props.clock ? clockText(props.clock) : props.money ? null : "9:42 AM"));
</script>

<template>
  <div class="tx-prompt flex h-full items-center justify-between gap-4 px-6">
    <span class="font-cat text-[22px] text-ink">${{ cash.toFixed(2) }}</span>
    <span v-if="gold != null" class="flex items-center gap-2 font-cat text-[18px] text-dim">
      <Icon name="star" :size="14" class="text-dim" />
      {{ gold.toFixed(2) }}
    </span>
    <span v-if="time" class="font-display text-[15px] text-dim">{{ time }}</span>
  </div>
</template>
