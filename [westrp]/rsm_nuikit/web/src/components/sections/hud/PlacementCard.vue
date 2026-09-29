<script setup>
import { computed, ref, watch } from "vue";
import { hostCan, placementOf, useKit } from "../../../state/kit.js";
import { PIECE_NAMES } from "../../../state/mock.js";
import { HOST_OWNED, HOST_PIECES, widgetDims } from "../../hud/dims.js";
import HudStage from "../../hud/HudStage.vue";
import { Button, Card, RowLine, Tabs, Tag } from "../../kit";

// Onde cada peça do HUD aparece. Só leitura: quem posiciona é cada jogador no
// /hudlayout do rsm_hud, ou o Config.Layout do config.lua quando ele não roda.
// O palco mostra o rsm_hud de verdade com o rascunho do estúdio, e as peças do
// kit por cima, no lugar exato.
const kit = useKit();
const isGame = window.rsmNui.isGame;
const host = computed(() => kit.state.host);
const mirrored = computed(() => hostCan(kit.state, "mirror"));
const pct = (v) => `${Math.round(v * 100)}%`;
const COLS = "grid grid-cols-[minmax(0,1fr)_7rem_4rem_4rem_4.5rem_7.5rem] items-center gap-4";

// "new" = personagem sem layout salvo; "mine" = o layout salvo do próprio jogador
// (só no jogo: é o rsm_hud deste client que sabe qual é)
const VIEWS = [
  { value: "new", label: "New Players" },
  { value: "mine", label: "My Layout" },
];
const view = ref("new");
const savedLayout = ref(false);
const canPickView = computed(() => isGame && host.value.present);

watch(
  view,
  async (v) => {
    if (v !== "mine" || !isGame) return;
    const res = await window.rsmNui.post("host:getLayout");
    const data = res && typeof res.json === "function" ? await res.json().catch(() => null) : null;
    savedLayout.value = data && typeof data.layout === "object" && data.layout ? data.layout : false;
  },
);

const rows = computed(() => {
  const s = kit.state;
  const ids = host.value.present ? HOST_PIECES : [...HOST_PIECES, ...HOST_OWNED];
  return ids.map((id) => {
    const p = placementOf(s, id);
    const [w, h] = widgetDims(id, s.hud.coreStyle);
    const fromPlayer = host.value.present && !!s.placement.host[id];
    return {
      id,
      name: PIECE_NAMES[id],
      size: `${w} × ${h}`,
      p,
      source: fromPlayer ? "Your layout" : "Default",
      note: !kit.isActive(id) ? "Module inactive" : !p.visible ? "Hidden by the player" : null,
    };
  });
});
</script>

<template>
  <Card
    title="Placement"
    :kicker="host.present ? `Placed by ${host.name} · /hudlayout` : 'Config.Layout · config.lua'"
    body-class="flex flex-col gap-8"
  >
    <template #right>
      <Tag :kind="host.present ? 'active' : 'neutral'">{{ host.present ? host.name : "Standalone" }}</Tag>
    </template>

    <div class="grid min-w-0 gap-8 min-[1600px]:grid-cols-[minmax(0,1fr)_minmax(0,21rem)]">
      <HudStage :view="canPickView ? view : 'new'" :saved-layout="savedLayout" />

      <div class="flex min-w-0 flex-col gap-4 text-[13px] leading-snug text-dim">
        <Tabs v-if="canPickView" v-model="view" :items="VIEWS" size="sm" />
        <template v-if="host.present">
          <p v-if="mirrored">
            This is {{ host.name }} itself, drawn by its own interface with your unpublished theme and HUD defaults. The kit pieces sit
            exactly where they will appear.
          </p>
          <p v-else>The kit pieces sit exactly where they will appear. This version of {{ host.name }} cannot be shown here.</p>
          <p class="text-faint">
            {{
              canPickView && view === "mine"
                ? "My Layout is your own character, as saved in /hudlayout."
                : "New Players is a character that never saved a layout: the Starting Layout and Meter Style above."
            }}
          </p>
          <p class="text-faint">
            Every player drags these pieces in <span class="text-ink">/hudlayout</span> together with the rest of the HUD, and
            {{ host.name }} saves them per character. Cores and money are drawn by {{ host.name }}.
          </p>
        </template>
        <template v-else>
          <p>
            {{ host.name }} is not running, so every player sees these pieces at the positions set in
            <span class="text-ink">Config.Layout</span> (config.lua).
          </p>
          <p class="text-faint">Start {{ host.name }} and players can place them in /hudlayout, next to its own elements.</p>
        </template>
        <div class="mt-auto flex flex-col gap-2">
          <Button variant="primary" @click="kit.previewPlacement()">Preview Placement</Button>
          <p class="text-[12px] text-faint">
            {{
              host.present
                ? `Closes the studio for 8 seconds: ${host.name} fills every element with an example, in the draft theme and defaults, and each kit piece shows a sample in its place.`
                : "Closes the studio and shows a sample of each piece in its place for 8 seconds."
            }}
          </p>
        </div>
      </div>
    </div>

    <div class="flex min-w-0 flex-col">
      <div :class="[COLS, 'kit-heading px-2 pb-2.5 text-[10px] text-faint']">
        <span>Piece</span>
        <span>Size (1080p)</span>
        <span>X</span>
        <span>Y</span>
        <span>Scale</span>
        <span>Source</span>
      </div>
      <div v-for="(r, i) in rows" :key="r.id">
        <RowLine />
        <div :class="[COLS, 'px-2 py-3', r.note && 'opacity-60']">
          <span class="min-w-0">
            <span class="kit-heading block truncate text-[12.5px] text-ink">{{ r.name }}</span>
            <span v-if="r.note" class="mt-0.5 block truncate text-[12px] text-faint">{{ r.note }}</span>
          </span>
          <span class="font-cat text-[13px] text-dim">{{ r.size }}</span>
          <span class="font-cat text-[13px] text-ink">{{ pct(r.p.x) }}</span>
          <span class="font-cat text-[13px] text-ink">{{ pct(r.p.y) }}</span>
          <span class="font-cat text-[13px] text-ink">{{ pct(r.p.scale) }}</span>
          <span :class="['text-[12.5px]', r.source === 'Default' ? 'text-faint' : 'text-dim']">{{ r.source }}</span>
        </div>
        <RowLine v-if="i === rows.length - 1" />
      </div>
    </div>
  </Card>
</template>
