<script setup>
import { computed, ref, watch } from "vue";
import { ROLE_SWATCHES } from "../../../state/mock.js";
import { hexToHsl, hslToHex, isHex } from "../../../lib/theme.js";
import { Divider, SliderField, Swatch, TextInput } from "../../kit";

// Custom mixer: HSL sliders + hex field for the selected role. The hex field
// holds a draft only while it is invalid, so half-typed values never reach the theme.
const props = defineProps({
  role: { type: Object, required: true },
  color: { type: String, required: true },
});
const emit = defineEmits(["change"]);

// HSL fica em estado local: um hex cinza não guarda matiz, então derivar
// sempre do hex fazia o matiz voltar a 0° ao zerar a saturação. Só quando a
// cor muda por fora (preset, amostra, hex) o HSL é recalculado.
const hsl = ref(hexToHsl(props.color));
watch(
  () => props.color,
  (c) => {
    if (hslToHex(hsl.value) !== c) hsl.value = hexToHsl(c);
  },
);

const draft = ref(null);
const shown = computed(() => draft.value ?? props.color);

const setHsl = (patch) => {
  const next = { ...hsl.value, ...patch };
  draft.value = null;
  hsl.value = next;
  emit("change", hslToHex(next));
};

const onHex = (v) => {
  const next = (v.startsWith("#") ? v : `#${v}`).toUpperCase();
  if (isHex(next)) {
    draft.value = null;
    emit("change", next);
  } else {
    draft.value = next;
  }
};

const pickSwatch = (c) => {
  draft.value = null;
  emit("change", c);
};
</script>

<template>
  <div class="flex flex-col gap-5">
    <div class="flex items-center gap-5">
      <Swatch :color="color" :size="84" />
      <div class="flex min-w-0 flex-1 flex-col gap-2">
        <p class="kit-heading text-[11px] text-dim">{{ role.label }} colour</p>
        <TextInput :model-value="shown" :max-length="7" @update:model-value="onHex" />
        <p :class="['text-[12px]', isHex(shown) ? 'text-faint' : 'text-accent']">
          {{ isHex(shown) ? "Six-digit hex, e.g. #CB0101" : "Not a valid hex yet" }}
        </p>
      </div>
    </div>
    <div class="flex flex-wrap gap-0.5">
      <Swatch v-for="c in ROLE_SWATCHES[role.id]" :key="c" :color="c" :size="30" :selected="c === color" @click="pickSwatch(c)" />
    </div>
    <Divider />
    <SliderField label="Hue" :model-value="hsl.h" :min="0" :max="359" :format="(v) => `${v}°`" @update:model-value="(v) => setHsl({ h: v })" />
    <SliderField label="Saturation" :model-value="hsl.s" :format="(v) => `${v}%`" @update:model-value="(v) => setHsl({ s: v })" />
    <SliderField label="Lightness" :model-value="hsl.l" :format="(v) => `${v}%`" @update:model-value="(v) => setHsl({ l: v })" />
  </div>
</template>
