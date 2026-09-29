<script setup>
import { ref, watch } from "vue";
import KeyCap from "./KeyCap.vue";
import { isTyping } from "./keys.js";

// Hold-to-confirm prompt. Hold the key (or press and hold the mouse on it);
// letting go early cancels. Completing emits `complete` once per hold.
const props = defineProps({
  k: { type: String, default: "G" },
  code: { type: String, default: "KeyG" },
  label: { type: String, required: true },
  duration: { type: Number, default: 1300 },
  disabled: { type: Boolean, default: false },
});
const emit = defineEmits(["complete"]);

const holding = ref(false);
const progress = ref(0);

// Laço de preenchimento: só roda enquanto segura. Soltar, completar ou
// desmontar cancela o frame pendente e zera tudo, então nunca fica preso.
watch(holding, (held, _old, onCleanup) => {
  if (!held) {
    progress.value = 0;
    return;
  }
  // o tempo vem sempre de performance.now(): o carimbo que o requestAnimationFrame
  // entrega pode estar em outro relógio, e aí a barra nunca enche
  const start = performance.now();
  let raf = 0;
  const tick = () => {
    const p = Math.min(1, Math.max(0, (performance.now() - start) / props.duration));
    progress.value = p;
    if (p >= 1) {
      raf = 0;
      holding.value = false;
      emit("complete");
      return;
    }
    raf = requestAnimationFrame(tick);
  };
  raf = requestAnimationFrame(tick);
  onCleanup(() => cancelAnimationFrame(raf));
});

// Segurar pelo teclado. A repetição automática é ignorada: uma segurada = um disparo.
watch(
  () => [props.code, props.disabled],
  ([code, disabled], _old, onCleanup) => {
    if (disabled) return;
    const down = (e) => {
      if (e.code !== code || e.repeat || isTyping(e.target)) return;
      holding.value = true;
    };
    const up = (e) => {
      if (e.code === code) holding.value = false;
    };
    const cancel = () => {
      holding.value = false;
    };
    window.addEventListener("keydown", down);
    window.addEventListener("keyup", up);
    window.addEventListener("blur", cancel);
    onCleanup(() => {
      window.removeEventListener("keydown", down);
      window.removeEventListener("keyup", up);
      window.removeEventListener("blur", cancel);
      holding.value = false;
    });
  },
  { immediate: true },
);

const start = (e) => {
  if (props.disabled) return;
  e.currentTarget.setPointerCapture(e.pointerId);
  holding.value = true;
};
const stop = () => {
  holding.value = false;
};
</script>

<template>
  <button
    type="button"
    :disabled="disabled"
    :class="['block touch-none text-left outline-none select-none', disabled ? 'cursor-not-allowed' : 'cursor-pointer']"
    @pointerdown="start"
    @pointerup="stop"
    @pointercancel="stop"
  >
    <div :class="['tx-prompt flex h-11 w-max min-w-[15rem] items-center gap-3 py-1.5 pr-6 pl-2', disabled && 'opacity-60']">
      <KeyCap :k="k" :fill="progress" :dim="disabled" />
      <span :class="['text-[14px]', disabled ? 'text-faint' : 'text-ink']">{{ label }}</span>
    </div>
  </button>
</template>
