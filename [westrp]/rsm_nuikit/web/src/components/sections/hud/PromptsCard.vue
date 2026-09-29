<script setup>
import { computed, ref } from "vue";
import { useKit } from "../../../state/kit.js";
import { Card, Counter, Divider, HoldPrompt, PressPrompt, Prompt, Tag } from "../../kit";

const kit = useKit();
const robbed = ref(0);
const on = computed(() => kit.isActive("prompts"));

const onRob = () => {
  robbed.value += 1;
  kit.notify("warning", "Register Robbed", "You took $18.40. The shopkeeper is running for the law.");
};
const onLedger = () => kit.notify("info", "Ledger Opened", "General Store · Valentine · 14 items in stock.");
</script>

<template>
  <Card title="Hold-Key Prompts" kicker="World interaction" body-class="flex flex-col gap-5">
    <template #right><Tag :kind="on ? 'active' : 'inactive'" /></template>
    <div class="flex flex-col gap-2.5">
      <PressPrompt k="R" code="KeyR" label="Open Ledger" :disabled="!on" @press="onLedger" />
      <HoldPrompt k="G" code="KeyG" label="Hold to Rob Register" :disabled="!on" @complete="onRob" />
      <Prompt k="F" label="Talk to Shopkeeper" dim />
    </div>
    <Divider />
    <div class="flex items-center justify-between gap-4 text-[13px]">
      <span class="text-dim">
        Tap R to open the ledger. Hold G (or press and hold with the mouse) to rob; let go early and it cancels. The dimmed prompt is
        unavailable.
      </span>
      <span class="flex shrink-0 items-center gap-2 text-faint">Completed <Counter size="sm">{{ robbed }}</Counter></span>
    </div>
  </Card>
</template>
