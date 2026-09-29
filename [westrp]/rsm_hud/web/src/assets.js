// Registers every masked texture the HUD uses as an absolute CSS var
// (--tex-<name>), resolved through the asset bridge so the same path works in
// the preview, the exported build and in game. Components reference them as
// var(--tex-<name>) and never build a url() of their own.
import { tex, rsmAsset } from "./nui.js";

const TEXTURES = {
  // RDR2 core meter art (ui_hud)
  "core-bg": "tex/hud/core_bg.png",
  "ring": "tex/hud/meter_99.png",
  "ring-track": "tex/hud/meter_track.png",
  "core-health": "tex/hud/core_health.png",
  "core-stamina": "tex/hud/core_stamina.png",
  "core-deadeye": "tex/hud/core_deadeye.png",
  "core-horse-health": "tex/hud/core_horse_health.png",
  "core-horse-stamina": "tex/hud/core_horse_stamina.png",

  // needs + status effects
  "need-hunger": "tex/hud/emote_action_biting_gold_coin_1.png",
  "need-thirst": "tex/hud/emote_action_drinking_cowboy_1.png",
  "need-stress": "tex/hud/agitation.png",
  "need-hygiene": "tex/hud/horse_dirty.png",
  "need-alcohol": "tex/hud/emote_dance_drunk_a.png",
  "fx-cold": "tex/hud/cold.png",
  "fx-hot": "tex/hud/hot.png",
  "fx-wounded": "tex/hud/wounded.png",
  "fx-sick": "tex/hud/sick_01.png",
  "fx-venom": "tex/hud/snake_venom.png",
  "fx-drained": "tex/hud/drained.png",
  "fx-overfed": "tex/hud/overfed.png",
  "fx-disoriented": "tex/hud/disoriented.png",

  // info glyphs
  "g-cash": "tex/hud/leaderboard_cash.png",
  "g-gold": "tex/hud/leaderboard_gold.png",
  "g-town": "tex/hud/blip_town.png",
  "g-badge": "tex/hud/overhead_deputy.png",
  "g-speaker": "tex/hud/overhead_speaker.png",
  "g-speaker-off": "tex/hud/overhead_speaker_off.png",
  "g-ammo": "tex/hud/blip_ammo_bullets.png",
  "g-horse": "tex/hud/blip_horse_owned.png",
  "wanted-plate": "tex/hud/hud_wanted_bg_trim.png", // margem vazia da esquerda recortada

  // menu chrome
  "plate": "tex/ui/help_text_1a_trim.png", // margens vazias recortadas (fatias em styles.css)
  "panel": "tex/ui/translate_bg_1a.png",
  "row": "tex/ui/selection_box_bg_1b.png",
  "btn": "tex/ui/selection_box_bg_1d.png",
  "divider": "tex/ui/divider_line.png",
  "vdivider": "tex/ui/vertical_divider_line.png",
  "outline": "tex/ui/crafting_outline.png",
  "corner-tl": "tex/ui/crafting_highlight_tl.png",
  "corner-tr": "tex/ui/crafting_highlight_tr.png",
  "corner-bl": "tex/ui/crafting_highlight_bl.png",
  "corner-br": "tex/ui/crafting_highlight_br.png",
  "tick-box": "tex/ui/tick_box.png",
  "tick": "tex/ui/tick.png",
  "arrow-l": "tex/ui/selection_arrow_left.png",
  "arrow-r": "tex/ui/selection_arrow_right.png",
  "keycap": "tex/ui/counter_bg_1a.png",
  "slider-track": "tex/ui/weapon_stats_bar.png",
  "slider-fill": "tex/ui/weapon_stats_bar_mask.png",
  "slider-thumb": "tex/ui/tank_meter_marker.png",
  "dot": "tex/ui/filter_dot.png",
};

const root = document.documentElement;
for (const [name, path] of Object.entries(TEXTURES)) {
  root.style.setProperty(`--tex-${name}`, tex(path));
}

// Full-colour item artwork, shown as-is in <img src>.
export const itemArt = (name) => rsmAsset(`tex/items/${name}.png`);
