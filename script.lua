-- HVH Menu para Criminality
-- LocalScript em StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ===== VARIÁVEIS =====
local ESPEnabled = true
local AimLockEnabled = true
local FullBrightEnabled = false
local TeamCheckESP = true
local TeamCheckAim = true
local RainbowESP = false
local MaxScreenDistance = 400
local OnlyVisibles = false          -- NOVA OPÇÃO

local AllyColor = Color3.fromRGB(0, 150, 255)
local EnemyColor = Color3.fromRGB(255, 40, 40)

local Friends = {}
local ESP = {}
local LockedTarget = nil
local IsLocking = false

-- Sistema de Bind
local AimBind = {
	Type = "KeyCode",
	Value = Enum.KeyCode.C,
	Name = "C"
}
local WaitingForBind = false

local NoClipEnabled = false

local OriginalLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Ambient = Lighting.Ambient,
	ColorShift_Top = Lighting.ColorShift_Top,
	ColorShift_Bottom = Lighting.ColorShift_Bottom
}

-- ===== FULL BRIGHT =====
local function setFullBright(enabled)
	if enabled then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
		Lighting.Ambient = Color3.fromRGB(150, 150, 150)
		Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
		Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	else
		Lighting.Brightness = OriginalLighting.Brightness
		Lighting.ClockTime = OriginalLighting.ClockTime
		Lighting.FogEnd = OriginalLighting.FogEnd
		Lighting.GlobalShadows = OriginalLighting.GlobalShadows
		Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
		Lighting.Ambient = OriginalLighting.Ambient
		Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
		Lighting.ColorShift_Bottom = OriginalLighting.ColorShift_Bottom
	end
end

-- ===== AUXILIARES =====
local function getBestPart(character)
	if not character then return nil end
	return character:FindFirstChild("Head")
		or character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChildWhichIsA("BasePart")
end

local function isFriend(player)
	return Friends[player.UserId] == true
end

local function isEnemy(player)
	if isFriend(player) then return false end
	if not player.Team or not LocalPlayer.Team then return true end
	return player.Team ~= LocalPlayer.Team
end

local function getTeamColor(player)
	if RainbowESP then
		local t = tick() * 2
		return Color3.fromHSV(t % 1, 1, 1)
	end
	if isFriend(player) or not isEnemy(player) then
		return AllyColor
	else
		return EnemyColor
	end
end

-- ===== CHECAGEM DE VISIBILIDADE =====
local function isVisible(part)
	if not part then return false end

	local origin = Camera.CFrame.Position
	local targetPos = part.Position
	local direction = (targetPos - origin)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {LocalPlayer.Character}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)

	if not result then
		return true -- nada no caminho
	end

	-- Se acertou alguma parte do personagem do alvo, está visível
	return result.Instance:IsDescendantOf(part.Parent)
end

-- ===== ESP =====
local function createESP(character, player)
	if not ESPEnabled then return end
	if not character or not player or player == LocalPlayer then return end

	if ESP[character] then
		if ESP[character].Highlight then ESP[character].Highlight:Destroy() end
		if ESP[character].Billboard then ESP[character].Billboard:Destroy() end
		ESP[character] = nil
	end

	if TeamCheckESP and not isEnemy(player) and not isFriend(player) then return end

	local targetPart = getBestPart(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not targetPart or not humanoid or humanoid.Health <= 0 then return end

	local color = getTeamColor(player)

	local highlight = Instance.new("Highlight")
	highlight.Name = "Chams"
	highlight.Adornee = character
	highlight.FillColor = color
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Adornee = targetPart
	billboard.Size = UDim2.new(0, 220, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 2500
	billboard.Parent = character

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName .. (isFriend(player) and " [AMIGO]" or "")
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.Parent = billboard

	ESP[character] = {
		Highlight = highlight,
		Billboard = billboard,
		Label = nameLabel
	}

	humanoid.Died:Once(function()
		if ESP[character] then
			if ESP[character].Highlight then ESP[character].Highlight:Destroy() end
			if ESP[character].Billboard then ESP[character].Billboard:Destroy() end
			ESP[character] = nil
		end
		if LockedTarget and LockedTarget:IsDescendantOf(character) then
			LockedTarget = nil
		end
	end)
end

local function removeESP(character)
	if ESP[character] then
		if ESP[character].Highlight then ESP[character].Highlight:Destroy() end
		if ESP[character].Billboard then ESP[character].Billboard:Destroy() end
		ESP[character] = nil
	end
end

local function removeAllESP()
	for character, data in pairs(ESP) do
		if data.Highlight then data.Highlight:Destroy() end
		if data.Billboard then data.Billboard:Destroy() end
	end
	table.clear(ESP)
end

local function refreshAllESP()
	removeAllESP()
	if not ESPEnabled then return end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			task.spawn(createESP, player.Character, player)
		end
	end
end

RunService.RenderStepped:Connect(function()
	if not RainbowESP or not ESPEnabled then return end
	local color = Color3.fromHSV(tick() * 2 % 1, 1, 1)
	for _, data in pairs(ESP) do
		if data.Highlight then
			data.Highlight.FillColor = color
		end
		if data.Label then
			data.Label.TextColor3 = color
		end
	end
end)

-- ===== AIM LOCK =====
local function getClosestPartToMouse()
	local mousePos = UserInputService:GetMouseLocation()
	local closestPart = nil
	local closestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			if isFriend(player) then continue end

			local part = getBestPart(player.Character)
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

			if part and humanoid and humanoid.Health > 0 then
				if TeamCheckAim and not isEnemy(player) then continue end

				-- Only Visibles
				if OnlyVisibles and not isVisible(part) then continue end

				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if distance < closestDistance and distance < MaxScreenDistance then
						closestDistance = distance
						closestPart = part
					end
				end
			end
		end
	end
	return closestPart
end

local function isAimBindHeld()
	if AimBind.Type == "UserInputType" then
		return UserInputService:IsMouseButtonPressed(AimBind.Value)
	else
		return UserInputService:IsKeyDown(AimBind.Value)
	end
end

local function updateLock()
	if not AimLockEnabled then 
		IsLocking = false
		LockedTarget = nil
		return 
	end

	if isAimBindHeld() then
		IsLocking = true
		local newTarget = getClosestPartToMouse()
		if newTarget then
			LockedTarget = newTarget
		end
		if LockedTarget and LockedTarget.Parent then
			Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, LockedTarget.Position)
		end
	else
		IsLocking = false
		LockedTarget = nil
	end
end

RunService.RenderStepped:Connect(updateLock)

-- Detecta a nova bind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not WaitingForBind then return end
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		AimBind.Type = "KeyCode"
		AimBind.Value = input.KeyCode
		AimBind.Name = input.KeyCode.Name
		WaitingForBind = false
		Rayfield:Notify({
			Title = "Bind Definida",
			Content = "Tecla: " .. AimBind.Name,
			Duration = 3
		})
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.MouseButton2 
		or input.UserInputType == Enum.UserInputType.MouseButton3 then

		AimBind.Type = "UserInputType"
		AimBind.Value = input.UserInputType
		AimBind.Name = input.UserInputType.Name
		WaitingForBind = false
		Rayfield:Notify({
			Title = "Bind Definida",
			Content = "Mouse: " .. AimBind.Name,
			Duration = 3
		})
	end
end)

-- ===== NOCLIP =====
local NoClipConnection
local function setNoClip(enabled)
	NoClipEnabled = enabled
	if NoClipConnection then
		NoClipConnection:Disconnect()
		NoClipConnection = nil
	end

	if enabled then
		NoClipConnection = RunService.Stepped:Connect(function()
			local char = LocalPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	end
end

-- ===== SETUP PLAYERS =====
local function setupPlayer(player)
	if player == LocalPlayer then return end

	local function onCharacterAdded(character)
		task.spawn(function()
			for i = 1, 20 do
				task.wait(0.2)
				if getBestPart(character) and character:FindFirstChildOfClass("Humanoid") then
					createESP(character, player)
					break
				end
			end
		end)
	end

	if player.Character then onCharacterAdded(player.Character) end
	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(function(character) removeESP(character) end)
end

for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	if player.Character then removeESP(player.Character) end
	Friends[player.UserId] = nil
end)

task.spawn(function()
	while true do
		task.wait(2)
		if ESPEnabled then refreshAllESP() end
	end
end)

-- ===== MENU =====
local Window = Rayfield:CreateWindow({
	Name = "seven menu",
	LoadingTitle = "Carregando...",
	LoadingSubtitle = "esse cheat funciona pra qualquer jogo...",
	ConfigurationSaving = { Enabled = false },
	KeySystem = false
})

-- ABA ESP
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateToggle({
	Name = "Ativar ESP",
	CurrentValue = true,
	Callback = function(Value)
		ESPEnabled = Value
		if Value then refreshAllESP() else removeAllESP() end
	end,
})

ESPTab:CreateToggle({
	Name = "Team Check",
	CurrentValue = true,
	Callback = function(Value)
		TeamCheckESP = Value
		refreshAllESP()
	end,
})

ESPTab:CreateToggle({
	Name = "Rainbow ESP (RGB)",
	CurrentValue = false,
	Callback = function(Value)
		RainbowESP = Value
		if not Value then refreshAllESP() end
	end,
})

ESPTab:CreateColorPicker({
	Name = "Cor Aliado / Amigo",
	Color = AllyColor,
	Callback = function(Value)
		AllyColor = Value
		if not RainbowESP then refreshAllESP() end
	end,
})

ESPTab:CreateColorPicker({
	Name = "Cor Inimigo",
	Color = EnemyColor,
	Callback = function(Value)
		EnemyColor = Value
		if not RainbowESP then refreshAllESP() end
	end,
})

-- ABA AIM LOCK
local AimTab = Window:CreateTab("Aim Lock", 4483362458)

AimTab:CreateToggle({
	Name = "Ativar Aim Lock",
	CurrentValue = true,
	Callback = function(Value)
		AimLockEnabled = Value
		if not Value then
			IsLocking = false
			LockedTarget = nil
		end
	end,
})

AimTab:CreateToggle({
	Name = "Only Visibles",
	CurrentValue = false,
	Callback = function(Value)
		OnlyVisibles = Value
	end,
})

AimTab:CreateButton({
	Name = "Trocar Bind (atual: C)",
	Callback = function()
		WaitingForBind = true
		Rayfield:Notify({
			Title = "Aguardando Bind",
			Content = "Pressione qualquer tecla ou botão do mouse...",
			Duration = 5
		})
	end,
})

AimTab:CreateToggle({
	Name = "Team Check",
	CurrentValue = true,
	Callback = function(Value) TeamCheckAim = Value end,
})

AimTab:CreateSlider({
	Name = "Área de Detecção",
	Range = {100, 1000},
	Increment = 10,
	Suffix = "px",
	CurrentValue = 400,
	Callback = function(Value) MaxScreenDistance = Value end,
})

AimTab:CreateParagraph({
	Title = "Como usar",
	Content = "• Only Visibles: só trava em inimigos que estão visíveis (sem parede na frente)\n• Clique em Trocar Bind e pressione a tecla/botão desejado\n• Segure a bind para grudar"
})

-- ABA VISUALS
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

VisualsTab:CreateToggle({
	Name = "Full Bright",
	CurrentValue = false,
	Callback = function(Value)
		FullBrightEnabled = Value
		setFullBright(Value)
	end,
})

-- ABA MISC
local MiscTab = Window:CreateTab("MISC", 4483362458)

MiscTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {16, 150},
	Increment = 1,
	CurrentValue = 16,
	Callback = function(Value)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Value
		end
	end,
})

MiscTab:CreateSlider({
	Name = "JumpPower",
	Range = {50, 200},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(Value)
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.JumpPower = Value
			humanoid.UseJumpPower = true
		end
	end,
})

MiscTab:CreateToggle({
	Name = "NoClip",
	CurrentValue = false,
	Callback = function(Value)
		setNoClip(Value)
	end,
})

-- Sistema de Amigos
local function getPlayerNames()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(list, player.DisplayName .. " (@" .. player.Name .. ")")
		end
	end
	return #list > 0 and list or {"Nenhum player"}
end

local SelectedPlayer = nil

local PlayerDropdown = MiscTab:CreateDropdown({
	Name = "Selecionar Player",
	Options = getPlayerNames(),
	CurrentOption = {"Nenhum player"},
	Callback = function(Value)
		SelectedPlayer = Value[1]
	end,
})

MiscTab:CreateButton({
	Name = "Atualizar Lista",
	Callback = function()
		PlayerDropdown:Refresh(getPlayerNames())
	end,
})

MiscTab:CreateButton({
	Name = "Adicionar Amigo",
	Callback = function()
		if not SelectedPlayer or SelectedPlayer == "Nenhum player" then return end
		for _, player in ipairs(Players:GetPlayers()) do
			local full = player.DisplayName .. " (@" .. player.Name .. ")"
			if full == SelectedPlayer then
				Friends[player.UserId] = true
				refreshAllESP()
				Rayfield:Notify({Title = "Amigo", Content = player.DisplayName .. " adicionado", Duration = 3})
				break
			end
		end
	end,
})

MiscTab:CreateButton({
	Name = "Remover Amigo",
	Callback = function()
		if not SelectedPlayer then return end
		for _, player in ipairs(Players:GetPlayers()) do
			local full = player.DisplayName .. " (@" .. player.Name .. ")"
			if full == SelectedPlayer then
				Friends[player.UserId] = nil
				refreshAllESP()
				Rayfield:Notify({Title = "Amigo", Content = player.DisplayName .. " removido", Duration = 3})
				break
			end
		end
	end,
})

MiscTab:CreateButton({
	Name = "Limpar Amigos",
	Callback = function()
		table.clear(Friends)
		refreshAllESP()
	end,
})

MiscTab:CreateParagraph({
	Title = "Amigos",
	Content = "Amigos aparecem no ESP mas o Aim Lock nunca trava neles."
})

print("[Criminality HVH] Only Visibles adicionado")
