<script setup>
import { Icon, Switch, Tag } from "../../kit";

// host: nome do HUD que desenha este módulo no lugar do kit (cores, dinheiro)
defineProps({
  m: { type: Object, required: true },
  host: { type: String, default: null },
});
const emit = defineEmits(["toggle"]);
</script>

<template>
  <div :class="['flex items-center gap-5 px-2 py-3.5', (!m.active || host) && 'opacity-70']">
    <span class="grid h-9 w-9 shrink-0 place-items-center">
      <Icon
        :name="m.locked ? 'menu-icon-info-lock' : m.active ? 'menu-icon-tick' : 'cross'"
        :size="m.locked ? 18 : 24"
        :class="m.active ? (m.locked ? 'text-dim' : 'text-accent') : 'text-faint'"
      />
    </span>
    <div class="min-w-0 flex-1">
      <div class="flex items-center gap-3">
        <p :class="['kit-heading truncate text-[13px]', m.active ? 'text-ink' : 'text-dim']">{{ m.name }}</p>
        <Tag v-if="m.locked" kind="locked" />
        <Tag v-else-if="host" kind="neutral">{{ host }}</Tag>
      </div>
      <p class="mt-1 truncate text-[13px] text-faint">{{ host ? `Drawn by ${host} while it runs.` : m.desc }}</p>
    </div>
    <Tag kind="neutral" class="w-[5.5rem] justify-center">{{ m.group }}</Tag>
    <Switch :model-value="m.active" :disabled="!!m.locked || !!host" @update:model-value="emit('toggle')" />
  </div>
</template>
