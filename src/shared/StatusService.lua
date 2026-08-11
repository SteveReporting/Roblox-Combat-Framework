--!strict

local StatusService = {}
local activeTokens: {[Instance]: {[string]: {}}} = setmetatable({}, { __mode = "k" })
local PREFIX = "State_"

local function key(name: string): string
    return PREFIX .. name
end

local function bucket(character: Model): {[string]: {}}
    local current = activeTokens[character]
    if current then return current end
    current = {}
    activeTokens[character] = current
    return current
end

function StatusService.Set(character: Model, name: string, value: any, duration: number?)
    character:SetAttribute(key(name), value)
    local tokens = bucket(character)
    local token = {}
    tokens[name] = token

    if duration and duration > 0 then
        task.delay(duration, function()
            if character.Parent and tokens[name] == token then
                tokens[name] = nil
                character:SetAttribute(key(name), nil)
            end
        end)
    end
end

function StatusService.Clear(character: Model, name: string)
    local tokens = activeTokens[character]
    if tokens then tokens[name] = nil end
    character:SetAttribute(key(name), nil)
end

function StatusService.IsActive(character: Model, name: string): boolean
    local value = character:GetAttribute(key(name))
    return value ~= nil and value ~= false
end

function StatusService.CanAct(character: Model): boolean
    return not StatusService.IsActive(character, "Stunned")
end

function StatusService.CanAttack(character: Model): boolean
    return StatusService.CanAct(character)
        and not StatusService.IsActive(character, "Attacking")
        and not StatusService.IsActive(character, "Kicking")
end

return StatusService
