<script setup>
import { computed } from "vue";
import { useKit } from "../../../state/kit.js";
import { CoreMeter, coreGroup } from "../../kit";
import { CORE_BASE, SAMPLE_CORES } from "../dims.js";

const props = defineProps({ cores: { type: Object, default: null } });
const kit = useKit();

const CORE_ORDER = ["health", "stamina", "deadeye"];
const variant = computed(() => kit.state.hud.coreStyle);
const group = computed(() => coreGroup(variant.value, CORE_BASE));
const list = computed(() =>
  props.cores ? CORE_ORDER.map((k) => ({ icon: `core-${k}`, ...props.cores[k] })) : SAMPLE_CORES,
);
</script>

<template>
  <div
    :class="['flex items-start', group.col ? 'flex-col' : 'flex-row']"
    :style="{ width: `${group.width}px`, height: `${group.height}px`, gap: `${group.gap}px` }"
  >
    <CoreMeter v-for="c in list" :key="c.icon" :variant="variant" :size="CORE_BASE" :icon="c.icon" :ring="c.ring" :core="c.core" />
  </div>
</template>
