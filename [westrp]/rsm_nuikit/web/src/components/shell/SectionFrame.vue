<script setup>
import { Divider } from "../kit";

// Section header (title, hint, actions) over a body that scrolls inside itself.
defineProps({
  title: { type: String, required: true },
  hint: { type: String, required: true },
});
</script>

<template>
  <section class="flex min-h-0 min-w-0 flex-1 flex-col gap-5">
    <header class="flex items-end justify-between gap-6">
      <div class="min-w-0">
        <h2 class="kit-heading text-[24px] leading-none text-ink">{{ title }}</h2>
        <p class="mt-2 text-[14px] text-dim">{{ hint }}</p>
      </div>
      <div v-if="$slots.actions" class="flex shrink-0 items-center gap-3"><slot name="actions" /></div>
    </header>
    <Divider />
    <div class="min-h-0 flex-1 overflow-y-auto pr-3 pb-2"><slot /></div>
  </section>
</template>
