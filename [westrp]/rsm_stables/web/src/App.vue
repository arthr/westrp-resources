<script setup>
import { provideStable } from "./state/stable.js";
import { useStableKeys } from "./lib/useStableKeys.js";
import StableShell from "./components/StableShell.vue";
import StableDialog from "./components/common/StableDialog.vue";
import PreviewToast from "./components/common/PreviewToast.vue";
import PreviewReopen from "./components/common/PreviewReopen.vue";

// rsm_stables: loja, estábulo, arreios e transferências, no visual do rsm_nuikit.
// O meio da tela fica livre para a câmera mostrar o animal.
const stable = provideStable();
useStableKeys(stable);
</script>

<template>
  <Transition
    enter-active-class="transition-opacity duration-200"
    enter-from-class="opacity-0"
    leave-active-class="transition-opacity duration-150"
    leave-to-class="opacity-0"
  >
    <StableShell v-if="stable.state.open && stable.state.data" />
  </Transition>
  <PreviewReopen v-if="!stable.state.open && !stable.isGame" />
  <StableDialog />
  <PreviewToast v-if="!stable.isGame" />
</template>
