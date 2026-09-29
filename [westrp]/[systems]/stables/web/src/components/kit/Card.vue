<script setup>
import Divider from "./Divider.vue";

defineProps({
  title: { type: String, default: null },
  kicker: { type: String, default: null },
  bodyClass: { type: String, default: "" },
  solid: { type: Boolean, default: false },
});
</script>

<template>
  <section :class="[solid ? 'tx-card-solid' : 'tx-card', 'flex min-h-0 min-w-0 flex-col gap-4 px-7 py-6']">
    <template v-if="title || $slots.right">
      <header class="flex items-start justify-between gap-4">
        <div class="min-w-0">
          <p v-if="kicker" class="kit-heading mb-1 text-[10px] text-faint">{{ kicker }}</p>
          <h3 class="kit-heading text-[15px] leading-tight text-ink">{{ title }}</h3>
        </div>
        <div v-if="$slots.right" class="flex shrink-0 items-center gap-2"><slot name="right" /></div>
      </header>
      <Divider />
    </template>
    <div :class="['min-h-0 min-w-0', bodyClass]"><slot /></div>
  </section>
</template>
