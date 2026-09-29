import { useKit } from "../../state/KitStore.jsx";
import { SectionFrame } from "../shell/SectionFrame.jsx";
import { Button, Card, Divider, Tag } from "../kit";

// Manda para a interface exatamente a mensagem que o cliente mandaria com
// SendNUIMessage: o teste passa pelo mesmo roteador que o jogo usa.
const send = (msg) => window.postMessage(msg, "*");

const SAMPLE_CONFIRM = {
  kicker: "Valentine Gunsmith",
  title: "Buy Schofield Revolver?",
  body: "The revolver and 24 rounds of regular ammunition go into your satchel.",
  lines: [
    ["Schofield Revolver", "$98.00"],
    ["Revolver Ammo ×24", "$6.00"],
    ["Total", "$104.00"],
  ],
  confirm: "Buy",
  cancel: "Not Now",
};

const SAMPLE_HUD = [
  { action: "cores", cores: { health: { ring: 82, core: 70 }, stamina: { ring: 64, core: 92 }, deadeye: { ring: 22, core: 40 } } },
  { action: "money", cash: 142.6, gold: 2.5 },
  { action: "clock", h: 9, m: 42 },
  { action: "objective", text: "Ride to Valentine and meet the sheriff." },
  { action: "help", text: "Hold near a register to rob it. Lawmen in town will notice.", key: "G" },
];

const API = [
  {
    name: "Notify",
    side: "Client · Server",
    desc: "Feed notification at the Notifications anchor. kind is info, success, warning or error; duration in ms is optional.",
    code: `-- client
exports.rsm_nuikit:Notify("success", "Purchase Complete", "Bought 2 Coffee for $1.50.")

-- server (target -1 = every player)
exports.rsm_nuikit:Notify(source, "warning", "Wanted", "A $25.00 bounty is on your head.", 8000)`,
    test: () => send({ action: "notify", kind: "success", title: "Purchase Complete", body: "Bought 2 Coffee for $1.50." }),
  },
  {
    name: "Confirm",
    side: "Client · Server",
    desc: "Two-choice dialog. Takes the mouse only while it is open. cb(accepted) runs once; cancel, ESC, leaving or the server timeout all answer false.",
    code: `exports.rsm_nuikit:Confirm({
  kicker = "Valentine Gunsmith",
  title = "Buy Schofield Revolver?",
  lines = { { "Schofield Revolver", "$98.00" }, { "Total", "$104.00" } },
  confirm = "Buy", cancel = "Not Now", danger = false,
}, function(accepted)
  if accepted then TriggerServerEvent("myshop:buy", "schofield") end
end)

-- server: exports.rsm_nuikit:Confirm(source, opts, function(accepted) end)`,
    test: () => send({ action: "confirm", id: "test", dialog: SAMPLE_CONFIRM }),
  },
  {
    name: "SetCores",
    side: "Client",
    desc: "Health, stamina and Dead Eye in the published core style. Values 0–100; only the cores you send change. nil hides them.",
    code: `exports.rsm_nuikit:SetCores({
  health  = { ring = 82, core = 70 },
  stamina = { ring = 64, core = 92 },
  deadeye = { ring = 22, core = 40 },
})
exports.rsm_nuikit:SetCores(nil) -- hide`,
    hud: true,
    test: () => send(SAMPLE_HUD[0]),
  },
  {
    name: "SetMoney",
    side: "Client",
    desc: "Wallet and gold. The in-game clock is added automatically while it is shown. nil hides it.",
    code: `exports.rsm_nuikit:SetMoney(142.60, 2.5)
exports.rsm_nuikit:SetMoney(nil) -- hide`,
    hud: true,
    test: () => {
      send(SAMPLE_HUD[1]);
      send(SAMPLE_HUD[2]);
    },
  },
  {
    name: "SetObjective",
    side: "Client",
    desc: "The mission or job line. nil hides it.",
    code: `exports.rsm_nuikit:SetObjective("Ride to Valentine and meet the sheriff.")`,
    hud: true,
    test: () => send(SAMPLE_HUD[3]),
  },
  {
    name: "ShowHelp · HideHelp",
    side: "Client",
    desc: "Context tip with an optional keycap. For world interaction, keep using RedM's own hold-key prompts.",
    code: `exports.rsm_nuikit:ShowHelp("Hold near a register to rob it.", "G")
exports.rsm_nuikit:HideHelp()`,
    hud: true,
    test: () => send(SAMPLE_HUD[4]),
  },
  {
    name: "SetHudHidden",
    side: "Client",
    desc: "Hides everything the kit draws except Confirm dialogs, for cutscenes or photo mode. Notifications wait in the queue.",
    code: `exports.rsm_nuikit:SetHudHidden(true)
exports.rsm_nuikit:SetHudHidden(false)`,
  },
  {
    name: "IsModuleActive",
    side: "Client · Server",
    desc: "Whether a module is switched on in the published settings, so your resource can fall back to its own UI.",
    code: `if exports.rsm_nuikit:IsModuleActive("money") then
  exports.rsm_nuikit:SetMoney(cash, gold)
end`,
  },
];

function ApiCard({ api, onTest, testLabel }) {
  return (
    <Card title={api.name} kicker={api.hud ? "HUD" : "Service"} right={<Tag kind="neutral">{api.side}</Tag>} bodyClass="flex flex-col gap-4">
      <p className="text-[13.5px] leading-snug text-dim">{api.desc}</p>
      <pre className="tx-help overflow-x-auto px-5 py-4 font-sans text-[12.5px] leading-relaxed whitespace-pre text-ink [--plate:rgb(0_0_0/0.35)]">
        {api.code}
      </pre>
      {onTest && (
        <div className="flex justify-end">
          <Button size="sm" onClick={onTest}>
            {testLabel}
          </Button>
        </div>
      )}
    </Card>
  );
}

export function ServiceSection() {
  const { state, notify, isActive, closePanel } = useKit();

  const previewHud = () => {
    SAMPLE_HUD.forEach(send);
    closePanel();
  };

  // o teste de HUD manda os dados; o HUD aparece quando o estúdio fecha
  const testHud = (api) => {
    api.test();
    notify("info", `${api.name} Sent`, "The HUD shows it once the studio is closed. Use Preview the HUD to see it now.");
  };

  const testFor = (api) => {
    if (api.name === "SetHudHidden") {
      return () => send({ action: "hud:hidden", hidden: !state.hud.hidden });
    }
    if (api.name === "IsModuleActive") {
      return () =>
        notify("info", "IsModuleActive", `money → ${isActive("money")} · cores → ${isActive("cores")} · toasts → ${isActive("toasts")}`, {
          force: true,
        });
    }
    return api.hud ? () => testHud(api) : api.test;
  };

  const labelFor = (api) =>
    api.name === "SetHudHidden" ? (state.hud.hidden ? "Show the HUD" : "Hide the HUD") : api.name === "IsModuleActive" ? "Check Modules" : "Send Test";

  return (
    <SectionFrame
      title="Service API"
      hint="Any resource on the server can call these exports. The kit draws the result with the published layout, theme and modules. Test buttons send the exact message the client sends."
      actions={
        <Button variant="primary" onClick={previewHud}>
          Preview the HUD
        </Button>
      }
    >
      <div className="flex min-w-0 flex-col gap-6">
        <Card title="How Resources Use the Kit" kicker="rsm_nuikit as a service">
          <div className="grid gap-6 text-[13.5px] leading-snug text-dim min-[1400px]:grid-cols-3">
            <p>
              <span className="kit-heading mb-1.5 block text-[11px] text-ink">1 · Call an export</span>
              From a client or server script. Add <span className="text-ink">ensure rsm_nuikit</span> in server.cfg before the resources that
              use it.
            </p>
            <p>
              <span className="kit-heading mb-1.5 block text-[11px] text-ink">2 · The kit draws it</span>
              Same anchors, style and colours for every resource. The HUD never takes the mouse; only Confirm and this studio do.
            </p>
            <p>
              <span className="kit-heading mb-1.5 block text-[11px] text-ink">3 · Answers come back</span>
              Confirm results return to your callback. Text from other resources is shown as plain text, never as markup.
            </p>
          </div>
          <Divider className="my-5" />
          <p className="text-[13px] text-faint">
            Staff open this studio with <span className="text-ink">/nuikit</span> (ACE <span className="text-ink">rsm_nuikit.admin</span>). Players
            only ever see the HUD, notifications and dialogs.
          </p>
        </Card>

        <div className="grid min-w-0 grid-cols-[repeat(auto-fit,minmax(26rem,1fr))] gap-6">
          {API.map((api) => (
            <ApiCard key={api.name} api={api} onTest={testFor(api)} testLabel={labelFor(api)} />
          ))}
        </div>
      </div>
    </SectionFrame>
  );
}
