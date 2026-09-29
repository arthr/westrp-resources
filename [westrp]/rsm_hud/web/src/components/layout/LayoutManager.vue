<script setup>
import { computed, onMounted, onUnmounted, ref } from "vue";
import TexButton from "./TexButton.vue";
import TexToggle from "./TexToggle.vue";
import TexSlider from "./TexSlider.vue";
import KeyCap from "./KeyCap.vue";
import CoreMeter from "../CoreMeter.vue";
import { t } from "../../locale.js";
import {
  layout,
  WIDGETS,
  external,
  allWidgetIds,
  widgetLabel,
  widgetHint,
  isDisabled,
  PRESETS,
  METER_STYLES,
  setMeterStyle,
  cycleMeterStyle,
  applyPreset,
  resetAll,
  resetWidget,
  setWidget,
  selectRelative,
  nudgeWidget,
  centerWidget,
  saveLayout,
  cancelLayout,
} from "../../store/layout.js";

// "elements": posição e visibilidade · "meters": estilo dos medidores
const tab = ref("elements");

const sel = computed(() => (layout.selected ? layout.widgets[layout.selected] : null));
// Elementos do HUD e, em seguida, as peças que outros resources registraram
const rows = computed(() => [
  ...WIDGETS.filter((w) => !isDisabled(w.id)).map((w) => ({ id: w.id, first: false })),
  ...external.map((s, i) => ({ id: s.id, first: i === 0 })),
]);
const visibleCount = computed(() => allWidgetIds().filter((id) => layout.widgets[id]?.visible).length);

const scale = computed({
  get: () => Math.round((sel.value?.scale ?? 1) * 100),
  set: (v) => setWidget(layout.selected, { scale: v / 100 }),
});
const opacity = computed({
  get: () => Math.round((sel.value?.opacity ?? 1) * 100),
  set: (v) => setWidget(layout.selected, { opacity: v / 100 }),
});

const flipDock = () => {
  layout.prefs.dock = layout.prefs.dock === "right" ? "left" : "right";
};

function onKey(e) {
  const tag = e.target && e.target.tagName;
  const id = layout.selected;
  const step = e.shiftKey ? 10 : 1;
  switch (e.key) {
    case "Escape":
      e.preventDefault();
      cancelLayout();
      return;
    case "Enter":
      if (tag === "BUTTON") return; // o botão focado cuida do próprio Enter
      e.preventDefault();
      saveLayout();
      return;
    case "Tab":
      e.preventDefault();
      selectRelative(e.shiftKey ? -1 : 1);
      return;
  }
  if (!id) return;
  const moves = { ArrowLeft: [-step, 0], ArrowRight: [step, 0], ArrowUp: [0, -step], ArrowDown: [0, step] };
  if (moves[e.key]) {
    e.preventDefault();
    nudgeWidget(id, ...moves[e.key]);
  } else if (e.key === "h" || e.key === "H") {
    setWidget(id, { visible: !layout.widgets[id].visible });
  } else if (e.key === "+" || e.key === "=") {
    setWidget(id, { scale: layout.widgets[id].scale + 0.05 });
  } else if (e.key === "-" || e.key === "_") {
    setWidget(id, { scale: layout.widgets[id].scale - 0.05 });
  } else if (e.key === "r" || e.key === "R") {
    resetWidget(id);
  } else if (e.key === "m" || e.key === "M") {
    cycleMeterStyle(e.shiftKey ? -1 : 1);
  }
}

onMounted(() => window.addEventListener("keydown", onKey));
onUnmounted(() => window.removeEventListener("keydown", onKey));
</script>

<template>
  <aside
    class="skin skin-panel fixed top-[5vh] bottom-[5vh] z-30 flex w-[24rem] flex-col gap-4 pb-7 pl-[2.05rem] pr-[1.95rem] pt-6"
    :class="layout.prefs.dock === 'right' ? 'right-[2vw]' : 'left-[2vw]'"
    style="--skin-fill: rgb(var(--hud-panel-rgb) / calc(0.95 * var(--hud-surface-k)))"
    @pointerdown.stop
  >
    <!-- cabeçalho -->
    <header class="flex shrink-0 flex-col gap-2">
      <div class="flex items-start justify-between gap-3">
        <div class="flex flex-col gap-1">
          <span class="font-display text-[0.6rem] uppercase tracking-[0.32em] text-red">{{ t("lm.kicker") }}</span>
          <h2 class="m-0 font-title text-[2.3rem] font-normal leading-none text-paper">{{ t("lm.title") }}</h2>
        </div>
        <button
          type="button"
          class="flex h-[2rem] w-[2rem] shrink-0 cursor-pointer items-center justify-center text-dim hover:text-paper"
          :title="layout.prefs.dock === 'right' ? t('lm.dockLeft') : t('lm.dockRight')"
          @click="flipDock"
        >
          <span
            class="tex h-[1.6rem] w-[1.6rem]"
            :style="{ '--m': layout.prefs.dock === 'right' ? 'var(--tex-arrow-l)' : 'var(--tex-arrow-r)' }"
          />
        </button>
      </div>
      <p class="m-0 text-[0.78rem] leading-snug text-dim">
        {{ t("lm.intro") }}
      </p>
      <span class="tex mt-1 h-[0.18rem] w-full text-[rgb(var(--hud-text-rgb)/0.22)] [mask-size:100%_100%] [-webkit-mask-size:100%_100%]" style="--m: var(--tex-divider)" />
    </header>

    <!-- abas -->
    <nav class="grid shrink-0 grid-cols-2 gap-2">
      <TexButton :active="tab === 'elements'" @click="tab = 'elements'">{{ t("lm.tabElements") }}</TexButton>
      <TexButton :active="tab === 'meters'" @click="tab = 'meters'">{{ t("lm.tabMeters") }}</TexButton>
    </nav>

    <template v-if="tab === 'elements'">
      <!-- predefinições -->
      <section class="flex shrink-0 flex-col gap-2">
        <h3 class="m-0 font-display text-[0.64rem] font-normal uppercase tracking-[0.22em] text-dim">{{ t("lm.presets") }}</h3>
        <div class="grid grid-cols-3 gap-2">
          <TexButton v-for="key in Object.keys(PRESETS)" :key="key" :active="layout.preset === key" @click="applyPreset(key)">
            {{ t(`preset.${key}`) }}
          </TexButton>
        </div>
      </section>

      <!-- lista de elementos: a única região que cresce, então rola por dentro -->
      <section class="flex min-h-0 flex-1 flex-col gap-2">
        <h3 class="m-0 flex items-baseline justify-between font-display text-[0.64rem] font-normal uppercase tracking-[0.22em] text-dim">
          {{ t("lm.elements") }}
          <span class="font-num text-[0.8rem] tracking-normal text-paper">{{ visibleCount }} / {{ rows.length }}</span>
        </h3>
        <ul class="scroll-thin m-0 flex min-h-0 flex-1 list-none flex-col gap-1.5 overflow-y-auto p-0 pr-1.5">
          <li v-for="w in rows" :key="w.id">
            <p
              v-if="w.first"
              class="m-0 pb-1 pt-2.5 font-display text-[0.6rem] uppercase tracking-[0.22em] text-dim"
            >{{ t("lm.external") }}</p>
            <div
              class="skin skin-row flex cursor-pointer items-center gap-3 px-4 py-2.5"
              :class="
                layout.selected === w.id
                  ? '[--skin-fill:rgb(var(--hud-accent-rgb)/0.3)]'
                  : '[--skin-fill:rgb(var(--hud-text-rgb)/0.05)] hover:[--skin-fill:rgb(var(--hud-text-rgb)/0.1)]'
              "
              @click="layout.selected = w.id"
            >
              <TexToggle
                :model-value="layout.widgets[w.id].visible"
                :label="`${t('lm.show')} ${widgetLabel(w.id)}`"
                @update:model-value="(v) => setWidget(w.id, { visible: v })"
              />
              <div class="flex min-w-0 flex-1 flex-col gap-0.5">
                <span
                  class="font-display text-[0.74rem] uppercase tracking-[0.12em]"
                  :class="layout.widgets[w.id].visible ? 'text-paper' : 'text-faint'"
                >{{ widgetLabel(w.id) }}</span>
                <span class="truncate text-[0.66rem] text-dim">{{ widgetHint(w.id) }}</span>
              </div>
              <span
                v-if="layout.selected === w.id"
                class="tex h-[1rem] w-[1rem] shrink-0 text-red"
                style="--m: var(--tex-arrow-r)"
              />
            </div>
          </li>
        </ul>
      </section>

      <!-- elemento selecionado -->
      <section v-if="sel" class="flex shrink-0 flex-col gap-3">
        <h3 class="m-0 flex items-baseline justify-between font-display text-[0.64rem] font-normal uppercase tracking-[0.22em] text-dim">
          {{ t("lm.selected") }}
          <span class="text-[0.72rem] tracking-[0.14em] text-paper">{{ widgetLabel(layout.selected) }}</span>
        </h3>
        <TexSlider v-model="scale" :label="t('lm.scale')" unit="%" :min="50" :max="160" :step="5" />
        <TexSlider v-model="opacity" :label="t('lm.opacity')" unit="%" :min="30" :max="100" :step="5" />
        <div class="grid grid-cols-3 gap-2">
          <TexButton @click="centerWidget(layout.selected, 'x')">{{ t("lm.centerX") }}</TexButton>
          <TexButton @click="centerWidget(layout.selected, 'y')">{{ t("lm.centerY") }}</TexButton>
          <TexButton @click="resetWidget(layout.selected)">{{ t("lm.reset") }}</TexButton>
        </div>
      </section>

      <!-- opções -->
      <section class="flex shrink-0 flex-col gap-2">
        <div class="flex cursor-pointer items-center gap-3" @click="layout.prefs.snap = !layout.prefs.snap">
          <TexToggle v-model="layout.prefs.snap" :label="t('lm.snap')" />
          <span class="text-[0.76rem] text-paper">{{ t("lm.snap") }}</span>
        </div>
      </section>
    </template>

    <!-- medidores: a região cresce e rola por dentro, como a lista de elementos -->
    <section v-else class="scroll-thin flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto pr-1.5">
      <h3 class="m-0 font-display text-[0.64rem] font-normal uppercase tracking-[0.22em] text-dim">{{ t("lm.meterStyle") }}</h3>
      <div class="grid grid-cols-3 gap-2.5">
        <button
          v-for="s in METER_STYLES"
          :key="s"
          type="button"
          class="skin skin-row flex h-[6.4rem] cursor-pointer flex-col items-center justify-between px-1.5 pb-2.5 pt-2"
          :class="
            layout.prefs.meterStyle === s
              ? '[--skin-fill:rgb(var(--hud-accent-rgb)/0.24)]'
              : '[--skin-fill:rgb(var(--hud-text-rgb)/0.05)] hover:[--skin-fill:rgb(var(--hud-text-rgb)/0.1)]'
          "
          :title="t(`style.${s}`)"
          @click="setMeterStyle(s)"
        >
          <span class="pointer-events-none flex min-h-0 flex-1 items-center justify-center">
            <CoreMeter :variant="s" icon="core-health" :ring="72" :core="80" size="2.1rem" compact />
          </span>
          <span
            class="font-display text-[0.58rem] uppercase tracking-[0.16em]"
            :class="layout.prefs.meterStyle === s ? 'text-paper' : 'text-dim'"
          >{{ t(`style.${s}`) }}</span>
          <span
            v-if="layout.prefs.meterStyle === s"
            class="skin skin-outline pointer-events-none absolute -inset-1"
            style="--skin-fill: rgb(var(--hud-accent-rgb) / 0.85)"
          />
        </button>
      </div>
      <p class="m-0 text-[0.72rem] leading-snug text-dim">{{ t("lm.meterStyleHint") }}</p>
      <div class="flex cursor-pointer items-center gap-3" @click="layout.prefs.values = !layout.prefs.values">
        <TexToggle v-model="layout.prefs.values" :label="t('lm.values')" />
        <span class="text-[0.76rem] text-paper">{{ t("lm.values") }}</span>
      </div>
    </section>

    <!-- rodapé -->
    <footer class="flex shrink-0 flex-col gap-3">
      <span class="tex h-[0.18rem] w-full text-[rgb(var(--hud-text-rgb)/0.22)] [mask-size:100%_100%] [-webkit-mask-size:100%_100%]" style="--m: var(--tex-divider)" />
      <div class="grid grid-cols-[1fr_1fr_1.35fr] gap-2">
        <TexButton @click="resetAll">{{ t("lm.resetAll") }}</TexButton>
        <TexButton @click="cancelLayout">{{ t("lm.cancel") }}</TexButton>
        <TexButton primary @click="saveLayout">{{ t("lm.save") }}</TexButton>
      </div>
      <div class="flex flex-wrap items-center gap-x-3.5 gap-y-1.5 text-[0.62rem] text-dim">
        <span class="flex items-center gap-1.5"><KeyCap k="Esc" /> {{ t("lm.hintCancel") }}</span>
        <span class="flex items-center gap-1.5"><KeyCap k="Enter" /> {{ t("lm.hintSave") }}</span>
        <span class="flex items-center gap-1.5"><KeyCap k="Tab" /> {{ t("lm.hintNext") }}</span>
        <span class="flex items-center gap-1.5"><KeyCap :k="t('lm.keyArrows')" /> {{ t("lm.hintNudge") }}</span>
        <span class="flex items-center gap-1.5"><KeyCap k="H" /> {{ t("lm.hintHide") }}</span>
        <span class="flex items-center gap-1.5"><KeyCap k="+ −" /> {{ t("lm.hintScale") }}</span>
        <span class="flex items-center gap-1.5"><KeyCap k="M" /> {{ t("lm.hintStyle") }}</span>
      </div>
    </footer>
  </aside>
</template>
