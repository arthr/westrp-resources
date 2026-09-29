<script setup>
import { computed } from "vue";
import { useKit } from "../../../state/kit.js";
import { TOAST_SAMPLES } from "../../../state/mock.js";
import Toast from "../../hud/Toast.vue";
import { Button, Card, Divider, Tag } from "../../kit";

const TOAST_BUTTONS = [
  { type: "info", label: "Info" },
  { type: "success", label: "Success" },
  { type: "warning", label: "Warning" },
  { type: "error", label: "Error" },
];

const kit = useKit();
const on = computed(() => kit.isActive("toasts"));
const fire = (type) => kit.notify(type, TOAST_SAMPLES[type].title, TOAST_SAMPLES[type].body);
</script>

<template>
  <Card title="Notifications" kicker="The feed" body-class="flex flex-col gap-5">
    <template #right><Tag :kind="on ? 'active' : 'inactive'" /></template>
    <div class="grid grid-cols-2 gap-2.5">
      <Button
        v-for="b in TOAST_BUTTONS"
        :key="b.type"
        size="sm"
        :variant="b.type === 'error' ? 'primary' : 'secondary'"
        :disabled="!on"
        @click="fire(b.type)"
      >
        Fire {{ b.label }}
      </Button>
    </div>
    <p class="text-[13px] leading-snug text-faint">
      <template v-if="on">
        Toasts appear where each player placed Notifications
        {{ kit.state.host.present ? "in /hudlayout" : "(Config.Layout, config.lua)" }}, three at most. Click one to dismiss it.
      </template>
      <template v-else>The Notifications module is inactive. Switch it on under Active / Inactive to fire toasts.</template>
    </p>
    <Divider />
    <div class="flex justify-center">
      <Toast type="warning" :title="TOAST_SAMPLES.warning.title" :body="TOAST_SAMPLES.warning.body" width="100%" />
    </div>
  </Card>
</template>
