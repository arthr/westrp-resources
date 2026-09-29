<script setup>
import { TOAST_SAMPLES } from "../../state/mock.js";
import { px } from "../kit/surface.js";
import { TOAST_GAP } from "./dims.js";
import Toast from "./Toast.vue";

// O feed cheio de exemplo (no /hudlayout, no Preview Placement e no palco da
// prévia). Na metade de baixo da tela ele se empilha a partir da base, como o
// feed de verdade.
defineProps({ fromBottom: { type: Boolean, default: false } });

const SAMPLE_LIST = ["info", "success", "warning"].map((type) => ({ type, ...TOAST_SAMPLES[type] }));
const gap = px(TOAST_GAP);
</script>

<template>
  <div :class="['flex h-full overflow-hidden', fromBottom ? 'flex-col-reverse' : 'flex-col']" :style="{ gap }">
    <Toast v-for="t in SAMPLE_LIST" :key="t.type" :type="t.type" :title="t.title" :body="t.body" />
  </div>
</template>
