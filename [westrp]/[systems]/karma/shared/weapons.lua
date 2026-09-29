-- ====================================================================
-- WestRP Karma — Shared: Weapons Dictionary & Ballistic Resolver
-- File: shared/weapons.lua
-- ====================================================================

---@class Weapons
Weapons = {}

local UNARMED_HASH_SIGNED = -1569615261
local UNARMED_HASH_UNSIGNED = 0xA2719263

---Registro descritivo legível de armas
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
    [GetHashKey("WEAPON_THROWN_THROWING_KNIVES")] = "WEAPON_THROWN_THROWING_KNIVES (Facas de Arremesso)",

    -- Efeitos de Área e Fogo
    [GetHashKey("WEAPON_FIRE")] = "WEAPON_FIRE (Fogo / Chamas)",
    [GetHashKey("WEAPON_EXPLOSION")] = "WEAPON_EXPLOSION (Explosão)"
}

---Categorização balística por arma
local WEAPON_CATEGORIES = {
    -- Revólveres
    [GetHashKey("WEAPON_REVOLVER_CATTLEMAN")] = "REVOLVER",
    [GetHashKey("WEAPON_REVOLVER_DOUBLEACTION")] = "REVOLVER",
    [GetHashKey("WEAPON_REVOLVER_SCHOFIELD")] = "REVOLVER",
    [GetHashKey("WEAPON_REVOLVER_LEMAT")] = "REVOLVER",
    [GetHashKey("WEAPON_REVOLVER_NAVY")] = "REVOLVER",

    -- Pistolas
    [GetHashKey("WEAPON_PISTOL_VOLCANIC")] = "PISTOL",
    [GetHashKey("WEAPON_PISTOL_SEMIAUTO")] = "PISTOL",
    [GetHashKey("WEAPON_PISTOL_MAUSER")] = "PISTOL",
    [GetHashKey("WEAPON_PISTOL_M1899")] = "PISTOL",

    -- Repetidoras
    [GetHashKey("WEAPON_REPEATER_CARBINE")] = "REPEATER",
    [GetHashKey("WEAPON_REPEATER_WINCHESTER")] = "REPEATER",
    [GetHashKey("WEAPON_REPEATER_HENRY")] = "REPEATER",
    [GetHashKey("WEAPON_REPEATER_EVANS")] = "REPEATER",

    -- Rifles & Snipers
    [GetHashKey("WEAPON_RIFLE_BOLTACTION")] = "RIFLE",
    [GetHashKey("WEAPON_RIFLE_SPRINGFIELD")] = "RIFLE",
    [GetHashKey("WEAPON_SNIPERRIFLE_ROLLINGBLOCK")] = "SNIPER",
    [GetHashKey("WEAPON_SNIPERRIFLE_CARCANO")] = "SNIPER",
    [GetHashKey("WEAPON_RIFLE_VARMINT")] = "RIFLE",

    -- Escopetas
    [GetHashKey("WEAPON_SHOTGUN_DOUBLEBARREL")] = "SHOTGUN",
    [GetHashKey("WEAPON_SHOTGUN_SAWEDOFF")] = "SHOTGUN",
    [GetHashKey("WEAPON_SHOTGUN_PUMP")] = "SHOTGUN",
    [GetHashKey("WEAPON_SHOTGUN_REPEATING")] = "SHOTGUN",
    [GetHashKey("WEAPON_SHOTGUN_SEMIAUTO")] = "SHOTGUN",

    -- Arcos e Arremesso
    [GetHashKey("WEAPON_BOW")] = "BOW",
    [GetHashKey("WEAPON_THROWN_DYNAMITE")] = "EXPLOSIVE",
    [GetHashKey("WEAPON_THROWN_MOLOTOV")] = "EXPLOSIVE",
    [GetHashKey("WEAPON_FIRE")] = "EXPLOSIVE",
    [GetHashKey("WEAPON_EXPLOSION")] = "EXPLOSIVE",
    [GetHashKey("WEAPON_THROWN_TOMAHAWK")] = "THROWN",
    [GetHashKey("WEAPON_THROWN_THROWING_KNIVES")] = "THROWN",

    -- Melee
    [GetHashKey("WEAPON_MELEE_KNIFE")] = "MELEE",
    [GetHashKey("WEAPON_MELEE_KNIFE_JAWBONE")] = "MELEE",
    [GetHashKey("WEAPON_MELEE_KNIFE_TRADER")] = "MELEE",
    [GetHashKey("WEAPON_MELEE_CLEAVER")] = "MELEE",
    [GetHashKey("WEAPON_MELEE_HATCHET")] = "MELEE",
    [GetHashKey("WEAPON_MELEE_HATCHET_HUNTER")] = "MELEE",
    [GetHashKey("WEAPON_MELEE_MACHETE")] = "MELEE",
    [GetHashKey("WEAPON_LASSO")] = "MELEE",

    -- Desarmado
    [UNARMED_HASH_SIGNED] = "UNARMED",
    [UNARMED_HASH_UNSIGNED] = "UNARMED",
    [0] = "UNARMED"
}

---Mapa de tipos de munições do RDR3 mapeados para sua família balística
local AMMO_TO_WEAPON_FAMILY = {
    -- Revólveres
    [GetHashKey("AMMO_REVOLVER")] = "REVOLVER",
    [GetHashKey("AMMO_REVOLVER_EXPRESS")] = "REVOLVER",
    [GetHashKey("AMMO_REVOLVER_HIGH_VELOCITY")] = "REVOLVER",
    [GetHashKey("AMMO_REVOLVER_SPLIT_POINT")] = "REVOLVER",
    [GetHashKey("AMMO_REVOLVER_EXPLOSIVE")] = "REVOLVER",

    -- Pistolas
    [GetHashKey("AMMO_PISTOL")] = "PISTOL",
    [GetHashKey("AMMO_PISTOL_EXPRESS")] = "PISTOL",
    [GetHashKey("AMMO_PISTOL_HIGH_VELOCITY")] = "PISTOL",
    [GetHashKey("AMMO_PISTOL_SPLIT_POINT")] = "PISTOL",
    [GetHashKey("AMMO_PISTOL_EXPLOSIVE")] = "PISTOL",

    -- Repetidoras
    [GetHashKey("AMMO_REPEATER")] = "REPEATER",
    [GetHashKey("AMMO_REPEATER_EXPRESS")] = "REPEATER",
    [GetHashKey("AMMO_REPEATER_HIGH_VELOCITY")] = "REPEATER",
    [GetHashKey("AMMO_REPEATER_SPLIT_POINT")] = "REPEATER",
    [GetHashKey("AMMO_REPEATER_EXPLOSIVE")] = "REPEATER",

    -- Rifles & Snipers
    [GetHashKey("AMMO_RIFLE")] = "RIFLE",
    [GetHashKey("AMMO_RIFLE_EXPRESS")] = "RIFLE",
    [GetHashKey("AMMO_RIFLE_HIGH_VELOCITY")] = "RIFLE",
    [GetHashKey("AMMO_RIFLE_SPLIT_POINT")] = "RIFLE",
    [GetHashKey("AMMO_RIFLE_EXPLOSIVE")] = "RIFLE",
    [GetHashKey("AMMO_RIFLE_VARMINT")] = "RIFLE",

    -- Escopetas
    [GetHashKey("AMMO_SHOTGUN")] = "SHOTGUN",
    [GetHashKey("AMMO_SHOTGUN_BUCKSHOT")] = "SHOTGUN",
    [GetHashKey("AMMO_SHOTGUN_SLUG")] = "SHOTGUN",
    [GetHashKey("AMMO_SHOTGUN_INCENDIARY")] = "SHOTGUN",
    [GetHashKey("AMMO_SHOTGUN_EXPLOSIVE")] = "SHOTGUN",

    -- Arcos
    [GetHashKey("AMMO_ARROW")] = "BOW",
    [GetHashKey("AMMO_ARROW_FIRE")] = "BOW",
    [GetHashKey("AMMO_ARROW_POISON")] = "BOW",
    [GetHashKey("AMMO_ARROW_DYNAMITE")] = "BOW",
    [GetHashKey("AMMO_ARROW_SMALL_GAME")] = "BOW",
    [GetHashKey("AMMO_ARROW_IMPROVED")] = "BOW",

    -- Arremessáveis
    [GetHashKey("AMMO_DYNAMITE")] = "EXPLOSIVE",
    [GetHashKey("AMMO_MOLOTOV")] = "EXPLOSIVE",
    [GetHashKey("AMMO_THROWING_KNIVES")] = "THROWN",
    [GetHashKey("AMMO_TOMAHAWK")] = "THROWN"
}

---Arma padrão canônica representativa por família
local DEFAULT_FAMILY_WEAPONS = {
    REVOLVER = GetHashKey("WEAPON_REVOLVER_CATTLEMAN"),
    PISTOL = GetHashKey("WEAPON_PISTOL_VOLCANIC"),
    REPEATER = GetHashKey("WEAPON_REPEATER_CARBINE"),
    RIFLE = GetHashKey("WEAPON_RIFLE_BOLTACTION"),
    SNIPER = GetHashKey("WEAPON_SNIPERRIFLE_ROLLINGBLOCK"),
    SHOTGUN = GetHashKey("WEAPON_SHOTGUN_DOUBLEBARREL"),
    BOW = GetHashKey("WEAPON_BOW"),
    THROWN = GetHashKey("WEAPON_THROWN_THROWING_KNIVES"),
    EXPLOSIVE = GetHashKey("WEAPON_THROWN_DYNAMITE"),
    MELEE = GetHashKey("WEAPON_MELEE_KNIFE"),
    UNARMED = `WEAPON_UNARMED`
}

---Verifica se a hash corresponde a mãos vazias / desarmado
---@param hash integer?
---@return boolean
function Weapons.IsUnarmed(hash)
    if not hash or hash == 0 or hash == -1 or hash == UNARMED_HASH_SIGNED or hash == UNARMED_HASH_UNSIGNED then
        return true
    end

    local hNum = tonumber(hash)
    if not hNum or hNum == 0 or hNum == -1 then return true end

    if hNum == UNARMED_HASH_SIGNED or hNum == UNARMED_HASH_UNSIGNED then
        return true
    end

    local normalized = (hNum < 0) and (hNum + 0x100000000) or hNum
    return normalized == UNARMED_HASH_UNSIGNED
end

---Retorna a categoria funcional da arma
---@param hash integer?
---@return "REVOLVER" | "PISTOL" | "REPEATER" | "RIFLE" | "SHOTGUN" | "SNIPER" | "BOW" | "THROWN" | "EXPLOSIVE" | "MELEE" | "UNARMED"
function Weapons.GetWeaponCategory(hash)
    if not hash or Weapons.IsUnarmed(hash) then
        return "UNARMED"
    end

    local hNum = tonumber(hash) or 0
    if WEAPON_CATEGORIES[hNum] then
        return WEAPON_CATEGORIES[hNum]
    end

    local altHash = (hNum > 0x7FFFFFFF) and (hNum - 0x100000000) or (hNum + 0x100000000)
    if WEAPON_CATEGORIES[altHash] then
        return WEAPON_CATEGORIES[altHash]
    end

    -- Se for uma hash de munição
    if AMMO_TO_WEAPON_FAMILY[hNum] or AMMO_TO_WEAPON_FAMILY[altHash] then
        return AMMO_TO_WEAPON_FAMILY[hNum] or AMMO_TO_WEAPON_FAMILY[altHash]
    end

    return "UNARMED"
end

---Verifica se a hash corresponde a uma arma de fogo balística
---@param hash integer?
---@return boolean
function Weapons.IsFirearm(hash)
    local cat = Weapons.GetWeaponCategory(hash)
    return cat == "REVOLVER" or cat == "PISTOL" or cat == "REPEATER" or cat == "RIFLE" or cat == "SHOTGUN" or cat == "SNIPER"
end

---Verifica se a hash corresponde a projéteis arremessáveis ou explosivos
---@param hash integer?
---@return boolean
function Weapons.IsThrowableOrExplosive(hash)
    local cat = Weapons.GetWeaponCategory(hash)
    return cat == "THROWN" or cat == "EXPLOSIVE"
end

---Resolve a arma real do jogador a partir de uma hash que pode ser uma munição ou arma
---@param rawHash integer
---@param heldWeapon integer?
---@return integer resolvedWeaponHash
function Weapons.ResolveWeaponFromAmmo(rawHash, heldWeapon)
    if not rawHash or rawHash == 0 or rawHash == -1 or Weapons.IsUnarmed(rawHash) then
        if heldWeapon and not Weapons.IsUnarmed(heldWeapon) then
            return heldWeapon
        end
        return `WEAPON_UNARMED`
    end

    local hNum = tonumber(rawHash) or 0
    local altHash = (hNum > 0x7FFFFFFF) and (hNum - 0x100000000) or (hNum + 0x100000000)

    -- 1. Se já for uma arma conhecida cadastrada
    if WEAPON_REGISTRY[hNum] or WEAPON_REGISTRY[altHash] then
        return hNum
    end

    -- 2. Se for uma munição conhecida, resolve através da família balística
    local family = AMMO_TO_WEAPON_FAMILY[hNum] or AMMO_TO_WEAPON_FAMILY[altHash]
    if family then
        -- Se o jogador está empunhando uma arma da mesma família, honra a arma empunhada
        if heldWeapon and heldWeapon ~= 0 then
            local heldCat = Weapons.GetWeaponCategory(heldWeapon)
            if heldCat == family then
                return heldWeapon
            end
        end
        -- Fallback para arma canônica padrão da família
        return DEFAULT_FAMILY_WEAPONS[family] or heldWeapon or `WEAPON_UNARMED`
    end

    -- 3. Se a arma em punho for válida, utiliza a arma em punho
    if heldWeapon and not Weapons.IsUnarmed(heldWeapon) then
        return heldWeapon
    end

    if hNum == 0 or Weapons.IsUnarmed(hNum) then
        return `WEAPON_UNARMED`
    end

    return hNum
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

    -- Se for hash de munição, gera label legível
    local family = AMMO_TO_WEAPON_FAMILY[hNum] or AMMO_TO_WEAPON_FAMILY[altHash]
    if family then
        return string.format("MUNIÇÃO_%s [Hash: %d]", family, hNum)
    end

    return string.format("ARMA_DESCONHECIDA [Hash: %d | 0x%X]", hNum, (hNum < 0) and (hNum + 0x100000000) or hNum)
end
