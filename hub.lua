-- Roblox Universal Hub v4.2 - Vollständig überarbeitet
local hub = {}
hub.version = "4.2"
hub.running = true
hub.minimized = false
hub.guiVisible = true

hub.settings = {
	theme = "Dark",
	transparency = 0.85,
	guiToggleKey = Enum.KeyCode.F2,
	teleportKey = Enum.KeyCode.F,
	mouseTPToggleKey = Enum.KeyCode.H,
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
	multiTPLoopActive = false,
	multiTPLoopInfinite = false,
	multiTPCurrentIndex = 1,
	multiTPLoopDelay = 1, -- Sekunden zwischen Teleports
}

hub.connections = {}
hub.uiElements = {} -- Für Status-Buttons

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

function hub:updateStatusButton(button, isActive)
	if button then
		if isActive then
			button.Text = "🟢 ON"
			button.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		else
			button.Text = "🔴 OFF"
			button.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		end
	end
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
		mainFrame.Size = UDim2.new(0, 800, 0, 850)
		mainFrame.Position = UDim2.new(0.5, -400, 0.5, -425)
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
		tabBar.Size = UDim2.new(0, 150, 1, 0)
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
		contentArea.Size = UDim2.new(1, -150, 1, 0)
		contentArea.Position = UDim2.new(0, 150, 0, 0)
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
			local targetSize = hub.minimized and UDim2.new(0, 800, 0, 50) or UDim2.new(0, 800, 0, 850)
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
		btn.Size = UDim2.new(1, -20, 0, 40)
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
			print("✅ Death Position gespeichert!")
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

		local posLabel = Instance.new("TextLabel")
		posLabel.Name = "PositionLabel"
		posLabel.Size = UDim2.new(1, -20, 0, 50)
		posLabel.Position = UDim2.new(0, 10, 0, teleportOffset)
		posLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		posLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
		posLabel.Text = "Keine Position gespeichert"
		posLabel.TextSize = 12
		posLabel.Font = Enum.Font.Gotham
		posLabel.TextXAlignment = Enum.TextXAlignment.Left
		posLabel.TextYAlignment = Enum.TextYAlignment.Top
		posLabel.Parent = teleportContent

		createUICorner(posLabel, 8)
		teleportOffset = teleportOffset + 60

		hub:addButton(teleportContent, "Save Position", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				hub.data.teleportPosition = LocalPlayer.Character.HumanoidRootPart.Position
				local x = math.floor(hub.data.teleportPosition.X)
				local y = math.floor(hub.data.teleportPosition.Y)
				local z = math.floor(hub.data.teleportPosition.Z)
				posLabel.Text = "X: " .. x .. "\nY: " .. y .. "\nZ: " .. z
				print("✅ Position gespeichert!")
			end
		end, teleportOffset)
		teleportOffset = teleportOffset + 45

		hub:addLabel(teleportContent, "Teleport Key: F", teleportOffset)
		teleportOffset = teleportOffset + 30

		hub:addButton(teleportContent, "Change Key", function()
			print("🔑 Drücke eine Taste...")
			local connection
			connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
					hub.settings.teleportKey = input.KeyCode
					print("✅ Key geändert!")
					connection:Disconnect()
				end
			end)
		end, teleportOffset)
		teleportOffset = teleportOffset + 45

		hub:addButton(teleportContent, "Teleport", function()
			if hub.data.teleportPosition then
				hub:teleportPlayer(hub.data.teleportPosition + Vector3.new(0, 3, 0))
				print("✅ Teleportiert!")
			else
				print("❌ Keine Position!")
			end
		end, teleportOffset)
		teleportOffset = teleportOffset + 45

		teleportContent.Size = UDim2.new(1, 0, 0, teleportOffset + 10)

		-- ===== MULTI TELEPORT TAB =====
		local multiTPContent = tabContents["Multi TP"]
		local multiOffset = 10

		hub:addLabel(multiTPContent, "🎯 Multi Teleport", multiOffset, 30)
		multiOffset = multiOffset + 35

		hub:addButton(multiTPContent, "Save New Slot", function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local slotNum = #hub.data.multiTPOrder + 1
				hub.data.multiTeleportSlots[slotNum] = {
					pos = LocalPlayer.Character.HumanoidRootPart.Position,
					name = "Slot " .. slotNum
				}
				table.insert(hub.data.multiTPOrder, slotNum)
				print("✅ Slot " .. slotNum .. " gespeichert!")
				hub:updateMultiTPUI(multiTPContent, multiOffset + 40)
			end
		end, multiOffset)
		multiOffset = multiOffset + 45

		hub:addLabel(multiTPContent, "Loop Mode:", multiOffset)
		multiOffset = multiOffset + 30

		local loopBtn = nil
		loopBtn = hub:addButton(multiTPContent, "🔴 OFF", function()
			if hub.data.multiTPLoopInfinite then
				hub.data.multiTPLoopInfinite = false
				hub.data.multiTPLoopActive = false
				hub:updateStatusButton(loopBtn, false)
				print("❌ Loop gestoppt!")
			else
				hub.data.multiTPLoopActive = true
				hub.data.multiTPLoopInfinite = false
				hub:updateStatusButton(loopBtn, true)
				hub:startMultiTPLoop(false, loopBtn)
				print("✅ Loop (1x) gestartet!")
			end
		end, multiOffset)
		hub.uiElements.loopBtn = loopBtn
		multiOffset = multiOffset + 45

		hub:addLabel(multiTPContent, "Infinite Loop:", multiOffset)
		multiOffset = multiOffset + 30

		local infLoopBtn = nil
		infLoopBtn = hub:addButton(multiTPContent, "🔴 OFF", function()
			if hub.data.multiTPLoopInfinite then
				hub.data.multiTPLoopInfinite = false
				hub.data.multiTPLoopActive = false
				hub:updateStatusButton(infLoopBtn, false)
				print("❌ Infinite Loop gestoppt!")
			else
				hub.data.multiTPLoopInfinite = true
				hub.data.multiTPLoopActive = true
				hub:updateStatusButton(infLoopBtn, true)
				hub:startMultiTPLoop(true, infLoopBtn)
				print("✅ Infinite Loop gestartet!")
			end
		end, multiOffset)
		hub.uiElements.infLoopBtn = infLoopBtn
		multiOffset = multiOffset + 45

		hub:addLabel(multiTPContent, "Delay (Sekunden):", multiOffset)
		multiOffset = multiOffset + 30

		local delayInput = hub:addInput(multiTPContent, "z.B. 1", multiOffset, function(value)
			local num = tonumber(value)
			if num and num > 0 then
				hub.data.multiTPLoopDelay = num
				print("✅ Delay: " .. num .. "s")
			end
		end)
		multiOffset = multiOffset + 40

		hub:addLabel(multiTPContent, "Slots:", multiOffset)
		multiOffset = multiOffset + 35

		function hub:updateMultiTPUI(parent, startOffset)
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
					container.Size = UDim2.new(1, -20, 0, 100)
					container.Position = UDim2.new(0, 10, 0, currentOffset)
					container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
					container.BorderSizePixel = 0
					container.Parent = parent

					createUICorner(container, 8)

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, -10, 0, 20)
					label.Position = UDim2.new(0, 5, 0, 2)
					label.BackgroundTransparency = 1
					label.TextColor3 = Color3.fromRGB(150, 200, 255)
					label.Text = "🎯 " .. slotData.name
					label.TextSize = 12
					label.Font = Enum.Font.GothamBold
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = container

					local x = math.floor(slotData.pos.X)
					local y = math.floor(slotData.pos.Y)
					local z = math.floor(slotData.pos.Z)

					local posLbl = Instance.new("TextLabel")
					posLbl.Size = UDim2.new(1, -10, 0, 16)
					posLbl.Position = UDim2.new(0, 5, 0, 24)
					posLbl.BackgroundTransparency = 1
					posLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
					posLbl.Text = "X:" .. x .. " Y:" .. y .. " Z:" .. z
					posLbl.TextSize = 10
					posLbl.Font = Enum.Font.Gotham
					posLbl.TextXAlignment = Enum.TextXAlignment.Left
					posLbl.Parent = container

					local btnFrame = Instance.new("Frame")
					btnFrame.Size = UDim2.new(1, -10, 0, 38)
					btnFrame.Position = UDim2.new(0, 5, 0, 43)
					btnFrame.BackgroundTransparency = 1
					btnFrame.BorderSizePixel = 0
					btnFrame.Parent = container

					local tpBtn = Instance.new("TextButton")
					tpBtn.Size = UDim2.new(0.48, 0, 1, 0)
					tpBtn.Position = UDim2.new(0, 0, 0, 0)
					tpBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
					tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
					tpBtn.Text = "TP"
					tpBtn.TextSize = 11
					tpBtn.Font = Enum.Font.GothamBold
					tpBtn.BorderSizePixel = 0
					tpBtn.Parent = btnFrame

					createUICorner(tpBtn, 6)

					storeConnection(tpBtn.MouseButton1Click:Connect(function()
						hub:teleportPlayer(slotData.pos + Vector3.new(0, 3, 0))
						print("✅ Zu " .. slotData.name .. "!")
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
					delBtn.Parent = btnFrame

					createUICorner(delBtn, 6)

					storeConnection(delBtn.MouseButton1Click:Connect(function()
						hub.data.multiTeleportSlots[slotNum] = nil
						for i, v in ipairs(hub.data.multiTPOrder) do
							if v == slotNum then
								table.remove(hub.data.multiTPOrder, i)
								break
							end
						end
						print("❌ Gelöscht!")
						hub:updateMultiTPUI(parent, multiOffset + 40)
					end))

					currentOffset = currentOffset + 105
				end
			end

			multiTPContent.Size = UDim2.new(1, 0, 0, currentOffset + 10)
		end

		hub:updateMultiTPUI(multiTPContent, multiOffset)

		function hub:startMultiTPLoop(infinite, btn)
			if infinite then
				while hub.data.multiTPLoopInfinite and #hub.data.multiTPOrder > 0 do
					local slotNum = hub.data.multiTPOrder[hub.data.multiTPCurrentIndex]
					if hub.data.multiTeleportSlots[slotNum] then
						hub:teleportPlayer(hub.data.multiTeleportSlots[slotNum].pos + Vector3.new(0, 3, 0))
					end
					hub.data.multiTPCurrentIndex = hub.data.multiTPCurrentIndex + 1
					if hub.data.multiTPCurrentIndex > #hub.data.multiTPOrder then
						hub.data.multiTPCurrentIndex = 1
					end
					wait(hub.data.multiTPLoopDelay)
				end
			else
				for i = 1, #hub.data.multiTPOrder do
					if not hub.data.multiTPLoopActive then break end
					local slotNum = hub.data.multiTPOrder[i]
					if hub.data.multiTeleportSlots[slotNum] then
						hub:teleportPlayer(hub.data.multiTeleportSlots[slotNum].pos + Vector3.new(0, 3, 0))
					end
					wait(hub.data.multiTPLoopDelay)
				end
				hub.data.multiTPLoopActive = false
				hub:updateStatusButton(btn, false)
				print("✅ Loop fertig!")
			end
		end

		-- ===== MOUSE TELEPORT TAB =====
		local mouseTPContent = tabContents["Mouse TP"]
		local mouseOffset = 10

		hub:addLabel(mouseTPContent, "🖱️ Mouse Teleport", mouseOffset, 30)
		mouseOffset = mouseOffset + 35

		local mouseTPBtn = nil
		mouseTPBtn = hub:addButton(mouseTPContent, "🔴 OFF", function()
			hub.data.mouseTPActive = not hub.data.mouseTPActive
			hub:updateStatusButton(mouseTPBtn, hub.data.mouseTPActive)
		end, mouseOffset)
		hub.uiElements.mouseTPBtn = mouseTPBtn
		mouseOffset = mouseOffset + 45

		hub:addLabel(mouseTPContent, "Toggle Key: H", mouseOffset)
		mouseOffset = mouseOffset + 30

		hub:addButton(mouseTPContent, "Change Key", function()
			print("🔑 Drücke eine Taste...")
			local connection
			connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
					hub.settings.mouseTPToggleKey = input.KeyCode
					print("✅ Key geändert!")
					connection:Disconnect()
				end
			end)
		end, mouseOffset)
		mouseOffset = mouseOffset + 45

		hub:addLabel(mouseTPContent, "Wie es funktioniert:", mouseOffset)
		mouseOffset = mouseOffset + 30

		hub:addLabel(mouseTPContent, "1. Klick auf ON Button um Mouse TP zu aktivieren", mouseOffset, 35)
		mouseOffset = mouseOffset + 40

		hub:addLabel(mouseTPContent, "2. Schaue auf die Position", mouseOffset, 35)
		mouseOffset = mouseOffset + 40

		hub:addLabel(mouseTPContent, "3. Linksklick um dich zu teleportieren", mouseOffset, 35)
		mouseOffset = mouseOffset + 40

		mouseTPContent.Size = UDim2.new(1, 0, 0, mouseOffset + 10)

		-- ===== DEATH RETURN TAB =====
		local deathReturnContent = tabContents["Death Return"]
		local deathOffset = 10

		hub:addLabel(deathReturnContent, "☠️ Death Return", deathOffset, 30)
		deathOffset = deathOffset + 35

		hub:addButton(deathReturnContent, "Save Death Position", function()
			hub:saveDeathPosition()
		end, deathOffset)
		deathOffset = deathOffset + 45

		local deathReturnBtn = nil
		deathReturnBtn = hub:addButton(deathReturnContent, "🔴 OFF", function()
			hub.data.deathReturnEnabled = not hub.data.deathReturnEnabled
			hub:updateStatusButton(deathReturnBtn, hub.data.deathReturnEnabled)
		end, deathOffset)
		hub.uiElements.deathReturnBtn = deathReturnBtn
		deathOffset = deathOffset + 45

		hub:addLabel(deathReturnContent, "Timer (Sekunden):", deathOffset)
		deathOffset = deathOffset + 30

		local timerInput = hub:addInput(deathReturnContent, "z.B. 5", deathOffset, function(value)
			local num = tonumber(value)
			if num and num > 0 then
				hub.settings.deathReturnTimer = num
				print("✅ Timer: " .. num .. "s")
			end
		end)
		deathOffset = deathOffset + 40

		hub:addButton(deathReturnContent, "Return Now", function()
			if hub.data.deathPosition then
				hub:teleportPlayer(hub.data.deathPosition + Vector3.new(0, 3, 0))
				print("✅ Zurückgekehrt!")
			end
		end, deathOffset)
		deathOffset = deathOffset + 45

		deathReturnContent.Size = UDim2.new(1, 0, 0, deathOffset + 10)

		-- ===== SETTINGS TAB =====
		local settingsContent = tabContents["Settings"]
		local settingsOffset = 10

		hub:addLabel(settingsContent, "🎨 Design - Theme:", settingsOffset)
		settingsOffset = settingsOffset + 30

		local themes_list = {"Dark", "Red", "Pink", "White", "Purple", "Blue", "AMOLED"}
		for _, themeName in ipairs(themes_list) do
			hub:addButton(settingsContent, themeName, function()
				hub.currentTheme = themes[themeName]
				hub.settings.theme = themeName
				mainFrame.BackgroundColor3 = hub.currentTheme
				tabBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
				contentFrame.BackgroundColor3 = hub.currentTheme
				contentArea.BackgroundColor3 = hub.currentTheme
				print("✅ Theme: " .. themeName)
			end, settingsOffset)
			settingsOffset = settingsOffset + 45
		end

		hub:addLabel(settingsContent, "Transparenz:", settingsOffset)
		settingsOffset = settingsOffset + 30

		hub:addButton(settingsContent, "Opak (0.9)", function()
			hub.settings.transparency = 0.9
			mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
		end, settingsOffset)
		settingsOffset = settingsOffset + 45

		hub:addButton(settingsContent, "Normal (0.7)", function()
			hub.settings.transparency = 0.7
			mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
		end, settingsOffset)
		settingsOffset = settingsOffset + 45

		hub:addButton(settingsContent, "Transparent (0.3)", function()
			hub.settings.transparency = 0.3
			mainFrame.BackgroundTransparency = 1 - hub.settings.transparency
		end, settingsOffset)
		settingsOffset = settingsOffset + 45

		hub:addLabel(settingsContent, "⌨️ Keybinds - Anpassen:", settingsOffset)
		settingsOffset = settingsOffset + 30

		hub:addButton(settingsContent, "GUI Toggle Key", function()
			print("🔑 Drücke eine Taste...")
			local connection
			connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
					hub.settings.guiToggleKey = input.KeyCode
					print("✅ GUI Toggle Key geändert!")
					connection:Disconnect()
				end
			end)
		end, settingsOffset)
		settingsOffset = settingsOffset + 45

		hub:addButton(settingsContent, "Teleport Key", function()
			print("🔑 Drücke eine Taste...")
			local connection
			connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
					hub.settings.teleportKey = input.KeyCode
					print("✅ Teleport Key geändert!")
					connection:Disconnect()
				end
			end)
		end, settingsOffset)
		settingsOffset = settingsOffset + 45

		hub:addButton(settingsContent, "Mouse TP Key", function()
			print("🔑 Drücke eine Taste...")
			local connection
			connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
					hub.settings.mouseTPToggleKey = input.KeyCode
					print("✅ Mouse TP Key geändert!")
					connection:Disconnect()
				end
			end)
		end, settingsOffset)
		settingsOffset = settingsOffset + 45

		settingsContent.Size = UDim2.new(1, 0, 0, settingsOffset + 10)

		print("✅ Tabs ready!")
	end)
end

function hub:destroy()
	print("🛑 Hub closed")
	hub.running = false
	hub.data.multiTPLoopActive = false
	hub.data.multiTPLoopInfinite = false
	for _, connection in ipairs(hub.connections) do
		if connection then
			pcall(function() connection:Disconnect() end)
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

		if input.KeyCode == hub.settings.guiToggleKey then
			hub.guiVisible = not hub.guiVisible
			screenGui.Enabled = hub.guiVisible
		end

		if input.KeyCode == Enum.KeyCode.X and
		   UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and
		   UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			hub:destroy()
		end

		if input.KeyCode == hub.settings.teleportKey then
			if hub.data.teleportPosition then
				hub:teleportPlayer(hub.data.teleportPosition + Vector3.new(0, 3, 0))
			end
		end

		if input.KeyCode == hub.settings.mouseTPToggleKey then
			hub.data.mouseTPActive = not hub.data.mouseTPActive
			hub:updateStatusButton(hub.uiElements.mouseTPBtn, hub.data.mouseTPActive)
		end

		if hub.data.mouseTPActive and input.UserInputType == Enum.UserInputType.MouseButton1 then
			if Mouse.Target then
				hub:teleportPlayer(Mouse.Hit.Position + Vector3.new(0, 3, 0))
			end
		end
	end))

	storeConnection(LocalPlayer.CharacterAdded:Connect(function()
		if hub.data.deathReturnEnabled and hub.data.deathPosition then
			wait(hub.settings.deathReturnTimer)
			hub:teleportPlayer(hub.data.deathPosition + Vector3.new(0, 3, 0))
		end
	end))
end

function hub:init()
	print("🎮 Hub v" .. hub.version .. " loading...")

	if not hub.running then
		print("⚠️ Hub inactive")
		return
	end

	hub:createGui()
	hub:setupTabs()
	hub:setupHotkey()

	print("✅ Hub loaded!")
end

hub:init()
return hub
