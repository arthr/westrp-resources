<script setup>
import { ref } from "vue";
import { ArrowSelector, Card, Divider, Field, Stepper } from "../../kit";

const time = ref("Dusk");
const weather = ref("Overcast");
const horse = ref("Arabian");
const qty = ref(2);
</script>

<template>
  <Card title="Arrow Selectors" kicker="The RDR menu row" body-class="flex flex-col gap-4">
    <Field label="Time of day">
      <ArrowSelector v-model="time" :options="['Dawn', 'Noon', 'Dusk', 'Night']" />
    </Field>
    <Field label="Weather">
      <ArrowSelector v-model="weather" :options="['Sunny', 'Overcast', 'Rain', 'Fog', 'Snow']" />
    </Field>
    <Field label="Horse" hint="Locked until level 12">
      <ArrowSelector v-model="horse" :options="['Arabian', 'Morgan', 'Mustang']" disabled />
    </Field>
    <Divider />
    <Field label="Coffee" :hint="`$0.75 each · total $${(qty * 0.75).toFixed(2)}`">
      <Stepper v-model="qty" :min="1" :max="10" />
    </Field>
  </Card>
</template>
