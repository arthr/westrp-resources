WestRP = WestRP or {}
WestRP.Client = WestRP.Client or {}
WestRP.Client.PromptManager = {}

local activePrompts = {}

---@class PromptInstance
---@field public handle number
---@field public text string
---@field public control number
---@field public isHold boolean
---@field public SetVisible fun(self: PromptInstance, visible: boolean)
---@field public SetEnabled fun(self: PromptInstance, enabled: boolean)
---@field public SetText fun(self: PromptInstance, text: string)
---@field public IsCompleted fun(self: PromptInstance): boolean
---@field public IsJustPressed fun(self: PromptInstance): boolean
---@field public Delete fun(self: PromptInstance)

---Cria e configura um prompt nativo do RDR3 com ciclo de vida gerenciado
---@param options { text: string, control: number, hold?: boolean, holdTime?: number, group?: number }
---@return PromptInstance
function WestRP.Client.PromptManager.Create(options)
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

    ---@type PromptInstance
    local instance = {
        handle = prompt,
        text = options.text or "",
        control = options.control or 0x760A9C6F,
        isHold = isHold,
        SetVisible = function(self, visible)
            PromptSetVisible(self.handle, visible)
        end,
        SetEnabled = function(self, enabled)
            PromptSetEnabled(self.handle, enabled)
        end,
        SetText = function(self, newText)
            local s = CreateVarString(10, 'LITERAL_STRING', newText)
            PromptSetText(self.handle, s)
            self.text = newText
        end,
        IsCompleted = function(self)
            if self.isHold then
                return PromptHasHoldModeCompleted(self.handle)
            end
            return PromptHasStandardModeCompleted(self.handle)
        end,
        IsJustPressed = function(self)
            return PromptIsJustPressed(self.handle)
        end,
        Delete = function(self)
            if self.handle then
                PromptDelete(self.handle)
                activePrompts[self.handle] = nil
                self.handle = nil
            end
        end
    }

    activePrompts[prompt] = instance
    return instance
end

---Remove todos os prompts gerenciados (invocado no descarregamento)
function WestRP.Client.PromptManager.DeleteAll()
    for handle, prompt in pairs(activePrompts) do
        if handle then
            PromptDelete(handle)
        end
    end
    activePrompts = {}
end

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        WestRP.Client.PromptManager.DeleteAll()
    end
end)
