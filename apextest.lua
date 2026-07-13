-- FIXED ApexUI - Single File Menu Library
local ApexUI = {}

-- Configuration
ApexUI.Config = {
    Theme = {
        Background = {r = 20, g = 20, b = 25, a = 250},
        Header = {r = 30, g = 30, b = 35, a = 255},
        Accent = {r = 59, g = 130, b = 246, a = 255},
        Text = {r = 255, g = 255, b = 255, a = 255},
        TextDim = {r = 180, g = 180, b = 180, a = 255},
        Hover = {r = 40, g = 45, b = 55, a = 255},
        Selected = {r = 59, g = 130, b = 246, a = 80},
        Border = {r = 60, g = 60, b = 70, a = 150}
    },
    Width = 0.22,
    HeaderHeight = 0.045,
    ItemHeight = 0.035,
    MaxVisibleItems = 10,
    X = 0.15,
    Y = 0.15,
    AnimationSpeed = 0.15
}

-- State
ApexUI.State = {
    CurrentMenu = nil,
    MenuStack = {},
    CurrentIndex = 1,
    ScrollOffset = 0,
    IsVisible = false,
    AnimationProgress = 0,
    MouseX = 0,
    MouseY = 0
}

-- Item Types
ApexUI.BUTTON = 1
ApexUI.TOGGLE = 2
ApexUI.SLIDER = 3
ApexUI.INPUT = 4
ApexUI.LIST = 5
ApexUI.SEPARATOR = 6
ApexUI.SUBMENU = 7
ApexUI.TEXT = 8

-- Storage
ApexUI.Menus = {}

-- Utility Functions
function ApexUI.Lerp(a, b, t)
    return a + (b - a) * t
end

function ApexUI.SmoothStep(t)
    t = t > 1 and 1 or (t < 0 and 0 or t)
    return t * t * (3 - 2 * t)
end

function ApexUI.DrawRect(x, y, w, h, color)
    DrawRect(x + w/2, y + h/2, w, h, color.r, color.g, color.b, color.a)
end

function ApexUI.DrawText(text, x, y, font, scale, color, alignRight)
    SetTextFont(font or 4)
    SetTextScale(0.0, scale or 0.35)
    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextDropShadow()
    SetTextCentre(alignRight == nil and false or not alignRight)
    SetTextRightJustify(alignRight == true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(tostring(text))
    EndTextCommandDisplayText(x, y)
end

function ApexUI.IsMouseOver(x, y, w, h)
    local mx, my = ApexUI.State.MouseX, ApexUI.State.MouseY
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- Menu Creation
function ApexUI.CreateMenu(title, subtitle)
    return {
        Title = title or "Menu",
        Subtitle = subtitle or "",
        Items = {},
        Parent = nil,
        CurrentIndex = 1,
        ScrollOffset = 0,
        X = ApexUI.Config.X,
        Y = ApexUI.Config.Y,
        Width = ApexUI.Config.Width
    }
end

function ApexUI.CreateSubmenu(parent, title, subtitle)
    local menu = ApexUI.CreateMenu(title, subtitle)
    menu.Parent = parent
    return menu
end

-- Add Items
function ApexUI.Button(menu, label, description, callback)
    table.insert(menu.Items, {
        Type = ApexUI.BUTTON,
        Label = label,
        Description = description,
        Callback = callback,
        Disabled = false
    })
end

function ApexUI.Toggle(menu, label, description, checked, callback)
    table.insert(menu.Items, {
        Type = ApexUI.TOGGLE,
        Label = label,
        Description = description,
        Checked = checked or false,
        Callback = callback,
        Disabled = false
    })
end

function ApexUI.Slider(menu, label, description, value, min, max, step, callback)
    table.insert(menu.Items, {
        Type = ApexUI.SLIDER,
        Label = label,
        Description = description,
        Value = value or min,
        Min = min,
        Max = max,
        Step = step or 1,
        Callback = callback,
        Disabled = false
    })
end

function ApexUI.Input(menu, label, description, defaultText, maxLength, callback)
    table.insert(menu.Items, {
        Type = ApexUI.INPUT,
        Label = label,
        Description = description,
        Text = defaultText or "",
        DefaultText = defaultText or "",
        MaxLength = maxLength or 50,
        Callback = callback,
        Disabled = false,
        Active = false
    })
end

function ApexUI.List(menu, label, description, items, selectedIndex, callback)
    table.insert(menu.Items, {
        Type = ApexUI.LIST,
        Label = label,
        Description = description,
        Items = items or {},
        SelectedIndex = selectedIndex or 1,
        Callback = callback,
        Disabled = false
    })
end

function ApexUI.Separator(menu, label)
    table.insert(menu.Items, {
        Type = ApexUI.SEPARATOR,
        Label = label or "",
        Disabled = true
    })
end

function ApexUI.Text(menu, label)
    table.insert(menu.Items, {
        Type = ApexUI.TEXT,
        Label = label,
        Disabled = true
    })
end

function ApexUI.SubmenuButton(menu, label, description, submenu, callback)
    table.insert(menu.Items, {
        Type = ApexUI.SUBMENU,
        Label = label,
        Description = description,
        Submenu = submenu,
        Callback = callback,
        Disabled = false
    })
end

-- Drawing Functions
function ApexUI.DrawHeader(menu, x, y, w, h)
    local theme = ApexUI.Config.Theme
    ApexUI.DrawRect(x, y, w, h, theme.Header)
    ApexUI.DrawRect(x, y + h - 0.002, w, 0.002, theme.Accent)
    ApexUI.DrawText(menu.Title, x + 0.01, y + 0.008, 4, 0.45, theme.Text)
    if menu.Subtitle ~= "" then
        ApexUI.DrawText(menu.Subtitle, x + w - 0.01, y + 0.012, 4, 0.3, theme.TextDim, true)
    end
end

function ApexUI.DrawButton(item, x, y, w, h, selected)
    local theme = ApexUI.Config.Theme
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    end
    local color = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.005, 4, 0.35, color)
    if selected then
        ApexUI.DrawText(">", x + w - 0.015, y + 0.005, 4, 0.35, theme.Accent, true)
    end
end

function ApexUI.DrawToggle(item, x, y, w, h, selected)
    local theme = ApexUI.Config.Theme
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    end
    local color = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.005, 4, 0.35, color)
    
    local toggleX = x + w - 0.035
    local toggleY = y + 0.008
    local bgColor = item.Checked and theme.Accent or theme.Border
    ApexUI.DrawRect(toggleX, toggleY, 0.025, 0.02, bgColor)
    local knobX = item.Checked and (toggleX + 0.013) or (toggleX + 0.002)
    ApexUI.DrawRect(knobX, toggleY + 0.002, 0.01, 0.016, theme.Text)
end

function ApexUI.DrawSlider(item, x, y, w, h, selected)
    local theme = ApexUI.Config.Theme
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    end
    local color = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.005, 4, 0.35, color)
    local valText = string.format("%.2f", item.Value)
    ApexUI.DrawText(valText, x + w - 0.01, y + 0.005, 4, 0.35, theme.Accent, true)
    
    local progress = (item.Value - item.Min) / (item.Max - item.Min)
    local barY = y + h - 0.008
    ApexUI.DrawRect(x + 0.01, barY, w - 0.02, 0.005, theme.Border)
    ApexUI.DrawRect(x + 0.01, barY, (w - 0.02) * progress, 0.005, theme.Accent)
end

function ApexUI.DrawInput(item, x, y, w, h, selected)
    local theme = ApexUI.Config.Theme
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    end
    local color = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.005, 4, 0.35, color)
    
    local inputX = x + w - 0.11
    local boxColor = item.Active and theme.Accent or theme.Border
    ApexUI.DrawRect(inputX, y + 0.005, 0.10, h - 0.01, theme.Header)
    ApexUI.DrawRect(inputX, y + h - 0.006, 0.10, 0.002, boxColor)
    
    local displayText = item.Text ~= "" and item.Text or item.DefaultText
    local txtColor = item.Text ~= "" and theme.Text or theme.TextDim
    ApexUI.DrawText(displayText, inputX + 0.005, y + 0.006, 4, 0.32, txtColor)
end

function ApexUI.DrawList(item, x, y, w, h, selected)
    local theme = ApexUI.Config.Theme
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    end
    local color = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.005, 4, 0.35, color)
    
    local current = item.Items[item.SelectedIndex] or "None"
    local listX = x + w - 0.08
    ApexUI.DrawText("<", listX, y + 0.005, 4, 0.35, theme.Accent)
    ApexUI.DrawText(current, listX + 0.015, y + 0.005, 4, 0.35, theme.Text)
    ApexUI.DrawText(">", listX + 0.065, y + 0.005, 4, 0.35, theme.Accent)
end

function ApexUI.DrawSeparator(item, x, y, w, h)
    local theme = ApexUI.Config.Theme
    if item.Label and item.Label ~= "" then
        ApexUI.DrawText(item.Label, x + w/2, y + 0.01, 4, 0.3, theme.TextDim)
    else
        ApexUI.DrawRect(x + 0.01, y + h/2, w - 0.02, 0.001, theme.Border)
    end
end

function ApexUI.DrawSubmenuButton(item, x, y, w, h, selected)
    local theme = ApexUI.Config.Theme
    if selected then
        ApexUI.DrawRect(x, y, w, h, theme.Selected)
        ApexUI.DrawRect(x, y, 0.004, h, theme.Accent)
    end
    local color = item.Disabled and theme.TextDim or theme.Text
    ApexUI.DrawText(item.Label, x + 0.01, y + 0.005, 4, 0.35, color)
    ApexUI.DrawText(">>", x + w - 0.02, y + 0.005, 4, 0.35, theme.Accent, true)
end

function ApexUI.DrawTextItem(item, x, y, w, h)
    local theme = ApexUI.Config.Theme
    ApexUI.DrawText(item.Label, x + w/2, y + 0.01, 4, 0.32, theme.TextDim)
end

-- Main Render
function ApexUI.Render()
    local menu = ApexUI.State.CurrentMenu
    if not menu then return end
    
    local state = ApexUI.State
    local config = ApexUI.Config
    
    -- Animation
    local target = state.IsVisible and 1 or 0
    state.AnimationProgress = ApexUI.Lerp(state.AnimationProgress, target, config.AnimationSpeed)
    
    if state.AnimationProgress < 0.01 and not state.IsVisible then
        return
    end
    
    local anim = ApexUI.SmoothStep(state.AnimationProgress)
    local baseX = menu.X - (0.05 * (1 - anim))
    local baseY = menu.Y
    
    -- Mouse position
    state.MouseX = GetControlNormal(0, 239)
    state.MouseY = GetControlNormal(0, 240)
    
    -- Calculate dimensions
    local visibleItems = math.min(#menu.Items, config.MaxVisibleItems)
    local totalHeight = config.HeaderHeight + (visibleItems * config.ItemHeight)
    
    -- Background
    ApexUI.DrawRect(baseX, baseY, menu.Width, totalHeight, config.Theme.Background)
    
    -- Header
    ApexUI.DrawHeader(menu, baseX, baseY, menu.Width, config.HeaderHeight)
    
    -- Items
    local itemY = baseY + config.HeaderHeight
    
    -- Update scroll
    if menu.CurrentIndex > menu.ScrollOffset + visibleItems then
        menu.ScrollOffset = menu.CurrentIndex - visibleItems
    elseif menu.CurrentIndex <= menu.ScrollOffset then
        menu.ScrollOffset = menu.CurrentIndex - 1
    end
    
    -- Draw items
    for i = 1, visibleItems do
        local itemIndex = i + menu.ScrollOffset
        local item = menu.Items[itemIndex]
        if not item then break end
        
        local itemH = config.ItemHeight
        local selected = (itemIndex == menu.CurrentIndex)
        
        if ApexUI.IsMouseOver(baseX, itemY, menu.Width, itemH) then
            state.HoverIndex = itemIndex
        end
        
        if item.Type == ApexUI.BUTTON then
            ApexUI.DrawButton(item, baseX, itemY, menu.Width, itemH, selected)
        elseif item.Type == ApexUI.TOGGLE then
            ApexUI.DrawToggle(item, baseX, itemY, menu.Width, itemH, selected)
        elseif item.Type == ApexUI.SLIDER then
            ApexUI.DrawSlider(item, baseX, itemY, menu.Width, itemH, selected)
        elseif item.Type == ApexUI.INPUT then
            ApexUI.DrawInput(item, baseX, itemY, menu.Width, itemH, selected)
        elseif item.Type == ApexUI.LIST then
            ApexUI.DrawList(item, baseX, itemY, menu.Width, itemH, selected)
        elseif item.Type == ApexUI.SEPARATOR then
            ApexUI.DrawSeparator(item, baseX, itemY, menu.Width, itemH)
        elseif item.Type == ApexUI.SUBMENU then
            ApexUI.DrawSubmenuButton(item, baseX, itemY, menu.Width, itemH, selected)
        elseif item.Type == ApexUI.TEXT then
            ApexUI.DrawTextItem(item, baseX, itemY, menu.Width, itemH)
        end
        
        itemY = itemY + itemH
    end
    
    -- Counter
    local counterText = string.format("%d / %d", menu.CurrentIndex, #menu.Items)
    ApexUI.DrawText(counterText, baseX + menu.Width - 0.01, baseY + config.HeaderHeight - 0.015, 4, 0.28, config.Theme.TextDim, true)
end

-- Input Handling
function ApexUI.HandleInput()
    local menu = ApexUI.State.CurrentMenu
    if not menu or not ApexUI.State.IsVisible then return end
    
    DisableControlAction(0, 1, true)
    DisableControlAction(0, 2, true)
    DisableControlAction(0, 142, true)
    
    local delay = 150
    
    -- Up
    if IsDisabledControlJustPressed(0, 172) then
        repeat
            menu.CurrentIndex = menu.CurrentIndex - 1
            if menu.CurrentIndex < 1 then menu.CurrentIndex = #menu.Items end
        until not menu.Items[menu.CurrentIndex] or menu.Items[menu.CurrentIndex].Type ~= ApexUI.SEPARATOR
        Citizen.Wait(delay)
    end
    
    -- Down
    if IsDisabledControlJustPressed(0, 173) then
        repeat
            menu.CurrentIndex = menu.CurrentIndex + 1
            if menu.CurrentIndex > #menu.Items then menu.CurrentIndex = 1 end
        until not menu.Items[menu.CurrentIndex] or menu.Items[menu.CurrentIndex].Type ~= ApexUI.SEPARATOR
        Citizen.Wait(delay)
    end
    
    -- Enter
    if IsDisabledControlJustPressed(0, 176) then
        local item = menu.Items[menu.CurrentIndex]
        if item and not item.Disabled then
            if item.Type == ApexUI.BUTTON and item.Callback then
                item.Callback()
            elseif item.Type == ApexUI.TOGGLE then
                item.Checked = not item.Checked
                if item.Callback then item.Callback(item.Checked) end
            elseif item.Type == ApexUI.SUBMENU then
                if item.Callback then item.Callback() end
                ApexUI.OpenMenu(item.Submenu)
            elseif item.Type == ApexUI.INPUT then
                if item.Active then
                    item.Active = false
                    if item.Callback then item.Callback(item.Text) end
                else
                    item.Active = true
                    AddTextEntry("APEX_INPUT", item.Label)
                    DisplayOnscreenKeyboard(1, "APEX_INPUT", "", item.Text, "", "", "", item.MaxLength)
                end
            end
        end
        Citizen.Wait(100)
    end
    
    -- Back
    if IsDisabledControlJustPressed(0, 177) then
        if menu.Parent then
            ApexUI.OpenMenu(menu.Parent)
        else
            ApexUI.CloseMenu()
        end
        Citizen.Wait(100)
    end
    
    -- Left
    if IsDisabledControlJustPressed(0, 174) then
        local item = menu.Items[menu.CurrentIndex]
        if item and not item.Disabled then
            if item.Type == ApexUI.SLIDER then
                item.Value = math.max(item.Min, item.Value - item.Step)
                if item.Callback then item.Callback(item.Value) end
            elseif item.Type == ApexUI.LIST then
                item.SelectedIndex = item.SelectedIndex - 1
                if item.SelectedIndex < 1 then item.SelectedIndex = #item.Items end
                if item.Callback then item.Callback(item.Items[item.SelectedIndex], item.SelectedIndex) end
            end
        end
        Citizen.Wait(100)
    end
    
    -- Right
    if IsDisabledControlJustPressed(0, 175) then
        local item = menu.Items[menu.CurrentIndex]
        if item and not item.Disabled then
            if item.Type == ApexUI.SLIDER then
                item.Value = math.min(item.Max, item.Value + item.Step)
                if item.Callback then item.Callback(item.Value) end
            elseif item.Type == ApexUI.LIST then
                item.SelectedIndex = item.SelectedIndex + 1
                if item.SelectedIndex > #item.Items then item.SelectedIndex = 1 end
                if item.Callback then item.Callback(item.Items[item.SelectedIndex], item.SelectedIndex) end
            end
        end
        Citizen.Wait(100)
    end
    
    -- Handle keyboard input
    local item = menu.Items[menu.CurrentIndex]
    if item and item.Type == ApexUI.INPUT and item.Active then
        UpdateOnscreenKeyboard()
        local status = UpdateOnscreenKeyboard()
        if status == 1 then
            item.Text = GetOnscreenKeyboardResult()
            item.Active = false
            if item.Callback then item.Callback(item.Text) end
        elseif status == 2 then
            item.Active = false
        end
    end
    
    -- Mouse click
    if IsDisabledControlJustPressed(0, 237) then
        local idx = ApexUI.State.HoverIndex
        if idx and idx > 0 and idx <= #menu.Items then
            menu.CurrentIndex = idx
            local item = menu.Items[idx]
            if item and not item.Disabled then
                if item.Type == ApexUI.BUTTON and item.Callback then
                    item.Callback()
                elseif item.Type == ApexUI.TOGGLE then
                    item.Checked = not item.Checked
                    if item.Callback then item.Callback(item.Checked) end
                elseif item.Type == ApexUI.SUBMENU then
                    if item.Callback then item.Callback() end
                    ApexUI.OpenMenu(item.Submenu)
                end
            end
        end
    end
end

-- Public API
function ApexUI.OpenMenu(menu)
    if ApexUI.State.CurrentMenu and ApexUI.State.CurrentMenu ~= menu then
        table.insert(ApexUI.State.MenuStack, ApexUI.State.CurrentMenu)
    end
    ApexUI.State.CurrentMenu = menu
    ApexUI.State.IsVisible = true
    ApexUI.State.AnimationProgress = 0
end

function ApexUI.CloseMenu()
    ApexUI.State.IsVisible = false
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        if not ApexUI.State.IsVisible then
            ApexUI.State.CurrentMenu = nil
        end
    end)
end

function ApexUI.ToggleMenu(menu)
    if ApexUI.State.IsVisible and ApexUI.State.CurrentMenu == menu then
        ApexUI.CloseMenu()
    else
        ApexUI.OpenMenu(menu)
    end
end

function ApexUI.IsMenuOpen()
    return ApexUI.State.IsVisible
end

-- Main Thread
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

-- Return library
_G.ApexUI = ApexUI
return ApexUI
