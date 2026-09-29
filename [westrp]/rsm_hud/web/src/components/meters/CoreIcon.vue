<script setup>
import { computed } from "vue";

// Disco escuro do core + ícone. O ícone sobe de baixo para cima conforme o
// núcleo enche; com `core` = null ele aparece inteiro. Ocupa 100% da caixa do pai.
// Golden Core (núcleo fortificado pela native): ícone dourado, aro dourado em
// volta do disco, como o jogo desenha, e um brilho sutil que pulsa atrás do ícone.
const props = defineProps({
  icon: { type: String, required: true },
  core: { type: Number, default: null },
  iconScale: { type: Number, default: 1 },
  alert: { type: Boolean, default: false },
  gold: { type: Boolean, default: false },
  goldEnding: { type: Boolean, default: false },
});

const fill = computed(() => (props.core === null ? 100 : Math.min(100, Math.max(0, Number(props.core) || 0))));
const inset = computed(() => `${((1 - props.iconScale) / 2) * 100}%`);
const mask = computed(() => ({ "--m": `var(--tex-${props.icon})` }));
// núcleo fortificado não esvazia, então o alerta vermelho não se aplica a ele
const tone = computed(() => (props.gold ? "text-gold" : props.alert ? "text-red" : "text-paper"));
</script>

<template>
  <span class="relative block h-full w-full">
    <span class="tex absolute inset-0 text-[rgba(1,1,1,0.72)]" style="--m: var(--tex-core-bg)" />

    <!-- aro dourado: o trilho fino do medidor, que já contorna a borda do disco -->
    <span v-if="gold" class="hud-glyph absolute inset-0">
      <span class="tex absolute inset-0 text-gold" style="--m: var(--tex-ring-track)" />
    </span>

    <span class="absolute" :class="{ pulse: alert && !gold }" :style="{ inset }">
      <span v-if="gold" class="gold-glow absolute inset-0" :class="{ ending: goldEnding }">
        <span class="tex absolute inset-0 text-gold-bright" :style="mask" />
      </span>
      <span v-if="core !== null" class="tex absolute inset-0 text-[rgba(245,243,238,0.22)]" :style="mask" />
      <span class="core-rise absolute inset-0" :style="{ '--fill': `${fill}%` }">
        <span class="tex absolute inset-0 transition-colors duration-300" :class="tone" :style="mask" />
      </span>
    </span>
  </span>
</template>
