<script setup>
import { computed } from "vue";
import { useKit } from "../../../state/kit.js";
import { Button, Card, Divider, Field, KeyCap, Tag } from "../../kit";

const PURCHASE = {
  kicker: "Valentine Gunsmith",
  title: "Buy Schofield Revolver?",
  body: "The revolver and 24 rounds of regular ammunition will be added to your satchel.",
  lines: [
    ["Schofield Revolver", "$98.00"],
    ["Revolver Ammo ×24", "$6.00"],
    ["Total", "$104.00"],
  ],
  confirm: "Buy",
  cancel: "Not Now",
  result: { type: "success", title: "Purchase Complete", body: "Schofield Revolver added to your weapons." },
};
const DESTRUCTIVE = {
  kicker: "Layout Manager",
  title: "Delete Streamer Layout?",
  body: "Every player using this layout will fall back to Classic. This cannot be undone.",
  confirm: "Delete Layout",
  cancel: "Keep It",
  danger: true,
  result: { type: "error", title: "Layout Deleted", body: "Players on Streamer have been moved to Classic." },
};

const kit = useKit();
const on = computed(() => kit.isActive("dialogs"));
const open = (dialog) => kit.dispatch({ type: "dialog/open", dialog });
</script>

<template>
  <Card title="Confirm Dialogs" kicker="Two choices, one decision" body-class="flex flex-col gap-4">
    <template #right><Tag :kind="on ? 'active' : 'inactive'" /></template>
    <Field label="Purchase" hint="Totals block, confirm is primary">
      <Button size="sm" :disabled="!on" @click="open(PURCHASE)">Open</Button>
    </Field>
    <Field label="Destructive" hint="Warning icon, explicit wording">
      <Button size="sm" :disabled="!on" @click="open(DESTRUCTIVE)">Open</Button>
    </Field>
    <Divider />
    <div class="tx-help flex flex-col gap-2 px-6 py-4">
      <p class="kit-heading text-[11px] text-ink">Help Text</p>
      <p class="flex flex-wrap items-center gap-2 text-[14px] leading-relaxed text-dim">
        Press <KeyCap k="R" :size="24" /> to open the ledger, or hold <KeyCap k="G" :size="24" /> to rob the register.
      </p>
    </div>
  </Card>
</template>
