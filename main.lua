-- Roblox Universal Hub v3.0 - Verbessert
local hub = {}
hub.version = "3.0"
hub.running = true
hub.minimized = false
hub.guiVisible = true

hub.settings = {
	theme = "Dark",
	transparency = 0.1,
	hotkey = Enum.KeyCode.RightShift,
	guiPosition = nil,
	guiToggleKey = Enum.KeyCode.F2,
	guiColor = "Dark",
	guiOpacity = 0.9,
}

hub.data = {
	teleportSlots = {}, -- {slot1 = Vector3, slot2 = Vector3, ...}
	teleportHistory = {},
	deathPosition = nil,
	isFlying = false,
	isNoclipping = false,
	infiniteJumpEnabled = false,
	deathReturnEnabled = false,
	deathReturnTimer = 0,
	deathReturnDelay = 5, -- Sekunden
	multiTeleportSlots = {}, -- {1 = Vector3, 2 = Vector3, ...}
	currentTeleportIndex = 0,
}

hub.connections = {}
hub.loops = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local themes = {
	Dark = {
		primary = Color3.fromRGB(20, 20, 20),
		secondary = Color3.fromRGB(35, 35, 35),
		accent = Color3.fromRGB(100, 200, 255),
		text = Color3.fromRGB(255, 255, 255),
	},
	Red = {
		primary = Color3.fromRGB(30, 20, 20),
		secondary = Color3.fromRGB(50, 30, 30),
		accent = Color3.fromRGB(255, 80, 80),
		text = Color3.fromRGB(255, 255, 255),
	},
	Pink = {
		primary = Color3.fromRGB(40, 20, 35),
		secondary = Color3.fromRGB(60, 30, 50),
		accent = Color3.fromRGB(255, 105, 180),
		text = Color3.fromRGB(255, 255, 255),
	},
	White = {
		primary = Color3.fromRGB(240, 240, 240),
		secondary = Color3.fromRGB(220, 220, 220),
		accent = Color3.fromRGB(100, 150, 255),
		text = Color3.fromRGB(30, 30, 30),
	},
	Purple = {
		primary = Color3.fromRGB(30, 20, 40),
		secondary = Color3.fromRGB(45, 30, 60),
		accent = Color3.fromRGB(200, 100, 255),
		text = Color3.fromRGB(255, 255, 255),
	},
	Blue = {
		primary = Color3.fromRGB(20, 30, 45),
		secondary = Color3.fromRGB(30, 45, 65),
		accent = Color3.fromRGB(100, 150, 255),
		text = Color3.fromRGB(255, 255, 255),
	},
	AMOLED = {
		primary = Color3.fromRGB(0, 0, 0),
		secondary = Color3.fromRGB(10, 10, 10),
		accent = Color3.fromRGB(100, 200, 255),
		text = Color3.fromRGB(255, 255, 255),
	}
}

hub.currentTheme = themes[hub.settings.theme] or themes.Dark

local screenGui
local mainFrame
local tabButtons = {}
local tabContents = {}

local function createUICorner(parent, radius)
	pcall(function()
		if not parent then return end
		if parent:FindFirstChild("UICorner") then return end
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, radius or 8)
		corner.Parent = parent
		return corner
	end)
end

local function storeConnection(connection)
	if connection then
		table.insert(hub.connections, connection)
	end
	return connection
end

function hub:createGui()
	if screenGui and screenGui.Parent then
		print("⚠️ GUI existiert bereits!")
		return mainFrame, tabContents
	end

	pcall(function()
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "RobloxUniversalHub"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

		mainFrame = Instance.new("Frame")
		mainFrame.Name = "MainFrame"
		mainFrame.Size = UDim2.new(0, 600, 0, 700)
		mainFrame.Position = UDim2.new(0.5, -300, 0.5, -350)
		mainFrame.BackgroundColor3 = hub.currentTheme.primary
		mainFrame.BorderSizePixel = 0
		mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
		mainFrame.Parent = screenGui

		createUICorner(mainFrame, 12)

		local topBar = Instance.new("Frame")
		topBar.Name = "TopBar"
		topBar.Size = UDim2.new(1, 0, 0, 40)
		topBar.BackgroundColor3 = hub.currentTheme.secondary
		topBar.BorderSizePixel = 0
		topBar.Parent = mainFrame

		createUICorner(topBar, 12)

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
		titleLabel.Position = UDim2.new(0.02, 0, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "🎮 Universal Hub v" .. hub.version
		titleLabel.TextColor3 = hub.currentTheme.text
		titleLabel.TextSize = 14
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.Parent = topBar

		local minimizeBtn = Instance.new("TextButton")
		minimizeBtn.Name = "MinimizeBtn"
		minimizeBtn.Size = UDim2.new(0, 35, 0, 30)
		minimizeBtn.Position = UDim2.new(1, -75, 0.5, -15)
		minimizeBtn.BackgroundColor3 = hub.currentTheme.accent
		minimizeBtn.TextColor3 = hub.currentTheme.text
		minimizeBtn.Text = "−"
		minimizeBtn.TextSize = 20
		minimizeBtn.Font = Enum.Font.GothamBold
		minimizeBtn.BorderSizePixel = 0
		minimizeBtn.Parent = topBar

		createUICorner(minimizeBtn, 6)

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "CloseBtn"
		closeBtn.Size = UDim2.new(0, 35, 0, 30)
		closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
		closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		closeBtn.TextColor3 = hub.currentTheme.text
		closeBtn.Text = "×"
		closeBtn.TextSize = 22
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.BorderSizePixel = 0
		closeBtn.Parent = topBar

		createUICorner(closeBtn, 6)

		local contentFrame = Instance.new("Frame")
		contentFrame.Name = "ContentFrame"
		contentFrame.Size = UDim2.new(1, 0, 1, -40)
		contentFrame.Position = UDim2.new(0, 0, 0, 40)
		contentFrame.BackgroundColor3 = hub.currentTheme.primary
		contentFrame.BorderSizePixel = 0
		contentFrame.Parent = mainFrame

		local tabBar = Instance.new("Frame")
		tabBar.Name = "TabBar"
		tabBar.Size = UDim2.new(0, 120, 1, 0)
		tabBar.BackgroundColor3 = hub.currentTheme.secondary
		tabBar.BorderSizePixel = 0
		tabBar.Parent = contentFrame

		local tabScroll = Instance.new("ScrollingFrame")
		tabScroll.Name = "TabScroll"
		tabScroll.Size = UDim2.new(1, 0, 1, 0)
		tabScroll.BackgroundTransparency = 1
		tabScroll.BorderSizePixel = 0
		tabScroll.ScrollBarThickness = 4
		tabScroll.Parent = tabBar

		local contentArea = Instance.new("Frame")
		contentArea.Name = "ContentArea"
		contentArea.Size = UDim2.new(1, -120, 1, 0)
		contentArea.Position = UDim2.new(0, 120, 0, 0)
		contentArea.BackgroundColor3 = hub.currentTheme.primary
		contentArea.BorderSizePixel = 0
		contentArea.Parent = contentFrame

		local tabs = {
			{name = "Teleport", icon = "📍"},
			{name = "Multi TP", icon = "🎯"},
			{name = "Movement", icon = "🚀"},
			{name = "Utility", icon = "⚙️"},
			{name = "Death Return", icon = "☠️"},
			{name = "Settings", icon = "🔧"}
		}

		local yOffset = 5
		for i, tab in ipairs(tabs) do
			local tabBtn = Instance.new("TextButton")
			tabBtn.Name = tab.name .. "Tab"
			tabBtn.Size = UDim2.new(1, -10, 0, 38)
			tabBtn.Position = UDim2.new(0, 5, 0, yOffset)
			tabBtn.BackgroundColor3 = i == 1 and hub.currentTheme.accent or hub.currentTheme.primary
			tabBtn.TextColor3 = hub.currentTheme.text
			tabBtn.Text = tab.icon .. " " .. tab.name
			tabBtn.TextSize = 11
			tabBtn.Font = Enum.Font.Gotham
			tabBtn.BorderSizePixel = 0
			tabBtn.Parent = tabScroll

			createUICorner(tabBtn, 6)
			tabButtons[tab.name] = tabBtn

			local tabContent = Instance.new("ScrollingFrame")
			tabContent.Name = tab.name .. "Content"
			tabContent.Size = UDim2.new(1, 0, 1, 0)
			tabContent.Position = UDim2.new(0, 0, 0, 0)
			tabContent.BackgroundTransparency = 1
			tabContent.BorderSizePixel = 0
			tabContent.ScrollBarThickness = 4
			tabContent.Visible = (i == 1)
			tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
			tabContent.Parent = contentArea
			tabContents[tab.name] = tabContent

			yOffset = yOffset + 43
		end

		tabScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)

		hub:makeDraggable(mainFrame, topBar)

		storeConnection(minimizeBtn.MouseButton1Click:Connect(function()
			hub.minimized = not hub.minimized
			contentFrame.Visible = not hub.minimized
			local targetSize = hub.minimized and UDim2.new(0, 600, 0, 40) or UDim2.new(0, 600, 0, 700)
			local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = targetSize})
			tween:Play()
		end))

		storeConnection(closeBtn.MouseButton1Click:Connect(function()
			hub:destroy()
		end))

		for tabName, tabBtn in pairs(tabButtons) do
			storeConnection(tabBtn.MouseButton1Click:Connect(function()
				for tName, tBtn in pairs(tabButtons) do
					local targetColor = tName == tabName and hub.currentTheme.accent or hub.currentTheme.primary
					tBtn.BackgroundColor3 = targetColor
				end
				for tName, tContent in pairs(tabContents) do
					tContent.Visible = tName == tabName
				end
			end))
		end

		print("✅ GUI erfolgreich erstellt!")
	end)

	return mainFrame, contentArea
end

function hub:makeDraggable(frame, dragHandle)
	local dragging = false
	local dragStart
	local startPos

	storeConnection(dragHandle.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end))

	storeConnection(UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))

	storeConnection(UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end))
end

function hub:addButton(parent, text, callback, yOffset)
	pcall(function()
		local btn = Instance.new("TextButton")
		btn.Name = text
		btn.Size = UDim2.new(1, -20, 0, 35)
		btn.Position = UDim2.new(0, 10, 0, yOffset)
		btn.BackgroundColor3 = hub.currentTheme.accent
		btn.TextColor3 = hub.currentTheme.text
		btn.Text = text
		btn.TextSize = 13
		btn.Font = Enum.Font.Gotham
		btn.BorderSizePixel = 0
		btn.Parent = parent

		createUICorner(btn, 6)

		storeConnection(btn.MouseButton1Click:Connect(callback))

		storeConnection(btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.new(
				hub.currentTheme.accent.R * 0.8,
				hub.currentTheme.accent.G * 0.8,
				hub.currentTheme.accent.B * 0.8
			)
		end))

		storeConnection(btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = hub.currentTheme.accent
		end))

		return btn
	end)
end

function hub:addLabel(parent, text, yOffset)
	pcall(function()
		local label = Instance.new("TextLabel")
		label.Name = text
		label.Size = UDim2.new(1, -20, 0, 25)
		label.Position = UDim2.new(0, 10, 0, yOffset)
		label.BackgroundTransparency = 1
		label.TextColor3 = hub.currentTheme.text
		label.Text = text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = parent
		return label
	end)
end

function hub:teleportPlayer(position)
	pcall(function()
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
			table.insert(hub.data.teleportHistory, position)
		end
	end)
end

function hub:setWalkSpeed(speed)
	pcall(function()
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.WalkSpeed = speed
		end
	end)
end

function hub:saveDeathPosition()
	pcall(function()
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			hub.data.deathPosition = LocalPlayer.Character.HumanoidRootPart.Position
			print("✅ Death Position gespeichert: " .. tostring(hub.data.deathPosition))
		end
	end)
end

function hub:setupTabs()
	pcall(function()
		-- ===== TELEPORT TAB =====
		local teleportContent = tabContents["Teleport"]
		hub:addLabel(teleportContent, "📍 Teleport", 10)

		hub:addButton(teleportContent, "Save Position (Slot 1)", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub.data.teleportSlots[1] = LocalPlayer.Character.HumanoidRootPart.Position
				print("✅ Position in Slot 1 gespeichert!")
			end
		end, 40)

		hub:addButton(teleportContent, "Teleport to Slot 1", function()
			if hub.data.teleportSlots[1] then
				hub:teleportPlayer(hub.data.teleportSlots[1] + Vector3.new(0, 3, 0))
				print("✅ Zu Slot 1 teleportiert!")
			else
				print("❌ Slot 1 ist leer!")
			end
		end, 85)

		hub:addButton(teleportContent, "Save Position (Slot 2)", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub.data.teleportSlots[2] = LocalPlayer.Character.HumanoidRootPart.Position
				print("✅ Position in Slot 2 gespeichert!")
			end
		end, 130)

		hub:addButton(teleportContent, "Teleport to Slot 2", function()
			if hub.data.teleportSlots[2] then
				hub:teleportPlayer(hub.data.teleportSlots[2] + Vector3.new(0, 3, 0))
				print("✅ Zu Slot 2 teleportiert!")
			else
				print("❌ Slot 2 ist leer!")
			end
		end, 175)

		hub:addButton(teleportContent, "Click to Teleport (Mouse)", function()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("HumanoidRootPart") and Mouse.Target then
				hub:teleportPlayer(Mouse.Hit.Position + Vector3.new(0, 3, 0))
				print("✅ Zum Mauszeiger teleportiert!")
			end
		end, 220)

		-- ===== MULTI TELEPORT TAB =====
		local multiTPContent = tabContents["Multi TP"]
		hub:addLabel(multiTPContent, "🎯 Multi Teleport", 10)

		hub:addButton(multiTPContent, "Save Multi TP (Slot 1)", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub.data.multiTeleportSlots[1] = LocalPlayer.Character.HumanoidRootPart.Position
				print("✅ Multi TP Slot 1 gespeichert!")
			end
		end, 40)

		hub:addButton(multiTPContent, "Save Multi TP (Slot 2)", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub.data.multiTeleportSlots[2] = LocalPlayer.Character.HumanoidRootPart.Position
				print("✅ Multi TP Slot 2 gespeichert!")
			end
		end, 85)

		hub:addButton(multiTPContent, "Save Multi TP (Slot 3)", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub.data.multiTeleportSlots[3] = LocalPlayer.Character.HumanoidRootPart.Position
				print("✅ Multi TP Slot 3 gespeichert!")
			end
		end, 130)

		hub:addButton(multiTPContent, "Teleport durch alle Slots", function()
			for i = 1, 3 do
				if hub.data.multiTeleportSlots[i] then
					hub:teleportPlayer(hub.data.multiTeleportSlots[i] + Vector3.new(0, 3, 0))
					print("✅ Zu Multi Slot " .. i .. " teleportiert!")
					wait(1)
				end
			end
		end, 175)

		-- ===== MOVEMENT TAB =====
		local movementContent = tabContents["Movement"]
		hub:addLabel(movementContent, "🚀 Movement", 10)

		hub:addButton(movementContent, "Walk Speed +10", function()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("Humanoid") then
				local currentSpeed = char.Humanoid.WalkSpeed
				hub:setWalkSpeed(currentSpeed + 10)
				print("✅ Walk Speed: " .. (currentSpeed + 10))
			end
		end, 40)

		hub:addButton(movementContent, "Reset Walk Speed", function()
			hub:setWalkSpeed(16)
			print("✅ Walk Speed zurückgesetzt")
		end, 85)

		-- ===== UTILITY TAB =====
		local utilityContent = tabContents["Utility"]
		hub:addLabel(utilityContent, "⚙️ Utility", 10)

		local utilityEnabled = false
		hub:addButton(utilityContent, "Utility: OFF", function()
			utilityEnabled = not utilityEnabled
			local utilityBtn = utilityContent:FindFirstChild("Utility: OFF") or utilityContent:FindFirstChild("Utility: ON")
			if utilityBtn then
				utilityBtn.Text = utilityEnabled and "Utility: ON" or "Utility: OFF"
				utilityBtn.BackgroundColor3 = utilityEnabled and Color3.fromRGB(50, 200, 50) or hub.currentTheme.accent
			end
			print(utilityEnabled and "✅ Utility aktiviert!" or "❌ Utility deaktiviert!")
		end, 40)

		-- ===== DEATH RETURN TAB =====
		local deathReturnContent = tabContents["Death Return"]
		hub:addLabel(deathReturnContent, "☠️ Death Return", 10)

		hub:addButton(deathReturnContent, "Save Death Position", function()
			hub:saveDeathPosition()
		end, 40)

		local deathReturnEnabled = false
		hub:addButton(deathReturnContent, "Death Return: OFF", function()
			deathReturnEnabled = not deathReturnEnabled
			local deathBtn = deathReturnContent:FindFirstChild("Death Return: OFF") or deathReturnContent:FindFirstChild("Death Return: ON")
			if deathBtn then
				deathBtn.Text = deathReturnEnabled and "Death Return: ON" or "Death Return: OFF"
				deathBtn.BackgroundColor3 = deathReturnEnabled and Color3.fromRGB(50, 200, 50) or hub.currentTheme.accent
			end
			hub.data.deathReturnEnabled = deathReturnEnabled
			print(deathReturnEnabled and "✅ Death Return aktiviert!" or "❌ Death Return deaktiviert!")
		end, 85)

		hub:addLabel(deathReturnContent, "Timer: " .. hub.data.deathReturnDelay .. " Sekunden", 130)

		hub:addButton(deathReturnContent, "Return on Death", function()
			if hub.data.deathPosition and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub:teleportPlayer(hub.data.deathPosition + Vector3.new(0, 3, 0))
				print("✅ Zur Death Position zurückgekehrt!")
			end
		end, 165)

		-- ===== SETTINGS TAB =====
		local settingsContent = tabContents["Settings"]
		hub:addLabel(settingsContent, "🔧 Settings", 10)

		hub:addLabel(settingsContent, "Theme:", 40)
		hub:addButton(settingsContent, "Dark Theme", function()
			hub.currentTheme = themes.Dark
			hub.settings.theme = "Dark"
			print("✅ Dark Theme aktiviert")
		end, 65)

		hub:addButton(settingsContent, "Red Theme", function()
			hub.currentTheme = themes.Red
			hub.settings.theme = "Red"
			print("✅ Red Theme aktiviert")
		end, 110)

		hub:addButton(settingsContent, "Pink Theme", function()
			hub.currentTheme = themes.Pink
			hub.settings.theme = "Pink"
			print("✅ Pink Theme aktiviert")
		end, 155)

		hub:addButton(settingsContent, "White Theme", function()
			hub.currentTheme = themes.White
			hub.settings.theme = "White"
			print("✅ White Theme aktiviert")
		end, 200)

		hub:addButton(settingsContent, "Purple Theme", function()
			hub.currentTheme = themes.Purple
			hub.settings.theme = "Purple"
			print("✅ Purple Theme aktiviert")
		end, 245)

		hub:addLabel(settingsContent, "Transparenz (Deckkraft):", 290)
		hub:addButton(settingsContent, "More Visible (0.9)", function()
			hub.settings.transparency = 0.9
			if screenGui then
				mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
			end
			print("✅ Deckkraft: 0.9")
		end, 315)

		hub:addButton(settingsContent, "Medium (0.5)", function()
			hub.settings.transparency = 0.5
			if screenGui then
				mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
			end
			print("✅ Deckkraft: 0.5")
		end, 360)

		hub:addButton(settingsContent, "Transparent (0.1)", function()
			hub.settings.transparency = 0.1
			if screenGui then
				mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
			end
			print("✅ Deckkraft: 0.1")
		end, 405)

		hub:addLabel(settingsContent, "GUI Hotkey: F2", 450)
		hub:addLabel(settingsContent, "Close Hub: Ctrl + Shift + X", 475)

		print("✅ Tabs aufgebaut!")
	end)
end

function hub:destroy()
	print("🛑 Hub beendet")
	hub.running = false
	for _, connection in ipairs(hub.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	hub.connections = {}
	if screenGui then
		screenGui:Destroy()
	end
end

function hub:setupHotkey()
	storeConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- F2 zum GUI Toggle
		if input.KeyCode == Enum.KeyCode.F2 then
			if screenGui then
				hub.guiVisible = not hub.guiVisible
				screenGui.Enabled = hub.guiVisible
				print(hub.guiVisible and "✅ GUI angezeigt" or "❌ GUI verborgen")
			end
		end

		-- Ctrl + Shift + X zum Beenden
		if input.KeyCode == Enum.KeyCode.X and
		   UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and
		   UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			hub:destroy()
		end
	end))

	-- Death Return Handler
	storeConnection(LocalPlayer.CharacterAdded:Connect(function()
		if hub.data.deathReturnEnabled and hub.data.deathPosition then
			wait(hub.data.deathReturnDelay)
			hub:teleportPlayer(hub.data.deathPosition + Vector3.new(0, 3, 0))
			print("✅ Nach Tod zurückgekehrt!")
		end
	end))
end

function hub:init()
	print("🎮 Roblox Universal Hub v" .. hub.version .. " wird initialisiert...")

	if not hub.running then
		print("⚠️ Hub ist nicht aktiv")
		return
	end

	hub:createGui()
	hub:setupTabs()
	hub:setupHotkey()

	print("✅ Roblox Universal Hub erfolgreich geladen!")
	print("📍 Features:")
	print("   • Teleport mit Slots (Speichern & Laden)")
	print("   • Multi Teleport (bis zu 3 Slots)")
	print("   • Death Return (Nach Tod zurückkehren)")
	print("   • Utility Toggle (An/Aus)")
	print("   • Themes (Dark, Red, Pink, White, Purple)")
	print("   • Transparenz Einstellungen")
	print("🎮 GUI Toggle: F2")
	print("🛑 Panic: Ctrl + Shift + X")
end

-- START
hub:init()

return hub
