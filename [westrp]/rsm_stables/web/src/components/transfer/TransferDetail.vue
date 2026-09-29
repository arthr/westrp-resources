<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import OfferDetail from "./OfferDetail.vue";
import SendForm from "./SendForm.vue";
import EmptyState from "../common/EmptyState.vue";

const stable = useStable();
const sel = computed(() => stable.transferItem.value);
</script>

<template>
  <OfferDetail v-if="sel && sel.kind === 'offer'" :key="sel.item.id" :offer="sel.item" />
  <SendForm v-else-if="sel" :ride="sel.item" />
  <EmptyState v-else icon="menu-icon-invite-sent" title="Nada para transferir" body="Sem propostas e sem animais no seu estábulo." />
</template>
