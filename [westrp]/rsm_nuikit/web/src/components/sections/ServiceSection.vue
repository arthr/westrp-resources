<script setup>
import { useKit } from "../../state/kit.js";
import SectionFrame from "../shell/SectionFrame.vue";
import ApiCard from "./service/ApiCard.vue";
import { API, SAMPLE_HUD, send } from "./service/api.js";
import { Button, Card, Divider } from "../kit";

const kit = useKit();

const previewHud = () => {
  SAMPLE_HUD.forEach(send);
  kit.closePanel();
};

// o teste de HUD manda os dados; o HUD aparece quando o estúdio fecha
const runTest = (api) => {
  if (api.name === "SetHudHidden") {
    send({ action: "hud:hidden", hidden: !kit.state.hud.hidden });
    return;
  }
  if (api.name === "IsModuleActive") {
    kit.notify(
      "info",
      "IsModuleActive",
      `money → ${kit.isActive("money")} · cores → ${kit.isActive("cores")} · toasts → ${kit.isActive("toasts")}`,
      { force: true },
    );
    return;
  }
  api.test();
  if (api.hud) {
    kit.notify("info", `${api.name} Sent`, "The HUD shows it once the studio is closed. Use Preview the HUD to see it now.");
  }
};

const labelFor = (api) => {
  if (api.name === "SetHudHidden") return kit.state.hud.hidden ? "Show the HUD" : "Hide the HUD";
  if (api.name === "IsModuleActive") return "Check Modules";
  return "Send Test";
};
</script>

<template>
  <SectionFrame
    title="Service API"
    hint="Any resource on the server can call these exports. The kit draws the result with the published theme and modules, where each player placed it. Test buttons send the exact message the client sends."
  >
    <template #actions>
      <Button variant="primary" @click="previewHud">Preview the HUD</Button>
    </template>

    <div class="flex min-w-0 flex-col gap-6">
      <Card title="How Resources Use the Kit" kicker="rsm_nuikit as a service">
        <div class="grid gap-6 text-[13.5px] leading-snug text-dim min-[1400px]:grid-cols-3">
          <p>
            <span class="kit-heading mb-1.5 block text-[11px] text-ink">1 · Call an export</span>
            From a client or server script. Add <span class="text-ink">ensure rsm_nuikit</span> in server.cfg before the resources that
            use it.
          </p>
          <p>
            <span class="kit-heading mb-1.5 block text-[11px] text-ink">2 · The kit draws it</span>
            Same placement, style and colours for every resource. The HUD never takes the mouse; only Confirm and this studio do.
          </p>
          <p>
            <span class="kit-heading mb-1.5 block text-[11px] text-ink">3 · Answers come back</span>
            Confirm results return to your callback. Text from other resources is shown as plain text, never as markup.
          </p>
        </div>
        <Divider class="my-5" />
        <p class="text-[13px] text-faint">
          Staff open this studio with <span class="text-ink">/nuikit</span> (ACE <span class="text-ink">rsm_nuikit.admin</span>). Players
          only ever see the HUD, notifications and dialogs.
        </p>
      </Card>

      <div class="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(26rem,1fr))] gap-6">
        <ApiCard v-for="api in API" :key="api.name" :api="api" :test-label="labelFor(api)" @test="runTest(api)" />
      </div>
    </div>
  </SectionFrame>
</template>
