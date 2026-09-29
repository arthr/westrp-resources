<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { toCatalog } from "../../lib/useNuiRouter.js";

// O rsm_hud de verdade, num iframe no modo espelho (?mirror=1): a mesma
// interface que os jogadores veem, alimentada daqui com as mesmas mensagens
// que o client dele manda (tema, padrões, layout). Ele só desenha; nada do que
// acontece aqui volta para o jogo nem mexe no layout salvo de ninguém.
const props = defineProps({
  page: { type: String, required: true },
  theme: { type: Object, default: null }, // { accent, surface, text, surfaceAlpha }
  policy: { type: Object, default: null }, // { preset, meterStyle, values, disabled }
  layout: { type: [Object, Boolean], default: false }, // layout salvo; false = padrões do servidor
  fill: { type: Boolean, default: false }, // true = a tela inteira; false = 1920×1080 (palco)
});
const emit = defineEmits(["ready", "fail"]);

const frame = ref(null);
const ready = ref(false);
const src = computed(() => `${props.page}${props.page.includes("?") ? "&" : "?"}mirror=1`);

// postMessage não aceita os proxies do Vue: vai sempre uma cópia simples. E só
// o que mudou de verdade (o estado do kit troca de objeto a cada ação).
let sent = {};
const send = (msg) => {
  const json = JSON.stringify(msg);
  if (sent[msg.action] === json) return;
  sent[msg.action] = json;
  frame.value?.contentWindow?.postMessage(JSON.parse(json), "*");
};
const sendTheme = () => send({ action: "hud:theme", theme: props.theme || false });
const sendPolicy = () => props.policy && send({ action: "hud:policy", policy: props.policy });
const sendLayout = () => send({ action: "hud:setLayout", layout: props.layout || false });

// Sem resposta do rsm_hud (página não encontrada, versão sem espelho) = falhou
let failTimer = 0;
const armFail = () => {
  clearTimeout(failTimer);
  failTimer = setTimeout(() => {
    if (!ready.value) emit("fail");
  }, 8000);
};

function onMessage(e) {
  if (!frame.value || e.source !== frame.value.contentWindow) return;
  const d = e.data;
  if (!d || d.source !== "rsm_hud" || d.action !== "mirror:ready") return;
  ready.value = true;
  clearTimeout(failTimer);
  sent = {}; // página nova (ou recarregada): manda tudo de novo
  // a ordem importa: com os padrões já aplicados, o layout "novo" nasce certo
  sendTheme();
  sendPolicy();
  sendLayout();
  emit("ready", toCatalog(d.catalog));
}

watch(src, () => {
  ready.value = false;
  armFail();
});
watch(
  () => props.theme,
  () => ready.value && sendTheme(),
  { deep: true },
);
watch(
  () => props.policy,
  () => ready.value && sendPolicy(),
  { deep: true },
);
watch(
  () => props.layout,
  () => ready.value && sendLayout(),
);

onMounted(() => {
  window.addEventListener("message", onMessage);
  armFail();
});
onBeforeUnmount(() => {
  window.removeEventListener("message", onMessage);
  clearTimeout(failTimer);
});
</script>

<template>
  <iframe
    ref="frame"
    :src="src"
    title="rsm_hud"
    tabindex="-1"
    aria-hidden="true"
    :class="['pointer-events-none block border-0 bg-transparent transition-opacity duration-300', fill ? 'h-full w-full' : 'h-[1080px] w-[1920px]', ready ? 'opacity-100' : 'opacity-0']"
  />
</template>
