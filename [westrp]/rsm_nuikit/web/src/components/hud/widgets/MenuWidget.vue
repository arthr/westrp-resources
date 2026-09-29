<script setup>
import { Counter, Divider } from "../../kit";

const MENU_ROWS = [
  { name: "Coffee", price: "$0.75", qty: 2 },
  { name: "Canned Beans", price: "$0.60", qty: 1, selected: true },
  { name: "Whiskey", price: "$1.20", qty: 3 },
  { name: "Horse Brush", price: "$4.00" },
  { name: "Health Tonic", price: "$2.50" },
];
</script>

<template>
  <div class="tx-card-solid flex h-full flex-col gap-4 px-8 py-8">
    <div class="tx-header px-6 py-4 text-center">
      <p class="kit-heading text-[10px] text-faint">Valentine</p>
      <p class="font-title text-[34px] leading-none text-ink">General Store</p>
    </div>
    <div class="flex flex-col gap-1.5">
      <div
        v-for="r in MENU_ROWS"
        :key="r.name"
        :class="['row tx-plate flex h-11 items-center justify-between gap-3 px-4 text-[15px]', r.selected ? 'is-current' : 'text-ink']"
      >
        <span class="flex items-center gap-2.5">
          {{ r.name }}
          <Counter v-if="r.qty > 1" size="sm" muted>{{ r.qty }}</Counter>
        </span>
        <span class="font-cat">{{ r.price }}</span>
      </div>
    </div>
    <Divider class="mt-auto" />
    <div class="flex items-center justify-between text-[14px] text-dim">
      <span class="kit-heading text-[11px]">Your Total</span>
      <span class="font-cat text-[20px] text-ink">$1.35</span>
    </div>
  </div>
</template>
