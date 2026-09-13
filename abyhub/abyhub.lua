addon.name = 'abyhub'
addon.author = 'Laudout'
addon.version = '1.0.0'
addon.desc = 'Combined Abyssea Key Item and Stagger tracker.'

require('common')

local chat = require('chat')
local imgui = require('imgui')
local bit = require('bit')

local state = {
    visible = { false },
    tab = 1,
    pages = {},

    show_all = { false },
    compact = { false },
    target = 'No target',
    vana_hour = 0,
    vana_minute = 0,
    vana_day = 0,
    vana_weekday = 0,
    vana_ok = false,
    pVanaTime = 0,
}

local AREAS = {
    {
        name = 'Abyssea-Konschtat',
        kis = {
            {1459, 'Fragrant Treant Petal'},
            {1460, 'Fetid Rafflesia Stalk'},
            {1461, 'Decaying Morbol Tooth'},
            {1462, 'Turbid Slime Oil'},
            {1463, 'Venomous Peiste Claw'},
            {1464, 'Tattered Hippogryph Wing'},
            {1465, 'Cracked Wivre Horn'},
            {1466, 'Mucid Ahriman Eyeball'},
            {1467, 'Twisted Tonberry Crown'},
        },
    },
    {
        name = 'Abyssea-Tahrongi',
        kis = {
            {1468, 'Veinous Hecteyes Eyelid'},
            {1469, 'Torn Bat Wing'},
            {1470, 'Gory Scorpion Claw'},
            {1471, 'Mossy Adamantoise Shell'},
            {1472, 'Fat-lined Cockatrice Skin'},
            {1473, 'Sodden Sandworm Husk'},
            {1474, 'Luxuriant Manticore Mane'},
            {1475, 'Sticky Gnat Wing'},
            {1476, 'Overgrown Mandragora Flower'},
            {1477, 'Chipped Sandworm Tooth'},
        },
    },
    {
        name = 'Abyssea-La Theine',
        kis = {
            {1478, 'Marbled Mutton Chop'},
            {1479, 'Bloodied Saber Tooth'},
            {1480, 'Blood-smeared Gigas Helm'},
            {1481, 'Glittering Pixie Choker'},
            {1482, 'Dented Gigas Shield'},
            {1483, 'Warped Gigas Armband'},
            {1484, 'Severed Gigas Collar'},
            {1485, 'Pellucid Fly Eye'},
            {1486, 'Shimmering Pixie Pinion'},
        },
    },
}

local BOSSES = {
    {
        area = 'Abyssea-Konschtat',
        name = 'Eccentric Eve',
        kis = {1459, 1460, 1461, 1462, 1463},
    },
    {
        area = 'Abyssea-Konschtat',
        name = 'Kukulkan',
        kis = {1464, 1465, 1466},
    },
    {
        area = 'Abyssea-Konschtat',
        name = 'Bloodeye Vileberry',
        kis = {1467},
    },
    {
        area = 'Abyssea-Tahrongi',
        name = 'Chloris',
        kis = {1468, 1469, 1470, 1471},
    },
    {
        area = 'Abyssea-Tahrongi',
        name = 'Glavoid',
        kis = {1472, 1473, 1474, 1475},
    },
    {
        area = 'Abyssea-Tahrongi',
        name = 'Lacovie',
        kis = {1476, 1477},
    },
    {
        area = 'Abyssea-La Theine',
        name = 'Briareus',
        kis = {1482, 1483, 1484},
    },
    {
        area = 'Abyssea-La Theine',
        name = 'Carabosse',
        kis = {1485, 1486},
    },
    {
        area = 'Abyssea-La Theine',
        name = 'Hadhayosh',
        kis = {1478, 1479, 1481, 1480},
    },
}

local weekdays = {
    'Firesday', 'Earthsday', 'Watersday', 'Windsday',
    'Iceday', 'Lightningday', 'Lightsday', 'Darksday',
}

local RED = {
    {'Sword', 'Red Lotus', 50, 'Fire'},
    {'Great Sword', 'Freezebite', 100, 'Ice'},
    {'Dagger', 'Cyclone', 125, 'Wind'},
    {'Great Katana', 'Jinpu', 150, 'Wind'},
    {'Staff', 'Earth Crusher', 70, 'Earth'},
    {'Polearm', 'Raiden Thrust', 70, 'Lightning'},
    {'Sword', 'Seraph Blade', 125, 'Light'},
    {'Great Katana', 'Koki', 175, 'Light'},
    {'Club', 'Seraph Strike', 40, 'Light'},
    {'Staff', 'Sunburst', 150, 'Light'},
    {'Dagger', 'Energy Drain', 175, 'Dark'},
    {'Scythe', 'Shadow of Death', 70, 'Dark'},
    {'Katana', 'Blade: Ei', 175, 'Dark'},
};

local ELEMENT_MARKERS = {
    Fire      = { symbol = '[FIRE]',      color = { 1.00, 0.35, 0.15, 1.00 } },
    Ice       = { symbol = '[ICE]',       color = { 0.55, 0.80, 1.00, 1.00 } },
    Wind      = { symbol = '[WIND]',      color = { 0.35, 0.95, 0.65, 1.00 } },
    Earth     = { symbol = '[EARTH]',     color = { 0.80, 0.68, 0.25, 1.00 } },
    Lightning = { symbol = '[THUNDER]',   color = { 0.75, 0.55, 1.00, 1.00 } },
    Light     = { symbol = '[LIGHT]',     color = { 1.00, 0.95, 0.78, 1.00 } },
    Dark      = { symbol = '[DARK]',      color = { 0.62, 0.38, 0.72, 1.00 } },
};

local BLUE = {
    {'Piercing', 'Dagger', 'Shadowstitch', 70},
    {'Piercing', 'Dagger', 'Dancing Edge', 200},
    {'Piercing', 'Dagger', 'Shark Bite', 225},
    {'Piercing', 'Dagger', 'Evisceration', 230},
    {'Piercing', 'Polearm', 'Skewer', 200},
    {'Piercing', 'Polearm', 'Wheeling Thrust', 225},
    {'Piercing', 'Polearm', 'Impulse Drive', 240},
    {'Piercing', 'Archery', 'Sidewinder', 175},
    {'Piercing', 'Archery', 'Blast Arrow', 200},
    {'Piercing', 'Archery', 'Arching Arrow', 225},
    {'Piercing', 'Archery', 'Empyreal Arrow', 250},

    {'Slashing', 'Sword', 'Vorpal Blade', 200},
    {'Slashing', 'Sword', 'Swift Blade', 225},
    {'Slashing', 'Sword', 'Savage Blade', 240},
    {'Slashing', 'Great Sword', 'Spinning Slash', 225},
    {'Slashing', 'Great Sword', 'Ground Strike', 250},
    {'Slashing', 'Axe', 'Mistral Axe', 225},
    {'Slashing', 'Axe', 'Decimation', 240},
    {'Slashing', 'Great Axe', 'Full Break', 225},
    {'Slashing', 'Great Axe', 'Steel Cyclone', 240},
    {'Slashing', 'Scythe', 'Cross Reaper', 225},
    {'Slashing', 'Scythe', 'Spiral Hell', 240},
    {'Slashing', 'Katana', 'Blade: Ten', 225},
    {'Slashing', 'Katana', 'Blade: Ku', 250},
    {'Slashing', 'Great Katana', 'Gekko', 225},
    {'Slashing', 'Great Katana', 'Kasha', 250},

    {'Blunt', 'Hand-to-Hand', 'Raging Fists', 125},
    {'Blunt', 'Hand-to-Hand', 'Spinning Attack', 150},
    {'Blunt', 'Hand-to-Hand', 'Howling Fist', 200},
    {'Blunt', 'Hand-to-Hand', 'Dragon Kick', 225},
    {'Blunt', 'Hand-to-Hand', 'Asuran Fists', 250},
    {'Blunt', 'Club', 'Skullbreaker', 150},
    {'Blunt', 'Club', 'True Strike', 175},
    {'Blunt', 'Club', 'Judgment', 200},
    {'Blunt', 'Club', 'Hexa Strike', 220},
    {'Blunt', 'Club', 'Black Halo', 230},
};

local YELLOW = {
    {'Firesday', 'Fire', 'Fire III, Fire IV, Firaga III, Flare, Katon: Ni, Ice Threnody, Heat Breath'},
    {'Earthsday', 'Earth', 'Stone III, Stone IV, Stonega III, Quake, Doton: Ni, Lightning Threnody, Magnetite Cloud'},
    {'Watersday', 'Water', 'Water III, Water IV, Waterga III, Flood, Suiton: Ni, Fire Threnody, Maelstrom'},
    {'Windsday', 'Wind', 'Aero III, Aero IV, Aeroga III, Tornado, Huton: Ni, Earth Threnody, Mysterious Light'},
    {'Iceday', 'Ice', 'Blizzard III, Blizzard IV, Blizzaga III, Freeze, Hyoton: Ni, Wind Threnody, Ice Break'},
    {'Lightningday', 'Lightning', 'Thunder III, Thunder IV, Thundaga III, Burst, Raiton: Ni, Water Threnody, Mind Blast'},
    {'Lightsday', 'Light', 'Banish II, Banish III, Banishga III, Holy, Flash, Dark Threnody, Radiant Breath'},
    {'Darksday', 'Dark', 'Drain, Aspir, Dispel, Bio II, Kurayami: Ni, Light Threnody, Eyes On Me'},
};

local HUD = {
    accent       = {0.20, 0.72, 1.00, 1.00},
    accent2      = {0.42, 0.84, 1.00, 1.00},
    text         = {0.93, 0.95, 0.98, 1.00},
    muted        = {0.56, 0.61, 0.69, 1.00},
    owned        = {0.35, 1.00, 0.52, 1.00},
    missing      = {0.34, 0.37, 0.42, 1.00},
    warn         = {1.00, 0.70, 0.28, 1.00},
    window_bg    = {0.025, 0.035, 0.050, 0.97},
    child_bg     = {0.045, 0.050, 0.060, 0.94},
    border       = {0.10, 0.48, 0.72, 1.00},
    separator    = {0.10, 0.36, 0.55, 0.90},
    title_bg     = {0.025, 0.095, 0.145, 1.00},
    title_active = {0.035, 0.16, 0.24, 1.00},
    red          = {1.00, 0.30, 0.25, 1.00},
    blue         = {0.35, 0.68, 1.00, 1.00},
    yellow       = {1.00, 0.82, 0.18, 1.00},
    green        = {0.35, 1.00, 0.45, 1.00},
}

local function push_style()
    imgui.PushStyleColor(ImGuiCol_WindowBg, HUD.window_bg)
    imgui.PushStyleColor(ImGuiCol_ChildBg, HUD.child_bg)
    imgui.PushStyleColor(ImGuiCol_Border, HUD.border)
    imgui.PushStyleColor(ImGuiCol_Separator, HUD.separator)
    imgui.PushStyleColor(ImGuiCol_TitleBg, HUD.title_bg)
    imgui.PushStyleColor(ImGuiCol_TitleBgActive, HUD.title_active)
    imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, HUD.title_bg)

    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 6.0)
    imgui.PushStyleVar(ImGuiStyleVar_ChildRounding, 6.0)
    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 3.0)
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.0)
    imgui.PushStyleVar(ImGuiStyleVar_ChildBorderSize, 1.0)
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, {12, 10})
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, {8, 4})
end

local function pop_style()
    imgui.PopStyleVar(7)
    imgui.PopStyleColor(7)
end

local function draw_tab_button(label, tab_id, width)
    local active = state.tab == tab_id

    if active then
        imgui.PushStyleColor(ImGuiCol_Button, HUD.title_active)
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, HUD.title_active)
        imgui.PushStyleColor(ImGuiCol_ButtonActive, HUD.title_active)
        imgui.PushStyleColor(ImGuiCol_Text, HUD.accent2)
    else
        imgui.PushStyleColor(ImGuiCol_Button, HUD.title_bg)
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.04, 0.20, 0.30, 1.00})
        imgui.PushStyleColor(ImGuiCol_ButtonActive, HUD.title_active)
        imgui.PushStyleColor(ImGuiCol_Text, HUD.text)
    end

    if imgui.Button(label, {width, 28}) then
        state.tab = tab_id
    end

    imgui.PopStyleColor(4)
end

local function draw_tabs()
    draw_tab_button('KEY ITEMS', 1, 155)
    imgui.SameLine()
    draw_tab_button('STAGGERS', 2, 155)
    imgui.Separator()
    imgui.Spacing()
end

local function read_u32_packet(b, offset)
    local i = offset + 1
    return (b[i] or 0)
        + ((b[i + 1] or 0) * 0x100)
        + ((b[i + 2] or 0) * 0x10000)
        + ((b[i + 3] or 0) * 0x1000000)
end

local function capture_ki_packet(e)
    if e.id ~= 0x055 then return end

    local b = e.data:bytes()
    if not b then return end

    local page_type = read_u32_packet(b, 0x84)
    local available = {}

    for n = 0, 63 do
        available[n] = b[0x05 + n] or 0
    end

    state.pages[page_type] = available
end

local function has_key_item(id)
    local page_type = math.floor(id / 0x200)
    local offset = id % 0x200
    local page = state.pages[page_type]

    if not page then return false end

    local byte_index = math.floor(offset / 8)
    local bit_index = offset % 8
    local value = page[byte_index] or 0

    return bit.band(bit.rshift(value, bit_index), 1) == 1
end

local function has_required_page()
    return state.pages[2] ~= nil
end

local function count_owned()
    local total = 0
    for _, area in ipairs(AREAS) do
        for _, ki in ipairs(area.kis) do
            if has_key_item(ki[1]) then
                total = total + 1
            end
        end
    end
    return total
end

local function get_ki_name(area, id)
    for _, ki in ipairs(area.kis) do
        if ki[1] == id then return ki[2] end
    end
    return ('KI %d'):format(id)
end

local function count_area_owned(area)
    local owned = 0
    for _, ki in ipairs(area.kis) do
        if has_key_item(ki[1]) then owned = owned + 1 end
    end
    return owned
end

local function draw_boss_group(area, boss)
    local owned = 0
    for _, id in ipairs(boss.kis) do
        if has_key_item(id) then owned = owned + 1 end
    end

    imgui.TextColored(HUD.text, boss.name)
    imgui.SameLine()
    imgui.TextColored(HUD.muted, ('%d/%d'):format(owned, #boss.kis))

    for _, id in ipairs(boss.kis) do
        local name = get_ki_name(area, id)
        if has_key_item(id) then
            imgui.TextColored(HUD.owned, '  +')
            imgui.SameLine()
            imgui.TextColored(HUD.owned, name)
        else
            imgui.TextColored(HUD.missing, '  -')
            imgui.SameLine()
            imgui.TextColored(HUD.missing, name)
        end
    end
end

local function draw_ki_area(area)
    local owned_count = count_area_owned(area)

    imgui.TextColored(HUD.accent2, area.name)
    imgui.SameLine()
    imgui.TextColored(HUD.muted, ('%d/%d'):format(owned_count, #area.kis))
    imgui.Separator()

    local first = true
    for _, boss in ipairs(BOSSES) do
        if boss.area == area.name then
            if not first then imgui.Spacing() end
            draw_boss_group(area, boss)
            first = false
        end
    end
end

local function draw_zone_columns()
    imgui.Columns(3, 'abyssea_zone_columns', true)

    local top_y = imgui.GetCursorPosY()
    local bottom_y = top_y

    for index, area in ipairs(AREAS) do
        imgui.SetCursorPosY(top_y)
        draw_ki_area(area)

        local area_bottom = imgui.GetCursorPosY()
        if area_bottom > bottom_y then bottom_y = area_bottom end

        if index < #AREAS then imgui.NextColumn() end
    end

    imgui.Columns(1)
    imgui.SetCursorPosY(bottom_y)
end

local function render_key_items()
    local total_owned = count_owned()

    imgui.TextColored(HUD.accent, 'ABYSSEA KEY ITEMS')
    imgui.SameLine()
    imgui.TextColored(HUD.muted, ' | Owned Pop KIs')
    imgui.SameLine()
    imgui.TextColored(HUD.owned, tostring(total_owned))

    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    if not has_required_page() then
        imgui.TextColored(HUD.warn, 'WAITING FOR KEY ITEM DATA')
        imgui.Spacing()
        imgui.TextColored(HUD.muted, 'Zone once after loading the addon.')
        return
    end

    imgui.TextColored(HUD.accent, 'POP KEY ITEMS')
    imgui.Separator()
    draw_zone_columns()
end

local VANA_EPOCH_OFFSET = 92514960

local function init_vana_time()
    state.pVanaTime = ashita.memory.find(
        'FFXiMain.dll', 0,
        'B0015EC390518B4C24088D4424005068',
        0x34, 0
    )

    state.vana_ok = state.pVanaTime ~= nil and state.pVanaTime ~= 0

    if not state.vana_ok then
        print(chat.header(addon.name):append(chat.error(
            'Vana-diel clock signature not found; Blue/Yellow auto-selection disabled.'
        )))
    end
end

local function update_vana_time()
    if not state.vana_ok then return end

    local clock_ptr = ashita.memory.read_uint32(state.pVanaTime)
    if not clock_ptr or clock_ptr == 0 then return end

    local raw = ashita.memory.read_uint32(clock_ptr + 0x0C)
    if not raw then return end

    local ts = (raw + VANA_EPOCH_OFFSET) * 25
    local day = math.floor(ts / 86400)
    local hour = math.floor(ts / 3600) % 24
    local minute = math.floor(ts / 60) % 60
    local weekday = day % 8

    state.vana_day = day
    state.vana_hour = hour
    state.vana_minute = minute
    state.vana_weekday = weekday
end

local function update_target()
    local index = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0)
    local target = GetEntity(index)

    if target and target.Name and target.Name ~= '' then
        state.target = target.Name
    else
        state.target = 'No target'
    end
end

local function blue_window()
    local hour = state.vana_hour

    if hour >= 6 and hour < 14 then
        return 'Piercing'
    elseif hour >= 14 and hour < 22 then
        return 'Slashing'
    else
        return 'Blunt'
    end
end

local function current_day()
    return weekdays[state.vana_weekday + 1] or 'Unknown day'
end

local function begin_panel(title, color, height)
    imgui.PushStyleColor(ImGuiCol_ChildBg, HUD.child_bg)
    imgui.PushStyleColor(ImGuiCol_Border, HUD.border)
    imgui.BeginChild(title, {0, height}, ImGuiChildFlags_Borders)
    imgui.TextColored(color, title)
    imgui.Separator()
end

local function end_panel()
    imgui.EndChild()
    imgui.PopStyleColor(2)
end

local function render_red()
    begin_panel('!! RED !!  Elemental WS', HUD.red, state.compact[1] and 120 or 185)

    for _, s in ipairs(RED) do
        imgui.TextColored(HUD.red, s[1])
        imgui.SameLine()
        imgui.Text(s[2])

        local marker = ELEMENT_MARKERS[s[4]]
        if marker then
            imgui.SameLine()
            imgui.TextColored(marker.color, marker.symbol)
        end
    end

    end_panel()
end

local function render_blue()
    local active = blue_window()

    begin_panel(
        ('!! BLUE !!  Physical WS  (ACTIVE: %s)'):format(active),
        HUD.blue,
        state.compact[1] and 180 or 260
    )

    for _, s in ipairs(BLUE) do
        if state.show_all[1] or s[1] == active then
            imgui.TextColored(HUD.blue, s[2])
            imgui.SameLine()
            imgui.Text(s[3])
        end
    end

    end_panel()
end

local function render_yellow()
    local current_index = state.vana_weekday + 1
    local previous_index = ((state.vana_weekday - 1) % 8) + 1
    local next_index = ((state.vana_weekday + 1) % 8) + 1

    local previous_day = weekdays[previous_index] or 'Unknown day'
    local active_day = weekdays[current_index] or 'Unknown day'
    local next_day = weekdays[next_index] or 'Unknown day'

    begin_panel(
        ('!! YELLOW !!  Magic  (ACTIVE: %s / %s / %s)'):format(
            previous_day,
            active_day,
            next_day
        ),
        HUD.yellow,
        state.compact[1] and 145 or 205
    )

    for _, s in ipairs(YELLOW) do
        local is_active =
            (s[1] == previous_day) or
            (s[1] == active_day) or
            (s[1] == next_day)

        if state.show_all[1] or is_active then
            imgui.TextColored(HUD.yellow, s[1])
            imgui.SameLine()
            imgui.Text(('%s: %s'):format(s[2], s[3]))
        end
    end

    end_panel()
end

local function render_staggers()
    imgui.TextColored(HUD.accent, 'ABYSSEA STAGGER LIVE')
    imgui.Separator()

    imgui.TextColored(HUD.text, 'Target:')
    imgui.SameLine()
    imgui.TextColored(HUD.green, state.target)
    imgui.SameLine()
    imgui.TextColored(HUD.muted, ' | ')
    imgui.SameLine()
    imgui.TextColored(
        HUD.accent2,
        ('Vana %02d:%02d  %s'):format(state.vana_hour, state.vana_minute, current_day())
    )

    imgui.Separator()

    if imgui.Button(state.show_all[1] and 'SHOW ACTIVE ONLY' or 'SHOW ALL') then
        state.show_all[1] = not state.show_all[1]
    end

    imgui.SameLine()

    if imgui.Button(state.compact[1] and 'FULL MODE' or 'COMPACT MODE') then
        state.compact[1] = not state.compact[1]
    end

    imgui.Separator()

    render_red()
    imgui.Separator()
    render_blue()
    imgui.Separator()
    render_yellow()

    imgui.Separator()
    imgui.TextColored(HUD.muted,
        'Red: elemental WS | Blue: time-of-day | Yellow: previous/current/next day')
    imgui.TextColored(HUD.muted,
        'Blue proc windows: 06:00-13:59 Piercing | 14:00-21:59 Slashing | 22:00-05:59 Blunt')
end

ashita.events.register('packet_in', 'abyhub_packet_cb', function(e)
    capture_ki_packet(e)
end)

ashita.events.register('command', 'abyhub_command_cb', function(e)
    local args = e.command:args()
    if #args == 0 then return end

    local root = args[1]:lower()

    if root ~= '/aby'
        and root ~= '/abyssea'
        and root ~= '/aki'
        and root ~= '/abysseaki'
        and root ~= '/as'
        and root ~= '/abystagger' then
        return
    end

    e.blocked = true

    if root == '/aki' or root == '/abysseaki' then
        state.tab = 1
    elseif root == '/as' or root == '/abystagger' then
        state.tab = 2
    end

    if #args == 1 then
        state.visible[1] = not state.visible[1]
        return
    end

    local cmd = args[2]:lower()

    if cmd == 'show' then
        state.visible[1] = true
    elseif cmd == 'hide' then
        state.visible[1] = false
    elseif cmd == 'ki' or cmd == 'keyitems' then
        state.tab = 1
        state.visible[1] = true
    elseif cmd == 'stagger' or cmd == 'staggers' then
        state.tab = 2
        state.visible[1] = true
    elseif cmd == 'all' then
        state.tab = 2
        state.visible[1] = true
        state.show_all[1] = not state.show_all[1]
    elseif cmd == 'compact' then
        state.tab = 2
        state.visible[1] = true
        state.compact[1] = not state.compact[1]
    else
        print(chat.header(addon.name):append(chat.message(
            'Commands: /aby, /aby show, /aby hide, /aby ki, /aby stagger, /aby all, /aby compact'
        )))
    end
end)

ashita.events.register('d3d_present', 'abyhub_present_cb', function()
    update_vana_time()
    update_target()

    if not state.visible[1] then return end

    push_style()

    if state.tab == 1 then
        imgui.SetNextWindowSize({1020, 0}, ImGuiCond_FirstUseEver)
    else
        imgui.SetNextWindowSize({780, 780}, ImGuiCond_FirstUseEver)
    end

    if imgui.Begin('Abyssea Toolkit##abyhub_combined', state.visible, ImGuiWindowFlags_NoCollapse) then
        imgui.TextColored(HUD.accent, 'ABYSSEA TOOLKIT')
        imgui.SameLine()
        imgui.TextColored(HUD.muted, 'Key Items + Staggers')

        imgui.Spacing()
        draw_tabs()

        if state.tab == 1 then
            render_key_items()
        else
            render_staggers()
        end
    end

    imgui.End()
    pop_style()
end)

ashita.events.register('load', 'abyhub_load_cb', function()
    init_vana_time()
    print(chat.header(addon.name):append(chat.success(
        'v1.0.0 loaded - combined Key Items + Staggers. Use /aby.'
    )))
end)
