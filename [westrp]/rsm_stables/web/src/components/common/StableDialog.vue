<script setup>
import { computed, nextTick, ref, watch } from "vue";
import { useStable } from "../../state/stable.js";
import { Button, Divider, Icon, TextInput } from "../kit";

// Diálogo de confirmação no mesmo desenho do Confirm do rsm_nuikit, mas dentro
// deste resource: assim o foco do mouse nunca fica dividido entre dois NUIs.
// { kicker, title, body, lines: [[rótulo, valor]], confirm, cancel, danger,
//   input: { placeholder, value, match, maxLength, hint }, onConfirm(valor) }
// Cancelar, ESC e clicar fora fecham sem fazer nada.
const stable = useStable();
const d = computed(() => stable.state.dialog);
const value = ref("");
const panel = ref(null);

watch(
  d,
  (dialog) => {
    if (!dialog) return;
    value.value = dialog.input?.value ?? "";
    nextTick(() => {
      const el = panel.value && panel.value.querySelector(dialog.input ? "input" : "[data-autofocus]");
      if (el) el.focus();
    });
  },
  { immediate: true },
);

const valid = computed(() => {
  const inp = d.value?.input;
  if (!inp) return true;
  const v = value.value.trim();
  if (inp.match != null) return v.toLowerCase() === String(inp.match).trim().toLowerCase();
  return v.length >= (inp.minLength ?? 1);
});

const close = () => {
  stable.state.dialog = null;
};
const confirm = () => {
  const dialog = d.value;
  if (!dialog || !valid.value) return;
  stable.state.dialog = null;
  if (dialog.onConfirm) dialog.onConfirm(value.value.trim());
};
</script>

<template>
  <Transition
    enter-active-class="transition-opacity duration-150"
    enter-from-class="opacity-0"
    leave-active-class="transition-opacity duration-150"
    leave-to-class="opacity-0"
  >
    <div v-if="d" class="fixed inset-0 z-50 grid place-items-center p-8" style="background: rgba(0, 0, 0, 0.38)" @pointerdown.self="close">
      <form
        ref="panel"
        role="dialog"
        aria-modal="true"
        :aria-label="d.title"
        class="tx-dialog flex w-[min(34rem,90vw)] animate-kit-dialog flex-col gap-5 px-11 py-10"
        @submit.prevent="confirm"
      >
        <header class="flex items-start gap-4">
          <Icon :name="d.danger ? 'menu-icon-alert' : 'menu-icon-tick'" :size="34" :class="d.danger ? 'text-accent' : 'text-ink'" />
          <div class="min-w-0 flex-1">
            <p v-if="d.kicker" class="kit-heading text-[10px] text-faint">{{ d.kicker }}</p>
            <h2 class="kit-heading mt-1 text-[19px] leading-tight text-ink">{{ d.title }}</h2>
          </div>
        </header>
        <Divider />
        <p v-if="d.body" class="text-[15px] leading-relaxed text-dim">{{ d.body }}</p>
        <div v-if="d.lines" class="tx-help flex flex-col gap-2 px-6 py-4">
          <div v-for="(line, i) in d.lines" :key="i" class="flex items-baseline justify-between gap-6 text-[14px]">
            <span class="text-dim">{{ line[0] }}</span>
            <span class="font-cat text-[16px] text-ink">{{ line[1] }}</span>
          </div>
        </div>
        <div v-if="d.input" class="flex flex-col gap-2">
          <TextInput v-model="value" :placeholder="d.input.placeholder" :max-length="d.input.maxLength ?? 24" />
          <p v-if="d.input.hint" class="text-[12px] text-faint">{{ d.input.hint }}</p>
        </div>
        <div class="mt-1 flex justify-end gap-3">
          <Button @click="close">{{ d.cancel ?? "Cancelar" }}</Button>
          <Button type="submit" variant="primary" data-autofocus :disabled="!valid">{{ d.confirm ?? "Confirmar" }}</Button>
        </div>
      </form>
    </div>
  </Transition>
</template>
