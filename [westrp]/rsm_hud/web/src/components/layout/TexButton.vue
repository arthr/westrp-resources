<script setup>
// A button on the game's selection plate. `primary` fills it red; `active`
// marks the current choice in a group (presets).
defineProps({
  primary: { type: Boolean, default: false },
  active: { type: Boolean, default: false },
});
</script>

<template>
  <button
    type="button"
    class="skin skin-btn flex min-h-[2.3rem] cursor-pointer items-center justify-center gap-2 px-3 py-2 font-display text-[0.66rem] uppercase tracking-[0.16em]"
    :class="
      primary || active
        ? 'text-on-accent [--skin-fill:var(--red)] hover:[--skin-fill:var(--red-hover)]'
        : 'text-paper [--skin-fill:rgb(var(--hud-text-rgb)/0.1)] hover:[--skin-fill:rgb(var(--hud-text-rgb)/0.18)]'
    "
  >
    <slot />
  </button>
</template>
