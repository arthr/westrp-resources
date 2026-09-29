<script setup>
import { computed } from "vue";
import { useKit } from "../../state/kit.js";
import { ROLES, THEME_PRESETS } from "../../state/mock.js";
import { contrast, onAccent } from "../../lib/theme.js";
import SectionFrame from "../shell/SectionFrame.vue";
import PresetRow from "./colors/PresetRow.vue";
import RoleRow from "./colors/RoleRow.vue";
import Mixer from "./colors/Mixer.vue";
import ContrastRow from "./colors/ContrastRow.vue";
import LivePreview from "./colors/LivePreview.vue";
import { Button, Card, Divider, SliderField } from "../kit";

const kit = useKit();
const t = computed(() => kit.state.theme);
const role = computed(() => ROLES.find((r) => r.id === t.value.role));
const presetName = computed(() => THEME_PRESETS.find((p) => p.id === t.value.preset)?.name ?? "Custom");

const setColor = (hex) => kit.dispatch({ type: "theme/set", patch: { [t.value.role]: hex } });
const setAlpha = (v) => kit.dispatch({ type: "theme/set", patch: { surfaceAlpha: v }, keepPreset: true });
</script>

<template>
  <SectionFrame
    title="Color Manager"
    hint="Every surface, fill and state in the kit reads from these three roles. Pick a preset or mix your server's own colours, then Publish."
  >
    <template #actions>
      <Button @click="kit.dispatch({ type: 'theme/preset', id: 'blood' })">Reset to Blood &amp; Black</Button>
    </template>

    <div
      class="grid min-w-0 grid-cols-[minmax(0,20rem)_minmax(0,1fr)] gap-6 min-[1600px]:grid-cols-[minmax(0,20rem)_minmax(0,1fr)_minmax(0,19rem)]"
    >
      <div class="flex min-w-0 flex-col gap-6">
        <Card title="Theme Presets" :kicker="presetName" body-class="flex flex-col gap-1.5">
          <PresetRow
            v-for="p in THEME_PRESETS"
            :key="p.id"
            :preset="p"
            :current="t.preset === p.id"
            @click="kit.dispatch({ type: 'theme/preset', id: p.id })"
          />
        </Card>
        <Card title="Roles" kicker="Select one to edit" body-class="flex flex-col gap-1.5">
          <RoleRow
            v-for="r in ROLES"
            :key="r.id"
            :role="r"
            :color="t[r.id]"
            :current="t.role === r.id"
            @click="kit.dispatch({ type: 'theme/role', role: r.id })"
          />
        </Card>
      </div>

      <div class="flex min-w-0 flex-col gap-6">
        <Card :title="`Mix ${role.label}`" kicker="Custom mixer">
          <Mixer :key="role.id" :role="role" :color="t[role.id]" @change="setColor" />
        </Card>
        <Card title="Surface & Legibility" kicker="Checks against WCAG" body-class="flex flex-col gap-4">
          <SliderField label="Panel opacity" :model-value="t.surfaceAlpha" :min="70" :max="100" :format="(v) => `${v}%`" @update:model-value="setAlpha" />
          <Divider />
          <ContrastRow label="Text on surface" :ratio="contrast(t.text, t.surface)" />
          <ContrastRow label="Accent on surface" :ratio="contrast(t.accent, t.surface)" />
          <ContrastRow label="Label on accent button" :ratio="contrast(onAccent(t.accent), t.accent)" />
        </Card>
      </div>

      <Card title="Live Preview" kicker="Updates as you mix" solid class="col-span-2 min-[1600px]:col-span-1" body-class="flex flex-col">
        <LivePreview />
      </Card>
    </div>
  </SectionFrame>
</template>
