<script setup>
import { onBeforeUnmount, ref, watch } from "vue";
import Prompt from "./Prompt.vue";
import { isTyping } from "./keys.js";

// Prompt de toque: um toque na tecla (ou um clique) emite `press`.
const props = defineProps({
  k: { type: String, required: true },
  code: { type: String, required: true },
  label: { type: String, required: true },
  disabled: { type: Boolean, default: false },
});
const emit = defineEmits(["press"]);

// o keycap acende por um instante a cada toque
const flash = ref(false);
let flashTimer = 0;
const press = () => {
  flash.value = true;
  clearTimeout(flashTimer);
  flashTimer = setTimeout(() => {
    flash.value = false;
  }, 180);
  emit("press");
};

// A escuta da tecla é refeita quando a tecla ou o disabled mudam, e sai
// sozinha quando o componente desmonta (o cleanup do watch roda no stop).
watch(
  () => [props.code, props.disabled],
  ([code, disabled], _old, onCleanup) => {
    if (disabled) return;
    const down = (e) => {
      if (e.code !== code || e.repeat || isTyping(e.target)) return;
      press();
    };
    window.addEventListener("keydown", down);
    onCleanup(() => window.removeEventListener("keydown", down));
  },
  { immediate: true },
);

onBeforeUnmount(() => clearTimeout(flashTimer));
</script>

<template>
  <button
    type="button"
    :disabled="disabled"
    :class="['block text-left outline-none select-none', disabled ? 'cursor-not-allowed' : 'cursor-pointer']"
    @click="press"
  >
    <Prompt :k="k" :label="label" :dim="disabled" :fill="flash ? 1 : 0" />
  </button>
</template>
