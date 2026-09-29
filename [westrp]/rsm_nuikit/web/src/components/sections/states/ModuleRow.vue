<script setup>
import { Icon, Switch, Tag } from "../../kit";

defineProps({ m: { type: Object, required: true } });
const emit = defineEmits(["toggle"]);
</script>

<template>
  <div :class="['flex items-center gap-5 px-2 py-3.5', !m.active && 'opacity-70']">
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
      </div>
      <p class="mt-1 truncate text-[13px] text-faint">{{ m.desc }}</p>
    </div>
    <Tag kind="neutral" class="w-[5.5rem] justify-center">{{ m.group }}</Tag>
    <Switch :model-value="m.active" :disabled="!!m.locked" @update:model-value="emit('toggle')" />
  </div>
</template>
