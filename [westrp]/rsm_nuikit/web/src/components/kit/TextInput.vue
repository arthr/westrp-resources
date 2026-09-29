<script setup>
import { nextTick, ref } from "vue";
import Icon from "./Icon.vue";

// Text field on the dark selection plate; focus lifts it to the accent tint.
const model = defineModel({ type: String, default: "" });
defineProps({
  placeholder: { type: String, default: null },
  icon: { type: String, default: null },
  prefix: { type: String, default: null },
  disabled: { type: Boolean, default: false },
  maxLength: { type: Number, default: null },
  inputMode: { type: String, default: null },
});

const input = ref(null);

// Campo controlado: se quem usa filtrar o texto (só números, maiúsculas…),
// o que aparece no campo volta a ser o valor aceito, não o que foi digitado.
const onInput = (e) => {
  model.value = e.target.value;
  nextTick(() => {
    const shown = model.value ?? "";
    if (input.value && input.value.value !== shown) input.value.value = shown;
  });
};
</script>

<template>
  <label :class="['field tx-plate flex h-11 min-w-0 items-center gap-3 px-4', disabled ? 'cursor-not-allowed opacity-45' : 'cursor-text']">
    <Icon v-if="icon" :name="icon" :size="15" class="text-dim" />
    <span v-if="prefix" class="font-cat text-[14px] text-dim">{{ prefix }}</span>
    <input
      ref="input"
      :value="model"
      :disabled="disabled"
      :maxlength="maxLength"
      :inputmode="inputMode"
      :placeholder="placeholder"
      spellcheck="false"
      class="min-w-0 flex-1 bg-transparent text-[14px] text-ink caret-accent outline-none placeholder:text-faint disabled:cursor-not-allowed"
      @input="onInput"
    />
    <slot name="suffix" />
  </label>
</template>
