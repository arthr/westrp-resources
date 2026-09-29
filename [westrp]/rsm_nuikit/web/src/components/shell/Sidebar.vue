<script setup>
import { computed } from "vue";
import { useKit } from "../../state/kit.js";
import { SECTIONS, THEME_PRESETS } from "../../state/mock.js";
import { Button, Counter, Divider, Swatch, Tag } from "../kit";

const kit = useKit();
const activeCount = computed(() => kit.state.modules.filter((m) => m.active).length);
const themeName = computed(() => THEME_PRESETS.find((p) => p.id === kit.state.theme.preset)?.name ?? "Custom");
// quem decide onde ficam as peças do HUD: o /hudlayout do rsm_hud ou o config.lua
const placedBy = computed(() => (kit.state.host.present ? kit.state.host.name : "config.lua"));
</script>

<template>
  <aside class="flex min-h-0 min-w-0 flex-col gap-6">
    <div class="tx-header px-6 pt-6 pb-5 text-center">
      <p class="kit-heading text-[10px] text-faint">RedM · rsm_nuikit</p>
      <h1 class="mt-2 font-title text-[40px] leading-[0.9] text-ink">Components</h1>
      <p class="kit-heading mt-2 text-[10px] text-dim">Kit Studio</p>
    </div>

    <nav class="flex min-h-0 flex-1 flex-col gap-1.5 overflow-y-auto pr-1">
      <button
        v-for="(s, i) in SECTIONS"
        :key="s.id"
        type="button"
        :aria-current="kit.state.section === s.id ? 'page' : undefined"
        :class="[
          'row tx-plate flex shrink-0 cursor-pointer items-center gap-3.5 px-4 py-3 text-left transition-colors',
          kit.state.section === s.id ? 'is-current' : 'text-ink',
        ]"
        @click="kit.dispatch({ type: 'section', id: s.id })"
      >
        <span class="w-6 shrink-0 font-cat text-[14px] opacity-60">{{ String(i + 1).padStart(2, "0") }}</span>
        <span class="min-w-0">
          <span class="kit-heading block truncate text-[12px]">{{ s.label }}</span>
          <span class="mt-0.5 block truncate text-[12px] opacity-65">{{ s.hint }}</span>
        </span>
      </button>
    </nav>

    <Divider />

    <div class="flex flex-col gap-3.5 text-[13px]">
      <div class="flex items-center justify-between gap-3">
        <span class="text-dim">Theme</span>
        <span class="flex items-center">
          <Swatch :color="kit.state.theme.accent" :size="16" label="Accent" />
          <Swatch :color="kit.state.theme.text" :size="16" label="Text" />
          <span class="kit-heading ml-1.5 text-[10px] text-ink">{{ themeName }}</span>
        </span>
      </div>
      <div class="flex items-center justify-between gap-3">
        <span class="text-dim">Placement</span>
        <span class="kit-heading text-[10px] text-ink">{{ placedBy }}</span>
      </div>
      <div class="flex items-center justify-between gap-3">
        <span class="text-dim">Modules active</span>
        <Counter>{{ activeCount }}/{{ kit.state.modules.length }}</Counter>
      </div>
    </div>

    <!-- nada muda para os jogadores até publicar; o servidor valida e salva -->
    <div class="flex flex-col gap-2.5">
      <div class="flex items-center justify-between gap-3 text-[13px]">
        <span class="text-dim">Server</span>
        <Tag :kind="kit.dirty ? 'warning' : 'active'">{{ kit.dirty ? "Unpublished" : "Published" }}</Tag>
      </div>
      <div class="grid grid-cols-2 gap-2">
        <Button size="sm" :disabled="!kit.dirty" @click="kit.discard()">Discard</Button>
        <Button size="sm" variant="primary" :disabled="!kit.dirty" @click="kit.publish()">Publish</Button>
      </div>
    </div>
  </aside>
</template>
