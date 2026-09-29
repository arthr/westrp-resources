<script setup>
import { computed } from "vue";
import CoreIcon from "./meters/CoreIcon.vue";
import TexBar from "./meters/TexBar.vue";
import { layout } from "../store/layout.js";

// Um medidor de core do RDR2 em seis estilos. Todos usam a arte real do jogo:
//   ring       disco + anel completo (rpg_meter), varrido a partir das 12h
//   half       meio anel de 9h a 3h sobre o disco, como um mostrador
//   segmented  o mesmo anel cortado em 10 gomos, enchendo gomo a gomo
//   bars-h     ícone + barra horizontal (barra de atributos das armas)
//   bars-v     ícone em cima + a mesma barra na vertical
//   numeric    ícone + número numa plaqueta
// O ícone sempre mostra o núcleo interno subindo; anel, barra ou número mostram
// o valor externo. `core` = null para medidores sem núcleo (necessidades).
// Golden Core: o núcleo (goldCore) e o anel/atributo (goldRing) fortificados
// pelas natives ficam dourados com um brilho que pulsa; *Ending acelera o pulso
// quando o efeito está acabando.
const props = defineProps({
  icon: { type: String, required: true },
  ring: { type: Number, default: 100 },
  core: { type: Number, default: null },
  size: { type: String, default: "4rem" },
  iconScale: { type: Number, default: 1 },
  label: { type: String, default: "" },
  showValue: { type: Boolean, default: false },
  // estresse e embriaguez são ruins quando ALTOS
  invert: { type: Boolean, default: false },
  alertAt: { type: Number, default: 20 },
  // estilo fixo (miniaturas do editor); sem ele vale o estilo escolhido no editor
  variant: { type: String, default: null },
  // barras mais curtas, para caber nas miniaturas
  compact: { type: Boolean, default: false },
  goldCore: { type: Boolean, default: false },
  goldRing: { type: Boolean, default: false },
  goldCoreEnding: { type: Boolean, default: false },
  goldRingEnding: { type: Boolean, default: false },
});

const style = computed(() => props.variant || layout.prefs.meterStyle || "ring");
const isRow = computed(() => style.value === "bars-h" || style.value === "numeric");

const pct = (v) => Math.min(100, Math.max(0, Number(v) || 0));
const ringPct = computed(() => pct(props.ring));
const value = computed(() => Math.round(ringPct.value));

// o que está fortificado não esvazia: o alerta vermelho não vale para ele
const ringAlert = computed(
  () => !props.goldRing && (props.invert ? ringPct.value >= 100 - props.alertAt : ringPct.value <= props.alertAt),
);
const coreAlert = computed(() => !props.goldCore && props.core !== null && pct(props.core) <= props.alertAt);
const alert = computed(() => ringAlert.value || coreAlert.value);

// medidas proporcionais ao tamanho base
const sz = (k) => `calc(${props.size} * ${k})`;
const iconBox = computed(() => ({ width: sz(0.56), height: sz(0.56) }));
const barThickness = computed(() => sz(0.2));
const barLengthH = computed(() => sz(props.compact ? 1.5 : 2.3));
const barLengthV = computed(() => sz(props.compact ? 1.1 : 1.5));

// o anel enche em graus; o segmentado arredonda para gomos inteiros de 36°
const ringDeg = computed(() => `${ringPct.value * 3.6}deg`);
const segDeg = computed(() => `${Math.round(ringPct.value / 10) * 36}deg`);
const halfDeg = computed(() => `${ringPct.value * 1.8}deg`);
const tone = computed(() => (props.goldRing ? "text-gold" : ringAlert.value ? "text-red" : "text-paper"));
</script>

<template>
  <div
    class="flex items-center"
    :class="isRow ? 'flex-row' : 'flex-col'"
    :style="{ gap: sz(isRow ? 0.12 : 0.08) }"
    :title="label"
  >
    <!-- anel completo e segmentado -->
    <div v-if="style === 'ring' || style === 'segmented'" class="relative shrink-0" :style="{ width: size, height: size }">
      <span class="absolute inset-0">
        <CoreIcon :icon="icon" :core="core" :icon-scale="iconScale" :alert="alert" :gold="goldCore" :gold-ending="goldCoreEnding" />
      </span>
      <span v-if="!goldCore" class="absolute inset-0" :class="{ segments: style === 'segmented' }">
        <span class="tex absolute inset-0 rotate-180 text-[rgb(var(--hud-text-rgb)/0.18)]" style="--m: var(--tex-ring-track)" />
      </span>
      <span v-if="goldRing" class="ring-sweep absolute inset-0" :style="{ '--deg': style === 'segmented' ? segDeg : ringDeg }">
        <span class="gold-glow absolute inset-0" :class="{ ending: goldRingEnding }">
          <span class="absolute inset-0" :class="{ segments: style === 'segmented' }">
            <span
              class="tex absolute inset-0 text-gold-bright"
              :class="{ 'rotate-180': style === 'segmented' }"
              style="--m: var(--tex-ring)"
            />
          </span>
        </span>
      </span>
      <span class="ring-sweep hud-glyph absolute inset-0" :style="{ '--deg': style === 'segmented' ? segDeg : ringDeg }">
        <span class="absolute inset-0" :class="{ segments: style === 'segmented' }">
          <!-- a arte de 99% tem um fio aberto perto das 12h: no segmentado ela gira
               180° para o fio cair num corte entre gomos -->
          <span
            class="tex absolute inset-0 transition-colors duration-300"
            :class="[tone, { 'rotate-180': style === 'segmented' }]"
            style="--m: var(--tex-ring)"
          />
        </span>
      </span>
    </div>

    <!-- meio anel: a metade de cima da mesma arte, girada para esconder o fio -->
    <div v-else-if="style === 'half'" class="relative shrink-0" :style="{ width: size, height: sz(0.74) }">
      <span class="absolute left-0 top-0" :style="{ width: size, height: size }">
        <span class="absolute inset-[20%]">
          <CoreIcon :icon="icon" :core="core" :icon-scale="iconScale" :alert="alert" :gold="goldCore" :gold-ending="goldCoreEnding" />
        </span>
        <span class="half-track absolute inset-0">
          <span class="tex absolute inset-0 rotate-180 text-[rgb(var(--hud-text-rgb)/0.18)]" style="--m: var(--tex-ring-track)" />
        </span>
        <span v-if="goldRing" class="half-sweep absolute inset-0" :style="{ '--deg': halfDeg }">
          <span class="gold-glow absolute inset-0" :class="{ ending: goldRingEnding }">
            <span class="tex absolute inset-0 rotate-180 text-gold-bright" style="--m: var(--tex-ring)" />
          </span>
        </span>
        <span class="half-sweep hud-glyph absolute inset-0" :style="{ '--deg': halfDeg }">
          <span class="tex absolute inset-0 rotate-180 transition-colors duration-300" :class="tone" style="--m: var(--tex-ring)" />
        </span>
      </span>
    </div>

    <!-- barra horizontal -->
    <template v-else-if="style === 'bars-h'">
      <span class="relative shrink-0" :style="iconBox">
        <CoreIcon :icon="icon" :core="core" :icon-scale="iconScale" :alert="alert" :gold="goldCore" :gold-ending="goldCoreEnding" />
      </span>
      <TexBar
        :pct="ringPct"
        :alert="ringAlert"
        :gold="goldRing"
        :gold-ending="goldRingEnding"
        :length="barLengthH"
        :thickness="barThickness"
      />
    </template>

    <!-- barra vertical: a mesma barra girada, então enche de baixo para cima -->
    <template v-else-if="style === 'bars-v'">
      <span class="relative shrink-0" :style="iconBox">
        <CoreIcon :icon="icon" :core="core" :icon-scale="iconScale" :alert="alert" :gold="goldCore" :gold-ending="goldCoreEnding" />
      </span>
      <span class="relative shrink-0" :style="{ width: barThickness, height: barLengthV }">
        <span class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 -rotate-90">
          <TexBar
            :pct="ringPct"
            :alert="ringAlert"
            :gold="goldRing"
            :gold-ending="goldRingEnding"
            :length="barLengthV"
            :thickness="barThickness"
          />
        </span>
      </span>
    </template>

    <!-- numérico -->
    <template v-else>
      <span class="relative shrink-0" :style="iconBox">
        <CoreIcon :icon="icon" :core="core" :icon-scale="iconScale" :alert="alert" :gold="goldCore" :gold-ending="goldCoreEnding" />
      </span>
      <span
        class="skin skin-key flex shrink-0 items-center justify-center font-num leading-none transition-colors duration-300"
        :class="goldRing ? ['text-gold', 'gold-text', { ending: goldRingEnding }] : [alert ? 'text-red' : 'text-paper', 'hud-text']"
        :style="{
          minWidth: sz(0.66),
          height: sz(0.46),
          padding: `0 ${sz(0.1)}`,
          fontSize: sz(0.28),
          '--skin-fill': 'rgb(var(--hud-surface-rgb) / calc(0.68 * var(--hud-surface-k)))',
        }"
      >{{ value }}</span>
    </template>

    <span
      v-if="showValue && style !== 'numeric'"
      class="font-num leading-none tracking-wide transition-colors duration-300"
      :class="goldRing ? ['text-gold', 'gold-text', { ending: goldRingEnding }] : [alert ? 'text-red' : 'text-paper', 'hud-text']"
      :style="{ fontSize: `max(0.62rem, ${sz(0.17)})` }"
    >{{ value }}</span>
  </div>
</template>
