<script setup>
import { computed } from "vue";
import { px } from "./surface.js";

const props = defineProps({
  name: { type: String, required: true },
  size: { type: Number, default: 20 },
  fill: { type: String, default: null },
});

const style = computed(() => ({
  width: px(props.size),
  height: px(props.size),
  "--ico": `var(--tex-${props.name})`,
  ...(props.fill ? { "--ico-fill": props.fill } : null),
}));
</script>

<template>
  <span aria-hidden="true" class="ico inline-block" :style="style" />
</template>
