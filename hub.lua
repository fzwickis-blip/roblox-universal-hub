-- Roblox Universal Hub v4.0 - Verbessert
local hub = {}
hub.version = "4.0"
hub.running = true
hub.minimized = false
hub.guiVisible = true

hub.settings = {
	theme = "Dark",
	transparency = 0.85,
	hotkey = Enum.KeyCode.RightShift,
	guiPosition = nil,
	guiToggleKey = Enum.KeyCode.F2,
	teleportKey = Enum.KeyCode.F,
	mouseTPEnabled = false,
	deathReturnTimer = 5,
}

hub.data = {
	teleportPosition = nil,
	teleportHistory = {},
	deathPosition = nil,
	mouseTPActive = false,
	deathReturnEnabled = false,
	multiTeleportSlots = {}, -- {1 = {pos = Vector3, name = "Slot 1"}, ...}
	multiTPOrder = {}, -- für Reihenfolge
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
	Dark = Color3.fromRGB(20, 20, 20),
	Red = Color3.fromRGB(40, 15, 15),
	Pink = Color3.fromRGB(50, 20, 35),
	White = Color3.fromRGB(240, 240, 240),
	Purple = Color3.fromRGB(35, 20, 50),
	Blue = Color3.fromRGB(20, 30, 50),
	AMOLED = Color3.fromRGB(0, 0, 0),
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
		mainFrame.Size = UDim2.new(0, 700, 0, 750)
		mainFrame.Position = UDim2.new(0.5, -350, 0.5, -375)
		mainFrame.BackgroundColor3 = hub.currentTheme
		mainFrame.BorderSizePixel = 0
		mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
		mainFrame.Parent = screenGui

		createUICorner(mainFrame, 15)

		-- HEADER
		local topBar = Instance.new("Frame")
		topBar.Name = "TopBar"
		topBar.Size = UDim2.new(1, 0, 0, 50)
		topBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		topBar.BorderSizePixel = 0
		topBar.Parent = mainFrame

		createUICorner(topBar, 15)

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
		titleLabel.Position = UDim2.new(0.02, 0, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "🎮 Universal Hub v" .. hub.version
		titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		titleLabel.TextSize = 16
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.Parent = topBar

		local minimizeBtn = Instance.new("TextButton")
		minimizeBtn.Name = "MinimizeBtn"
		minimizeBtn.Size = UDim2.new(0, 40, 0, 35)
		minimizeBtn.Position = UDim2.new(1, -85, 0.5, -17.5)
		minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
		minimizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		minimizeBtn.Text = "−"
		minimizeBtn.TextSize = 22
		minimizeBtn.Font = Enum.Font.GothamBold
		minimizeBtn.BorderSizePixel = 0
		minimizeBtn.Parent = topBar

		createUICorner(minimizeBtn, 8)

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "CloseBtn"
		closeBtn.Size = UDim2.new(0, 40, 0, 35)
		closeBtn.Position = UDim2.new(1, -40, 0.5, -17.5)
		closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeBtn.Text = "×"
		closeBtn.TextSize = 24
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.BorderSizePixel = 0
		closeBtn.Parent = topBar

		createUICorner(closeBtn, 8)

		local contentFrame = Instance.new("Frame")
		contentFrame.Name = "ContentFrame"
		contentFrame.Size = UDim2.new(1, 0, 1, -50)
		contentFrame.Position = UDim2.new(0, 0, 0, 50)
		contentFrame.BackgroundColor3 = hub.currentTheme
		contentFrame.BorderSizePixel = 0
		contentFrame.Parent = mainFrame

		local tabBar = Instance.new("Frame")
		tabBar.Name = "TabBar"
		tabBar.Size = UDim2.new(0, 140, 1, 0)
		tabBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		tabBar.BorderSizePixel = 0
		tabBar.Parent = contentFrame

		createUICorner(tabBar, 0)

		local tabScroll = Instance.new("ScrollingFrame")
		tabScroll.Name = "TabScroll"
		tabScroll.Size = UDim2.new(1, 0, 1, 0)
		tabScroll.BackgroundTransparency = 1
		tabScroll.BorderSizePixel = 0
		tabScroll.ScrollBarThickness = 4
		tabScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
		tabScroll.Parent = tabBar

		local contentArea = Instance.new("Frame")
		contentArea.Name = "ContentArea"
		contentArea.Size = UDim2.new(1, -140, 1, 0)
		contentArea.Position = UDim2.new(0, 140, 0, 0)
		contentArea.BackgroundColor3 = hub.currentTheme
		contentArea.BorderSizePixel = 0
		contentArea.Parent = contentFrame

		local contentScroll = Instance.new("ScrollingFrame")
		contentScroll.Name = "ContentScroll"
		contentScroll.Size = UDim2.new(1, 0, 1, 0)
		contentScroll.BackgroundTransparency = 1
		contentScroll.BorderSizePixel = 0
		contentScroll.ScrollBarThickness = 5
		contentScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
		contentScroll.Parent = contentArea

		local tabs = {
			{name = "Teleport", icon = "📍"},
			{name = "Multi TP", icon = "🎯"},
			{name = "Mouse TP", icon = "🖱️"},
			{name = "Death Return", icon = "☠️"},
			{name = "Settings", icon = "🔧"}
		}

		local yOffset = 5
		for i, tab in ipairs(tabs) do
			local tabBtn = Instance.new("TextButton")
			tabBtn.Name = tab.name .. "Tab"
			tabBtn.Size = UDim2.new(1, -10, 0, 42)
			tabBtn.Position = UDim2.new(0, 5, 0, yOffset)
			tabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(30, 30, 30)
			tabBtn.TextColor3 = i == 1 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
			tabBtn.Text = tab.icon .. " " .. tab.name
			tabBtn.TextSize = 12
			tabBtn.Font = Enum.Font.GothamBold
			tabBtn.BorderSizePixel = 0
			tabBtn.Parent = tabScroll

			createUICorner(tabBtn, 8)
			tabButtons[tab.name] = tabBtn

			local tabContent = Instance.new("Frame")
			tabContent.Name = tab.name .. "Content"
			tabContent.Size = UDim2.new(1, 0, 0, 0)
			tabContent.BackgroundTransparency = 1
			tabContent.BorderSizePixel = 0
			tabContent.Visible = (i == 1)
			tabContent.Parent = contentScroll
			tabContents[tab.name] = tabContent

			yOffset = yOffset + 47
		end

		tabScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)

		hub:makeDraggable(mainFrame, topBar)

		storeConnection(minimizeBtn.MouseButton1Click:Connect(function()
			hub.minimized = not hub.minimized
			contentFrame.Visible = not hub.minimized
			local targetSize = hub.minimized and UDim2.new(0, 700, 0, 50) or UDim2.new(0, 700, 0, 750)
			local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = targetSize})
			tween:Play()
		end))

		storeConnection(closeBtn.MouseButton1Click:Connect(function()
			hub:destroy()
		end))

		for tabName, tabBtn in pairs(tabButtons) do
			storeConnection(tabBtn.MouseButton1Click:Connect(function()
				for tName, tBtn in pairs(tabButtons) do
					if tName == tabName then
						tBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
						tBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
					else
						tBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
						tBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
					end
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
		btn.Size = UDim2.new(1, -20, 0, 38)
		btn.Position = UDim2.new(0, 10, 0, yOffset)
		btn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
		btn.TextColor3 = Color3.fromRGB(0, 0, 0)
		btn.Text = text
		btn.TextSize = 13
		btn.Font = Enum.Font.GothamBold
		btn.BorderSizePixel = 0
		btn.Parent = parent

		createUICorner(btn, 8)

		storeConnection(btn.MouseButton1Click:Connect(callback))

		storeConnection(btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(130, 220, 255)
		end))

		storeConnection(btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
		end))

		return btn
	end)
end

function hub:addLabel(parent, text, yOffset, size)
	pcall(function()
		local label = Instance.new("TextLabel")
		label.Name = text
		label.Size = UDim2.new(1, -20, 0, size or 25)
		label.Position = UDim2.new(0, 10, 0, yOffset)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.Text = text
		label.TextSize = 13
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = parent
		return label
	end)
end

function hub:addInput(parent, placeholder, yOffset, callback)
	pcall(function()
		local inputBox = Instance.new("TextBox")
		inputBox.Name = "InputBox"
		inputBox.Size = UDim2.new(1, -20, 0, 35)
		inputBox.Position = UDim2.new(0, 10, 0, yOffset)
		inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		inputBox.TextColor3 = Color3.fromRGB(200, 200, 200)
		inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
		inputBox.PlaceholderText = placeholder
		inputBox.TextSize = 13
		inputBox.Font = Enum.Font.Gotham
		inputBox.BorderSizePixel = 0
		inputBox.Parent = parent

		createUICorner(inputBox, 8)

		storeConnection(inputBox.FocusLost:Connect(function(enterPressed)
			if enterPressed and callback then
				callback(inputBox.Text)
				inputBox.Text = ""
			end
		end))

		return inputBox
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
		local teleportOffset = 10

		hub:addLabel(teleportContent, "📍 Single Teleport", teleportOffset, 30)
		teleportOffset = teleportOffset + 35

		hub:addButton(teleportContent, "Save Position", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub.data.teleportPosition = LocalPlayer.Character.HumanoidRootPart.Position
				print("✅ Position gespeichert!")
			end
		end, teleportOffset)
		teleportOffset = teleportOffset + 43

		hub:addLabel(teleportContent, "Teleport Key: [" .. tostring(hub.settings.teleportKey):match("%.(.+)") .. "]", teleportOffset)
		teleportOffset = teleportOffset + 30

		hub:addButton(teleportContent, "Teleport to Saved Pos", function()
			if hub.data.teleportPosition then
				hub:teleportPlayer(hub.data.teleportPosition + Vector3.new(0, 3, 0))
				print("✅ Teleportiert!")
			else
				print("❌ Keine Position gespeichert!")
			end
		end, teleportOffset)
		teleportOffset = teleportOffset + 43

		hub:addButton(teleportContent, "Change Teleport Key", function()
			print("🔑 Drücke eine Taste um den Teleport-Key zu setzen...")
			local connection
			connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
					hub.settings.teleportKey = input.KeyCode
					print("✅ Teleport-Key geändert zu: " .. tostring(input.KeyCode):match("%.(.+)"))
					connection:Disconnect()
					-- Update label
					local label = teleportContent:FindFirstChild("Teleport Key: [F]") or teleportContent:FindFirstChildOfClass("TextLabel", true)
					if label then
						label.Text = "Teleport Key: [" .. tostring(hub.settings.teleportKey):match("%.(.+)") .. "]"
					end
				end
			end)
		end, teleportOffset)
		teleportOffset = teleportOffset + 43

		teleportContent.Size = UDim2.new(1, 0, 0, teleportOffset + 10)

		-- ===== MULTI TELEPORT TAB =====
		local multiTPContent = tabContents["Multi TP"]
		local multiOffset = 10

		hub:addLabel(multiTPContent, "🎯 Multi Teleport Slots", multiOffset, 30)
		multiOffset = multiOffset + 35

		hub:addButton(multiTPContent, "➕ Save New Position", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local slotNum = #hub.data.multiTPOrder + 1
				hub.data.multiTeleportSlots[slotNum] = {
					pos = LocalPlayer.Character.HumanoidRootPart.Position,
					name = "Slot " .. slotNum
				}
				table.insert(hub.data.multiTPOrder, slotNum)
				print("✅ Slot " .. slotNum .. " gespeichert!")
				hub:updateMultiTPUI(multiTPContent, multiOffset)
			end
		end, multiOffset)
		multiOffset = multiOffset + 43

		hub:addLabel(multiTPContent, "Slots:", multiOffset)
		multiOffset = multiOffset + 30

		function hub:updateMultiTPUI(parent, startOffset)
			-- Alte Slots löschen
			for i = 1, 50 do
				local slot = parent:FindFirstChild("SlotContainer" .. i)
				if slot then slot:Destroy() end
			end

			local currentOffset = startOffset

			for _, slotNum in ipairs(hub.data.multiTPOrder) do
				if hub.data.multiTeleportSlots[slotNum] then
					local slotData = hub.data.multiTeleportSlots[slotNum]

					local container = Instance.new("Frame")
					container.Name = "SlotContainer" .. slotNum
					container.Size = UDim2.new(1, -20, 0, 75)
					container.Position = UDim2.new(0, 10, 0, currentOffset)
					container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
					container.BorderSizePixel = 0
					container.Parent = parent

					createUICorner(container, 8)

					local slotLabel = Instance.new("TextLabel")
					slotLabel.Size = UDim2.new(1, -10, 0, 20)
					slotLabel.Position = UDim2.new(0, 5, 0, 2)
					slotLabel.BackgroundTransparency = 1
					slotLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
					slotLabel.Text = "🎯 " .. slotData.name
					slotLabel.TextSize = 12
					slotLabel.Font = Enum.Font.GothamBold
					slotLabel.TextXAlignment = Enum.TextXAlignment.Left
					slotLabel.Parent = container

					local btnContainer = Instance.new("Frame")
					btnContainer.Size = UDim2.new(1, -10, 0, 38)
					btnContainer.Position = UDim2.new(0, 5, 0, 25)
					btnContainer.BackgroundTransparency = 1
					btnContainer.BorderSizePixel = 0
					btnContainer.Parent = container

					local tpBtn = Instance.new("TextButton")
					tpBtn.Size = UDim2.new(0.48, 0, 1, 0)
					tpBtn.Position = UDim2.new(0, 0, 0, 0)
					tpBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
					tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
					tpBtn.Text = "Teleport"
					tpBtn.TextSize = 11
					tpBtn.Font = Enum.Font.GothamBold
					tpBtn.BorderSizePixel = 0
					tpBtn.Parent = btnContainer

					createUICorner(tpBtn, 6)

					storeConnection(tpBtn.MouseButton1Click:Connect(function()
						hub:teleportPlayer(slotData.pos + Vector3.new(0, 3, 0))
						print("✅ Zu " .. slotData.name .. " teleportiert!")
					end))

					local delBtn = Instance.new("TextButton")
					delBtn.Size = UDim2.new(0.48, 0, 1, 0)
					delBtn.Position = UDim2.new(0.52, 0, 0, 0)
					delBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
					delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
					delBtn.Text = "Delete"
					delBtn.TextSize = 11
					delBtn.Font = Enum.Font.GothamBold
					delBtn.BorderSizePixel = 0
					delBtn.Parent = btnContainer

					createUICorner(delBtn, 6)

					storeConnection(delBtn.MouseButton1Click:Connect(function()
						hub.data.multiTeleportSlots[slotNum] = nil
						for i, v in ipairs(hub.data.multiTPOrder) do
							if v == slotNum then
								table.remove(hub.data.multiTPOrder, i)
								break
							end
						end
						print("❌ " .. slotData.name .. " gelöscht!")
						hub:updateMultiTPUI(parent, startOffset)
					end))

					currentOffset = currentOffset + 80
				end
			end

			multiTPContent.Size = UDim2.new(1, 0, 0, currentOffset + 10)
		end

		hub:updateMultiTPUI(multiTPContent, multiOffset)

		-- ===== MOUSE TELEPORT TAB =====
		local mouseTPContent = tabContents["Mouse TP"]
		local mouseOffset = 10

		hub:addLabel(mouseTPContent, "🖱️ Mouse Teleport", mouseOffset, 30)
		mouseOffset = mouseOffset + 35

		local mouseTpStatusBtn = hub:addButton(mouseTPContent, "Mouse TP: OFF", function()
			hub.data.mouseTPActive = not hub.data.mouseTPActive
			mouseTpStatusBtn.Text = hub.data.mouseTPActive and "Mouse TP: ON ✓" or "Mouse TP: OFF"
			mouseTpStatusBtn.BackgroundColor3 = hub.data.mouseTPActive and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 200, 255)
			print(hub.data.mouseTPActive and "✅ Mouse TP aktiviert!" or "❌ Mouse TP deaktiviert!")
		end, mouseOffset)
		mouseOffset = mouseOffset + 43

		hub:addLabel(mouseTPContent, "Halte Shift und klicke um zu teleportieren", mouseOffset, 40)
		mouseOffset = mouseOffset + 50

		mouseTPContent.Size = UDim2.new(1, 0, 0, mouseOffset + 10)

		-- ===== DEATH RETURN TAB =====
		local deathReturnContent = tabContents["Death Return"]
		local deathOffset = 10

		hub:addLabel(deathReturnContent, "☠️ Death Return", deathOffset, 30)
		deathOffset = deathOffset + 35

		hub:addButton(deathReturnContent, "Save Death Position", function()
			hub:saveDeathPosition()
		end, deathOffset)
		deathOffset = deathOffset + 43

		local deathReturnStatusBtn = hub:addButton(deathReturnContent, "Death Return: OFF", function()
			hub.data.deathReturnEnabled = not hub.data.deathReturnEnabled
			deathReturnStatusBtn.Text = hub.data.deathReturnEnabled and "Death Return: ON ✓" or "Death Return: OFF"
			deathReturnStatusBtn.BackgroundColor3 = hub.data.deathReturnEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 200, 255)
			print(hub.data.deathReturnEnabled and "✅ Death Return aktiviert!" or "❌ Death Return deaktiviert!")
		end, deathOffset)
		deathOffset = deathOffset + 43

		hub:addLabel(deathReturnContent, "Timer (Sekunden):", deathOffset)
		deathOffset = deathOffset + 30

		local timerInput = hub:addInput(deathReturnContent, "z.B. 5", deathOffset, function(value)
			local num = tonumber(value)
			if num and num > 0 then
				hub.settings.deathReturnTimer = num
				print("✅ Timer auf " .. num .. " Sekunden gesetzt!")
			end
		end)
		deathOffset = deathOffset + 40

		hub:addButton(deathReturnContent, "Return on Death", function()
			if hub.data.deathPosition and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub:teleportPlayer(hub.data.deathPosition + Vector3.new(0, 3, 0))
				print("✅ Zur Death Position zurückgekehrt!")
			end
		end, deathOffset)
		deathOffset = deathOffset + 43

		deathReturnContent.Size = UDim2.new(1, 0, 0, deathOffset + 10)

		-- ===== SETTINGS TAB =====
		local settingsContent = tabContents["Settings"]
		local settingsOffset = 10

		hub:addLabel(settingsContent, "🎨 Theme (nur Hintergrund)", settingsOffset, 30)
		settingsOffset = settingsOffset + 35

		local themes_list = {"Dark", "Red", "Pink", "White", "Purple", "Blue", "AMOLED"}
		for _, themeName in ipairs(themes_list) do
			hub:addButton(settingsContent, themeName, function()
				hub.currentTheme = themes[themeName]
				hub.settings.theme = themeName
				mainFrame.BackgroundColor3 = hub.currentTheme
				tabBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
				contentFrame.BackgroundColor3 = hub.currentTheme
				contentArea.BackgroundColor3 = hub.currentTheme
				print("✅ Theme zu " .. themeName .. " geändert!")
			end, settingsOffset)
			settingsOffset = settingsOffset + 43
		end

		hub:addLabel(settingsContent, "Transparenz:", settingsOffset, 30)
		settingsOffset = settingsOffset + 35

		hub:addButton(settingsContent, "Opak (0.9)", function()
			hub.settings.transparency = 0.9
			mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
			print("✅ Transparenz: 0.9")
		end, settingsOffset)
		settingsOffset = settingsOffset + 43

		hub:addButton(settingsContent, "Normal (0.7)", function()
			hub.settings.transparency = 0.7
			mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
			print("✅ Transparenz: 0.7")
		end, settingsOffset)
		settingsOffset = settingsOffset + 43

		hub:addButton(settingsContent, "Transparent (0.3)", function()
			hub.settings.transparency = 0.3
			mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
			print("✅ Transparenz: 0.3")
		end, settingsOffset)
		settingsOffset = settingsOffset + 43

		hub:addLabel(settingsContent, "📋 Keybinds:", settingsOffset, 30)
		settingsOffset = settingsOffset + 35

		hub:addLabel(settingsContent, "• GUI Toggle: F2", settingsOffset)
		settingsOffset = settingsOffset + 25

		hub:addLabel(settingsContent, "• Teleport: [KEY]", settingsOffset)
		settingsOffset = settingsOffset + 25

		hub:addLabel(settingsContent, "• Mouse TP: Shift + Click", settingsOffset)
		settingsOffset = settingsOffset + 25

		hub:addLabel(settingsContent, "• Close Hub: Ctrl + Shift + X", settingsOffset)
		settingsOffset = settingsOffset + 25

		settingsContent.Size = UDim2.new(1, 0, 0, settingsOffset + 10)

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
	-- GUI Toggle
	storeConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.F2 then
			if screenGui then
				hub.guiVisible = not hub.guiVisible
				screenGui.Enabled = hub.guiVisible
				print(hub.guiVisible and "✅ GUI angezeigt" or "❌ GUI verborgen")
			end
		end

		if input.KeyCode == Enum.KeyCode.X and
		   UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and
		   UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			hub:destroy()
		end

		-- Teleport Key
		if input.KeyCode == hub.settings.teleportKey then
			if hub.data.teleportPosition then
				hub:teleportPlayer(hub.data.teleportPosition + Vector3.new(0, 3, 0))
				print("✅ Teleportiert!")
			end
		end

		-- Mouse Teleport
		if hub.data.mouseTPActive and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and input.UserInputType == Enum.UserInputType.MouseButton1 then
			if Mouse.Target then
				hub:teleportPlayer(Mouse.Hit.Position + Vector3.new(0, 3, 0))
				print("✅ Zum Mauszeiger teleportiert!")
			end
		end
	end))

	-- Death Return Handler
	storeConnection(LocalPlayer.CharacterAdded:Connect(function()
		if hub.data.deathReturnEnabled and hub.data.deathPosition then
			wait(hub.settings.deathReturnTimer)
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
	print("   • Single Teleport (1 Position speichern)")
	print("   • Multi Teleport (Unbegrenzte Slots)")
	print("   • Mouse Teleport (Shift + Click)")
	print("   • Death Return (Mit anpassbarem Timer)")
	print("   • 7 Themes (nur Hintergrund)")
	print("   • Transparenz Einstellungen")
	print("🎮 GUI Toggle: F2")
	print("🛑 Panic: Ctrl + Shift + X")
end

-- START
hub:init()

return hub
