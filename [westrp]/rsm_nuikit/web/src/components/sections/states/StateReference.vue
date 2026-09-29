<script setup>
import { Button, Checkbox, Counter, Divider, Icon, Tag } from "../../kit";
</script>

<!-- Every control in each of its states, side by side.
     `inert`: são estados congelados para consulta, não controles clicáveis. -->
<template>
  <div inert class="flex flex-col gap-6 select-none">
    <div class="flex flex-col gap-3">
      <p class="kit-heading text-[10px] text-faint">Buttons</p>
      <div class="grid grid-cols-2 gap-2.5">
        <Button size="sm">Default</Button>
        <Button size="sm" force-hover>Hover</Button>
        <Button size="sm" active>Active</Button>
        <Button size="sm" disabled>Inactive</Button>
        <Button size="sm" variant="primary">Primary</Button>
        <Button size="sm" variant="primary" disabled>Locked</Button>
      </div>
    </div>
    <Divider />
    <div class="flex flex-col gap-2">
      <p class="kit-heading mb-1 text-[10px] text-faint">Menu rows</p>
      <div class="row tx-plate flex items-center justify-between px-4 py-2.5 text-[14px] text-ink">
        Normal <span class="font-cat text-dim">$0.75</span>
      </div>
      <div class="row tx-plate is-current flex items-center justify-between px-4 py-2.5 text-[14px]">
        Selected <span class="font-cat">$1.20</span>
      </div>
      <div class="row tx-plate is-selected flex items-center justify-between px-4 py-2.5 text-[14px] text-ink">
        Marked <Counter size="sm">2</Counter>
      </div>
      <div class="row tx-plate is-inactive flex items-center justify-between px-4 py-2.5 text-[14px]">
        Inactive <span class="kit-heading text-[10px]">Sold out</span>
      </div>
      <div class="row tx-plate is-inactive flex items-center justify-between px-4 py-2.5 text-[14px]">
        Locked <Icon name="menu-icon-info-lock" :size="16" class="text-faint" />
      </div>
    </div>
    <Divider />
    <div class="flex flex-col gap-3">
      <p class="kit-heading text-[10px] text-faint">Checks &amp; tags</p>
      <div class="flex flex-wrap gap-x-6 gap-y-3">
        <Checkbox :model-value="false" label="Off" />
        <Checkbox :model-value="true" label="On" />
        <Checkbox :model-value="true" disabled label="Inactive" />
      </div>
      <div class="flex flex-wrap gap-2">
        <Tag kind="active" />
        <Tag kind="inactive" />
        <Tag kind="locked" />
        <Tag kind="new" />
        <Tag kind="warning" />
      </div>
    </div>
  </div>
</template>
