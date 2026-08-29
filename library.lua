local library = {}
library.Version = "1.0.0"
library.Flags = {}
library.Sets = {}
library.Windows = {}

local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")
local http = game:GetService("HttpService")

local function gethui()
	if getgenv and getgenv().gethui and type(getgenv().gethui) == "function" then
		local ok, ui = pcall(getgenv().gethui)
		if ok and ui then
			return ui
		end
	end
	return game:GetService("CoreGui")
end

local hui = gethui()

library.Theme = {
	Accent = Color3.fromRGB(0, 200, 255),
	Main = Color3.fromRGB(43, 43, 46),
	Background = Color3.fromRGB(27, 27, 30),
	Outline = Color3.fromRGB(0, 0, 0),
	Text = Color3.fromRGB(235, 235, 235),
	SubText = Color3.fromRGB(150, 150, 150),
	Danger = Color3.fromRGB(255, 85, 85),
}

local function nf(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

local function corner(parent, radius)
	return nf("UICorner", {
		CornerRadius = UDim.new(0, radius),
		Parent = parent,
	})
end

local function stroke(parent, color, thickness)
	return nf("UIStroke", {
		Color = color,
		Thickness = thickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function btn(parent, textname, height, sizeX)
	return nf("TextButton", {
		Text = textname,
		TextColor3 = library.Theme.Text,
		BackgroundColor3 = library.Theme.Background,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		Size = sizeX and UDim2.new(sizeX, 0, 0, height) or UDim2.new(0, 100, 0, height),
		Parent = parent,
	})
end

local function text(parent, str, size, color, xa)
	return nf("TextLabel", {
		Text = str,
		TextColor3 = color or library.Theme.Text,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = size,
		TextXAlignment = xa or Enum.TextXAlignment.Center,
		Parent = parent,
	})
end

local function tween(obj, duration, goals)
	ts:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals):Play()
end

local function row(parent, height)
	return nf("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		Parent = parent,
	})
end

local function flagset(name, fn)
	if name then
		library.Sets[name] = fn
	end
end

local function applyflag(name, value)
	if not name then return end
	library.Flags[name] = value
end

local notifCounts = {}

local function notify(config, parent)
	config = config or {}
	local notif = nf("Frame", {
		Size = UDim2.new(0, 220, 0, 0),
		Position = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = library.Theme.Main,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	corner(notif, 8)
	stroke(notif, library.Theme.Outline, 1)
	nf("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = library.Theme.Accent,
		BorderSizePixel = 0,
		Parent = notif,
	})
	local t = text(notif, config.Title or "", 14, library.Theme.Text, Enum.TextXAlignment.Left)
	t.Size = UDim2.new(1, -14, 0, 20)
	t.Position = UDim2.new(0, 10, 0, 6)
	t.Font = Enum.Font.GothamBold
	local d = text(notif, config.Text or "", 12, library.Theme.SubText, Enum.TextXAlignment.Left)
	d.Size = UDim2.new(1, -14, 0, 18)
	d.Position = UDim2.new(0, 10, 0, 26)
	d.TextWrapped = true
	local count = (notifCounts[parent] or 0) + 1
	notifCounts[parent] = count
	notif.Position = UDim2.new(1, 40, 0, 60 + (count - 1) * 62)
	tween(notif, 0.4, { Position = UDim2.new(1, -230, 0, 60 + (count - 1) * 62) })
	task.delay(config.Duration or 5, function()
		tween(notif, 0.3, {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
		})
		task.delay(0.32, function()
			notif:Destroy()
			notifCounts[parent] = math.max(0, notifCounts[parent] - 1)
		end)
	end)
end

function library:CreateWindow(config)
	config = config or {}

	local sg = nf("ScreenGui", {
		Name = config.Name or "Library",
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 500,
		Parent = hui,
	})

	local mainFrame = nf("Frame", {
		Size = UDim2.new(0, config.Width or 660, 0, config.Height or 440),
		Position = UDim2.new(0.5, -(config.Width or 660) / 2, 0.5, -(config.Height or 440) / 2),
		BackgroundColor3 = library.Theme.Main,
		BorderSizePixel = 0,
		Active = true,
		Draggable = true,
		Parent = sg,
	})
	corner(mainFrame, 10)
	stroke(mainFrame, library.Theme.Outline, 1)

	local accentBar = nf("Frame", {
		Size = UDim2.new(1, -8, 0, 2),
		Position = UDim2.new(0, 4, 0, 2),
		BackgroundColor3 = library.Theme.Accent,
		BorderSizePixel = 0,
		Parent = mainFrame,
	})
	corner(accentBar, 1)

	local header = nf("Frame", {
		Size = UDim2.new(1, -20, 0, 38),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		Parent = mainFrame,
	})

	local logo
	if config.Logo and config.Logo ~= "" then
		logo = nf("ImageLabel", {
			Image = config.Logo,
			Size = UDim2.new(0, 34, 0, 34),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = header,
		})
	end

	local title = nf("TextLabel", {
		Text = config.Name or "Library",
		TextColor3 = library.Theme.Text,
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, logo and 44 or 4, 0, 7),
		Size = UDim2.new(0, 300, 0, 24),
		Parent = header,
	})

	local minimized = false
	local minimizeBtn = btn(header, "-", 26, 30)
	minimizeBtn.Position = UDim2.new(1, -40, 0, 4)
	minimizeBtn.AnchorPoint = Vector2.new(1, 0)
	minimizeBtn.BackgroundColor3 = library.Theme.Background
	corner(minimizeBtn, 6)
	minimizeBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		local target = minimized and UDim2.new(0, config.Width or 660, 0, 62) or UDim2.new(0, config.Width or 660, 0, config.Height or 440)
		tween(mainFrame, 0.25, { Size = target })
		task.delay(0.05, function()
			tabBar.Visible = not minimized
			contentFrame.Visible = not minimized
		end)
	end)

	local tabBar = nf("Frame", {
		Size = UDim2.new(1, -20, 0, 28),
		Position = UDim2.new(0, 10, 0, 48),
		BackgroundTransparency = 1,
		Parent = mainFrame,
	})

	local tabLayout = nf("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabBar,
	})

	local contentFrame = nf("Frame", {
		Size = UDim2.new(1, -20, 1, -84),
		Position = UDim2.new(0, 10, 0, 82),
		BackgroundTransparency = 1,
		Parent = mainFrame,
	})

	local Window = {
		Name = config.Name or "Library",
		ScreenGui = sg,
		Frame = mainFrame,
		Tabs = {},
	}
	Window.Close = function()
		sg:Destroy()
	end
	table.insert(library.Windows, Window)

	local function column(side)
		local sf = nf("ScrollingFrame", {
			Size = UDim2.new(0.5, -5, 1, -4),
			Position = UDim2.new(side == "left" and 0 or 0.5, side == "left" and 0 or 5, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Parent = contentFrame,
		})
		nf("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = sf,
		})
		return sf
	end

	Window.CreateTab = function(self, tabConfig)
		tabConfig = tabConfig or {}

		local tabBtn = btn(tabBar, tabConfig.Name or "Tab", 26, 90)
		corner(tabBtn, 6)
		tabBtn.LayoutOrder = #Window.Tabs + 1
		tabBtn.BackgroundColor3 = library.Theme.Background

		local tabContent = nf("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = contentFrame,
		})

		local leftCol = column("left")
		local rightCol = column("right")
		leftCol.Parent = tabContent
		rightCol.Parent = tabContent

		local Tab = {
			Name = tabConfig.Name or "Tab",
			Button = tabBtn,
			Content = tabContent,
			Left = leftCol,
			Right = rightCol,
		}

		tabBtn.MouseButton1Click:Connect(function()
			Window:SelectTab(Tab)
		end)

		Tab.CreateSection = function(self, secConfig)
			secConfig = secConfig or {}
			local target = (secConfig.Side or "left"):lower() == "right" and rightCol or leftCol

			local secFrame = nf("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = library.Theme.Background,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = target,
			})
			corner(secFrame, 8)
			stroke(secFrame, library.Theme.Outline, 1)

			local secLayout = nf("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = secFrame,
			})

			nf("TextLabel", {
				Text = secConfig.Name or "Section",
				TextColor3 = library.Theme.Accent,
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, -16, 0, 20),
				Position = UDim2.new(0, 8, 0, 8),
				Parent = secFrame,
			})

			local Section = {
				Object = secFrame,
			}

			Section.CreateLabel = function(self, cfg)
				cfg = cfg or {}
				local fr = nf("Frame", {
					Size = UDim2.new(1, -12, 0, 18),
					Position = UDim2.new(0, 6, 0, 0),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = secFrame,
				})
				local lb = text(fr, cfg.Text or cfg.Name or "Label", 13, cfg.Color or library.Theme.SubText, Enum.TextXAlignment.Left)
				lb.Size = UDim2.new(1, 0, 0, 18)
				lb.ZIndex = 2
				local obj = {}
				obj.Object = fr
				function obj:Set(str)
					lb.Text = str
				end
				function obj:GetValue()
					return lb.Text
				end
				return obj
			end

			Section.CreateToggle = function(self, cfg)
				cfg = cfg or {}
				local fr = row(secFrame, 30)
				fr.Size = UDim2.new(1, -12, 0, 30)
				fr.Position = UDim2.new(0, 6, 0, 0)
				local lb = text(fr, cfg.Name or "Toggle", 13, library.Theme.Text, Enum.TextXAlignment.Left)
				lb.Position = UDim2.new(0, 0, 0.5, -8)
				lb.Size = UDim2.new(0, 170, 0, 16)

				local box = nf("Frame", {
					Size = UDim2.new(0, 42, 0, 22),
					Position = UDim2.new(1, -48, 0.5, -11),
					BackgroundColor3 = library.Theme.Main,
					BorderSizePixel = 0,
					Parent = fr,
				})
				corner(box, 11)
				stroke(box, library.Theme.Outline, 1)
				local knob = nf("Frame", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, 2, 0.5, -9),
					BackgroundColor3 = library.Theme.Text,
					BorderSizePixel = 0,
					Parent = box,
				})
				corner(knob, 9)

				local state = false
				local obj = {}
				obj.Object = fr

				local function render()
					if state then
						tween(box, 0.15, { BackgroundColor3 = library.Theme.Accent })
						tween(knob, 0.15, { Position = UDim2.new(0, 22, 0.5, -9) })
					else
						tween(box, 0.15, { BackgroundColor3 = library.Theme.Main })
						tween(knob, 0.15, { Position = UDim2.new(0, 2, 0.5, -9) })
					end
				end

				function obj:Set(v)
					v = v == true
					if state == v then return end
					state = v
					applyflag(cfg.Flag, state)
					render()
					if cfg.Callback then
						pcall(cfg.Callback, state)
					end
				end
				function obj:Toggle()
					obj:Set(not state)
				end
				function obj:GetValue()
					return state
				end

				box.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						obj:Toggle()
					end
				end)
				if cfg.Default == true then
					state = true
				end
				render()
				if cfg.Flag then
					flagset(cfg.Flag, function(v) obj:Set(v) end)
					applyflag(cfg.Flag, state)
				end
				return obj
			end

			Section.CreateSlider = function(self, cfg)
				cfg = cfg or {}
				local min = cfg.Min or 0
				local max = cfg.Max or 100
				local dec = cfg.Decimals or 0
				local fr = row(secFrame, 38)
				fr.Size = UDim2.new(1, -12, 0, 38)
				fr.Position = UDim2.new(0, 6, 0, 0)

				local lb = text(fr, cfg.Name or "Slider", 13, library.Theme.Text, Enum.TextXAlignment.Left)
				lb.Position = UDim2.new(0, 0, 0, 0)
				lb.Size = UDim2.new(0, 160, 0, 14)

				local vl = text(fr, tostring(cfg.Default or min), 12, library.Theme.SubText, Enum.TextXAlignment.Right)
				vl.Position = UDim2.new(1, -80, 0, 0)
				vl.Size = UDim2.new(0, 80, 0, 14)

				local bar = nf("Frame", {
					Size = UDim2.new(1, 0, 0, 4),
					Position = UDim2.new(0, 0, 0, 22),
					BackgroundColor3 = library.Theme.Main,
					BorderSizePixel = 0,
					Parent = fr,
				})
				corner(bar, 2)
				stroke(bar, library.Theme.Outline, 1)

				local fill = nf("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = library.Theme.Accent,
					BorderSizePixel = 0,
					Parent = bar,
				})
				corner(fill, 2)

				local grab = nf("Frame", {
					Size = UDim2.new(0, 12, 0, 12),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					BackgroundColor3 = library.Theme.Text,
					BorderSizePixel = 0,
					Parent = fr,
				})
				corner(grab, 6)

				local value = cfg.Default or min
				local dragging = false
				local obj = {}
				obj.Object = fr

				local function compute(x)
					local w = bar.AbsoluteSize.X
					if w <= 0 then return min end
					local t = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
					local mult = 10 ^ dec
					return math.floor((min + (max - min) * t) * mult + 0.5) / mult
				end

				local function render()
					local t = (value - min) / (max - min)
					local w = bar.AbsoluteSize.X
					fill.Size = UDim2.new(0, w * t, 1, 0)
					grab.Position = UDim2.new(0, math.clamp(w * t, 6, w - 6), 0.5, 0)
					local suffix = cfg.Suffix and (" " .. cfg.Suffix) or ""
					vl.Text = tostring(value) .. suffix
				end

				function obj:Set(v)
					v = tonumber(v) or min
					v = math.clamp(v, min, max)
					if v == value then return end
					value = v
					applyflag(cfg.Flag, value)
					render()
					if cfg.Callback then
						pcall(cfg.Callback, value)
					end
				end
				function obj:GetValue()
					return value
				end

				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						obj:Set(compute(uis:GetMouseLocation().X))
					end
				end)
				bar.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)
				rs.RenderStepped:Connect(function()
					if dragging then
						obj:Set(compute(uis:GetMouseLocation().X))
					end
				end)

				obj:Set(value)
				if cfg.Flag then
					flagset(cfg.Flag, function(v) obj:Set(v) end)
					applyflag(cfg.Flag, value)
				end
				return obj
			end

			Section.CreateDropdown = function(self, cfg)
				cfg = cfg or {}
				local items = cfg.List or {}
				local multi = cfg.Multi == true
				local current = cfg.Default
				if type(current) ~= "table" then
					current = current and { current } or (multi and {} or { items[1] })
				end
				if type(current) ~= "table" then
					current = {}
				end

				local fr = row(secFrame, 34)
				fr.Size = UDim2.new(1, -12, 0, 34)
				fr.Position = UDim2.new(0, 6, 0, 0)

				local lb = text(fr, cfg.Name or "Dropdown", 13, library.Theme.Text, Enum.TextXAlignment.Left)
				lb.Position = UDim2.new(0, 0, 0.5, -8)
				lb.Size = UDim2.new(0, 140, 0, 16)

				local selBtn = btn(fr, "", 24, nil)
				selBtn.Position = UDim2.new(1, -140, 0, 5)
				selBtn.Size = UDim2.new(0, 132, 0, 24)
				selBtn.BackgroundColor3 = library.Theme.Main
				corner(selBtn, 5)
				stroke(selBtn, library.Theme.Outline, 1)
				local selText = text(selBtn, table.concat(current, ", "), 12, library.Theme.Text, Enum.TextXAlignment.Center)
				selText.Size = UDim2.new(1, 0, 1, 0)

				local list = nf("ScrollingFrame", {
					Size = UDim2.new(0, 164, 0, 0),
					BackgroundColor3 = library.Theme.Main,
					BorderSizePixel = 0,
					ScrollBarThickness = 0,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					Visible = false,
					ZIndex = 20,
					Parent = sg,
				})
				corner(list, 6)
				stroke(list, library.Theme.Outline, 1)
				nf("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 4),
					Parent = list,
				})

				local obj = {}
				obj.Object = fr

				local function refreshlist()
					for _, child in pairs(list:GetChildren()) do
						if child:IsA("TextButton") then
							child:Destroy()
						end
					end
					for _, item in ipairs(items) do
						local b = btn(list, tostring(item), 22, nil)
						b.Size = UDim2.new(1, -8, 0, 22)
						b.Position = UDim2.new(0, 4, 0, 0)
						corner(b, 5)
						local selected = table.find(current, item) ~= nil
						b.BackgroundColor3 = selected and library.Theme.Accent or library.Theme.Background
						b.TextColor3 = selected and Color3.fromRGB(0, 0, 0) or library.Theme.Text
						b.MouseButton1Click:Connect(function()
							if multi then
								local idx = table.find(current, item)
								if idx then
									table.remove(current, idx)
								else
									table.insert(current, item)
								end
							else
								current = { item }
								list.Visible = false
							end
							selText.Text = table.concat(current, ", ")
							applyflag(cfg.Flag, multi and current or current[1])
							if cfg.Callback then
								pcall(cfg.Callback, multi and current or current[1])
							end
							refreshlist()
						end)
					end
					local h = 8 + #items * 26
					list.Size = UDim2.new(0, 164, 0, math.min(h, 140))
				end

				function obj:Set(v)
					if type(v) == "table" then
						current = {}
						for _, item in ipairs(items) do
							if table.find(v, item) then
								table.insert(current, item)
							end
						end
						if not multi then
							current = current[1] and { current[1] } or {}
						end
					else
						current = v and { v } or {}
					end
					selText.Text = table.concat(current, ", ")
					applyflag(cfg.Flag, multi and current or current[1])
					refreshlist()
				end
				function obj:GetValue()
					return multi and current or current[1]
				end

				selBtn.MouseButton1Click:Connect(function()
					list.Visible = not list.Visible
					if list.Visible then
						list.Position = UDim2.fromOffset(selBtn.AbsolutePosition.X, selBtn.AbsolutePosition.Y + selBtn.AbsoluteSize.Y + 4)
					end
				end)
				refreshlist()
				if cfg.Flag then
					flagset(cfg.Flag, function(v) obj:Set(v) end)
					applyflag(cfg.Flag, multi and current or current[1])
				end
				return obj
			end

			Section.CreateTextbox = function(self, cfg)
				cfg = cfg or {}
				local fr = row(secFrame, 34)
				fr.Size = UDim2.new(1, -12, 0, 34)
				fr.Position = UDim2.new(0, 6, 0, 0)

				local lb = text(fr, cfg.Name or "Textbox", 13, library.Theme.Text, Enum.TextXAlignment.Left)
				lb.Position = UDim2.new(0, 0, 0.5, -8)
				lb.Size = UDim2.new(0, 140, 0, 16)

				local tb = nf("TextBox", {
					Size = UDim2.new(0, 150, 0, 24),
					Position = UDim2.new(1, -156, 0, 5),
					Text = cfg.Placeholder or "",
					PlaceholderText = cfg.Placeholder or "",
					TextColor3 = library.Theme.Text,
					PlaceholderColor3 = library.Theme.SubText,
					BackgroundColor3 = library.Theme.Main,
					BorderSizePixel = 0,
					Font = Enum.Font.Gotham,
					TextSize = 13,
					ClearTextOnFocus = true,
					Parent = fr,
				})
				corner(tb, 5)
				stroke(tb, library.Theme.Outline, 1)

				local obj = {}
				obj.Object = fr
				function obj:Set(str)
					tb.Text = str
				end
				function obj:GetValue()
					return tb.Text
				end
				tb.FocusLost:Connect(function(enter)
					if enter and cfg.Callback then
						pcall(cfg.Callback, tb.Text)
					end
					applyflag(cfg.Flag, tb.Text)
				end)
				if cfg.Flag then
					flagset(cfg.Flag, function(v) tb.Text = v end)
					applyflag(cfg.Flag, tb.Text)
				end
				return obj
			end

			Section.CreateButton = function(self, cfg)
				cfg = cfg or {}
				local fr = row(secFrame, 26)
				fr.Size = UDim2.new(1, -12, 0, 26)
				fr.Position = UDim2.new(0, 6, 0, 0)
				local b = btn(fr, cfg.Name or "Button", 26, nil)
				b.Size = UDim2.new(1, 0, 0, 26)
				b.BackgroundColor3 = cfg.Danger and library.Theme.Danger or library.Theme.Main
				corner(b, 5)
				stroke(b, library.Theme.Outline, 1)
				b.MouseEnter:Connect(function()
					tween(b, 0.1, { BackgroundColor3 = library.Theme.Accent })
				end)
				b.MouseLeave:Connect(function()
					tween(b, 0.1, { BackgroundColor3 = cfg.Danger and library.Theme.Danger or library.Theme.Main })
				end)
				b.MouseButton1Click:Connect(function()
					if cfg.Callback then
						pcall(cfg.Callback)
					end
				end)
				local obj = {}
				obj.Object = fr
				function obj:Set(str)
					b.Text = str
				end
				return obj
			end

			Section.CreateColorpicker = function(self, cfg)
				cfg = cfg or {}
				local cur = cfg.Default
				local alpha = cfg.Alpha or 0
				if type(cur) == "table" then
					if cur.Color then
						alpha = cur.Alpha or alpha
						cur = cur.Color
					elseif cur.R then
						alpha = cur.A or alpha
						cur = Color3.fromRGB(cur.R, cur.G or cur.R, cur.B or cur.R)
					end
				end
				cur = cur or Color3.fromRGB(255, 255, 255)
				local fr = row(secFrame, 34)
				fr.Size = UDim2.new(1, -12, 0, 34)
				fr.Position = UDim2.new(0, 6, 0, 0)

				local lb = text(fr, cfg.Name or "Color", 13, library.Theme.Text, Enum.TextXAlignment.Left)
				lb.Position = UDim2.new(0, 0, 0.5, -8)
				lb.Size = UDim2.new(0, 140, 0, 16)

				local swatch = nf("Frame", {
					Size = UDim2.new(0, 40, 0, 24),
					Position = UDim2.new(1, -46, 0, 5),
					BackgroundColor3 = cur,
					BorderSizePixel = 0,
					Parent = fr,
				})
				corner(swatch, 4)
				stroke(swatch, library.Theme.Outline, 1)

				local obj = {}
				obj.Object = fr

				local picker
				local h, s, v = Color3.toHSV(cur)

				local function apply(color, alphaVal)
					cur = color
					alpha = alphaVal or alpha
					swatch.BackgroundColor3 = cur
					applyflag(cfg.Flag, { R = cur.R * 255, G = cur.G * 255, B = cur.B * 255, A = alpha })
					if cfg.Callback then
						pcall(cfg.Callback, cur, alpha)
					end
				end

				local function openpicker()
					if picker and picker.Parent then
						picker:Destroy()
					end
					h, s, v = Color3.toHSV(cur)

					local overlay = nf("TextButton", {
						Text = "",
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Parent = hui,
					})
					overlay.ZIndex = 500

					picker = nf("Frame", {
						Size = UDim2.new(0, 240, 0, 180),
						Position = UDim2.new(0.5, -120, 0.5, -90),
						BackgroundColor3 = library.Theme.Main,
						BorderSizePixel = 0,
						ZIndex = 501,
						Parent = hui,
					})
					corner(picker, 8)
					stroke(picker, library.Theme.Outline, 1)

					local satv = nf("Frame", {
						Size = UDim2.new(0, 120, 0, 100),
						Position = UDim2.new(0, 16, 0, 20),
						BackgroundColor3 = Color3.fromHSV(h, 1, 1),
						BorderSizePixel = 0,
						ZIndex = 502,
						Parent = picker,
					})
					corner(satv, 4)
					stroke(satv, library.Theme.Outline, 1)
					local white = nf("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						ZIndex = 503,
						Parent = satv,
					})
					corner(white, 4)
					local wg = nf("UIGradient", {
						Rotation = 90,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
						}),
						Parent = white,
					})
					local black = nf("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						ZIndex = 504,
						Parent = satv,
					})
					local bg = nf("UIGradient", {
						Rotation = 0,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
						}),
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(1, 0.85),
						}),
						Parent = black,
					})
					corner(black, 4)

					local cursor = nf("Frame", {
						Size = UDim2.new(0, 3, 0, 14),
						Position = UDim2.new(s, 0, v, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						ZIndex = 505,
						Parent = satv,
					})

					local huebar = nf("Frame", {
						Size = UDim2.new(0, 120, 0, 10),
						Position = UDim2.new(0, 16, 0, 128),
						BackgroundColor3 = Color3.fromRGB(255, 0, 0),
						BorderSizePixel = 0,
						ZIndex = 502,
						Parent = picker,
					})
					corner(huebar, 3)
					stroke(huebar, library.Theme.Outline, 1)
					local hg = nf("UIGradient", {
						Rotation = 90,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
							ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
							ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
							ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
							ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
							ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
						}),
						Parent = huebar,
					})
					local hcur = nf("Frame", {
						Size = UDim2.new(0, 6, 0, 14),
						Position = UDim2.new(h, -3, 0, -2),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						ZIndex = 505,
						Parent = picker,
					})

					local hexin = nf("TextBox", {
						Size = UDim2.new(0, 90, 0, 20),
						Position = UDim2.new(1, -106, 0, 16),
						Text = cur:ToHex():upper(),
						TextColor3 = library.Theme.Text,
						BackgroundColor3 = library.Theme.Background,
						BorderSizePixel = 0,
						Font = Enum.Font.Code,
						TextSize = 12,
						ZIndex = 502,
						Parent = picker,
					})
					corner(hexin, 4)
					stroke(hexin, library.Theme.Outline, 1)

					local closebtn = btn(picker, "done", 22, 84)
					closebtn.Position = UDim2.new(1, -98, 1, -30)
					closebtn.BackgroundColor3 = library.Theme.Accent
					closebtn.TextColor3 = Color3.fromRGB(0, 0, 0)
					closebtn.ZIndex = 502
					corner(closebtn, 5)

					local satdrag = false
					local hudrag = false
					local sconn, hconn, uconn, rconn

					local function getsv(x, y)
						local w, ht = satv.AbsoluteSize.X, satv.AbsoluteSize.Y
						if w <= 0 or ht <= 0 then return s, v end
						s = math.clamp((x - satv.AbsolutePosition.X) / w, 0, 1)
						v = math.clamp(1 - (y - satv.AbsolutePosition.Y) / ht, 0, 1)
						white.BackgroundColor3 = Color3.fromHSV(h, s, v)
						return s, v
					end
					local function gethue(x)
						local w = huebar.AbsoluteSize.X
						if w <= 0 then return h end
						h = math.clamp((x - huebar.AbsolutePosition.X) / w, 0, 1)
						white.BackgroundColor3 = Color3.fromHSV(h, s, v)
						satv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
						return h
					end
					local function sync()
						cursor.Position = UDim2.new(s, 0, v, 0)
						hcur.Position = UDim2.new(h, -3, 0, -2)
						hexin.Text = Color3.fromHSV(h, s, v):ToHex():upper()
					end

					local function cleanup()
						if sconn then sconn:Disconnect() end
						if hconn then hconn:Disconnect() end
						if uconn then uconn:Disconnect() end
						if rconn then rconn:Disconnect() end
						sconn, hconn, uconn, rconn = nil, nil, nil, nil
						if picker then
							picker:Destroy()
						end
					end
					local function close()
						cleanup()
						overlay:Destroy()
					end

					sconn = satv.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							satdrag = true
							getsv(uis:GetMouseLocation().X, uis:GetMouseLocation().Y)
							sync()
						end
					end)
					hconn = huebar.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							hudrag = true
							gethue(uis:GetMouseLocation().X)
							sync()
						end
					end)
					uconn = uis.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							satdrag = false
							hudrag = false
						end
					end)
					rconn = rs.RenderStepped:Connect(function()
						if satdrag then
							getsv(uis:GetMouseLocation().X, uis:GetMouseLocation().Y)
							sync()
						elseif hudrag then
							gethue(uis:GetMouseLocation().X)
							sync()
						end
					end)
					hexin.FocusLost:Connect(function(enter)
						if not enter then return end
						local ok, col = pcall(Color3.fromHex, hexin.Text:gsub("#", ""))
						if ok and col then
							apply(col, alpha)
						end
						close()
					end)
					closebtn.MouseButton1Click:Connect(function()
						apply(Color3.fromHSV(h, s, v), alpha)
						close()
					end)
					overlay.MouseButton1Click:Connect(function()
						close()
					end)
				end

				function obj:Set(color)
					if type(color) == "table" then
						if color.Color then
							alpha = color.Alpha or alpha
							color = color.Color
						elseif color.R then
							alpha = color.A or alpha
							color = Color3.fromRGB(color.R, color.G or color.R, color.B or color.R)
						end
					end
					apply(color, alpha)
					h, s, v = Color3.toHSV(color)
				end
				function obj:GetValue()
					return cur
				end

				swatch.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						openpicker()
					end
				end)
				if cfg.Flag then
					flagset(cfg.Flag, function(c) obj:Set(c) end)
					applyflag(cfg.Flag, { R = cur.R * 255, G = cur.G * 255, B = cur.B * 255, A = alpha })
				end
				return obj
			end

			Section.CreateKeybind = function(self, cfg)
				cfg = cfg or {}
				local mode = cfg.Mode or "Toggle"
				local key = cfg.Default or Enum.KeyCode.Unknown
				local active = false
				local fr = row(secFrame, 34)
				fr.Size = UDim2.new(1, -12, 0, 34)
				fr.Position = UDim2.new(0, 6, 0, 0)

				local lb = text(fr, cfg.Name or "Keybind", 13, library.Theme.Text, Enum.TextXAlignment.Left)
				lb.Position = UDim2.new(0, 0, 0.5, -8)
				lb.Size = UDim2.new(0, 140, 0, 16)

				local kb = btn(fr, "", 24, nil)
				kb.Position = UDim2.new(1, -90, 0, 5)
				kb.Size = UDim2.new(0, 84, 0, 24)
				kb.BackgroundColor3 = library.Theme.Main
				corner(kb, 5)
				stroke(kb, library.Theme.Outline, 1)

				local obj = {}
				obj.Object = fr

				local function render()
					kb.Text = key == Enum.KeyCode.Unknown and "none" or key.Name
				end

				local bindMode = false

				function obj:Set(k)
					key = k or Enum.KeyCode.Unknown
					render()
				end
				function obj:GetValue()
					return key
				end
				function obj:GetKey()
					return key
				end

				local function press()
					if mode == "Toggle" then
						active = not active
						if cfg.Callback then
							pcall(cfg.Callback, active)
						end
					else
						if cfg.Callback then
							pcall(cfg.Callback, true)
						end
					end
				end
				local function release()
					if mode ~= "Toggle" then
						if cfg.Callback then
							pcall(cfg.Callback, false)
						end
					end
				end

				kb.MouseButton1Click:Connect(function()
					bindMode = true
					kb.Text = "..."
				end)
				uis.InputBegan:Connect(function(input, gp)
					if gp then return end
					if bindMode and input.UserInputType == Enum.UserInputType.Keyboard then
						key = input.KeyCode
						bindMode = false
						render()
						applyflag(cfg.Flag, key.Name)
						return
					end
					if not bindMode and input.KeyCode == key and key ~= Enum.KeyCode.Unknown then
						press()
					end
				end)
				uis.InputEnded:Connect(function(input)
					if not bindMode and input.KeyCode == key and key ~= Enum.KeyCode.Unknown then
						release()
					end
				end)
				if cfg.Flag then
					flagset(cfg.Flag, function(k) obj:Set(Enum.KeyCode[k] or Enum.KeyCode.Unknown) end)
					applyflag(cfg.Flag, key.Name)
				end
				render()
				return obj
			end

			return Section
		end

		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then
			Window:SelectTab(Tab)
		end

		Tab.Select = function(self)
			Window:SelectTab(self)
		end

		return Tab
	end

	Window.SelectTab = function(self, tab)
		for _, other in pairs(Window.Tabs) do
			other.Content.Visible = false
			other.Button.TextColor3 = library.Theme.SubText
			other.Button.BackgroundColor3 = library.Theme.Background
		end
		tab.Content.Visible = true
		tab.Button.TextColor3 = library.Theme.Accent
		tab.Button.BackgroundColor3 = library.Theme.Main
	end

	function Window:CreateNotification(config)
		notify(config, sg)
	end

	return Window
end

local notifGui

function library:CreateNotification(config)
	if not notifGui then
		notifGui = nf("ScreenGui", {
			Name = "Notifications",
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 501,
			Parent = hui,
		})
	end
	notify(config, notifGui)
end

function library:Notify(textname, title, duration)
	library:CreateNotification({
		Title = title or "Notification",
		Text = textname or "",
		Duration = duration or 5,
	})
end

function library:SaveConfig(fileName)
	if isfolder and makefolder then
		pcall(function()
			if not isfolder("Tolerate") then
				makefolder("Tolerate")
			end
		end)
	end
	if isfile and writefile then
		pcall(function()
			writefile("Tolerate/" .. (fileName or "config") .. ".json", http:JSONEncode(library.Flags))
		end)
	end
end

function library:LoadConfig(fileName)
	if isfile and readfile and isfile("Tolerate/" .. (fileName or "config") .. ".json") then
		pcall(function()
			local data = http:JSONDecode(readfile("Tolerate/" .. (fileName or "config") .. ".json"))
			for k, v in pairs(data) do
				if library.Sets[k] then
					pcall(library.Sets[k], v)
				end
				library.Flags[k] = v
			end
		end)
	end
end

function library.Toggle()
	for _, w in pairs(library.Windows) do
		w.Frame.Visible = not w.Frame.Visible
	end
end

return library