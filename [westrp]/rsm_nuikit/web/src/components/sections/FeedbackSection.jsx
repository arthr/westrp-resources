import { useState } from "react";
import { useKit } from "../../state/KitStore.jsx";
import { ANCHOR_NAMES, TOAST_SAMPLES } from "../../state/mock.js";
import { Toast } from "../hud/Toast.jsx";
import { SectionFrame } from "../shell/SectionFrame.jsx";
import { Button, Card, Counter, Divider, Field, KeyCap, ProgressBar, SliderField, StatBar, Tag } from "../kit";

const TOAST_BUTTONS = [
  { type: "info", label: "Info" },
  { type: "success", label: "Success" },
  { type: "warning", label: "Warning" },
  { type: "error", label: "Error" },
];

function NotificationsCard() {
  const { state, notify, isActive } = useKit();
  const on = isActive("toasts");
  const w = state.layout.widgets.toasts;
  return (
    <Card title="Notifications" kicker="The feed" right={<Tag kind={on ? "active" : "inactive"} />} bodyClass="flex flex-col gap-5">
      <div className="grid grid-cols-2 gap-2.5">
        {TOAST_BUTTONS.map((b) => (
          <Button
            key={b.type}
            size="sm"
            variant={b.type === "error" ? "primary" : "secondary"}
            disabled={!on}
            onClick={() => notify(b.type, TOAST_SAMPLES[b.type].title, TOAST_SAMPLES[b.type].body)}
          >
            Fire {b.label}
          </Button>
        ))}
      </div>
      <p className="text-[13px] leading-snug text-faint">
        {on
          ? `Toasts appear at ${ANCHOR_NAMES[w.anchor]} (${w.scale}%), wherever the Layout Manager puts them. Click one to dismiss it.`
          : "The Notifications module is inactive. Switch it on under Active / Inactive to fire toasts."}
      </p>
      <Divider />
      <div className="flex justify-center">
        <Toast type="warning" title={TOAST_SAMPLES.warning.title} body={TOAST_SAMPLES.warning.body} width="100%" />
      </div>
    </Card>
  );
}

function DialogsCard() {
  const { dispatch, isActive } = useKit();
  const on = isActive("dialogs");
  const open = (dialog) => dispatch({ type: "dialog/open", dialog });
  return (
    <Card title="Confirm Dialogs" kicker="Two choices, one decision" right={<Tag kind={on ? "active" : "inactive"} />} bodyClass="flex flex-col gap-4">
      <Field label="Purchase" hint="Totals block, confirm is primary">
        <Button
          size="sm"
          disabled={!on}
          onClick={() =>
            open({
              kicker: "Valentine Gunsmith",
              title: "Buy Schofield Revolver?",
              body: "The revolver and 24 rounds of regular ammunition will be added to your satchel.",
              lines: [["Schofield Revolver", "$98.00"], ["Revolver Ammo ×24", "$6.00"], ["Total", "$104.00"]],
              confirm: "Buy",
              cancel: "Not Now",
              result: { type: "success", title: "Purchase Complete", body: "Schofield Revolver added to your weapons." },
            })
          }
        >
          Open
        </Button>
      </Field>
      <Field label="Destructive" hint="Warning icon, explicit wording">
        <Button
          size="sm"
          disabled={!on}
          onClick={() =>
            open({
              kicker: "Layout Manager",
              title: "Delete Streamer Layout?",
              body: "Every player using this layout will fall back to Classic. This cannot be undone.",
              confirm: "Delete Layout",
              cancel: "Keep It",
              danger: true,
              result: { type: "error", title: "Layout Deleted", body: "Players on Streamer have been moved to Classic." },
            })
          }
        >
          Open
        </Button>
      </Field>
      <Divider />
      <div className="tx-help flex flex-col gap-2 px-6 py-4">
        <p className="kit-heading text-[11px] text-ink">Help Text</p>
        <p className="flex flex-wrap items-center gap-2 text-[14px] leading-relaxed text-dim">
          Press <KeyCap k="R" size={24} /> to open the ledger, or hold <KeyCap k="G" size={24} /> to rob the register.
        </p>
      </div>
    </Card>
  );
}

function ProgressCard() {
  const [value, setValue] = useState(64);
  return (
    <Card title="Progress" kicker="Bars and loaders" bodyClass="flex flex-col gap-5">
      <div className="flex flex-col gap-2">
        <div className="flex items-baseline justify-between text-[13px]">
          <span className="text-dim">Crafting Special Tonic</span>
          <span className="font-cat text-ink">{value}%</span>
        </div>
        <ProgressBar value={value} />
      </div>
      <SliderField label="Drive the bar" value={value} onChange={setValue} format={(v) => `${v}%`} />
      <div className="flex flex-col gap-2">
        <span className="text-[13px] text-dim">Loading saved outfits…</span>
        <ProgressBar />
      </div>
      <Divider />
      <p className="kit-heading text-[10px] text-faint">Weapon stats · Cattleman Revolver</p>
      {[
        ["Damage", 56],
        ["Range", 42],
        ["Fire rate", 50],
        ["Accuracy", 64],
        ["Reload", 38],
      ].map(([label, v]) => (
        <div key={label} className="flex items-center justify-between gap-4 text-[13px]">
          <span className="text-dim">{label}</span>
          <StatBar value={v} width={208} />
        </div>
      ))}
    </Card>
  );
}

function BadgesCard() {
  return (
    <Card title="Badges & Counters" kicker="Small status pieces" bodyClass="flex flex-col gap-5">
      <Field label="Counters" hint="Quantities, unread mail, stacks">
        <Counter size="sm">3</Counter>
        <Counter>12</Counter>
        <Counter size="lg">99</Counter>
        <Counter muted>0</Counter>
      </Field>
      <Divider />
      <div className="flex flex-col gap-2.5">
        <span className="text-[14px] text-ink">Status tags</span>
        <div className="flex flex-wrap gap-2">
          <Tag kind="active" />
          <Tag kind="inactive" />
          <Tag kind="locked" />
          <Tag kind="new" />
          <Tag kind="warning">Wanted</Tag>
          <Tag kind="neutral">Provisions</Tag>
        </div>
      </div>
    </Card>
  );
}

export function FeedbackSection() {
  return (
    <SectionFrame title="Feedback" hint="How the kit talks back: feed toasts, confirm dialogs, help text, progress and badges.">
      <div className="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(26rem,1fr))] gap-6">
        <NotificationsCard />
        <DialogsCard />
        <ProgressCard />
        <BadgesCard />
      </div>
    </SectionFrame>
  );
}
