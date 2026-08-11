--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatAction") :: RemoteEvent

local toggleGuard = false
local holdGuard = false
local actionLock = false

local LOCKS = {
    Slash = 0.35,
    Stab = 0.42,
    Kick = 0.55,
}

local function syncGuard()
    remote:FireServer("Block", toggleGuard or holdGuard)
end

local function requestAttack(name: "Slash" | "Stab" | "Kick")
    if actionLock then return end
    local character = player.Character
    if not character or character:GetAttribute("State_Stunned") then return end

    actionLock = true
    if name == "Kick" then
        toggleGuard = false
        holdGuard = false
        syncGuard()
    end

    remote:FireServer(name)
    task.delay(LOCKS[name], function()
        actionLock = false
    end)
end

ContextActionService:BindAction("Slash", function(_, state)
    if state == Enum.UserInputState.Begin then requestAttack("Slash") end
    return Enum.ContextActionResult.Sink
end, false, Enum.UserInputType.MouseButton1)

ContextActionService:BindAction("Stab", function(_, state)
    if state == Enum.UserInputState.Begin then requestAttack("Stab") end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.R)

ContextActionService:BindAction("Kick", function(_, state)
    if state == Enum.UserInputState.Begin then requestAttack("Kick") end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.K)

ContextActionService:BindAction("ToggleGuard", function(_, state)
    if state == Enum.UserInputState.Begin then
        toggleGuard = not toggleGuard
        syncGuard()
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.E)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdGuard = true
        syncGuard()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdGuard = false
        syncGuard()
    end
end)
