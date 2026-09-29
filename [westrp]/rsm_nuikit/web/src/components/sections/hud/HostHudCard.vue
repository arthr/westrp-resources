<script setup>
import { computed } from "vue";
import { useKit } from "../../../state/kit.js";
import { Card, Checkbox, CoreStylePicker, RowLine, Switch, Tabs, Tag } from "../../kit";

// Os recursos que o rsm_hud tem, como ele mesmo informa (elementos, predefinições,
// estilos dos medidores), e os padrões do servidor para eles. Publicar manda
// tudo para o HUD de cada jogador; no /hudlayout o jogador ajusta o resto.
const kit = useKit();
const isGame = window.rsmNui.isGame;
const host = computed(() => kit.state.host);
const cfg = computed(() => kit.state.hostHud);
const catalog = computed(() => host.value.catalog);

// mesmos seis estilos nos dois resources; só os nomes das barras mudam
const TO_KIT = { ring: "ring", half: "half", segmented: "segmented", "bars-h": "barsH", "bars-v": "barsV", numeric: "numeric" };
const TO_HOST = Object.fromEntries(Object.entries(TO_KIT).map(([h, k]) => [k, h]));
const meterStyle = computed({
  get: () => TO_KIT[cfg.value.meterStyle] ?? "ring",
  set: (v) => kit.dispatch({ type: "hostHud/set", patch: { meterStyle: TO_HOST[v] ?? "ring" } }),
});
const preset = computed({
  get: () => cfg.value.preset,
  set: (v) => kit.dispatch({ type: "hostHud/set", patch: { preset: v } }),
});
const values = computed({
  get: () => cfg.value.values,
  set: (v) => kit.dispatch({ type: "hostHud/set", patch: { values: v } }),
});

const presetTabs = computed(() => (catalog.value?.presets ?? []).map((p) => ({ value: p.id, label: p.label })));
const widgets = computed(() => catalog.value?.widgets ?? []);
const onCount = computed(() => widgets.value.filter((w) => !cfg.value.disabled.includes(w.id)).length);
const toggle = (id) => kit.dispatch({ type: "hostHud/toggle", id });
</script>

<template>
  <Card
    :title="host.name"
    :kicker="`${onCount} of ${widgets.length} elements available · server defaults`"
    body-class="grid gap-8 min-[1500px]:grid-cols-[minmax(0,1fr)_minmax(0,26rem)]"
  >
    <template #right>
      <Tag :kind="isGame ? 'active' : 'neutral'">{{ isGame ? "Running" : "Preview Sample" }}</Tag>
    </template>

    <div class="flex min-w-0 flex-col">
      <p class="kit-heading pb-2.5 text-[10px] text-faint">Elements</p>
      <div class="grid min-w-0 grid-cols-[repeat(auto-fill,minmax(19rem,1fr))] gap-x-8">
        <div v-for="w in widgets" :key="w.id" class="min-w-0">
          <RowLine />
          <div :class="['flex items-center gap-4 px-1 py-3', cfg.disabled.includes(w.id) && 'opacity-60']">
            <span class="min-w-0 flex-1">
              <span class="kit-heading block truncate text-[12.5px] text-ink">{{ w.label }}</span>
              <span class="mt-0.5 block truncate text-[12px] text-faint">{{ w.hint }}</span>
            </span>
            <Switch
              :model-value="!cfg.disabled.includes(w.id)"
              :labels="['On', 'Off']"
              width="6.5rem"
              :aria-label="`${w.label} available`"
              @update:model-value="toggle(w.id)"
            />
          </div>
        </div>
      </div>
      <p class="mt-4 text-[12.5px] leading-snug text-faint">
        Off removes the element for every player, including from the /hudlayout list. Their saved positions are kept, so switching it back on
        restores them.
      </p>
    </div>

    <div class="flex min-w-0 flex-col gap-6">
      <div class="flex flex-col gap-2.5">
        <p class="kit-heading text-[10px] text-faint">Starting Layout</p>
        <Tabs v-model="preset" :items="presetTabs" size="sm" />
      </div>
      <div class="flex flex-col gap-2.5">
        <p class="kit-heading text-[10px] text-faint">Meter Style</p>
        <CoreStylePicker v-model="meterStyle" />
      </div>
      <Checkbox v-model="values" label="Numbers on meters" hint="Shows the value next to each meter." />
      <p class="text-[12.5px] leading-snug text-dim">
        These are the starting point for characters that never saved a layout, and what Restaurar in /hudlayout goes back to. Players who
        already saved keep their own choices.
      </p>
      <p v-if="!isGame" class="text-[12px] text-faint">In the preview this list is a sample; in game it comes from {{ host.name }} itself.</p>
    </div>
  </Card>
</template>
