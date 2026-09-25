-- ====================================================================
-- WestRP Karma — Shared: Weapons Dictionary & Resolver
-- File: shared/weapons.lua
-- ====================================================================

---@class Weapons
Weapons = {}

local UNARMED_HASH_SIGNED = -1569615261
local UNARMED_HASH_UNSIGNED = 0xA2719263

local WEAPON_REGISTRY = {
    -- Desarmado / Punhos / Mãos
    [UNARMED_HASH_SIGNED] = "WEAPON_UNARMED (Desarmado / Mãos)",
    [UNARMED_HASH_UNSIGNED] = "WEAPON_UNARMED (Desarmado / Mãos)",
    [0] = "WEAPON_UNARMED (Desarmado / Mãos)",

    -- Armas Brancas / Melee
    [GetHashKey("WEAPON_MELEE_KNIFE")] = "WEAPON_MELEE_KNIFE (Faca)",
    [GetHashKey("WEAPON_MELEE_KNIFE_JAWBONE")] = "WEAPON_MELEE_KNIFE_JAWBONE (Faca de Mandíbula)",
    [GetHashKey("WEAPON_MELEE_KNIFE_TRADER")] = "WEAPON_MELEE_KNIFE_TRADER (Faca do Mercador)",
    [GetHashKey("WEAPON_MELEE_CLEAVER")] = "WEAPON_MELEE_CLEAVER (Cutelo)",
    [GetHashKey("WEAPON_MELEE_HATCHET")] = "WEAPON_MELEE_HATCHET (Machadinha)",
    [GetHashKey("WEAPON_MELEE_HATCHET_HUNTER")] = "WEAPON_MELEE_HATCHET_HUNTER (Machadinha de Caça)",
    [GetHashKey("WEAPON_MELEE_MACHETE")] = "WEAPON_MELEE_MACHETE (Facão / Machete)",
    [GetHashKey("WEAPON_LASSO")] = "WEAPON_LASSO (Laço)",

    -- Revólveres
    [GetHashKey("WEAPON_REVOLVER_CATTLEMAN")] = "WEAPON_REVOLVER_CATTLEMAN (Cattleman)",
    [GetHashKey("WEAPON_REVOLVER_DOUBLEACTION")] = "WEAPON_REVOLVER_DOUBLEACTION (Double-Action)",
    [GetHashKey("WEAPON_REVOLVER_SCHOFIELD")] = "WEAPON_REVOLVER_SCHOFIELD (Schofield)",
    [GetHashKey("WEAPON_REVOLVER_LEMAT")] = "WEAPON_REVOLVER_LEMAT (LeMat)",
    [GetHashKey("WEAPON_REVOLVER_NAVY")] = "WEAPON_REVOLVER_NAVY (Navy)",

    -- Pistolas
    [GetHashKey("WEAPON_PISTOL_VOLCANIC")] = "WEAPON_PISTOL_VOLCANIC (Volcanic)",
    [GetHashKey("WEAPON_PISTOL_SEMIAUTO")] = "WEAPON_PISTOL_SEMIAUTO (Semi-Auto)",
    [GetHashKey("WEAPON_PISTOL_MAUSER")] = "WEAPON_PISTOL_MAUSER (Mauser)",
    [GetHashKey("WEAPON_PISTOL_M1899")] = "WEAPON_PISTOL_M1899 (M1899)",

    -- Repetidoras
    [GetHashKey("WEAPON_REPEATER_CARBINE")] = "WEAPON_REPEATER_CARBINE (Carabina)",
    [GetHashKey("WEAPON_REPEATER_WINCHESTER")] = "WEAPON_REPEATER_WINCHESTER (Lancaster)",
    [GetHashKey("WEAPON_REPEATER_HENRY")] = "WEAPON_REPEATER_HENRY (Litchfield)",
    [GetHashKey("WEAPON_REPEATER_EVANS")] = "WEAPON_REPEATER_EVANS (Evans)",

    -- Rifles & Snipers
    [GetHashKey("WEAPON_RIFLE_BOLTACTION")] = "WEAPON_RIFLE_BOLTACTION (Bolt Action)",
    [GetHashKey("WEAPON_RIFLE_SPRINGFIELD")] = "WEAPON_RIFLE_SPRINGFIELD (Springfield)",
    [GetHashKey("WEAPON_SNIPERRIFLE_ROLLINGBLOCK")] = "WEAPON_SNIPERRIFLE_ROLLINGBLOCK (Rolling Block)",
    [GetHashKey("WEAPON_SNIPERRIFLE_CARCANO")] = "WEAPON_SNIPERRIFLE_CARCANO (Carcano)",
    [GetHashKey("WEAPON_RIFLE_VARMINT")] = "WEAPON_RIFLE_VARMINT (Varmint)",

    -- Escopetas
    [GetHashKey("WEAPON_SHOTGUN_DOUBLEBARREL")] = "WEAPON_SHOTGUN_DOUBLEBARREL (Cano Duplo)",
    [GetHashKey("WEAPON_SHOTGUN_SAWEDOFF")] = "WEAPON_SHOTGUN_SAWEDOFF (Cano Serrado)",
    [GetHashKey("WEAPON_SHOTGUN_PUMP")] = "WEAPON_SHOTGUN_PUMP (Pump Shotgun)",
    [GetHashKey("WEAPON_SHOTGUN_REPEATING")] = "WEAPON_SHOTGUN_REPEATING (Repetidora Cal. 12)",
    [GetHashKey("WEAPON_SHOTGUN_SEMIAUTO")] = "WEAPON_SHOTGUN_SEMIAUTO (Semi-Auto)",

    -- Arcos e Arremesso
    [GetHashKey("WEAPON_BOW")] = "WEAPON_BOW (Arco)",
    [GetHashKey("WEAPON_THROWN_DYNAMITE")] = "WEAPON_THROWN_DYNAMITE (Dinamite)",
    [GetHashKey("WEAPON_THROWN_MOLOTOV")] = "WEAPON_THROWN_MOLOTOV (Cóctel Molotov)",
    [GetHashKey("WEAPON_THROWN_TOMAHAWK")] = "WEAPON_THROWN_TOMAHAWK (Tomahawk)",
    [GetHashKey("WEAPON_THROWN_THROWING_KNIVES")] = "WEAPON_THROWN_THROWING_KNIVES (Facas de Arremesso)"
}

---Verifica se a hash corresponde a mãos vazias / desarmado
---@param hash integer?
---@return boolean
function Weapons.IsUnarmed(hash)
    if not hash or hash == 0 or hash == UNARMED_HASH_SIGNED or hash == UNARMED_HASH_UNSIGNED then
        return true
    end

    local hNum = tonumber(hash)
    if not hNum then return false end

    if hNum == UNARMED_HASH_SIGNED or hNum == UNARMED_HASH_UNSIGNED then
        return true
    end

    local normalized = (hNum < 0) and (hNum + 0x100000000) or hNum
    return normalized == UNARMED_HASH_UNSIGNED
end

---Retorna o nome legível da arma formatado para logs
---@param hash integer?
---@return string
function Weapons.GetWeaponLabel(hash)
    if not hash or hash == 0 or Weapons.IsUnarmed(hash) then
        return "WEAPON_UNARMED (Desarmado / Mãos)"
    end

    local hNum = tonumber(hash) or 0
    if WEAPON_REGISTRY[hNum] then
        return WEAPON_REGISTRY[hNum]
    end

    local altHash = (hNum > 0x7FFFFFFF) and (hNum - 0x100000000) or (hNum + 0x100000000)
    if WEAPON_REGISTRY[altHash] then
        return WEAPON_REGISTRY[altHash]
    end

    return string.format("ARMA_DESCONHECIDA [Hash: %d | 0x%X]", hNum, (hNum < 0) and (hNum + 0x100000000) or hNum)
end
