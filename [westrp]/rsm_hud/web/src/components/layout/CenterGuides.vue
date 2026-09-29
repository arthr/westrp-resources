<script setup>
import { layout } from "../../store/layout.js";
</script>

<template>
  <!-- Screen-centre guides, lit while a dragged element snaps to them. -->
  <span
    v-if="layout.guides.v"
    class="tex pointer-events-none fixed inset-y-0 left-1/2 z-20 w-[0.2rem] -translate-x-1/2 text-[rgb(var(--hud-accent-rgb)/0.75)] [mask-size:100%_100%] [-webkit-mask-size:100%_100%]"
    style="--m: var(--tex-vdivider)"
  />
  <span
    v-if="layout.guides.h"
    class="tex pointer-events-none fixed inset-x-0 top-1/2 z-20 h-[0.2rem] -translate-y-1/2 text-[rgb(var(--hud-accent-rgb)/0.75)] [mask-size:100%_100%] [-webkit-mask-size:100%_100%]"
    style="--m: var(--tex-divider)"
  />
</template>
