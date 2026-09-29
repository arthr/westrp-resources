<script setup>
import { computed } from "vue";
import Brackets from "./Brackets.vue";
import Counter from "./Counter.vue";

// Framed item slot. Item art is shown as-is: never masked, tinted or cropped.
// qty: quantidade exibida (durante um arraste parcial, o que sobrou na origem).
// drop: null | "valid" | "invalid" enquanto um arraste passa por cima.
// lifted: a pilha inteira está na mão; o slot mostra só a sombra do item.
// popDelay: ms; toca a animação de entrada (usada depois do auto-ordenar).
// Eventos (@pointerdown, @click…) e atributos data-*/aria-* vão direto para o botão.
const props = defineProps({
  item: { type: Object, default: null },
  qty: { type: Number, default: null },
  selected: { type: Boolean, default: false },
  drop: { type: String, default: null },
  lifted: { type: Boolean, default: false },
  popDelay: { type: Number, default: null },
  size: { type: Number, default: 76 },
  disabled: { type: Boolean, default: false },
});

// arte do item pela ponte de assets do main.jsx (lida na hora, nunca no topo do módulo)
const itemArt = (item) => window.rsmAsset(`tex/items/${item.img}.png`);

const count = computed(() => props.qty ?? (props.item ? props.item.qty : 0));
const frame = computed(() =>
  props.drop === "valid" || props.selected
    ? "var(--kit-accent)"
    : props.drop === "invalid"
      ? "rgb(var(--kit-text-rgb) / 0.12)"
      : "rgb(var(--kit-text-rgb) / 0.22)",
);
</script>

<template>
  <button
    type="button"
    :disabled="disabled"
    :title="item ? `${item.name}${count > 1 ? ` ×${count}` : ''}` : 'Empty slot'"
    :class="[
      'tx-frame group relative grid shrink-0 place-items-center p-3 outline-none transition-opacity',
      disabled ? 'cursor-not-allowed opacity-40' : drop === 'invalid' ? 'cursor-not-allowed opacity-45' : '',
    ]"
    :style="{ width: `${size}px`, height: `${size}px`, '--frame': frame }"
  >
    <img
      v-if="item"
      :src="itemArt(item)"
      :alt="item.name"
      draggable="false"
      :class="['pointer-events-none h-full w-full object-contain transition-opacity', lifted && 'opacity-20']"
      :style="popDelay != null ? { animation: `kit-pop 0.32s ease-out ${popDelay}ms both` } : undefined"
    />
    <span v-if="item && !lifted && count > 1" class="pointer-events-none absolute right-1.5 bottom-1.5">
      <Counter size="sm">{{ count }}</Counter>
    </span>
    <Brackets v-if="selected || drop === 'valid'" :size="14" :fill="drop === 'valid' ? 'var(--kit-accent)' : 'var(--kit-text)'" />
  </button>
</template>
