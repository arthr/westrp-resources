<script setup>
import { computed, ref } from "vue";
import { useKit } from "../../state/kit.js";
import SectionFrame from "../shell/SectionFrame.vue";
import ModuleRow from "./states/ModuleRow.vue";
import StateReference from "./states/StateReference.vue";
import { Button, Card, RowLine, Tabs } from "../kit";

const kit = useKit();
const filter = ref("all");
const mods = computed(() => kit.state.modules);
const activeCount = computed(() => mods.value.filter((m) => m.active).length);
const shown = computed(() => mods.value.filter((m) => filter.value === "all" || (filter.value === "active" ? m.active : !m.active)));
const filterTabs = computed(() => [
  { value: "all", label: "All", count: mods.value.length },
  { value: "active", label: "Active", count: activeCount.value },
  { value: "inactive", label: "Inactive", count: mods.value.length - activeCount.value },
]);

const toggle = (m) => {
  kit.dispatch({ type: "module/toggle", id: m.id });
  kit.notify(
    m.active ? "warning" : "success",
    m.active ? `${m.name} Inactive` : `${m.name} Active`,
    "Publish to apply it for every player.",
    { force: m.id === "toasts" },
  );
};
</script>

<template>
  <SectionFrame
    title="Active / Inactive"
    hint="Switch whole components on or off for the server, then Publish. Required modules stay locked on; everything else follows your call, including the HUD layout."
  >
    <template #actions>
      <Button @click="kit.dispatch({ type: 'module/all', active: false })">Deactivate All</Button>
      <Button variant="primary" @click="kit.dispatch({ type: 'module/all', active: true })">Activate All</Button>
    </template>

    <div class="grid min-w-0 grid-cols-1 gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(0,22rem)]">
      <Card title="Module Registry" :kicker="`${activeCount} of ${mods.length} active`">
        <template #right><Tabs v-model="filter" size="sm" :items="filterTabs" /></template>
        <div class="flex flex-col">
          <div v-for="(m, i) in shown" :key="m.id">
            <RowLine v-if="i > 0" />
            <ModuleRow :m="m" @toggle="toggle(m)" />
          </div>
          <p v-if="shown.length === 0" class="py-10 text-center text-[14px] text-faint">Nothing {{ filter }} right now.</p>
        </div>
      </Card>

      <Card title="State Reference" kicker="Every state, side by side" body-class="flex flex-col">
        <StateReference />
      </Card>
    </div>
  </SectionFrame>
</template>
