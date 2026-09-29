import { onBeforeUnmount, onMounted, ref } from "vue";

// true em telas largas (≥ 1600 px): as grades de arte crescem um pouco
export function useWide(min = 1600) {
  const wide = ref(window.innerWidth >= min);
  const onResize = () => {
    wide.value = window.innerWidth >= min;
  };
  onMounted(() => window.addEventListener("resize", onResize));
  onBeforeUnmount(() => window.removeEventListener("resize", onResize));
  return wide;
}
