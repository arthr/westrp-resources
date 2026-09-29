<script setup>
import { computed, ref } from "vue";
import { useKit } from "../../../state/kit.js";
import { Button, Checkbox, Field, ProgressBar, Switch } from "../../kit";

// A small menu built from the kit, so every change is visible in context.
const kit = useKit();
const tabOpen = ref(true);
const double = ref(true);
const rows = ["Coffee", "Canned Beans", "Whiskey"];
const sel = ref(1);
const price = computed(() => (0.75 + sel.value * 0.45) * (double.value ? 2 : 1));

const buy = () =>
  kit.notify(
    "success",
    `Bought ${rows[sel.value]}`,
    `${double.value ? "A double" : "A single"} for $${price.value.toFixed(2)}, ${tabOpen.value ? "put on your tab" : "paid in cash"}.`,
  );
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="tx-header px-5 py-3.5 text-center">
      <p class="font-title text-[28px] leading-none text-ink">Saloon</p>
    </div>
    <div class="flex flex-col gap-1.5">
      <button
        v-for="(r, i) in rows"
        :key="r"
        type="button"
        :class="['row tx-plate flex cursor-pointer items-center justify-between px-4 py-2.5 text-[14px]', sel === i ? 'is-current' : 'text-ink']"
        @click="sel = i"
      >
        <span>{{ r }}</span>
        <span class="font-cat">${{ (0.75 + i * 0.45).toFixed(2) }}</span>
      </button>
    </div>
    <Field label="Tab open">
      <Switch v-model="tabOpen" :labels="['Yes', 'No']" width="7rem" />
    </Field>
    <Checkbox v-model="double" label="Pour a double" />
    <ProgressBar :value="62" />
    <div class="flex gap-2.5">
      <Button variant="primary" size="sm" class="flex-1" @click="buy">Buy</Button>
      <Button size="sm" class="flex-1" @click="kit.notify('info', 'Left the Saloon', 'Back out on the Valentine boardwalk.')">Back</Button>
    </div>
  </div>
</template>
