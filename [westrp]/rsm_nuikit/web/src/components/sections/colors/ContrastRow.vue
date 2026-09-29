<script setup>
import { computed } from "vue";
import { Tag } from "../../kit";

const props = defineProps({
  label: { type: String, required: true },
  ratio: { type: Number, required: true },
});
const pass = computed(() => props.ratio >= 4.5);
const large = computed(() => props.ratio >= 3);
</script>

<template>
  <div class="flex items-center justify-between gap-3 text-[13px]">
    <span class="text-dim">{{ label }}</span>
    <span class="flex items-center gap-2.5">
      <span class="font-cat text-[14px] text-ink">{{ ratio.toFixed(2) }}:1</span>
      <Tag :kind="pass ? 'active' : large ? 'warning' : 'inactive'">{{ pass ? "AA" : large ? "Large only" : "Fail" }}</Tag>
    </span>
  </div>
</template>
