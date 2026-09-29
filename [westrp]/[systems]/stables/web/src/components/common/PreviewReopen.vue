<script setup>
import { useStable } from "../../state/stable.js";
import { PressPrompt } from "../kit";

// Só na prévia: no jogo o estábulo reabre pelo prompt do cavalariço.
const stable = useStable();
</script>

<template>
  <div class="fixed inset-x-0 bottom-[6vh] z-30 flex justify-center">
    <PressPrompt k="G" code="KeyG" label="Falar com o cavalariço" @press="stable.reopen()" />
  </div>
</template>
