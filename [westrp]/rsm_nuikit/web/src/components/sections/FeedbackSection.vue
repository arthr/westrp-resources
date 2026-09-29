<script setup>
import SectionFrame from "../shell/SectionFrame.vue";
import NotificationsCard from "./feedback/NotificationsCard.vue";
import DialogsCard from "./feedback/DialogsCard.vue";
import ProgressCard from "./feedback/ProgressCard.vue";
import BadgesCard from "./feedback/BadgesCard.vue";
</script>

<template>
  <SectionFrame title="Feedback" hint="How the kit talks back: feed toasts, confirm dialogs, help text, progress and badges.">
    <div class="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(26rem,1fr))] gap-6">
      <NotificationsCard />
      <DialogsCard />
      <ProgressCard />
      <BadgesCard />
    </div>
  </SectionFrame>
</template>
