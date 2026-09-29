WestRP = WestRP or {}
WestRP.Client = WestRP.Client or {}
WestRP.Client.TickManager = {}

local activeTasks = {}

---@class TaskContext
---@field public name string
---@field public interval number
---@field public isRunning boolean
---@field public SetInterval fun(self: TaskContext, ms: number)
---@field public Stop fun(self: TaskContext)

---Cria e inicia uma tarefa gerenciada com intervalo adaptativo dinâmico
---@param name string
---@param fn fun(task: TaskContext)
---@param initialInterval? number
---@return TaskContext
function WestRP.Client.TickManager.CreateTask(name, fn, initialInterval)
    if activeTasks[name] then
        WestRP.Client.TickManager.RemoveTask(name)
    end

    local owner = GetInvokingResource() or GetCurrentResourceName()

    ---@type TaskContext
    local task = {
        name = name,
        owner = owner,
        interval = initialInterval or 1000,
        isRunning = true,
        SetInterval = function(self, ms)
            self.interval = math.max(0, ms or 0)
        end,
        Stop = function(self)
            self.isRunning = false
        end
    }

    activeTasks[name] = task

    CreateThread(function()
        while task.isRunning do
            if not task.isRunning then break end
            local ok, err = pcall(fn, task)
            if not ok then
                local errStr = tostring(err or "")
                if string.find(errStr, "script host failed") or string.find(errStr, "function reference") or not task.isRunning then
                    task.isRunning = false
                    break
                end
                WestRP.Shared.Logger.Error("TICK", "Erro na execução da tarefa '%s': %s", name, err)
                task.isRunning = false
                break
            end
            if not task.isRunning then break end
            Wait(task.interval)
        end
        activeTasks[name] = nil
    end)

    return task
end

---Remove e encerra imediatamente uma tarefa gerenciada
---@param name string
function WestRP.Client.TickManager.RemoveTask(name)
    if activeTasks[name] then
        activeTasks[name].isRunning = false
        activeTasks[name] = nil
    end
end

---Registra um tick gerenciado (executado a cada frame com interval 0 por padrão)
---@param name string
---@param fn fun()
---@param interval? number ms (padrão 0)
function WestRP.Client.TickManager.RegisterTick(name, fn, interval)
    return WestRP.Client.TickManager.CreateTask(name, function(task)
        fn()
    end, interval or 0)
end

---Desregistra e remove um tick gerenciado
---@param name string
function WestRP.Client.TickManager.UnregisterTick(name)
    WestRP.Client.TickManager.RemoveTask(name)
end

---Encerra todas as tarefas ativas do TickManager (usado no onResourceStop)
function WestRP.Client.TickManager.StopAll()
    for name, task in pairs(activeTasks) do
        task.isRunning = false
    end
    activeTasks = {}
end

local function handleResourceStop(resName)
    if resName == GetCurrentResourceName() then
        WestRP.Client.TickManager.StopAll()
    else
        for name, task in pairs(activeTasks) do
            if task.owner == resName then
                task.isRunning = false
                activeTasks[name] = nil
            end
        end
    end
end

AddEventHandler('onResourceStop', handleResourceStop)
AddEventHandler('onClientResourceStop', handleResourceStop)
