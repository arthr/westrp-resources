<script setup>
import { watch } from "vue";
import Toast from "./Toast.vue";

const props = defineProps({
  toast: { type: Object, required: true },
  ttl: { type: Number, required: true },
});
const emit = defineEmits(["dismiss"]);

// Cada toast some sozinho depois do ttl. Se o ttl mudar (config publicada),
// o timer recomeça; ao desmontar, o cleanup do watch cancela o pendente.
watch(
  () => [props.toast.id, props.ttl],
  ([id, ttl], _old, onCleanup) => {
    const t = setTimeout(() => emit("dismiss", id), ttl);
    onCleanup(() => clearTimeout(t));
  },
  { immediate: true },
);
</script>

<template>
  <button type="button" class="pointer-events-auto block cursor-pointer outline-none" @click="emit('dismiss', toast.id)">
    <Toast :type="toast.type" :title="toast.title" :body="toast.body" :ttl="ttl" />
  </button>
</template>
