--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.CombatConfig)
local Status = require(ReplicatedStorage.Shared.StatusService)

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local combatRemote = remotes:FindFirstChild("CombatAction") or Instance.new("RemoteEvent")
combatRemote.Name = "CombatAction"
combatRemote.Parent = remotes

local lastAction: {[Player]: {[string]: number}} = {}
local lastShieldDamage: {[Model]: number} = setmetatable({}, { __mode = "k" })

local function getParts(player: Player): (Model?, Humanoid?, BasePart?)
    local character = player.Character
    if not character then return nil, nil, nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
        return nil, nil, nil
    end
    return character, humanoid, root
end

local function canUse(player: Player, actionName: string, cooldown: number): boolean
    local actions = lastAction[player] or {}
    lastAction[player] = actions
    local now = os.clock()
    if now - (actions[actionName] or 0) < cooldown then return false end
    actions[actionName] = now
    return true
end

local function guarded(targetRoot: BasePart, attackerRoot: BasePart): boolean
    local delta = attackerRoot.Position - targetRoot.Position
    if delta.Magnitude < 0.001 then return true end
    return targetRoot.CFrame.LookVector:Dot(delta.Unit) >= Config.Guard.FrontDotThreshold
end

local function lineOfSight(attacker: Model, target: Model, from: Vector3, to: Vector3): boolean
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { attacker }
    local hit = workspace:Raycast(from, to - from, params)
    return hit == nil or hit.Instance:IsDescendantOf(target)
end

local function findTarget(attacker: Model, root: BasePart, attackData)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { attacker }

    local seen = {}
    local candidates = {}
    for _, part in workspace:GetPartBoundsInRadius(root.Position, attackData.Range, params) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and not seen[model] then
            seen[model] = true
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local targetRoot = model:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and targetRoot and targetRoot:IsA("BasePart") then
                local offset = targetRoot.Position - root.Position
                if offset.Magnitude > 0.001
                    and root.CFrame.LookVector:Dot(offset.Unit) >= attackData.ArcDotThreshold
                    and lineOfSight(attacker, model, root.Position, targetRoot.Position)
                then
                    table.insert(candidates, {model = model, humanoid = humanoid, root = targetRoot, distance = offset.Magnitude})
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    return candidates[1]
end

local function damageGuard(character: Model, amount: number)
    local current = character:GetAttribute("ShieldStamina")
    if typeof(current) ~= "number" then current = Config.MaxShieldStamina end
    local remaining = math.max(0, current - amount)
    character:SetAttribute("ShieldStamina", remaining)
    lastShieldDamage[character] = os.clock()
    if remaining <= 0 then
        Status.Clear(character, "Blocking")
        Status.Set(character, "Stunned", true, Config.Guard.BrokenGuardStun)
    end
end

local function performAttack(player: Player, actionName: string)
    local data = Config.Attacks[actionName]
    if not data then return end

    local character, _, root = getParts(player)
    if not character or not root or not Status.CanAttack(character) then return end
    if not canUse(player, actionName, data.Cooldown) then return end

    if actionName == "Kick" then
        Status.Clear(character, "Blocking")
        Status.Set(character, "Kicking", true, data.ActiveTime)
    else
        Status.Set(character, "Attacking", actionName, data.ActiveTime)
    end

    task.delay(math.min(0.12, data.ActiveTime), function()
        if not character.Parent or not root.Parent then return end
        local target = findTarget(character, root, data)
        if not target then return end

        local isBlocking = Status.IsActive(target.model, "Blocking") and guarded(target.root, root)
        if actionName == "Kick" then
            if isBlocking then
                damageGuard(target.model, data.ShieldStaminaDamage)
            else
                target.humanoid:TakeDamage(data.Damage)
                Status.Set(target.model, "Stunned", true, data.OpenTargetStun)
            end
        elseif isBlocking then
            damageGuard(target.model, Config.Guard.DamageStaminaCost)
        else
            target.humanoid:TakeDamage(data.Damage)
        end
    end)
end

combatRemote.OnServerEvent:Connect(function(player: Player, actionName: any, payload: any)
    if typeof(actionName) ~= "string" then return end
    if actionName == "Block" then
        if typeof(payload) ~= "boolean" then return end
        local character = getParts(player)
        if not character then return end
        if payload and Status.CanAct(character) and (character:GetAttribute("ShieldStamina") or 0) > 0 then
            Status.Set(character, "Blocking", true)
        else
            Status.Clear(character, "Blocking")
        end
        return
    end
    performAttack(player, actionName)
end)

RunService.Heartbeat:Connect(function(dt)
    local now = os.clock()
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if not character then continue end
        local stamina = character:GetAttribute("ShieldStamina")
        if typeof(stamina) ~= "number" or stamina >= Config.MaxShieldStamina then continue end
        if Status.IsActive(character, "Blocking") then continue end
        if now - (lastShieldDamage[character] or 0) < Config.ShieldRegenDelay then continue end
        character:SetAttribute("ShieldStamina", math.min(Config.MaxShieldStamina, stamina + Config.ShieldRegenPerSecond * dt))
    end
end)

local function initialize(character: Model)
    character:SetAttribute("ShieldStamina", Config.MaxShieldStamina)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(initialize)
end)

Players.PlayerRemoving:Connect(function(player)
    lastAction[player] = nil
end)
