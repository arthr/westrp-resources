<script setup>
import { Button, Card, Tag } from "../../kit";

defineProps({
  api: { type: Object, required: true },
  testLabel: { type: String, required: true },
});
const emit = defineEmits(["test"]);
</script>

<template>
  <Card :title="api.name" :kicker="api.hud ? 'HUD' : 'Service'" body-class="flex flex-col gap-4">
    <template #right><Tag kind="neutral">{{ api.side }}</Tag></template>
    <p class="text-[13.5px] leading-snug text-dim">{{ api.desc }}</p>
    <pre class="tx-help overflow-x-auto px-5 py-4 font-sans text-[12.5px] leading-relaxed whitespace-pre text-ink [--plate:rgb(0_0_0/0.35)]">{{ api.code }}</pre>
    <div class="flex justify-end">
      <Button size="sm" @click="emit('test')">{{ testLabel }}</Button>
    </div>
  </Card>
</template>
