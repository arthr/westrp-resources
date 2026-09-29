WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}
WestRP.Shared.Logger = {}

local LogLevels = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4
}

local function GetCurrentLevel()
    local lvl = WestRP.Config and WestRP.Config.LogLevel or "INFO"
    return LogLevels[lvl] or LogLevels.INFO
end

local function GetTimestamp()
    if os and type(os.date) == "function" then
        return os.date('%H:%M:%S')
    end
    local ms = GetGameTimer()
    local totalSec = math.floor(ms / 1000)
    local sec = totalSec % 60
    local min = math.floor(totalSec / 60) % 60
    local hr = math.floor(totalSec / 3600) % 24
    return string.format('%02d:%02d:%02d', hr, min, sec)
end

local function FormatMessage(prefix, color, tag, msg, ...)
    local formattedMsg = (select('#', ...) > 0) and string.format(msg, ...) or tostring(msg)
    local timestamp = GetTimestamp()
    return string.format('^7[%s] %s[%s]^7 [^3%s^7] %s^0', timestamp, color, prefix, tag or 'SYSTEM', formattedMsg)
end

---@param tag string
---@param msg string
---@param ... any
function WestRP.Shared.Logger.Debug(tag, msg, ...)
    if not (WestRP.Config and WestRP.Config.Debug) then return end
    if GetCurrentLevel() > LogLevels.DEBUG then return end
    print(FormatMessage('DEBUG', '^5', tag, msg, ...))
end

---@param tag string
---@param msg string
---@param ... any
function WestRP.Shared.Logger.Info(tag, msg, ...)
    if GetCurrentLevel() > LogLevels.INFO then return end
    print(FormatMessage('INFO', '^2', tag, msg, ...))
end

---@param tag string
---@param msg string
---@param ... any
function WestRP.Shared.Logger.Warn(tag, msg, ...)
    if GetCurrentLevel() > LogLevels.WARN then return end
    print(FormatMessage('WARN', '^3', tag, msg, ...))
end

---@param tag string
---@param msg string
---@param ... any
function WestRP.Shared.Logger.Error(tag, msg, ...)
    print(FormatMessage('ERROR', '^1', tag, msg, ...))
end
