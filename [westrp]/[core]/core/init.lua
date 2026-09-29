--[[
    WestRP Framework — Unified Client/Server Initializer (Hybrid SDK Architecture)
    
    Uso no fxmanifest.lua de qualquer resource:
        shared_scripts {
            '@westrp_core/init.lua',
            -- seus scripts aqui...
        }

    Garante:
    1. Utilitários locais (TickManager, PromptManager, Logger) rodando no runtime do próprio script.
    2. Zero erros de "script host failed / invalid function reference" ao reiniciar scripts (ensure).
    3. Destruição garantida de threads e prompts nativos do RDR3 no onResourceStop.
    4. Conexão reativa e não-bloqueante com os serviços mestres do westrp_core (Bridge, DB, RPC).
]]

local isServer = IsDuplicityVersion()
local currentResource = GetCurrentResourceName()
local isCore = (currentResource == 'westrp_core')

WestRP = WestRP or {}
WestRP.Shared = WestRP.Shared or {}

if isServer then
    WestRP.Server = WestRP.Server or {}
else
    WestRP.Client = WestRP.Client or {}
end

-- ============================================================================
-- 1. LOGGER LOCAL (Alta Performance & Zero Overhead de Export)
-- ============================================================================
local LOG_COLORS = {
    DEBUG = "^5", -- Ciano
    INFO  = "^2", -- Verde
    WARN  = "^3", -- Amarelo
    ERROR = "^1", -- Vermelho
    RESET = "^0"
}

local function FormatLog(level, tag, msg, ...)
    local formatted = string.format(msg, ...)
    local color = LOG_COLORS[level] or LOG_COLORS.RESET
    return string.format("%s[%s]^0 ^4[%s]^0 %s[%s]^0 %s",
        color, level, currentResource, color, tostring(tag), formatted)
end

WestRP.Shared.Logger = {
    Debug = function(tag, msg, ...)
        print(FormatLog("DEBUG", tag, msg, ...))
    end,
    Info = function(tag, msg, ...)
        print(FormatLog("INFO", tag, msg, ...))
    end,
    Warn = function(tag, msg, ...)
        print(FormatLog("WARN", tag, msg, ...))
    end,
    Error = function(tag, msg, ...)
        print(FormatLog("ERROR", tag, msg, ...))
    end
}

-- ============================================================================
-- 2. CLIENT-SIDE UTILITIES (TickManager & PromptManager Locais)
-- ============================================================================
if not isServer then
    -- ------------------------------------------------------------------------
    -- 2.1 TICK MANAGER LOCAL (Dynamic Sleep 0.00ms no Runtime do Script)
    -- ------------------------------------------------------------------------
    local localTasks = {}

    ---@class LocalTaskContext
    ---@field public name string
    ---@field public interval number
    ---@field public isRunning boolean
    ---@field public SetInterval fun(self: LocalTaskContext, ms: number)
    ---@field public Stop fun(self: LocalTaskContext)

    WestRP.Client.TickManager = {
        ---Cria e inicia uma tarefa gerenciada local com intervalo adaptativo dinâmico
        ---@param name string
        ---@param fn fun(task: LocalTaskContext)
        ---@param initialInterval? number
        ---@return LocalTaskContext
        CreateTask = function(name, fn, initialInterval)
            if localTasks[name] then
                localTasks[name].isRunning = false
                localTasks[name] = nil
            end

            ---@type LocalTaskContext
            local task = {
                name = name,
                interval = math.max(0, initialInterval or 1000),
                isRunning = true,
                SetInterval = function(self, ms)
                    self.interval = math.max(0, ms or 0)
                end,
                Stop = function(self)
                    self.isRunning = false
                end
            }

            localTasks[name] = task

            CreateThread(function()
                while task.isRunning do
                    local ok, err = pcall(fn, task)
                    if not ok then
                        WestRP.Shared.Logger.Error("TICK", "Erro na tarefa '%s': %s", name, tostring(err))
                        task.isRunning = false
                        break
                    end
                    if not task.isRunning then break end
                    Wait(task.interval)
                end
                localTasks[name] = nil
            end)

            return task
        end,

        ---Remove e encerra imediatamente uma tarefa gerenciada local
        ---@param name string
        RemoveTask = function(name)
            local task = localTasks[name]
            if task then
                task.isRunning = false
                localTasks[name] = nil
            end
        end,

        ---Registra um tick gerenciado (atalho para CreateTask com intervalo 0)
        ---@param name string
        ---@param fn fun()
        ---@param interval? number
        RegisterTick = function(name, fn, interval)
            return WestRP.Client.TickManager.CreateTask(name, function(_)
                fn()
            end, interval or 0)
        end,

        ---Encerra todas as tarefas locais ativas
        StopAll = function()
            for _, task in pairs(localTasks) do
                task.isRunning = false
            end
            localTasks = {}
        end
    }

    -- ------------------------------------------------------------------------
    -- 2.2 PROMPT MANAGER LOCAL (RDR3 Prompts com Ciclo de Vida Nativo)
    -- ------------------------------------------------------------------------
    local localPrompts = {}

    ---@class LocalPromptInstance
    ---@field public handle number
    ---@field public text string
    ---@field public control number
    ---@field public isHold boolean
    ---@field public SetVisible fun(self: LocalPromptInstance, visible: boolean)
    ---@field public SetEnabled fun(self: LocalPromptInstance, enabled: boolean)
    ---@field public SetText fun(self: LocalPromptInstance, text: string)
    ---@field public IsCompleted fun(self: LocalPromptInstance): boolean
    ---@field public IsJustPressed fun(self: LocalPromptInstance): boolean
    ---@field public Delete fun(self: LocalPromptInstance)

    WestRP.Client.PromptManager = {
        ---Cria e configura um prompt nativo do RDR3 com ciclo de vida local gerenciado
        ---@param options { text: string, control: number, hold?: boolean, holdTime?: number, group?: number }
        ---@return LocalPromptInstance
        Create = function(options)
            local prompt = PromptRegisterBegin()
            PromptSetControlAction(prompt, options.control or 0x760A9C6F)

            local str = CreateVarString(10, 'LITERAL_STRING', options.text or "Interagir")
            PromptSetText(prompt, str)

            PromptSetEnabled(prompt, true)
            PromptSetVisible(prompt, true)

            local isHold = options.hold == true
            if isHold then
                PromptSetHoldMode(prompt, options.holdTime or 1000)
            else
                PromptSetStandardMode(prompt, true)
            end

            if options.group then
                PromptSetGroup(prompt, options.group)
            end

            PromptRegisterEnd(prompt)

            ---@type LocalPromptInstance
            local instance = {
                handle = prompt,
                text = options.text or "",
                control = options.control or 0x760A9C6F,
                isHold = isHold,
                SetVisible = function(self, visible)
                    if self.handle then
                        PromptSetVisible(self.handle, visible)
                    end
                end,
                SetEnabled = function(self, enabled)
                    if self.handle then
                        PromptSetEnabled(self.handle, enabled)
                    end
                end,
                SetText = function(self, newText)
                    if self.handle then
                        local s = CreateVarString(10, 'LITERAL_STRING', newText)
                        PromptSetText(self.handle, s)
                        self.text = newText
                    end
                end,
                IsCompleted = function(self)
                    if not self.handle then return false end
                    if self.isHold then
                        return PromptHasHoldModeCompleted(self.handle)
                    end
                    return PromptHasStandardModeCompleted(self.handle)
                end,
                IsJustPressed = function(self)
                    if not self.handle then return false end
                    return PromptIsJustPressed(self.handle)
                end,
                Delete = function(self)
                    if self.handle then
                        PromptDelete(self.handle)
                        localPrompts[self.handle] = nil
                        self.handle = nil
                    end
                end
            }

            localPrompts[prompt] = instance
            return instance
        end,

        ---Deleta todos os prompts registrados por este recurso
        DeleteAll = function()
            for handle, _ in pairs(localPrompts) do
                if handle then
                    PromptDelete(handle)
                end
            end
            localPrompts = {}
        end
    }

    -- ------------------------------------------------------------------------
    -- 2.3 LIMPEZA AUTOMÁTICA DE CICLO DE VIDA LOCAL (onResourceStop)
    -- ------------------------------------------------------------------------
    local function HandleResourceCleanup(resName)
        if resName == currentResource then
            WestRP.Client.TickManager.StopAll()
            WestRP.Client.PromptManager.DeleteAll()
        end
    end

    AddEventHandler('onResourceStop', HandleResourceCleanup)
    AddEventHandler('onClientResourceStop', HandleResourceCleanup)

    -- ------------------------------------------------------------------------
    -- 2.4 UI BRIDGE (Proxied para westrp_ui)
    -- ------------------------------------------------------------------------
    WestRP.Client.UI = WestRP.Client.UI or {}
    local uiMethods = {
        'OpenDock', 'CloseDock', 'IsDockOpen', 'UpdateItem', 'ShowToast',
        'OpenPanel', 'ClosePanel', 'IsPanelOpen',
        'OpenDialog', 'CloseDialog', 'IsDialogOpen', 'PromptInput',
        'OpenConfirm', 'CloseConfirm', 'IsConfirmOpen',
        'OpenRadial', 'CloseRadial', 'IsRadialOpen', 'RegisterRadialItem', 'UnregisterRadialItem',
        'StartProgressBar', 'ProgressBar', 'CancelProgressBar', 'IsProgressBarActive'
    }

    for _, method in ipairs(uiMethods) do
        if not WestRP.Client.UI[method] then
            WestRP.Client.UI[method] = function(...)
                if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                    return exports['westrp_ui'][method](exports['westrp_ui'], ...)
                end
                return nil
            end
        end
    end

    -- Submódulo de HUD Nativo (0.00ms via Scaleform / DataBinding)
    WestRP.Client.UI.NativeHUD = {
        ConfigureHonorScale = function(minVal, maxVal, defaultDuration)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_ConfigureHonorScale(minVal, maxVal, defaultDuration)
            end
        end,
        GetHonorScale = function()
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_GetHonorScale()
            end
        end,
        ConfigureHonorOverlays = function(wheel, status, delay)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_ConfigureHonorOverlays(wheel, status, delay)
            end
        end,
        GetHonorOverlaysConfig = function()
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_GetHonorOverlaysConfig()
            end
        end,
        CacheHonor = function(val)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_CacheHonor(val)
            end
        end,
        GetCachedHonor = function()
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_GetCachedHonor()
            end
        end,
        NormalizeHonor = function(val, customMin, customMax)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_NormalizeHonor(val, customMin, customMax)
            end
        end,
        SetHonor = function(lvl, dur, customMin, customMax)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_SetHonor(lvl, dur, customMin, customMax)
            end
        end,
        AnimateHonor = function(fromLvl, toLvl, stepDelay, holdDur, customMin, customMax)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_AnimateHonor(fromLvl, toLvl, stepDelay, holdDur, customMin, customMax)
            end
        end,
        HideHonor = function()
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_HideHonor()
            end
        end,
        StartTimer = function(dur, alert)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_StartTimer(dur, alert)
            end
        end,
        StopTimer = function()
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_StopTimer()
            end
        end,
        ShowCash = function(d, c)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_ShowCash(d, c)
            end
        end,
        SetRank = function(name, rank, xp)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_SetRank(name, rank, xp)
            end
        end,
        SetBounty = function(text, vis)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] then
                return exports['westrp_ui']:NativeHUD_SetBounty(text, vis)
            end
        end,
    }

    setmetatable(WestRP.Client.UI, {
        __index = function(_, k)
            if GetResourceState('westrp_ui') == 'started' and exports['westrp_ui'] and exports['westrp_ui'][k] then
                return function(...)
                    return exports['westrp_ui'][k](exports['westrp_ui'], ...)
                end
            end
            return nil
        end
    })
end

-- ============================================================================
-- 3. RESOLVER DE SERVIÇOS DO KERNEL (Bridge, DB, Security, Callback)
-- ============================================================================
if not isCore then
    local cachedCore = nil

    local function GetCore()
        if cachedCore then return cachedCore end
        if GetResourceState('westrp_core') == 'started' then
            local ok, core = pcall(function()
                return exports['westrp_core']:GetCoreObject()
            end)
            if ok and core then
                cachedCore = core
                return cachedCore
            end
        end
        return nil
    end

    local function SyncCoreReferences()
        local core = GetCore()
        if not core then return end

        if core.Shared then
            WestRP.Shared.Bridge = core.Shared.Bridge
            WestRP.Shared.Callback = core.Shared.Callback
            WestRP.Shared.Utils = core.Shared.Utils
            WestRP.Shared.Config = core.Shared.Config
        end

        if isServer and core.Server then
            WestRP.Server.Security = core.Server.Security
            WestRP.Server.Database = core.Server.Database
            WestRP.Server.Callback = core.Server.Callback
            WestRP.Server.Feed = core.Server.Feed
        elseif not isServer and core.Client then
            WestRP.Client.Callback = core.Client.Callback
            WestRP.Client.Feed = core.Client.Feed
        end
    end

    -- Sincroniza imediatamente na primeira tentativa
    SyncCoreReferences()

    -- Re-sincroniza caso o westrp_core seja iniciado/reiniciado posteriormente
    AddEventHandler('onResourceStart', function(resName)
        if resName == 'westrp_core' then
            cachedCore = nil
            Wait(50)
            SyncCoreReferences()
        end
    end)

    -- Metatables para fallback sob demanda (Lazy Loading) caso chamado antes do core subir
    setmetatable(WestRP.Shared, {
        __index = function(t, k)
            local core = GetCore()
            if core and core.Shared and core.Shared[k] then
                t[k] = core.Shared[k]
                return t[k]
            end
            return nil
        end
    })

    if isServer then
        setmetatable(WestRP.Server, {
            __index = function(t, k)
                local core = GetCore()
                if core and core.Server and core.Server[k] then
                    t[k] = core.Server[k]
                    return t[k]
                end
                return nil
            end
        })
    else
        setmetatable(WestRP.Client, {
            __index = function(t, k)
                if k == 'TickManager' or k == 'PromptManager' or k == 'UI' then
                    return rawget(t, k)
                end
                local core = GetCore()
                if core and core.Client and core.Client[k] then
                    t[k] = core.Client[k]
                    return t[k]
                end
                return nil
            end
        })
    end
end
