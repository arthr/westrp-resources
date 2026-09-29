<script setup>
import { ItemSlot } from "../kit";

// A pilha na mão segue o ponteiro. Teleport para o body: dentro do painel
// (que tem transform) um position:fixed seria relativo ao painel, não à tela.
defineProps({
  drag: { type: Object, required: true },
  item: { type: Object, required: true },
});
</script>

<template>
  <Teleport to="body">
    <div
      aria-hidden="true"
      class="pointer-events-none fixed z-[60]"
      :style="{
        left: `${drag.x}px`,
        top: `${drag.y}px`,
        transform: 'translate(-50%, -50%) scale(1.08)',
        filter: 'drop-shadow(0 12px 18px rgb(0 0 0 / 0.65))',
      }"
    >
      <ItemSlot :item="item" :qty="drag.qty" selected tabindex="-1" />
    </div>
  </Teleport>
</template>
