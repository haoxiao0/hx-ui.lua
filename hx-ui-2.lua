-- ==========================================
-- Part 2: UI 核心引擎 (Library.lua)
-- ==========================================
local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local function GetGuiParent()
    if gethui then return gethui() end
    if syn and syn.protect_gui then
        local gui = Instance.new("ScreenGui")
        syn.protect_gui(gui)
        local success, core = pcall(function() return game:GetService("CoreGui") end)
        if success and core then gui.Parent = core end
        return gui
    end
    local success, core = pcall(function() return game:GetService("CoreGui") end)
    if success and core then return core end
    if Players.LocalPlayer then return Players.LocalPlayer:WaitForChild("PlayerGui") end
    return nil
end

local function RandomString(length)
    local res = ""
    for i = 1, length do res = res .. string.char(math.random(97, 122)) end
    return res
end

function Library:CreateWindow(Settings)
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.IsMaximized = false
    
    local Config = Settings.Config
    local FontColor = Config.Typography.TextColor
    local DivColor = Config.Typography.DividerColor
    local StrokeColor = Config.Window.StrokeColor

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = RandomString(12)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local parent = GetGuiParent()
    if not parent then return end
    ScreenGui.Parent = parent
    Window.ScreenGui = ScreenGui

    -- 最小化悬浮按钮 (hx)
    local FloatingBtn = Instance.new("TextButton")
    FloatingBtn.Size = UDim2.fromOffset(Config.FloatingButton.Width, Config.FloatingButton.Height)
    FloatingBtn.Position = Config.FloatingButton.Position
    FloatingBtn.BackgroundColor3 = Config.FloatingButton.BackgroundColor
    FloatingBtn.BackgroundTransparency = Config.FloatingButton.BackgroundTransparency
    FloatingBtn.Text = Config.FloatingButton.Text
    FloatingBtn.TextColor3 = Config.FloatingButton.TextColor
    FloatingBtn.TextSize = Config.Typography.GlobalTextSize
    FloatingBtn.Font = Enum.Font.GothamBold
    FloatingBtn.Visible = false
    FloatingBtn.Parent = ScreenGui
    Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(0, Config.FloatingButton.CornerRadius)
    
    local fStroke = Instance.new("UIStroke", FloatingBtn)
    fStroke.Color = StrokeColor
    fStroke.Thickness = 1

    local fDragging, fDragInput, fDragStart, fStartPos
    FloatingBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fDragging = true
            fDragStart = input.Position
            fStartPos = FloatingBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then fDragging = false end
            end)
        end
    end)
    FloatingBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then fDragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == fDragInput and fDragging then
            local delta = input.Position - fDragStart
            FloatingBtn.Position = UDim2.new(fStartPos.X.Scale, fStartPos.X.Offset + delta.X, fStartPos.Y.Scale, fStartPos.Y.Offset + delta.Y)
        end
    end)

    -- 主框架
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.fromOffset(Config.Window.Width, Config.Window.Height)
    MainFrame.Position = Config.Window.Position
    MainFrame.AnchorPoint = Config.Window.AnchorPoint
    MainFrame.BackgroundColor3 = Config.Window.BackgroundColor
    MainFrame.BackgroundTransparency = Config.Window.BackgroundTransparency
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Window.MainFrame = MainFrame
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, Config.Window.CornerRadius)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = StrokeColor
    MainStroke.Thickness = 1.2

    FloatingBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        FloatingBtn.Visible = false
    end)

    local TopDivider = Instance.new("Frame")
    TopDivider.Size = UDim2.new(1, 0, 0, 1)
    TopDivider.Position = UDim2.new(0, 0, 0.1, -1)
    TopDivider.BackgroundColor3 = DivColor
    TopDivider.BorderSizePixel = 0
    TopDivider.ZIndex = 5
    TopDivider.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0.1, 0)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = MainFrame

    local TopLayout = Instance.new("UIListLayout")
    TopLayout.FillDirection = Enum.FillDirection.Horizontal
    TopLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TopLayout.Parent = TopBar

    local TitleArea = Instance.new("TextLabel")
    TitleArea.Size = UDim2.new(0.2, 0, 1, 0)
    TitleArea.BackgroundTransparency = 1
    TitleArea.Text = Settings.Title or "HAOXIAO"
    TitleArea.TextColor3 = FontColor
    TitleArea.Font = Config.Typography.FontType
    TitleArea.TextSize = Config.Typography.GlobalTextSize
    TitleArea.Parent = TopBar

    local SubTitleArea = Instance.new("TextLabel")
    SubTitleArea.Size = UDim2.new(0.5, 0, 1, 0)
    SubTitleArea.BackgroundTransparency = 1
    SubTitleArea.Text = Settings.SubTitle or "v1.0"
    SubTitleArea.TextColor3 = Config.Typography.DimTextColor
    SubTitleArea.TextTransparency = Config.Typography.DimTextTransparency
    SubTitleArea.Font = Config.Typography.FontType
    SubTitleArea.TextSize = Config.Typography.GlobalTextSize
    SubTitleArea.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleArea.Parent = TopBar

    local function CreateTopButton(widthScale, iconText, callback)
        local Area = Instance.new("Frame")
        Area.Size = UDim2.new(widthScale, 0, 1, 0)
        Area.BackgroundTransparency = 1
        Area.Parent = TopBar

        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.fromOffset(Config.TopButton.Width, Config.TopButton.Height)
        Btn.Position = UDim2.fromScale(0.5, 0.5)
        Btn.AnchorPoint = Vector2.new(0.5, 0.5)
        Btn.BackgroundColor3 = Config.TopButton.BackgroundColor
        Btn.BackgroundTransparency = Config.TopButton.BackgroundTransparency
        Btn.Text = iconText
        Btn.TextColor3 = Config.TopButton.TextColor
        Btn.TextSize = Config.Typography.GlobalTextSize
        Btn.Font = Enum.Font.GothamBold
        Btn.Parent = Area

        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, Config.TopButton.CornerRadius)
        Btn.MouseButton1Click:Connect(callback)
    end

    CreateTopButton(0.1, "-", function()
        MainFrame.Visible = false
        FloatingBtn.Visible = true
    end)

    local originalSize = MainFrame.Size
    local originalPos = MainFrame.Position
    CreateTopButton(0.1, "□", function()
        Window.IsMaximized = not Window.IsMaximized
        if Window.IsMaximized then
            originalSize = MainFrame.Size
            originalPos = MainFrame.Position
            local cam = workspace.CurrentCamera
            local newSizeX = cam.ViewportSize.X * 0.9
            local newSizeY = cam.ViewportSize.Y * 0.9
            local newPosX = (cam.ViewportSize.X - newSizeX) / 2
            local newPosY = (cam.ViewportSize.Y - newSizeY) / 2
            
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {
                Size = UDim2.fromOffset(newSizeX, newSizeY),
                Position = UDim2.fromOffset(newPosX, newPosY)
            }):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {
                Size = originalSize,
                Position = originalPos
            }):Play()
        end
    end)

    local DialogFrame = Instance.new("Frame")
    DialogFrame.Size = UDim2.fromOffset(220, 110) 
    DialogFrame.Position = UDim2.fromScale(0.5, 0.5)
    DialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    DialogFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    DialogFrame.BorderSizePixel = 0
    DialogFrame.ZIndex = 50
    DialogFrame.Visible = false
    DialogFrame.Parent = MainFrame

    Instance.new("UICorner", DialogFrame).CornerRadius = UDim.new(0, 10)
    
    local DialogStroke = Instance.new("UIStroke", DialogFrame)
    DialogStroke.Color = StrokeColor
    DialogStroke.Thickness = 1.2

    local DialogText = Instance.new("TextLabel")
    DialogText.Size = UDim2.new(1, 0, 0.6, 0)
    DialogText.BackgroundTransparency = 1
    DialogText.Text = "确定退出脚本?"
    DialogText.TextColor3 = FontColor
    DialogText.TextSize = Config.Typography.GlobalTextSize
    DialogText.Font = Config.Typography.FontType
    DialogText.ZIndex = 51
    DialogText.Parent = DialogFrame

    local DialogBtns = Instance.new("Frame")
    DialogBtns.Size = UDim2.new(1, -20, 0.4, -10)
    DialogBtns.Position = UDim2.new(0, 10, 0.6, 0)
    DialogBtns.BackgroundTransparency = 1
    DialogBtns.ZIndex = 51
    DialogBtns.Parent = DialogFrame

    local CancelBtn = Instance.new("TextButton")
    CancelBtn.Size = UDim2.new(0.45, 0, 1, 0)
    CancelBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    CancelBtn.Text = "取消"
    CancelBtn.TextColor3 = FontColor
    CancelBtn.TextSize = 13
    CancelBtn.Font = Config.Typography.FontType
    CancelBtn.ZIndex = 52
    CancelBtn.Parent = DialogBtns
    Instance.new("UICorner", CancelBtn).CornerRadius = UDim.new(0, 6)
    CancelBtn.MouseButton1Click:Connect(function() DialogFrame.Visible = false end)

    local ConfirmBtn = Instance.new("TextButton")
    ConfirmBtn.Size = UDim2.new(0.45, 0, 1, 0)
    ConfirmBtn.Position = UDim2.new(0.55, 0, 0, 0)
    ConfirmBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    ConfirmBtn.Text = "确定"
    ConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConfirmBtn.TextSize = 13
    ConfirmBtn.Font = Config.Typography.FontType
    ConfirmBtn.ZIndex = 52
    ConfirmBtn.Parent = DialogBtns
    Instance.new("UICorner", ConfirmBtn).CornerRadius = UDim.new(0, 6)
    ConfirmBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    CreateTopButton(0.1, "X", function() DialogFrame.Visible = true end)

    -- 调色盘
    local ColorDialog = Instance.new("Frame")
    ColorDialog.Size = UDim2.fromOffset(Config.ColorPicker.DialogWidth, Config.ColorPicker.DialogHeight)
    ColorDialog.Position = UDim2.fromScale(0.5, 0.5)
    ColorDialog.AnchorPoint = Vector2.new(0.5, 0.5)
    ColorDialog.BackgroundColor3 = Color3.fromRGB(22, 22, 22) 
    ColorDialog.BorderSizePixel = 0
    ColorDialog.ZIndex = 60
    ColorDialog.Visible = false
    ColorDialog.Parent = MainFrame

    Instance.new("UICorner", ColorDialog).CornerRadius = UDim.new(0, 12)
    
    local CStroke = Instance.new("UIStroke", ColorDialog)
    CStroke.Color = StrokeColor 
    CStroke.Thickness = 1.2

    local CTitle = Instance.new("TextLabel")
    CTitle.Size = UDim2.new(1, 0, 0, 35)
    CTitle.Text = "选择颜色"
    CTitle.Font = Enum.Font.GothamBold
    CTitle.TextColor3 = FontColor
    CTitle.TextSize = 13
    CTitle.BackgroundTransparency = 1
    CTitle.ZIndex = 61
    CTitle.Parent = ColorDialog

    local ColorMap = Instance.new("TextButton")
    ColorMap.Size = UDim2.new(1, -30, 0, 160)
    ColorMap.Position = UDim2.new(0, 15, 0, 40)
    ColorMap.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ColorMap.Text = ""
    ColorMap.AutoButtonColor = false
    ColorMap.ZIndex = 61
    ColorMap.Parent = ColorDialog
    Instance.new("UICorner", ColorMap).CornerRadius = UDim.new(0, 8)

    local HueGradient = Instance.new("UIGradient")
    HueGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    }
    HueGradient.Parent = ColorMap

    local RGBContainer = Instance.new("Frame")
    RGBContainer.Size = UDim2.new(1, -30, 0, 40)
    RGBContainer.Position = UDim2.new(0, 15, 0, 215)
    RGBContainer.BackgroundTransparency = 1
    RGBContainer.ZIndex = 61
    RGBContainer.Parent = ColorDialog
    
    local function CreateModernColorInput(posX, placeholder)
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0.3, 0, 1, 0)
        bg.Position = UDim2.new(posX, 0, 0, 0)
        bg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        bg.ZIndex = 62
        bg.Parent = RGBContainer
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, 0, 1, 0)
        box.BackgroundTransparency = 1
        box.TextColor3 = FontColor
        box.PlaceholderText = placeholder
        box.Font = Config.Typography.FontType
        box.TextSize = 12
        box.ZIndex = 63
        box.Parent = bg
        return box
    end
    
    local RInput = CreateModernColorInput(0, "R")
    local GInput = CreateModernColorInput(0.35, "G")
    local BInput = CreateModernColorInput(0.7, "B")

    local CBtnContainer = Instance.new("Frame")
    CBtnContainer.Size = UDim2.new(1, -30, 0, 35)
    CBtnContainer.Position = UDim2.new(0, 15, 0, 270)
    CBtnContainer.BackgroundTransparency = 1
    CBtnContainer.ZIndex = 61
    CBtnContainer.Parent = ColorDialog

    local C_CancelBtn = Instance.new("TextButton")
    C_CancelBtn.Size = UDim2.new(0.45, 0, 1, 0)
    C_CancelBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    C_CancelBtn.Text = "取消"
    C_CancelBtn.TextColor3 = FontColor
    C_CancelBtn.TextSize = 13
    C_CancelBtn.Font = Config.Typography.FontType
    C_CancelBtn.ZIndex = 62
    C_CancelBtn.Parent = CBtnContainer
    Instance.new("UICorner", C_CancelBtn).CornerRadius = UDim.new(0, 6)
    C_CancelBtn.MouseButton1Click:Connect(function() ColorDialog.Visible = false end)

    local C_ConfirmBtn = Instance.new("TextButton")
    C_ConfirmBtn.Size = UDim2.new(0.45, 0, 1, 0)
    C_ConfirmBtn.Position = UDim2.new(0.55, 0, 0, 0)
    C_ConfirmBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 100)
    C_ConfirmBtn.Text = "确定"
    C_ConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    C_ConfirmBtn.TextSize = 13
    C_ConfirmBtn.Font = Config.Typography.FontType
    C_ConfirmBtn.ZIndex = 62
    C_ConfirmBtn.Parent = CBtnContainer
    Instance.new("UICorner", C_ConfirmBtn).CornerRadius = UDim.new(0, 6)

    local activeColorCallback = nil
    local activeColorSquare = nil
    local tempColor = Color3.new(1,1,1)

    ColorMap.MouseButton1Down:Connect(function()
        local mouse = Players.LocalPlayer:GetMouse()
        local relativeX = math.clamp((mouse.X - ColorMap.AbsolutePosition.X) / ColorMap.AbsoluteSize.X, 0, 1)
        tempColor = Color3.fromHSV(relativeX, 1, 1)
        RInput.Text = tostring(math.floor(tempColor.R * 255))
        GInput.Text = tostring(math.floor(tempColor.G * 255))
        BInput.Text = tostring(math.floor(tempColor.B * 255))
    end)

    C_ConfirmBtn.MouseButton1Click:Connect(function()
        local r = tonumber(RInput.Text) or 255
        local g = tonumber(GInput.Text) or 255
        local b = tonumber(BInput.Text) or 255
        local finalColor = Color3.fromRGB(r, g, b)
        
        if activeColorSquare then activeColorSquare.BackgroundColor3 = finalColor end
        if activeColorCallback then activeColorCallback(finalColor) end
        ColorDialog.Visible = false
    end)

    local BottomArea = Instance.new("Frame")
    BottomArea.Size = UDim2.new(1, 0, 0.9, 0)
    BottomArea.Position = UDim2.new(0, 0, 0.1, 0)
    BottomArea.BackgroundTransparency = 1
    BottomArea.Parent = MainFrame

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(0.3, 0, 1, 0)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 2
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.Parent = BottomArea

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabLayout.Parent = TabContainer
    Instance.new("UIPadding", TabContainer).PaddingTop = UDim.new(0, 10)

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(0.7, 0, 1, 0)
    ContentContainer.Position = UDim2.new(0.3, 0, 0, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = BottomArea

    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    function Window:AddTab(TabConfig)
        local Tab = {}
        Tab.ItemCount = 0 -- 核心修复：用于严格控制所有组件的排序
        
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.fromOffset(100, 40)
        TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        TabBtn.BackgroundTransparency = 0.5
        TabBtn.Text = ""
        TabBtn.Parent = TabContainer
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

        local IconDisplay = Instance.new("ImageLabel")
        IconDisplay.Size = UDim2.new(0.33, 0, 1, 0)
        IconDisplay.BackgroundTransparency = 1
        IconDisplay.Image = TabConfig.Icon or ""
        IconDisplay.ScaleType = Enum.ScaleType.Fit
        IconDisplay.Parent = TabBtn

        local TextDisplay = Instance.new("TextLabel")
        TextDisplay.Size = UDim2.new(0.67, 0, 1, 0)
        TextDisplay.Position = UDim2.new(0.33, 0, 0, 0)
        TextDisplay.BackgroundTransparency = 1
        TextDisplay.Text = TabConfig.Title or "标签"
        TextDisplay.TextColor3 = Config.Typography.TextColor
        TextDisplay.TextSize = Config.Typography.GlobalTextSize
        TextDisplay.Font = Config.Typography.FontType
        TextDisplay.Parent = TabBtn

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, -10, 1, -10)
        Page.Position = UDim2.fromOffset(5, 5)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.Visible = false
        Page.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder -- 核心修复：确保依据 LayoutOrder 排列
        PageLayout.Parent = Page

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y)
        end)
        TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y + 20)
        end)

        TabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(Window.Tabs) do
                v.Page.Visible = false
                v.Button.BackgroundTransparency = 0.5
            end
            Page.Visible = true
            TabBtn.BackgroundTransparency = 0
            Window.CurrentTab = Tab
        end)

        if #Window.Tabs == 0 then
            Page.Visible = true
            TabBtn.BackgroundTransparency = 0
            Window.CurrentTab = Tab
        end

        Tab.Button = TabBtn
        Tab.Page = Page
        table.insert(Window.Tabs, Tab)

        function Tab:AddTitle(TitleText)
            Tab.ItemCount = Tab.ItemCount + 1
            local Element = Instance.new("TextLabel")
            Element.LayoutOrder = Tab.ItemCount
            Element.Size = UDim2.new(1, 0, 0, 40)
            Element.BackgroundTransparency = 1
            Element.Text = " " .. TitleText
            Element.TextColor3 = Config.Typography.TextColor
            Element.TextSize = Config.Typography.GlobalTextSize
            Element.Font = Enum.Font.GothamBold
            Element.TextXAlignment = Enum.TextXAlignment.Left
            Element.Parent = Page
        end

        function Tab:AddToggle(TogConfig)
            Tab.ItemCount = Tab.ItemCount + 1
            local ToggleVal = TogConfig.Default or false
            local Element = Instance.new("TextButton")
            Element.LayoutOrder = Tab.ItemCount
            Element.Size = UDim2.new(1, 0, 0, 50) 
            Element.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Element.BackgroundTransparency = 0.6
            Element.Text = ""
            Element.Parent = Page
            Instance.new("UICorner", Element).CornerRadius = UDim.new(0, 8)

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.8, 0, 1, 0)
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = TogConfig.Title or "Toggle"
            Title.TextColor3 = Config.Typography.TextColor
            Title.TextSize = Config.Typography.GlobalTextSize
            Title.Font = Config.Typography.FontType
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Element

            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.fromOffset(24, 24) 
            Indicator.Position = UDim2.new(1, -35, 0.5, 0)
            Indicator.AnchorPoint = Vector2.new(0, 0.5)
            Indicator.BackgroundColor3 = ToggleVal and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(60, 60, 60)
            Indicator.Parent = Element
            Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 6)

            Element.MouseButton1Click:Connect(function()
                ToggleVal = not ToggleVal
                Indicator.BackgroundColor3 = ToggleVal and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(60, 60, 60)
                if TogConfig.Callback then TogConfig.Callback(ToggleVal) end
            end)
        end

        function Tab:AddSlider(SliConfig)
            Tab.ItemCount = Tab.ItemCount + 1
            local Min = SliConfig.Min or 0
            local Max = SliConfig.Max or 100
            local Current = SliConfig.Default or Min

            local Element = Instance.new("Frame")
            Element.LayoutOrder = Tab.ItemCount
            Element.Size = UDim2.new(1, 0, 0, 50) 
            Element.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Element.BackgroundTransparency = 0.6
            Element.Parent = Page
            Instance.new("UICorner", Element).CornerRadius = UDim.new(0, 8)

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.5, 0, 1, 0)
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = SliConfig.Title or "Slider"
            Title.TextColor3 = Config.Typography.TextColor
            Title.TextSize = Config.Typography.GlobalTextSize
            Title.Font = Config.Typography.FontType
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Element

            local ValueDisplay = Instance.new("TextLabel")
            ValueDisplay.Size = UDim2.new(0.15, 0, 1, 0)
            ValueDisplay.Position = UDim2.new(0.40, 0, 0, 0)
            ValueDisplay.BackgroundTransparency = 1
            ValueDisplay.Text = tostring(Current)
            ValueDisplay.TextColor3 = Config.Typography.TextColor
            ValueDisplay.TextSize = 13
            ValueDisplay.Font = Config.Typography.FontType
            ValueDisplay.Parent = Element

            local SliderRail = Instance.new("TextButton")
            SliderRail.Size = UDim2.new(0.35, 0, 0.2, 0)
            SliderRail.Position = UDim2.new(0.6, 0, 0.5, 0)
            SliderRail.AnchorPoint = Vector2.new(0, 0.5)
            SliderRail.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            SliderRail.Text = ""
            SliderRail.Parent = Element
            Instance.new("UICorner", SliderRail).CornerRadius = UDim.new(1, 0)

            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new(math.clamp((Current - Min) / (Max - Min), 0, 1), 0, 1, 0)
            SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderFill.Parent = SliderRail
            Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

            local sDragging = false
            SliderRail.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sDragging = true end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sDragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local scale = math.clamp((input.Position.X - SliderRail.AbsolutePosition.X) / SliderRail.AbsoluteSize.X, 0, 1)
                    SliderFill.Size = UDim2.new(scale, 0, 1, 0)
                    local value = math.floor(Min + ((Max - Min) * scale))
                    ValueDisplay.Text = tostring(value)
                    if SliConfig.Callback then SliConfig.Callback(value) end
                end
            end)
        end

        function Tab:AddColorpicker(ColConfig)
            Tab.ItemCount = Tab.ItemCount + 1
            local CurrentColor = ColConfig.Default or Color3.fromRGB(255, 255, 255)

            local Element = Instance.new("Frame")
            Element.LayoutOrder = Tab.ItemCount
            Element.Size = UDim2.new(1, 0, 0, 50) 
            Element.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Element.BackgroundTransparency = 0.6
            Element.Parent = Page
            Instance.new("UICorner", Element).CornerRadius = UDim.new(0, 8)

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.8, 0, 1, 0)
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = ColConfig.Title or "Colorpicker"
            Title.TextColor3 = Config.Typography.TextColor
            Title.TextSize = Config.Typography.GlobalTextSize
            Title.Font = Config.Typography.FontType
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Element

            local ColorSquare = Instance.new("TextButton")
            ColorSquare.Size = UDim2.fromOffset(Config.ColorPicker.SquareSize, Config.ColorPicker.SquareSize)
            ColorSquare.Position = UDim2.new(1, -35, 0.5, 0)
            ColorSquare.AnchorPoint = Vector2.new(0, 0.5)
            ColorSquare.BackgroundColor3 = CurrentColor
            ColorSquare.Text = ""
            ColorSquare.Parent = Element
            Instance.new("UICorner", ColorSquare).CornerRadius = UDim.new(0, Config.ColorPicker.SquareCorner)

            ColorSquare.MouseButton1Click:Connect(function()
                activeColorCallback = ColConfig.Callback
                activeColorSquare = ColorSquare
                
                RInput.Text = tostring(math.floor(CurrentColor.R * 255))
                GInput.Text = tostring(math.floor(CurrentColor.G * 255))
                BInput.Text = tostring(math.floor(CurrentColor.B * 255))
                
                ColorDialog.Visible = true
            end)
        end

        -- 新增：下拉列表模块
        function Tab:AddDropdown(DropConfig)
            Tab.ItemCount = Tab.ItemCount + 1
            local Options = DropConfig.Options or {}
            local Current = DropConfig.Default or Options[1] or ""
            local IsDropped = false
            
            local ItemHeight = 30
            local MaxItems = 4
            local VisibleItems = math.min(#Options, MaxItems)
            local ExpandedHeight = 50 + (VisibleItems * ItemHeight) + 10 -- 50是基础高度，加10是底边距

            local Element = Instance.new("Frame")
            Element.LayoutOrder = Tab.ItemCount
            Element.Size = UDim2.new(1, 0, 0, 50)
            Element.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Element.BackgroundTransparency = 0.6
            Element.ClipsDescendants = true
            Element.Parent = Page
            Instance.new("UICorner", Element).CornerRadius = UDim.new(0, 8)

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.55, 0, 0, 50) 
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = DropConfig.Title or "Dropdown"
            Title.TextColor3 = Config.Typography.TextColor
            Title.TextSize = Config.Typography.GlobalTextSize
            Title.Font = Config.Typography.FontType
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Element

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(0.4, 0, 0, 34) 
            DropBtn.Position = UDim2.new(1, -10, 0, 8)
            DropBtn.AnchorPoint = Vector2.new(1, 0)
            DropBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            DropBtn.Text = Current
            DropBtn.TextColor3 = Config.Typography.TextColor
            DropBtn.TextSize = 13
            DropBtn.Font = Config.Typography.FontType
            DropBtn.Parent = Element
            Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)

            local ScrollFrame = Instance.new("ScrollingFrame")
            ScrollFrame.Size = UDim2.new(0.4, 0, 1, -60)
            ScrollFrame.Position = UDim2.new(1, -10, 0, 50)
            ScrollFrame.AnchorPoint = Vector2.new(1, 0)
            ScrollFrame.BackgroundTransparency = 1
            ScrollFrame.ScrollBarThickness = 2
            ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #Options * ItemHeight)
            ScrollFrame.Parent = Element

            local ScrollLayout = Instance.new("UIListLayout")
            ScrollLayout.Padding = UDim.new(0, 0)
            ScrollLayout.Parent = ScrollFrame

            for _, opt in pairs(Options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, ItemHeight)
                OptBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                OptBtn.BackgroundTransparency = 0.5
                OptBtn.Text = opt
                OptBtn.TextColor3 = Config.Typography.TextColor
                OptBtn.TextSize = 12
                OptBtn.Font = Config.Typography.FontType
                OptBtn.Parent = ScrollFrame

                OptBtn.MouseButton1Click:Connect(function()
                    Current = opt
                    DropBtn.Text = Current
                    if DropConfig.Callback then DropConfig.Callback(Current) end
                    
                    IsDropped = false
                    TweenService:Create(Element, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 50)}):Play()
                end)
            end

            DropBtn.MouseButton1Click:Connect(function()
                IsDropped = not IsDropped
                local TargetHeight = IsDropped and ExpandedHeight or 50
                TweenService:Create(Element, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, TargetHeight)}):Play()
            end)
        end

        -- 新增：输入框模块
        function Tab:AddTextbox(BoxConfig)
            Tab.ItemCount = Tab.ItemCount + 1
            local Element = Instance.new("Frame")
            Element.LayoutOrder = Tab.ItemCount
            Element.Size = UDim2.new(1, 0, 0, 50) 
            Element.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Element.BackgroundTransparency = 0.6
            Element.Parent = Page
            Instance.new("UICorner", Element).CornerRadius = UDim.new(0, 8)

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.55, 0, 1, 0)
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = BoxConfig.Title or "Textbox"
            Title.TextColor3 = Config.Typography.TextColor
            Title.TextSize = Config.Typography.GlobalTextSize
            Title.Font = Config.Typography.FontType
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Element

            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(0.4, 0, 0, 34) 
            InputBox.Position = UDim2.new(1, -10, 0.5, 0)
            InputBox.AnchorPoint = Vector2.new(1, 0.5)
            InputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            InputBox.Text = BoxConfig.Default or ""
            InputBox.PlaceholderText = BoxConfig.Placeholder or "点击输入..."
            InputBox.TextColor3 = Config.Typography.TextColor
            InputBox.TextSize = 13
            InputBox.Font = Config.Typography.FontType
            InputBox.ClearTextOnFocus = false
            InputBox.Parent = Element
            Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)

            InputBox.FocusLost:Connect(function(enterPressed)
                if BoxConfig.Callback then
                    BoxConfig.Callback(InputBox.Text, enterPressed)
                end
            end)
        end

        return Tab
    end

    return Window
end

return Library
