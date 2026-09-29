<script setup>
import { computed, nextTick, ref, watch } from "vue";
import { useKit } from "../../state/kit.js";
import { Button, Divider, Icon, Tag } from "../kit";

// Two-choice dialog. The payload is plain data, so any resource can open one
// through Confirm: { kicker, title, body, lines: [[label, value]], confirm, cancel, danger }.
// Cancelar, ESC e clicar fora respondem "não"; a resposta sempre volta a quem perguntou.
const kit = useKit();
const d = computed(() => kit.state.dialog);
const waiting = computed(() => kit.state.dialogQueue.length);
const close = () => kit.answerDialog(false);
const confirm = () => kit.answerDialog(true);

// A cada diálogo novo o botão de confirmar recebe o foco (Enter confirma).
const panel = ref(null);
watch(
  () => (d.value ? (d.value.requestId ?? d.value.title) : null),
  (key) => {
    if (!key) return;
    nextTick(() => {
      const btn = panel.value && panel.value.querySelector("[data-autofocus]");
      if (btn) btn.focus();
    });
  },
  { immediate: true },
);
</script>

<template>
  <Transition
    enter-active-class="transition-opacity duration-150"
    enter-from-class="opacity-0"
    leave-active-class="transition-opacity duration-150"
    leave-to-class="opacity-0"
  >
    <div
      v-if="d"
      class="fixed inset-0 z-50 grid place-items-center p-8"
      style="background: rgba(0, 0, 0, 0.38)"
      @pointerdown.self="close"
    >
      <div
        ref="panel"
        :key="d.requestId ?? d.title"
        role="dialog"
        aria-modal="true"
        :aria-label="d.title"
        class="tx-dialog flex w-[min(34rem,90vw)] animate-kit-dialog flex-col gap-5 px-11 py-10"
      >
        <header class="flex items-start gap-4">
          <Icon :name="d.danger ? 'menu-icon-alert' : 'menu-icon-tick'" :size="34" :class="d.danger ? 'text-accent' : 'text-ink'" />
          <div class="min-w-0 flex-1">
            <p v-if="d.kicker" class="kit-heading text-[10px] text-faint">{{ d.kicker }}</p>
            <h2 class="kit-heading mt-1 text-[19px] leading-tight text-ink">{{ d.title }}</h2>
          </div>
          <Tag v-if="waiting > 0" kind="neutral">+{{ waiting }} waiting</Tag>
        </header>
        <Divider />
        <p v-if="d.body" class="text-[15px] leading-relaxed text-dim">{{ d.body }}</p>
        <div v-if="d.lines" class="tx-help flex flex-col gap-2 px-6 py-4">
          <div v-for="(line, i) in d.lines" :key="i" class="flex items-baseline justify-between gap-6 text-[14px]">
            <span class="text-dim">{{ line[0] }}</span>
            <span class="font-cat text-[16px] text-ink">{{ line[1] }}</span>
          </div>
        </div>
        <div class="mt-1 flex justify-end gap-3">
          <Button @click="close">{{ d.cancel ?? "Cancel" }}</Button>
          <Button variant="primary" data-autofocus @click="confirm">{{ d.confirm ?? "Confirm" }}</Button>
        </div>
      </div>
    </div>
  </Transition>
</template>
