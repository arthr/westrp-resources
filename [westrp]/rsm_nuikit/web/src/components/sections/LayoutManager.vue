<script setup>
import { computed } from "vue";
import { useKit } from "../../state/kit.js";
import { ANCHOR_NAMES, LAYOUT_PRESETS, WIDGET_META } from "../../state/mock.js";
import SectionFrame from "../shell/SectionFrame.vue";
import MiniScreen from "./layout/MiniScreen.vue";
import AnchorPicker from "./layout/AnchorPicker.vue";
import { ArrowSelector, Button, Card, Checkbox, CORE_STYLES, Field, SliderField, Switch, Tabs, Tag } from "../kit";

const OFFSET = 40; // max ± offset, % of the screen
const SCALES = Array.from({ length: 17 }, (_, i) => 60 + i * 5).map((v) => ({ value: v, label: `${v}%` }));

const kit = useKit();
const layout = computed(() => kit.state.layout);
const selected = computed(() => layout.value.selected);
const w = computed(() => layout.value.widgets[selected.value]);
const meta = computed(() => WIDGET_META[selected.value]);
const module = computed(() => kit.state.modules.find((m) => m.id === selected.value));
const visibleCount = computed(() => Object.keys(layout.value.widgets).filter((id) => kit.isActive(id)).length);

const presetTabs = computed(() => [
  ...Object.entries(LAYOUT_PRESETS).map(([id, p]) => ({ value: id, label: p.label })),
  ...(layout.value.preset === "custom" ? [{ value: "custom", label: "Custom" }] : []),
]);

const update = (patch) => kit.dispatch({ type: "layout/widget", id: selected.value, patch });
const setLayout = (patch) => kit.dispatch({ type: "layout/set", patch });
const pickPreset = (id) => {
  if (id !== "custom") kit.dispatch({ type: "layout/preset", id });
};

const pct = (v) => `${v}%`;
const signed = (v) => `${v > 0 ? "+" : ""}${v}%`;
</script>

<template>
  <SectionFrame
    title="Layout Manager"
    hint="Place every HUD piece on a 9-point anchor grid, nudge it with offsets and scale it, then Publish. Drag on the mini screen or use the inspector."
  >
    <template #actions>
      <Button @click="kit.dispatch({ type: 'layout/preset', id: 'classic' })">Reset to Classic</Button>
    </template>

    <div class="flex min-w-0 flex-col gap-6">
      <!-- toolbar -->
      <div class="flex flex-wrap items-center justify-between gap-x-8 gap-y-4">
        <Tabs :items="presetTabs" :model-value="layout.preset" @update:model-value="pickPreset" />
        <div class="flex flex-wrap items-center gap-7">
          <Checkbox :model-value="layout.snap" label="Snap to anchors" @update:model-value="(v) => setLayout({ snap: v })" />
          <Checkbox :model-value="layout.grid" label="Thirds grid" @update:model-value="(v) => setLayout({ grid: v })" />
          <div class="w-52">
            <SliderField
              label="Safe zone"
              :model-value="layout.safeZone"
              :min="0"
              :max="10"
              :step="0.5"
              :format="pct"
              @update:model-value="(v) => setLayout({ safeZone: v, preset: 'custom' })"
            />
          </div>
        </div>
      </div>

      <div class="grid min-w-0 grid-cols-2 gap-6 min-[1600px]:grid-cols-[minmax(0,15rem)_minmax(0,1fr)_minmax(0,19rem)]">
        <!-- widget list -->
        <Card title="Widgets" :kicker="`${Object.keys(layout.widgets).length} HUD pieces`" body-class="flex flex-col gap-1.5">
          <button
            v-for="(wd, id) in layout.widgets"
            :key="id"
            type="button"
            :class="[
              'row tx-plate flex cursor-pointer items-center justify-between gap-2 px-3.5 py-2.5 text-left',
              selected === id && 'is-selected',
              kit.isActive(id) ? 'text-ink' : 'is-inactive',
            ]"
            @click="kit.dispatch({ type: 'layout/select', id })"
          >
            <span class="min-w-0">
              <span class="block truncate text-[14px]">{{ WIDGET_META[id].label }}</span>
              <span class="block text-[11.5px] text-faint">{{ kit.isActive(id) ? ANCHOR_NAMES[wd.anchor] : "Inactive" }}</span>
            </span>
            <span class="kit-heading shrink-0 font-cat text-[11px] text-dim">{{ wd.anchor.toUpperCase() }}</span>
          </button>
        </Card>

        <!-- mini screen -->
        <div class="order-first col-span-2 flex min-w-0 flex-col gap-3 min-[1600px]:order-none min-[1600px]:col-span-1">
          <MiniScreen />
          <div class="flex items-center justify-between gap-4 text-[12.5px] text-faint">
            <span>1920 × 1080 reference · safe zone in red · diamonds mark the anchors</span>
            <span class="font-cat text-dim">{{ visibleCount }} visible</span>
          </div>
        </div>

        <!-- inspector -->
        <Card :title="meta.label" kicker="Inspector" body-class="flex flex-col gap-5">
          <template #right><Tag :kind="module?.active ? 'active' : 'inactive'" /></template>
          <Field label="Shown on HUD" :hint="module?.locked ? 'Required module' : meta.size">
            <Switch
              :model-value="!!module?.active"
              :disabled="!!module?.locked"
              :labels="['On', 'Off']"
              width="7.5rem"
              @update:model-value="kit.dispatch({ type: 'module/toggle', id: selected })"
            />
          </Field>
          <div class="flex items-start justify-between gap-5">
            <div class="min-w-0">
              <p class="text-[14px] text-ink">Anchor</p>
              <p class="mt-0.5 text-[12px] text-faint">{{ ANCHOR_NAMES[w.anchor] }}</p>
            </div>
            <AnchorPicker :model-value="w.anchor" @update:model-value="(a) => update({ anchor: a })" />
          </div>
          <SliderField
            label="Offset X"
            :model-value="w.x"
            :min="-OFFSET"
            :max="OFFSET"
            :step="0.5"
            centered
            :format="signed"
            @update:model-value="(v) => update({ x: v })"
          />
          <SliderField
            label="Offset Y"
            :model-value="w.y"
            :min="-OFFSET"
            :max="OFFSET"
            :step="0.5"
            centered
            :format="signed"
            @update:model-value="(v) => update({ y: v })"
          />
          <Field label="Scale">
            <ArrowSelector :options="SCALES" :model-value="w.scale" width="4.5rem" @update:model-value="(v) => update({ scale: v })" />
          </Field>
          <Field v-if="selected === 'cores'" label="Style">
            <ArrowSelector
              :options="CORE_STYLES"
              :model-value="kit.state.hud.coreStyle"
              width="6.5rem"
              @update:model-value="(style) => kit.dispatch({ type: 'hud/coreStyle', style })"
            />
          </Field>
          <Button size="sm" variant="ghost" @click="update({ x: 0, y: 0, scale: 100 })">Clear Offsets &amp; Scale</Button>
        </Card>
      </div>
    </div>
  </SectionFrame>
</template>
