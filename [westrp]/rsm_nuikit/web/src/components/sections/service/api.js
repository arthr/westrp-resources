// Documentação dos exports do rsm_nuikit, com o teste de cada um.
// `send` manda para a interface exatamente a mensagem que o cliente mandaria
// com SendNUIMessage: o teste passa pelo mesmo roteador que o jogo usa.
export const send = (msg) => window.postMessage(msg, "*");

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

export const SAMPLE_HUD = [
  { action: "cores", cores: { health: { ring: 82, core: 70 }, stamina: { ring: 64, core: 92 }, deadeye: { ring: 22, core: 40 } } },
  { action: "money", cash: 142.6, gold: 2.5 },
  { action: "clock", h: 9, m: 42 },
  { action: "objective", text: "Ride to Valentine and meet the sheriff." },
  { action: "help", text: "Hold near a register to rob it. Lawmen in town will notice.", key: "G" },
];

export const API = [
  {
    name: "Notify",
    side: "Client · Server",
    desc: "Feed notification where the player placed Notifications. kind is info, success, warning or error; duration in ms is optional.",
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
    desc: "Health, stamina and Dead Eye in the published core style. Values 0–100; only the cores you send change. nil hides them. Ignored while rsm_hud runs.",
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
    desc: "Wallet and gold. The in-game clock is added automatically while it is shown. nil hides it. Ignored while rsm_hud runs.",
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
    desc: "Whether a module is switched on in the published settings, so your resource can fall back to its own UI. cores and money are false while rsm_hud runs.",
    code: `if exports.rsm_nuikit:IsModuleActive("money") then
  exports.rsm_nuikit:SetMoney(cash, gold)
end`,
  },
];
