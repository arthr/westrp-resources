<script setup>
import { ANCHORS, ANCHOR_NAMES } from "../../../state/mock.js";
import { Icon } from "../../kit";

// 9-point anchor grid for the selected widget.
const model = defineModel({ type: String, required: true });
</script>

<template>
  <div class="grid w-max grid-cols-3 gap-2">
    <button
      v-for="a in ANCHORS"
      :key="a"
      type="button"
      :title="ANCHOR_NAMES[a]"
      :aria-label="ANCHOR_NAMES[a]"
      :aria-pressed="a === model"
      :class="['tx-frame group grid h-11 w-11 cursor-pointer place-items-center outline-none', a === model ? 'text-accent' : 'text-faint hover:text-ink']"
      :style="{ '--frame': a === model ? 'var(--kit-accent)' : 'rgb(var(--kit-text-rgb) / 0.2)' }"
      @click="model = a"
    >
      <Icon name="diamond" :size="a === model ? 14 : 9" />
    </button>
  </div>
</template>
