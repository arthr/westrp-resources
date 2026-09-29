<script setup>
import { computed } from "vue";
import { useKit } from "../../../state/kit.js";
import { WIDGETS } from "../../hud/widgets.js";
import { Card, Tag } from "../../kit";

const props = defineProps({
  id: { type: String, required: true },
  title: { type: String, required: true },
  kicker: { type: String, required: true },
});
const kit = useKit();
const widget = computed(() => WIDGETS[props.id]);
</script>

<template>
  <Card :title="title" :kicker="kicker">
    <template #right><Tag :kind="kit.isActive(id) ? 'active' : 'inactive'" /></template>
    <div class="flex h-[56px] items-center justify-center">
      <div class="h-full w-full max-w-[480px]">
        <component :is="widget" />
      </div>
    </div>
  </Card>
</template>
