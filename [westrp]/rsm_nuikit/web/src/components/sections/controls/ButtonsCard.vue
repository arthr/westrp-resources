<script setup>
import { ref } from "vue";
import { useKit } from "../../../state/kit.js";
import { Button, Card, Divider, Field, IconButton } from "../../kit";

const kit = useKit();
const on = ref("tick");
const ICONS = ["tick", "cross", "lock", "star"];
</script>

<template>
  <Card title="Buttons" kicker="Primary · secondary · ghost" body-class="flex flex-col gap-5">
    <div class="flex flex-wrap gap-3">
      <Button variant="primary" @click="kit.notify('success', 'Purchase Complete', 'Bought a Bolt Action Rifle for $216.00.')">Buy Now</Button>
      <Button @click="kit.notify('info', 'Bolt Action Rifle', 'High damage, long range, slow to cycle.')">Inspect</Button>
      <Button variant="ghost" @click="kit.notify('info', 'Back', 'Returned to the gunsmith\'s catalogue.')">Back</Button>
      <Button disabled>Sold Out</Button>
    </div>
    <div class="flex flex-wrap items-center gap-3">
      <Button variant="primary" size="sm" icon="menu-icon-tick" @click="kit.notify('success', 'Invite Accepted', 'You joined Hosea\'s posse.')">
        Accept
      </Button>
      <Button size="sm" icon="cross" @click="kit.notify('warning', 'Invite Declined', 'Hosea rides on without you.')">Decline</Button>
      <Button size="lg" variant="primary" @click="kit.notify('info', 'Ride Out', 'Your posse is heading for Strawberry.')">Ride Out</Button>
    </div>
    <Divider />
    <Field label="Icon buttons" hint="Square plate, one piece of game art">
      <IconButton
        v-for="ic in ICONS"
        :key="ic"
        :icon="ic === 'tick' ? 'menu-icon-tick' : ic"
        :label="ic"
        :active="on === ic"
        @click="on = ic"
      />
    </Field>
  </Card>
</template>
