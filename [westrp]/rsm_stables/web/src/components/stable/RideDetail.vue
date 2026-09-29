<script setup>
import { computed } from "vue";
import { useStable } from "../../state/stable.js";
import { BOND_LABEL, CART_STATS, HORSE_STATS } from "../../lib/labels.js";
import { fmtClock } from "../../lib/format.js";
import { Button, Icon, ItemSlot, ProgressBar, Tag } from "../kit";
import DetailHead from "../common/DetailHead.vue";
import SectionLabel from "../common/SectionLabel.vue";
import StatList from "../common/StatList.vue";
import BondMeter from "../common/BondMeter.vue";
import EmptyState from "../common/EmptyState.vue";

// Ficha de um animal seu: vínculo, condição, atributos, arreios e ações
const stable = useStable();
const ride = computed(() => stable.selectedRide.value);
const isHorse = computed(() => ride.value?.type === "horse");
const injured = computed(() => (ride.value ? stable.injuredLeft(ride.value) : 0));
const xpPct = computed(() => (ride.value?.xpNext ? Math.min(100, (ride.value.xp / ride.value.xpNext) * 100) : 100));

// Arreios equipados, com a arte de cada categoria (mostrada como está)
const gear = computed(() => {
  const r = ride.value;
  if (!r || !isHorse.value) return [];
  return stable.state.data.tack
    .filter((c) => r.gear && r.gear[c.id])
    .map((c) => {
      const g = r.gear[c.id];
      const style = c.styles.find((s) => s.id === g.style);
      return { id: c.id, img: c.art, name: `${c.label}: ${style ? style.label : g.style} (cor ${g.variant})` };
    });
});
const tackTotal = computed(() => stable.state.data.tack.length);

const askRename = () => {
  const r = ride.value;
  const { min, max } = stable.nameRule.value;
  stable.state.dialog = {
    kicker: "Renomear",
    title: `Novo nome para ${r.name}`,
    confirm: "Salvar nome",
    input: { placeholder: r.name, value: r.name, maxLength: max, minLength: min, hint: `Entre ${min} e ${max} letras.` },
    onConfirm: (name) => stable.rename(r, name),
  };
};
const askRelease = () => {
  const r = ride.value;
  stable.state.dialog = {
    kicker: "Libertar animal",
    title: `Libertar ${r.name}?`,
    body: "O animal deixa o seu estábulo para sempre, junto com o vínculo e os arreios equipados nele. Não há reembolso.",
    danger: true,
    confirm: "Libertar",
    input: { placeholder: r.name, match: r.name, maxLength: Math.max(r.name.length, stable.nameRule.value.max), hint: `Digite "${r.name}" para confirmar.` },
    onConfirm: () => stable.release(r),
  };
};
</script>

<template>
  <div v-if="ride" class="flex min-h-0 flex-1 flex-col gap-6">
    <DetailHead
      :kicker="isHorse ? `Seu cavalo · ${ride.breed}` : 'Sua carroça'"
      :title="ride.name"
      :sub="isHorse ? ride.coat : ride.label"
    >
      <template #right>
        <Tag v-if="ride.active" kind="active">Ativo</Tag>
        <Tag v-if="injured > 0" kind="warning">Ferido</Tag>
      </template>
    </DetailHead>

    <div class="flex min-h-0 flex-1 flex-col gap-6 overflow-y-auto pr-2">
      <section v-if="isHorse" class="flex flex-col gap-3">
        <SectionLabel label="Vínculo">
          <span class="kit-heading text-[10px] text-dim">{{ BOND_LABEL[ride.bond] }}</span>
        </SectionLabel>
        <div class="flex items-center gap-4">
          <BondMeter :level="ride.bond" :size="22" />
          <div class="min-w-0 flex-1"><ProgressBar :value="xpPct" /></div>
        </div>
        <p class="text-right font-cat text-[13px] text-faint">{{ ride.xp }} / {{ ride.xpNext }} XP</p>
      </section>

      <section class="tx-help flex flex-col gap-3 px-6 py-4">
        <div class="flex items-center gap-3">
          <Icon name="horse-health" :size="22" :class="ride.health <= 30 ? 'text-accent' : 'text-ink'" />
          <span class="flex-1 text-[14px] text-dim">Saúde a longo prazo</span>
          <span class="font-cat text-[16px] text-ink">{{ ride.health }}%</span>
        </div>
        <ProgressBar :value="ride.health" />
        <div class="flex items-center gap-3 text-[13px]">
          <Icon :name="injured > 0 ? 'menu-icon-info-warning' : 'menu-icon-tick'" :size="15" :class="injured > 0 ? 'text-accent' : 'text-dim'" />
          <span v-if="injured > 0" class="text-ink">Se recuperando, disponível em <span class="font-cat">{{ fmtClock(injured) }}</span></span>
          <span v-else class="text-dim">Pronto para {{ isHorse ? "montar" : "atrelar" }}</span>
        </div>
      </section>

      <section class="flex flex-col gap-4">
        <SectionLabel label="Atributos" />
        <StatList :stats="ride.stats" :rows="isHorse ? HORSE_STATS : CART_STATS" />
      </section>

      <section v-if="isHorse" class="flex flex-col gap-3">
        <SectionLabel label="Arreios equipados">{{ gear.length }} de {{ tackTotal }}</SectionLabel>
        <div v-if="gear.length" class="flex flex-wrap gap-2">
          <ItemSlot v-for="g in gear" :key="g.id" :item="g" :size="56" @click="stable.openTack(ride)" />
        </div>
        <p v-else class="text-[13px] text-faint">Nenhum arreio equipado.</p>
      </section>
    </div>

    <div class="flex shrink-0 flex-col gap-3">
      <ProgressBar v-if="stable.state.busy" />
      <Button variant="primary" :disabled="ride.active || stable.state.busy" @click="stable.setActive(ride)">
        {{ ride.active ? (isHorse ? "Este é o seu cavalo ativo" : "Esta é a sua carroça ativa") : "Definir como ativo" }}
      </Button>
      <div class="grid grid-cols-2 gap-2">
        <Button v-if="isHorse" size="sm" @click="stable.openTack(ride)">Arreios</Button>
        <Button size="sm" :class="isHorse ? '' : 'col-span-2'" @click="stable.openTransfer(ride)">Transferir</Button>
        <Button size="sm" @click="askRename">Renomear</Button>
        <Button size="sm" variant="ghost" icon="cross" @click="askRelease">Libertar</Button>
      </div>
    </div>
  </div>
  <EmptyState v-else title="Estábulo vazio" body="Você ainda não tem animais. Compre o primeiro na loja.">
    <Button size="sm" variant="primary" @click="stable.setTab('shop')">Ir para a loja</Button>
  </EmptyState>
</template>
