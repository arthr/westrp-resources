<script setup>
import { Card, Counter, Divider, Field, Tag } from "../../kit";
</script>

<template>
  <Card title="Badges & Counters" kicker="Small status pieces" body-class="flex flex-col gap-5">
    <Field label="Counters" hint="Quantities, unread mail, stacks">
      <Counter size="sm">3</Counter>
      <Counter>12</Counter>
      <Counter size="lg">99</Counter>
      <Counter muted>0</Counter>
    </Field>
    <Divider />
    <div class="flex flex-col gap-2.5">
      <span class="text-[14px] text-ink">Status tags</span>
      <div class="flex flex-wrap gap-2">
        <Tag kind="active" />
        <Tag kind="inactive" />
        <Tag kind="locked" />
        <Tag kind="new" />
        <Tag kind="warning">Wanted</Tag>
        <Tag kind="neutral">Provisions</Tag>
      </div>
    </div>
  </Card>
</template>
