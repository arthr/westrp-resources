import { useState } from "react";
import { useKit } from "../../state/KitStore.jsx";
import { InventoryCard } from "../inventory/InventoryCard.jsx";
import { SectionFrame } from "../shell/SectionFrame.jsx";
import {
  ArrowSelector, Button, Card, Checkbox, Divider, Field, IconButton, RadioGroup, SliderField, Stepper, Tabs,
  TextInput,
} from "../kit";

function ButtonsCard() {
  const { notify } = useKit();
  const [on, setOn] = useState("tick");
  return (
    <Card title="Buttons" kicker="Primary · secondary · ghost" bodyClass="flex flex-col gap-5">
      <div className="flex flex-wrap gap-3">
        <Button variant="primary" onClick={() => notify("success", "Purchase Complete", "Bought a Bolt Action Rifle for $216.00.")}>
          Buy Now
        </Button>
        <Button onClick={() => notify("info", "Bolt Action Rifle", "High damage, long range, slow to cycle.")}>Inspect</Button>
        <Button variant="ghost" onClick={() => notify("info", "Back", "Returned to the gunsmith's catalogue.")}>
          Back
        </Button>
        <Button disabled>Sold Out</Button>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button variant="primary" size="sm" icon="menu-icon-tick" onClick={() => notify("success", "Invite Accepted", "You joined Hosea's posse.")}>
          Accept
        </Button>
        <Button size="sm" icon="cross" onClick={() => notify("warning", "Invite Declined", "Hosea rides on without you.")}>
          Decline
        </Button>
        <Button size="lg" variant="primary" onClick={() => notify("info", "Ride Out", "Your posse is heading for Strawberry.")}>
          Ride Out
        </Button>
      </div>
      <Divider />
      <Field label="Icon buttons" hint="Square plate, one piece of game art">
        {["tick", "cross", "lock", "star"].map((ic) => (
          <IconButton
            key={ic}
            icon={ic === "tick" ? "menu-icon-tick" : ic}
            label={ic}
            active={on === ic}
            onClick={() => setOn(ic)}
          />
        ))}
      </Field>
    </Card>
  );
}

function SelectorsCard() {
  const [time, setTime] = useState("Dusk");
  const [weather, setWeather] = useState("Overcast");
  const [horse, setHorse] = useState("Arabian");
  const [qty, setQty] = useState(2);
  return (
    <Card title="Arrow Selectors" kicker="The RDR menu row" bodyClass="flex flex-col gap-4">
      <Field label="Time of day">
        <ArrowSelector options={["Dawn", "Noon", "Dusk", "Night"]} value={time} onChange={setTime} />
      </Field>
      <Field label="Weather">
        <ArrowSelector options={["Sunny", "Overcast", "Rain", "Fog", "Snow"]} value={weather} onChange={setWeather} />
      </Field>
      <Field label="Horse" hint="Locked until level 12">
        <ArrowSelector options={["Arabian", "Morgan", "Mustang"]} value={horse} onChange={setHorse} disabled />
      </Field>
      <Divider />
      <Field label="Coffee" hint={`$0.75 each · total $${(qty * 0.75).toFixed(2)}`}>
        <Stepper value={qty} onChange={setQty} min={1} max={10} />
      </Field>
    </Card>
  );
}

function ChecksCard() {
  const [blips, setBlips] = useState(true);
  const [cine, setCine] = useState(false);
  const [diff, setDiff] = useState("gunslinger");
  return (
    <Card title="Checks & Radios" kicker="Tick box and ring" bodyClass="flex flex-col gap-4">
      <Checkbox checked={blips} onChange={setBlips} label="Show map blips" hint="Stores, stables, post offices" />
      <Checkbox checked={cine} onChange={setCine} label="Cinematic camera" hint="While riding on roads" />
      <Checkbox checked={false} onChange={() => {}} disabled label="Hardcore mode" hint="Set by the server owner" />
      <Divider />
      <RadioGroup
        value={diff}
        onChange={setDiff}
        options={[
          { value: "greenhorn", label: "Greenhorn", hint: "Forgiving aim assist" },
          { value: "gunslinger", label: "Gunslinger", hint: "Standard assist" },
          { value: "outlaw", label: "Outlaw", hint: "Free aim only", disabled: true },
        ]}
      />
    </Card>
  );
}

function SlidersCard() {
  const [music, setMusic] = useState(70);
  const [sfx, setSfx] = useState(85);
  const [bet, setBet] = useState(12.5);
  return (
    <Card title="Sliders" kicker="Bar track, diamond thumb" bodyClass="flex flex-col gap-5">
      <SliderField label="Music volume" value={music} onChange={setMusic} format={(v) => `${v}%`} />
      <SliderField label="Effects volume" value={sfx} onChange={setSfx} format={(v) => `${v}%`} />
      <SliderField label="Poker bet" value={bet} min={0.5} max={50} step={0.5} onChange={setBet} format={(v) => `$${v.toFixed(2)}`} />
      <SliderField label="Controller dead zone" value={20} onChange={() => {}} disabled format={(v) => `${v}%`} />
    </Card>
  );
}

function InputsCard() {
  const [name, setName] = useState("Hosea Matthews");
  const [amount, setAmount] = useState("25.00");
  const [q, setQ] = useState("");
  return (
    <Card title="Inputs" kicker="Fields on the dark plate" bodyClass="flex flex-col gap-4">
      <div className="flex flex-col gap-1.5">
        <span className="text-[13px] text-dim">Character name</span>
        <TextInput value={name} onChange={setName} maxLength={24} suffix={<span className="font-cat text-[12px] text-faint">{name.length}/24</span>} />
      </div>
      <div className="flex flex-col gap-1.5">
        <span className="text-[13px] text-dim">Deposit amount</span>
        <TextInput value={amount} onChange={(v) => setAmount(v.replace(/[^\d.]/g, ""))} prefix="$" inputMode="decimal" />
      </div>
      <div className="flex flex-col gap-1.5">
        <span className="text-[13px] text-dim">Search</span>
        <TextInput value={q} onChange={setQ} placeholder="Search the catalogue…" />
      </div>
    </Card>
  );
}

function TabsCard() {
  const [tab, setTab] = useState("all");
  const [view, setView] = useState("grid");
  const counts = { all: 42, food: 23, tonic: 3, kit: 1 };
  return (
    <Card title="Tabs" kicker="Chip plates · current tab takes the accent" bodyClass="flex flex-col gap-5">
      <Tabs
        value={tab}
        onChange={setTab}
        items={[
          { value: "all", label: "All", count: counts.all },
          { value: "food", label: "Provisions", count: counts.food },
          { value: "tonic", label: "Tonics", count: counts.tonic },
          { value: "kit", label: "Kit", count: counts.kit },
          { value: "gun", label: "Weapons", disabled: true },
        ]}
      />
      <p className="text-[13px] text-dim">
        Showing <span className="font-cat text-ink">{counts[tab]}</span> items in this tab. Weapons is locked until the gunsmith opens.
      </p>
      <Divider />
      <Field label="Compact strip" hint="Small size for toolbars">
        <Tabs
          size="sm"
          value={view}
          onChange={setView}
          items={[
            { value: "grid", label: "Grid" },
            { value: "list", label: "List" },
          ]}
        />
      </Field>
    </Card>
  );
}

export function ControlsSection() {
  return (
    <SectionFrame title="Controls" hint="Every input the kit ships, each in its live and inactive form. Everything here is clickable.">
      <div className="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(24rem,1fr))] gap-6">
        <InventoryCard />
        <ButtonsCard />
        <SelectorsCard />
        <ChecksCard />
        <SlidersCard />
        <InputsCard />
        <TabsCard />
      </div>
    </SectionFrame>
  );
}
