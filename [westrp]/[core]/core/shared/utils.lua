WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}
WestRP.Shared.Utils = {}

---Clona uma tabela profundamente (deep copy)
---@param orig table
---@return table
function WestRP.Shared.Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[WestRP.Shared.Utils.DeepCopy(orig_key)] = WestRP.Shared.Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, WestRP.Shared.Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

---Calcula a distância euclidiana 3D entre dois pontos
---@param coordsA vector3|table
---@param coordsB vector3|table
---@return number
function WestRP.Shared.Utils.Distance(coordsA, coordsB)
    if not coordsA or not coordsB then return 999999.0 end
    local vA = type(coordsA) == "vector3" and coordsA or vector3(coordsA.x or coordsA[1], coordsA.y or coordsA[2], coordsA.z or coordsA[3])
    local vB = type(coordsB) == "vector3" and coordsB or vector3(coordsB.x or coordsB[1], coordsB.y or coordsB[2], coordsB.z or coordsB[3])
    return #(vA - vB)
end

---Arredonda um número com precisão configurável
---@param num number
---@param decimals? number
---@return number
function WestRP.Shared.Utils.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

---Remove espaços extras no início e fim de strings
---@param str string
---@return string
function WestRP.Shared.Utils.Trim(str)
    if not str then return "" end
    return str:match("^%s*(.-)%s*$")
end
