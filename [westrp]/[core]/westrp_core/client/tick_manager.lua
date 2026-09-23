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

    ---@type TaskContext
    local task = {
        name = name,
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
            local ok, err = pcall(fn, task)
            if not ok then
                WestRP.Shared.Logger.Error("TICK", "Erro na execução da tarefa '%s': %s", name, err)
                task.isRunning = false
                break
            end
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

---Encerra todas as tarefas ativas do TickManager (usado no onResourceStop)
function WestRP.Client.TickManager.StopAll()
    for name, task in pairs(activeTasks) do
        task.isRunning = false
    end
    activeTasks = {}
end

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        WestRP.Client.TickManager.StopAll()
    end
end)
