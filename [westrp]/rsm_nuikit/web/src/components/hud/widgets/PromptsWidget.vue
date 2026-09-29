<script setup>
import { Prompt } from "../../kit";
</script>

<template>
  <div class="flex h-full flex-col items-end justify-between">
    <Prompt k="R" label="Open Ledger" />
    <Prompt k="G" label="Hold to Rob Register" :fill="0.45" />
  </div>
</template>
