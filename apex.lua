--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                        APEX UI v1.0                              ║
    ║              Single-File Modern Menu Library for FiveM           ║
    ║                     Compatible with Susano                       ║
    ╚══════════════════════════════════════════════════════════════════╝
    
    Features:
    - Modern glassmorphism design with glow effects
    - Smooth open/close/slide animations
    - Buttons, Toggles, Sliders, Inputs, Lists, Separators
    - Submenu support with breadcrumb navigation
    - Mouse & keyboard navigation
    - Configurable themes
    - All in ONE Lua file
]]

--╔══════════════════════════════════════════════════════════════════╗
--║                        CONFIGURATION                             ║
--╚══════════════════════════════════════════════════════════════════╝

ApexUI = {}
ApexUI.Config = {
    -- Appearance
    Theme = {
        Background = {r = 20, g = 20, b = 25, a = 250},      -- Main background
        Header = {r = 30, g = 30, b = 35, a = 255},           -- Header bar
        Accent = {r = 59, g = 130, b = 246, a = 255},         -- Blue accent
        AccentGlow = {r = 59, g = 130, b = 246, a = 100},    -- Glow effect
        Text = {r = 255, g = 255, b = 255, a = 255},         -- Primary text
        TextDim = {r = 180, g = 180, b = 180, a = 255},      -- Secondary text
        Hover = {r = 40, g = 45, b = 55, a = 255},           -- Hover state
        Selected = {r = 59, g = 130, b = 246, a = 80},       -- Selection bg
        Border = {r = 60, g = 60, b = 70, a = 150},          -- Border color
        Success = {r = 34, g = 197, b = 94, a = 255},        -- Green
        Danger = {r = 239, g = 68, b = 68, a = 255},         -- Red
        Warning = {r = 251, g = 191, b = 36, a = 255}        -- Yellow
    },
    
    -- Dimensions
    Width = 0.22,                    -- Menu width (0-1 screen ratio)
    HeaderHeight = 0.045,            -- Header height
    ItemHeight = 0.035,              -- Item height
    MaxVisibleItems = 10,            -- Items before scrolling
    
    -- Position
    X = 0.15,                        -- X position
    Y = 0.15,                        -- Y position
    
    -- Animation
    AnimationSpeed = 0.15,           -- 0-1, higher = faster
    EnableGlow = true,               -- Glow effects
    EnableSounds = false,            -- Audio feedback (requires interact-sound)
    
    -- Fonts
    TitleFont = 4,                   -- Header font
    ItemFont = 4,                    -- Item font
    DescFont = 4                     -- Description font
}

--╔══════════════════════════════════════════════════════════════════╗
--║                     INTERNAL STATE                               ║
--╚══════════════════════════════════════════════════════════════════╝

ApexUI.State = {
    CurrentMenu = nil,
    MenuStack = {},                  -- For submenu navigation
    CurrentIndex = 1,
    ScrollOffset = 0,
    IsVisible = false,
    AnimationProgress = 0,           -- 0-1 for open animation
    TargetAnimation = 0,
    
    -- Input state
    HoverIndex = 0,
    MouseX = 0,
    MouseY = 0,
    
    -- Animation timers
    LastTime = 0,
    DeltaTime = 0
}

-- Item type definitions
ApexUI.ItemTypes = {
    BUTTON = 1,
    TOGGLE = 2,
    SLIDER = 3,
    INPUT = 4,
    LIST = 5,
    SEPARATOR = 6,
    SUBMENU = 7,
    TEXT = 8
}

--╔══════════════════════════════════════════════════════════════════╗
--║                     UTILITY FUNCTIONS                            ║
--╚══════════════════════════════════════════════════════════════════╝

-- Convert RGB to table format
function ApexUI.RGB(r, g, b, a)
    return {r = r, g = g, b = b, a = a or 255}
end

-- Linear interpolation for animations
function ApexUI.Lerp(startVal, endVal, t)
    return startVal + (endVal - startVal) * t
end

-- Smoothstep easing
function ApexUI.SmoothStep(t)
    t = math.max(0, math.min(1, t))
    return t * t * (3 - 2 * t)
end

-- Draw rectangle with optional rounded corners (simulated)
function ApexUI.DrawRect(x, y, w, h, color)
    DrawRect(x + w/2, y + h/2, w, h, color.r, color.g, color.b, color.a)
end

-- Draw text with alignment
function ApexUI.DrawText(text, x, y, font, scale, color, alignRight, dropShadow)
    SetTextFont(font or 4)
    SetTextScale(0.0, scale or 0.35)
    SetTextColour(color.r, color.g, color.b, color.a)
    
    if dropShadow then
        SetTextDropShadow(1, 0, 0, 0, 100)
    end
    
    SetTextCentre(alignRight == nil and false or not alignRight)
    SetTextRightJustify(alignRight == true)
    
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(tostring(text))
    EndTextCommandDisplayText(x, y)
end

-- Draw glowing border effect
function ApexUI.DrawGlowBorder(x, y, w, h, color, intensity)
    if not ApexUI.Config.Theme.EnableGlow then return end
    
    for i = 1, 3 do
        local alpha = math.floor(color.a * intensity * (0.3 / i))
        local offset = i * 0.002
        DrawRect(x + w/2, y + h/2, w + offset*2, h + offset*2, 
            color.r, color.g, color.b, alpha)
    end
end

-- Format number with commas
function ApexUI.FormatNumber(num)
    return tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- Clamp value
function ApexUI.Clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

-- Check if point is in rectangle
function ApexUI.IsMouseOver(x, y, w, h)
    local mx, my = ApexUI.State.MouseX, ApexUI.State.MouseY
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

--╔══════════════════════════════════════════════════════════════════╗
--║                     MENU CREATION                                ║
--╚══════════════════════════════════════════════════════════════════╝

ApexUI.Menus = {}

-- Create a new menu
function ApexUI.CreateMenu(title, subtitle, banner)
    local menu = {
        Title = title or "Menu",
        Subtitle = subtitle or "",
        Banner = banner,             -- Texture dict/name for custom banner
        
        Items = {},
        Parent = nil,                -- Parent menu for submenus
        
        -- Style overrides
        X = ApexUI.Config.X,
        Y = ApexUI.Config.Y,
        Width = ApexUI.Config.Width,
        
        -- State
        CurrentIndex = 1,
        ScrollOffset = 0,
        
        -- Callbacks
        OnOpen = nil,
        OnClose = nil,
        OnIndexChange = nil
    }
    
    table.insert(ApexUI.Menus, menu)
    return menu
end

-- Create a submenu (linked to parent)
function ApexUI.CreateSubmenu(parent, title, subtitle)
    local submenu = ApexUI.CreateMenu(title, subtitle)
    submenu.Parent = parent
    return submenu
end

--╔══════════════════════════════════════════════════════════════════╗
--║                     MENU ITEMS                                   ║
--╚══════════════════════════════════════════════════════════════════╝

-- Add button
function ApexUI.Button(menu, label, description, callback)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.BUTTON,
        Label = label,
        Description = description,
        Callback = callback,
        Disabled = false
    })
    return #menu.Items
end

-- Add toggle
function ApexUI.Toggle(menu, label, description, checked, callback)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.TOGGLE,
        Label = label,
        Description = description,
        Checked = checked or false,
        Callback = callback,
        Disabled = false
    })
    return #menu.Items
end

-- Add slider
function ApexUI.Slider(menu, label, description, value, min, max, step, callback)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.SLIDER,
        Label = label,
        Description = description,
        Value = value or min,
        Min = min,
        Max = max,
        Step = step or 1,
        Callback = callback,
        Disabled = false,
        Dragging = false
    })
    return #menu.Items
end

-- Add text input
function ApexUI.Input(menu, label, description, defaultText, maxLength, callback)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.INPUT,
        Label = label,
        Description = description,
        Text = defaultText or "",
        DefaultText = defaultText or "",
        MaxLength = maxLength or 50,
        Callback = callback,
        Disabled = false,
        Active = false,
        CursorPos = 0
    })
    return #menu.Items
end

-- Add list selector
function ApexUI.List(menu, label, description, items, selectedIndex, callback)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.LIST,
        Label = label,
        Description = description,
        Items = items or {},
        SelectedIndex = selectedIndex or 1,
        Callback = callback,
        Disabled = false
    })
    return #menu.Items
end

-- Add separator/header
function ApexUI.Separator(menu, label)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.SEPARATOR,
        Label = label or "",
        Disabled = true
    })
    return #menu.Items
end

-- Add text label (non-interactive)
function ApexUI.Text(menu, label, description)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.TEXT,
        Label = label,
        Description = description,
        Disabled = true
    })
    return #menu.Items
end

-- Add submenu link
function ApexUI.SubmenuButton(menu, label, description, submenu, callback)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.SUBMENU,
        Label = label,
        Description = description,
        Submenu = submenu,
        Callback = callback,
        Disabled = false
    })
    return #menu.Items
end

--╔══════════════════════════════════════════════════════════════════╗
--║                     RENDERING                                    ║
--╚══════════════════════════════════════════════════════════════════╝

-- Draw the menu header
function ApexUI.DrawHeader(menu, x, y, w, h)
    local theme = ApexUI.Config.Theme
    
    -- Background with gradient effect
    ApexUI.DrawRect(x, y, w, h, theme.Header)
    
    -- Accent line at bottom
    ApexUI.DrawRect(x, y + h - 0.002, w, 0.002, theme.Accent)
    
    -- Glow effect
    if ApexUI.Config.EnableGlow then
        ApexUI.DrawGlowBorder(x, y, w, h, theme.Accent, 0.3)
    end
    
    -- Title
    ApexUI.DrawText(menu.Title, x + 0.01, y + 0.005, 
        ApexUI.Config.TitleFont, 0.45, theme.Text, false, true)
    
    -- Subtitle if exists
    if menu.Subtitle and menu.Subtitle ~= "" then
        ApexUI.DrawText(menu.Subtitle, x + w - 0.01, y + 0.01, 
            ApexUI.Config.ItemFont, 0.3, theme.TextDim, true)
    end
end

-- Draw a button item
function ApexUI.DrawButton(item, x, y, w, h, selected, hovered)
    local theme = ApexUI.Config.Theme
    
    -- Background
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        -- Selection indicator
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    elseif hovered then
        ApexUI.DrawRect(x, y, w, h, theme.Hover)
    end
    
    -- Label
    local textColor = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, textColor)
    
    -- Arrow indicator
    if selected then
        ApexUI.DrawText(">", x + w - 0.015, y + 0.003, 
            ApexUI.Config.ItemFont, 0.35, theme.Accent, true)
    end
end

-- Draw toggle
function ApexUI.DrawToggle(item, x, y, w, h, selected, hovered)
    local theme = ApexUI.Config.Theme
    
    -- Background
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    elseif hovered then
        ApexUI.DrawRect(x, y, w, h, theme.Hover)
    end
    
    -- Label
    local textColor = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, textColor)
    
    -- Toggle switch
    local toggleX = x + w - 0.035
    local toggleY = y + 0.007
    local toggleW = 0.025
    local toggleH = 0.02
    
    -- Toggle background
    local bgColor = item.Checked and theme.Accent or theme.Border
    ApexUI.DrawRect(toggleX, toggleY, toggleW, toggleH, bgColor)
    
    -- Toggle knob (animated position)
    local knobX = item.Checked and (toggleX + toggleW - 0.012) or (toggleX + 0.002)
    ApexUI.DrawRect(knobX, toggleY + 0.002, 0.01, toggleH - 0.004, theme.Text)
end

-- Draw slider
function ApexUI.DrawSlider(item, x, y, w, h, selected, hovered)
    local theme = ApexUI.Config.Theme
    
    -- Background
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    elseif hovered then
        ApexUI.DrawRect(x, y, w, h, theme.Hover)
    end
    
    -- Label and value
    local textColor = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, textColor)
    
    local valueText = tostring(math.floor(item.Value * 100) / 100)
    ApexUI.DrawText(valueText, x + w - 0.01, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, theme.Accent, true)
    
    -- Slider bar
    local barY = y + h - 0.008
    local barW = w - 0.02
    local progress = (item.Value - item.Min) / (item.Max - item.Min)
    
    -- Background bar
    ApexUI.DrawRect(x + 0.01, barY, barW, 0.005, theme.Border)
    -- Progress
    ApexUI.DrawRect(x + 0.01, barY, barW * progress, 0.005, theme.Accent)
end

-- Draw input
function ApexUI.DrawInput(item, x, y, w, h, selected, hovered)
    local theme = ApexUI.Config.Theme
    
    -- Background
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    elseif hovered then
        ApexUI.DrawRect(x, y, w, h, theme.Hover)
    end
    
    -- Label
    local textColor = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, textColor)
    
    -- Input box
    local inputX = x + w - 0.11
    local inputW = 0.10
    local inputColor = item.Active and theme.Accent or theme.Border
    ApexUI.DrawRect(inputX, y + 0.005, inputW, h - 0.01, theme.Header)
    ApexUI.DrawRect(inputX, y + h - 0.006, inputW, 0.002, inputColor)
    
    -- Text (or placeholder)
    local displayText = item.Text ~= "" and item.Text or item.DefaultText
    local txtColor = item.Text ~= "" and theme.Text or theme.TextDim
    ApexUI.DrawText(displayText, inputX + 0.005, y + 0.005, 
        ApexUI.Config.ItemFont, 0.32, txtColor)
    
    -- Cursor when active
    if item.Active and (GetGameTimer() % 1000 < 500) then
        ApexUI.DrawText("_", inputX + 0.005 + (string.len(displayText) * 0.005), 
            y + 0.003, ApexUI.Config.ItemFont, 0.35, theme.Accent)
    end
end

-- Draw list
function ApexUI.DrawList(item, x, y, w, h, selected, hovered)
    local theme = ApexUI.Config.Theme
    
    -- Background
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    elseif hovered then
        ApexUI.DrawRect(x, y, w, h, theme.Hover)
    end
    
    -- Label
    local textColor = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, textColor)
    
    -- Current value with arrows
    local currentItem = item.Items[item.SelectedIndex] or "None"
    local listX = x + w - 0.08
    
    -- Left arrow
    ApexUI.DrawText("<", listX, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, theme.Accent)
    -- Value
    ApexUI.DrawText(currentItem, listX + 0.015, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, theme.Text, false)
    -- Right arrow
    ApexUI.DrawText(">", listX + 0.065, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, theme.Accent)
end

-- Draw separator
function ApexUI.DrawSeparator(item, x, y, w, h)
    local theme = ApexUI.Config.Theme
    
    if item.Label and item.Label ~= "" then
        -- Text separator
        local lineW = (w - 0.02 - GetTextWidth(item.Label, 0.3)) / 2
        ApexUI.DrawRect(x + 0.01, y + h/2, lineW, 0.001, theme.Border)
        ApexUI.DrawText(item.Label, x + w/2, y + 0.008, 
            ApexUI.Config.ItemFont, 0.3, theme.TextDim, false)
        ApexUI.DrawRect(x + w - 0.01 - lineW, y + h/2, lineW, 0.001, theme.Border)
    else
        -- Simple line
        ApexUI.DrawRect(x + 0.01, y + h/2, w - 0.02, 0.001, theme.Border)
    end
end

-- Draw submenu button
function ApexUI.DrawSubmenuButton(item, x, y, w, h, selected, hovered)
    local theme = ApexUI.Config.Theme
    
    -- Background
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    elseif hovered then
        ApexUI.DrawRect(x, y, w, h, theme.Hover)
    end
    
    -- Label
    local textColor = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, textColor)
    
    -- Arrow
    ApexUI.DrawText(">>", x + w - 0.02, y + 0.003, 
        ApexUI.Config.ItemFont, 0.35, theme.Accent, true)
end

-- Draw text label
function ApexUI.DrawTextItem(item, x, y, w, h)
    local theme = ApexUI.Config.Theme
    ApexUI.DrawText(item.Label, x + w/2, y + 0.008, 
        ApexUI.Config.ItemFont, 0.32, theme.TextDim, false)
end

-- Get text width helper
function GetTextWidth(text, scale)
    BeginTextCommandGetWidth("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetTextFont(4)
    SetTextScale(0.0, scale)
    return EndTextCommandGetWidth(true)
end

-- Draw description panel
function ApexUI.DrawDescription(menu, item)
    if not item or not item.Description or item.Description == "" then return end
    
    local theme = ApexUI.Config.Theme
    local x = menu.X + menu.Width + 0.005
    local y = menu.Y + ApexUI.Config.HeaderHeight
    local w = 0.18
    
    -- Calculate height based on text
    local lines = math.ceil(string.len(item.Description) / 35)
    local h = 0.03 + (lines * 0.02)
    
    -- Background
    ApexUI.DrawRect(x, y, w, h, theme.Header)
    ApexUI.DrawRect(x, y, w, 0.002, theme.Accent)
    
    -- Text (wrapped)
    ApexUI.DrawText(item.Description, x + 0.008, y + 0.008, 
        ApexUI.Config.DescFont, 0.28, theme.Text)
end

-- Draw scrollbar
function ApexUI.DrawScrollbar(menu, totalItems, visibleItems)
    if totalItems <= visibleItems then return end
    
    local theme = ApexUI.Config.Theme
    local x = menu.X + menu.Width - 0.008
    local y = menu.Y + ApexUI.Config.HeaderHeight
    local h = visibleItems * ApexUI.Config.ItemHeight
    
    -- Background
    ApexUI.DrawRect(x, y, 0.004, h, theme.Border)
    
    -- Thumb
    local thumbH = (visibleItems / totalItems) * h
    local maxScroll = totalItems - visibleItems
    local thumbY = y + (menu.ScrollOffset / maxScroll) * (h - thumbH)
    
    ApexUI.DrawRect(x, thumbY, 0.004, thumbH, theme.Accent)
end

-- Draw counter (Item X/Y)
function ApexUI.DrawCounter(menu, current, total)
    local theme = ApexUI.Config.Theme
    local text = string.format("%d / %d", current, total)
    local x = menu.X + menu.Width - 0.01
    local y = menu.Y + ApexUI.Config.HeaderHeight - 0.015
    
    ApexUI.DrawText(text, x, y, ApexUI.Config.ItemFont, 0.28, theme.TextDim, true)
end

--╔══════════════════════════════════════════════════════════════════╗
--║                     MAIN RENDER LOOP                             ║
--╚══════════════════════════════════════════════════════════════════╝

function ApexUI.Render()
    local menu = ApexUI.State.CurrentMenu
    if not menu then return end
    
    local state = ApexUI.State
    local config = ApexUI.Config
    
    -- Update animation
    local target = state.IsVisible and 1 or 0
    state.AnimationProgress = ApexUI.Lerp(state.AnimationProgress, target, config.AnimationSpeed)
    
    if state.AnimationProgress < 0.01 and not state.IsVisible then
        return -- Fully closed
    end
    
    local anim = ApexUI.SmoothStep(state.AnimationProgress)
    
    -- Calculate animated position (slide in from left)
    local baseX = menu.X - (0.05 * (1 - anim))
    local baseY = menu.Y
    
    -- Get mouse position
    state.MouseX = GetControlNormal(0, 239) -- Mouse X
    state.MouseY = GetControlNormal(0, 240) -- Mouse Y
    
    -- Draw main container with glow
    local totalHeight = config.HeaderHeight + (math.min(#menu.Items, config.MaxVisibleItems) * config.ItemHeight)
    
    -- Background
    ApexUI.DrawRect(baseX, baseY, menu.Width, totalHeight, config.Theme.Background)
    
    -- Border glow
    if config.EnableGlow then
        ApexUI.DrawGlowBorder(baseX, baseY, menu.Width, totalHeight, config.Theme.Accent, 0.2)
    end
    
    -- Header
    ApexUI.DrawHeader(menu, baseX, baseY, menu.Width, config.HeaderHeight)
    
    -- Items
    local itemY = baseY + config.HeaderHeight
    local visibleItems = math.min(#menu.Items, config.MaxVisibleItems)
    
    -- Update scroll
    if menu.CurrentIndex > menu.ScrollOffset + visibleItems then
        menu.ScrollOffset = menu.CurrentIndex - visibleItems
    elseif menu.CurrentIndex <= menu.ScrollOffset then
        menu.ScrollOffset = menu.CurrentIndex - 1
    end
    
    -- Draw visible items
    for i = 1, visibleItems do
        local itemIndex = i + menu.ScrollOffset
        local item = menu.Items[itemIndex]
        if not item then break end
        
        local itemH = config.ItemHeight
        local selected = (itemIndex == menu.CurrentIndex)
        local hovered = ApexUI.IsMouseOver(baseX, itemY, menu.Width, itemH)
        
        -- Store hover for input handling
        if hovered then
            state.HoverIndex = itemIndex
        end
        
        -- Draw based on type
        if item.Type == ApexUI.ItemTypes.BUTTON then
            ApexUI.DrawButton(item, baseX, itemY, menu.Width, itemH, selected, hovered)
        elseif item.Type == ApexUI.ItemTypes.TOGGLE then
            ApexUI.DrawToggle(item, baseX, itemY, menu.Width, itemH, selected, hovered)
        elseif item.Type == ApexUI.ItemTypes.SLIDER then
            ApexUI.DrawSlider(item, baseX, itemY, menu.Width, itemH, selected, hovered)
        elseif item.Type == ApexUI.ItemTypes.INPUT then
            ApexUI.DrawInput(item, baseX, itemY, menu.Width, itemH, selected, hovered)
        elseif item.Type == ApexUI.ItemTypes.LIST then
            ApexUI.DrawList(item, baseX, itemY, menu.Width, itemH, selected, hovered)
        elseif item.Type == ApexUI.ItemTypes.SEPARATOR then
            ApexUI.DrawSeparator(item, baseX, itemY, menu.Width, itemH)
        elseif item.Type == ApexUI.ItemTypes.SUBMENU then
            ApexUI.DrawSubmenuButton(item, baseX, itemY, menu.Width, itemH, selected, hovered)
        elseif item.Type == ApexUI.ItemTypes.TEXT then
            ApexUI.DrawTextItem(item, baseX, itemY, menu.Width, itemH)
        end
        
        itemY = itemY + itemH
    end
    
    -- Scrollbar
    ApexUI.DrawScrollbar(menu, #menu.Items, visibleItems)
    
    -- Counter
    ApexUI.DrawCounter(menu, menu.CurrentIndex, #menu.Items)
    
    -- Description
    local currentItem = menu.Items[menu.CurrentIndex]
    if currentItem then
        ApexUI.DrawDescription(menu, currentItem)
    end
    
    -- Draw breadcrumb if in submenu
    if menu.Parent then
        local breadcrumb = "< " .. (menu.Parent.Title or "Back")
        ApexUI.DrawText(breadcrumb, baseX + 0.01, baseY - 0.02, 
            config.ItemFont, 0.3, config.Theme.TextDim)
    end
end

--╔══════════════════════════════════════════════════════════════════╗
--║                     INPUT HANDLING                               ║
--╚══════════════════════════════════════════════════════════════════╝

function ApexUI.HandleInput()
    local menu = ApexUI.State.CurrentMenu
    if not menu or not ApexUI.State.IsVisible then return end
    
    local state = ApexUI.State
    
    -- Disable controls while menu is open
    DisableControlAction(0, 1, true)   -- LookLeftRight
    DisableControlAction(0, 2, true)   -- LookUpDown
    DisableControlAction(0, 142, true) -- MeleeAttackAlternate
    DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
    
    -- Navigation delays
    local delay = 150 -- ms between key repeats
    
    -- Up
    if IsDisabledControlJustPressed(0, 172) or IsControlJustPressed(0, 172) then -- UP
        menu.CurrentIndex = menu.CurrentIndex - 1
        if menu.CurrentIndex < 1 then menu.CurrentIndex = #menu.Items end
        -- Skip separators
        while menu.Items[menu.CurrentIndex] and menu.Items[menu.CurrentIndex].Type == ApexUI.ItemTypes.SEPARATOR do
            menu.CurrentIndex = menu.CurrentIndex - 1
            if menu.CurrentIndex < 1 then menu.CurrentIndex = #menu.Items end
        end
        if menu.OnIndexChange then menu.OnIndexChange(menu.CurrentIndex) end
        Citizen.Wait(delay)
    end
    
    -- Down
    if IsDisabledControlJustPressed(0, 173) or IsControlJustPressed(0, 173) then -- DOWN
        menu.CurrentIndex = menu.CurrentIndex + 1
        if menu.CurrentIndex > #menu.Items then menu.CurrentIndex = 1 end
        -- Skip separators
        while menu.Items[menu.CurrentIndex] and menu.Items[menu.CurrentIndex].Type == ApexUI.ItemTypes.SEPARATOR do
            menu.CurrentIndex = menu.CurrentIndex + 1
            if menu.CurrentIndex > #menu.Items then menu.CurrentIndex = 1 end
        end
        if menu.OnIndexChange then menu.OnIndexChange(menu.CurrentIndex) end
        Citizen.Wait(delay)
    end
    
    -- Enter/Select
    if IsDisabledControlJustPressed(0, 176) or IsControlJustPressed(0, 176) then -- ENTER
        local item = menu.Items[menu.CurrentIndex]
        if item and not item.Disabled then
            if item.Type == ApexUI.ItemTypes.BUTTON then
                if item.Callback then item.Callback() end
                
            elseif item.Type == ApexUI.ItemTypes.TOGGLE then
                item.Checked = not item.Checked
                if item.Callback then item.Callback(item.Checked) end
                
            elseif item.Type == ApexUI.ItemTypes.SUBMENU then
                if item.Callback then item.Callback() end
                ApexUI.OpenMenu(item.Submenu)
                
            elseif item.Type == ApexUI.ItemTypes.INPUT then
                -- Toggle active state
                if item.Active then
                    -- Deactivate and callback
                    item.Active = false
                    if item.Callback then item.Callback(item.Text) end
                else
                    -- Activate for input
                    item.Active = true
                    -- Use GTA input method
                    AddTextEntry("APEX_INPUT", item.Label)
                    DisplayOnscreenKeyboard(1, "APEX_INPUT", "", item.Text, "", "", "", item.MaxLength)
                end
            end
        end
        Citizen.Wait(100)
    end
    
    -- Back/Close
    if IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 177) then -- BACKSPACE
        if menu.Parent then
            ApexUI.OpenMenu(menu.Parent)
        else
            ApexUI.CloseMenu()
        end
        Citizen.Wait(100)
    end
    
    -- Left/Right for sliders and lists
    if IsDisabledControlJustPressed(0, 174) or IsControlJustPressed(0, 174) then -- LEFT
        local item = menu.Items[menu.CurrentIndex]
        if item and not item.Disabled then
            if item.Type == ApexUI.ItemTypes.SLIDER then
                item.Value = math.max(item.Min, item.Value - item.Step)
                if item.Callback then item.Callback(item.Value) end
            elseif item.Type == ApexUI.ItemTypes.LIST then
                item.SelectedIndex = item.SelectedIndex - 1
                if item.SelectedIndex < 1 then item.SelectedIndex = #item.Items end
                if item.Callback then item.Callback(item.Items[item.SelectedIndex], item.SelectedIndex) end
            end
        end
        Citizen.Wait(100)
    end
    
    if IsDisabledControlJustPressed(0, 175) or IsControlJustPressed(0, 175) then -- RIGHT
        local item = menu.Items[menu.CurrentIndex]
        if item and not item.Disabled then
            if item.Type == ApexUI.ItemTypes.SLIDER then
                item.Value = math.min(item.Max, item.Value + item.Step)
                if item.Callback then item.Callback(item.Value) end
            elseif item.Type == ApexUI.ItemTypes.LIST then
                item.SelectedIndex = item.SelectedIndex + 1
                if item.SelectedIndex > #item.Items then item.SelectedIndex = 1 end
                if item.Callback then item.Callback(item.Items[item.SelectedIndex], item.SelectedIndex) end
            end
        end
        Citizen.Wait(100)
    end
    
    -- Handle keyboard input for active input field
    local item = menu.Items[menu.CurrentIndex]
    if item and item.Type == ApexUI.ItemTypes.INPUT and item.Active then
        UpdateOnscreenKeyboard()
        if UpdateOnscreenKeyboard() == 1 then
            item.Text = GetOnscreenKeyboardResult()
            item.Active = false
            if item.Callback then item.Callback(item.Text) end
        elseif UpdateOnscreenKeyboard() == 2 then
            item.Active = false -- Cancelled
        end
    end
    
    -- Mouse click handling
    if IsDisabledControlJustPressed(0, 237) then -- MOUSE_LEFT
        local itemIndex = state.HoverIndex
        if itemIndex and itemIndex > 0 and itemIndex <= #menu.Items then
            menu.CurrentIndex = itemIndex
            local item = menu.Items[itemIndex]
            if item and not item.Disabled then
                -- Simulate enter
                if item.Type == ApexUI.ItemTypes.BUTTON then
                    if item.Callback then item.Callback() end
                elseif item.Type == ApexUI.ItemTypes.TOGGLE then
                    item.Checked = not item.Checked
                    if item.Callback then item.Callback(item.Checked) end
                elseif item.Type == ApexUI.ItemTypes.SUBMENU then
                    if item.Callback then item.Callback() end
                    ApexUI.OpenMenu(item.Submenu)
                end
            end
        end
    end
end

--╔══════════════════════════════════════════════════════════════════╗
--║                     PUBLIC API                                   ║
--╚══════════════════════════════════════════════════════════════════╝

-- Open a menu
function ApexUI.OpenMenu(menu)
    if ApexUI.State.CurrentMenu and ApexUI.State.CurrentMenu ~= menu then
        table.insert(ApexUI.State.MenuStack, ApexUI.State.CurrentMenu)
    end
    
    ApexUI.State.CurrentMenu = menu
    ApexUI.State.IsVisible = true
    ApexUI.State.AnimationProgress = 0
    
    if menu.OnOpen then menu.OnOpen() end
end

-- Close current menu
function ApexUI.CloseMenu()
    ApexUI.State.IsVisible = false
    ApexUI.State.MenuStack = {}
    if ApexUI.State.CurrentMenu and ApexUI.State.CurrentMenu.OnClose then
        ApexUI.State.CurrentMenu.OnClose()
    end
    -- Actually clear after animation
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        if not ApexUI.State.IsVisible then
            ApexUI.State.CurrentMenu = nil
        end
    end)
end

-- Toggle menu visibility
function ApexUI.ToggleMenu(menu)
    if ApexUI.State.IsVisible and ApexUI.State.CurrentMenu == menu then
        ApexUI.CloseMenu()
    else
        ApexUI.OpenMenu(menu)
    end
end

-- Go back to parent menu
function ApexUI.GoBack()
    local menu = ApexUI.State.CurrentMenu
    if menu and menu.Parent then
        ApexUI.OpenMenu(menu.Parent)
    else
        ApexUI.CloseMenu()
    end
end

-- Check if any menu is open
function ApexUI.IsMenuOpen()
    return ApexUI.State.IsVisible
end

-- Get current menu
function ApexUI.GetCurrentMenu()
    return ApexUI.State.CurrentMenu
end

-- Set theme color
function ApexUI.SetThemeColor(key, r, g, b, a)
    if ApexUI.Config.Theme[key] then
        ApexUI.Config.Theme[key] = {r = r, g = g, b = b, a = a or 255}
    end
end

-- Main thread - REQUIRED
function ApexUI.Start()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if ApexUI.State.IsVisible or ApexUI.State.AnimationProgress > 0.01 then
                ApexUI.Render()
                ApexUI.HandleInput()
            end
        end
    end)
end

--╔══════════════════════════════════════════════════════════════════╗
--║                     CONVENIENCE FUNCTIONS                        ║
--╚══════════════════════════════════════════════════════════════════╝

-- Quick menu builder
function ApexUI.CreateListMenu(title, items, callback)
    local menu = ApexUI.CreateMenu(title)
    for _, item in ipairs(items) do
        if type(item) == "table" then
            ApexUI.Button(menu, item.label, item.desc, function() 
                if callback then callback(item.value or item.label) end
            end)
        else
            ApexUI.Button(menu, tostring(item), nil, function()
                if callback then callback(item) end
            end)
        end
    end
    return menu
end

-- Create confirmation dialog
function ApexUI.CreateConfirmDialog(title, message, onConfirm, onCancel)
    local menu = ApexUI.CreateMenu(title)
    ApexUI.Text(menu, message)
    ApexUI.Separator(menu)
    
    ApexUI.Button(menu, "Yes", nil, function()
        ApexUI.CloseMenu()
        if onConfirm then onConfirm() end
    end)
    
    ApexUI.Button(menu, "No", nil, function()
        ApexUI.CloseMenu()
        if onCancel then onCancel() end
    end)
    
    return menu
end

-- Add spacer (invisible item)
function ApexUI.Spacer(menu)
    table.insert(menu.Items, {
        Type = ApexUI.ItemTypes.TEXT,
        Label = "",
        Disabled = true
    })
end

-- Set item disabled state
function ApexUI.SetItemDisabled(menu, index, disabled)
    if menu.Items[index] then
        menu.Items[index].Disabled = disabled
    end
end

-- Remove all items from menu
function ApexUI.ClearMenu(menu)
    menu.Items = {}
    menu.CurrentIndex = 1
    menu.ScrollOffset = 0
end

-- Update item label dynamically
function ApexUI.SetItemLabel(menu, index, newLabel)
    if menu.Items[index] then
        menu.Items[index].Label = newLabel
    end
end

-- Get item value
function ApexUI.GetItemValue(menu, index)
    local item = menu.Items[index]
    if not item then return nil end
    
    if item.Type == ApexUI.ItemTypes.TOGGLE then
        return item.Checked
    elseif item.Type == ApexUI.ItemTypes.SLIDER then
        return item.Value
    elseif item.Type == ApexUI.ItemTypes.INPUT then
        return item.Text
    elseif item.Type == ApexUI.ItemTypes.LIST then
        return item.Items[item.SelectedIndex], item.SelectedIndex
    end
    return nil
end

-- Set item value
function ApexUI.SetItemValue(menu, index, value)
    local item = menu.Items[index]
    if not item then return end
    
    if item.Type == ApexUI.ItemTypes.TOGGLE then
        item.Checked = value
    elseif item.Type == ApexUI.ItemTypes.SLIDER then
        item.Value = ApexUI.Clamp(value, item.Min, item.Max)
    elseif item.Type == ApexUI.ItemTypes.INPUT then
        item.Text = tostring(value):sub(1, item.MaxLength)
    elseif item.Type == ApexUI.ItemTypes.LIST then
        for i, v in ipairs(item.Items) do
            if v == value then
                item.SelectedIndex = i
                break
            end
        end
    end
end

-- Return the library
return ApexUI
