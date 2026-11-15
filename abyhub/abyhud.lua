-- abyhub: sidebar window (tester).
--
-- A dark app-style layout: a sidebar on the left (logo, character / clock box,
-- menu with sub-items and counts, settings at the bottom) and the selected
-- tab's content on the right. The sidebar collapses to an icon rail; hovering
-- a menu icon there opens a card with its sub-items.
--
-- The tabs themselves (Key Items, Staggers, Atma, Empyrean, Search) are
-- abyhub's own; the sidebar takes over their sub-tabs (Vision / Scars /
-- Heroes, Armor / NMs / Weapons ...).
--
-- All data comes from abyhub.lua through the context table given to M.setup().
local imgui = require('imgui')
local bit = require('bit')

local M = {}
local C          -- context from abyhub.lua

M.view = 'tab'   -- 'tab' (one of abyhub's tabs) | 'search'

---------------------------------------------------------------------------- palette
local P = {
    win      = { 0.071, 0.071, 0.078, 0.98 },
    side     = { 0.051, 0.051, 0.059, 1.00 },
    content  = { 0.086, 0.086, 0.094, 1.00 },
    box      = { 0.106, 0.106, 0.118, 1.00 },
    sel      = { 0.149, 0.149, 0.165, 1.00 },
    logo     = { 0.165, 0.165, 0.180, 1.00 },
    hover    = { 1.00, 1.00, 1.00, 0.04 },
    line     = { 1.00, 1.00, 1.00, 0.06 },
    border   = { 1.00, 1.00, 1.00, 0.07 },
    text     = { 0.93, 0.93, 0.95, 1.00 },
    sub      = { 0.74, 0.74, 0.78, 1.00 },
    muted    = { 0.55, 0.56, 0.60, 1.00 },
    faint    = { 0.36, 0.37, 0.40, 1.00 },
    cyan     = { 0.33, 0.76, 0.93, 1.00 },
    purple   = { 0.62, 0.55, 0.95, 1.00 },
    red      = { 0.95, 0.36, 0.40, 1.00 },
    yellow   = { 0.98, 0.86, 0.45, 1.00 },
    green    = { 0.42, 0.86, 0.58, 1.00 },
    pink     = { 0.93, 0.52, 0.72, 1.00 },
}

local function rgba(c, a) return { c[1], c[2], c[3], a or c[4] or 1 } end
local function col(c, a) return imgui.GetColorU32(rgba(c, a)) end
local function DL() return imgui.GetWindowDrawList() end
local CORNERS_ALL = ImDrawFlags_RoundCornersAll or ImDrawCornerFlags_All or 15

---------------------------------------------------------------------------- fonts
-- body = Segoe UI, semi = Segoe UI Semibold. Newer ImGui (fonts with LegacySize)
-- scales one font to any size sharply; older ImGui gets each size loaded on its own.
local FONT_SPEC = {
    body = { files = { 'segoeui.ttf' }, sizes = { 13, 15, 17, 20 } },
    semi = { files = { 'seguisb.ttf', 'segoeuib.ttf', 'segoeui.ttf' }, sizes = { 15, 17, 22, 26 } },
}
local fonts = {}   -- key -> { dynamic = bool, list = { { size, font } ... } }

function M.load_fonts()
    if type(imgui.AddFontFromFileTTF) ~= 'function' then return end
    local dir = (os.getenv('WINDIR') or 'C:\\Windows') .. '\\Fonts\\'
    for key, spec in pairs(FONT_SPEC) do
        for _, fname in ipairs(spec.files) do
            local f = io.open(dir .. fname, 'rb')
            if f then
                f:close()
                local ok, fnt = pcall(imgui.AddFontFromFileTTF, dir .. fname, spec.sizes[#spec.sizes])
                if ok and fnt then
                    local dyn = false
                    pcall(function() dyn = fnt.LegacySize ~= nil end)
                    local entry = { dynamic = dyn, list = { { spec.sizes[#spec.sizes], fnt } } }
                    if not dyn then
                        for i = 1, #spec.sizes - 1 do
                            local ok2, f2 = pcall(imgui.AddFontFromFileTTF, dir .. fname, spec.sizes[i])
                            if ok2 and f2 then table.insert(entry.list, 1, { spec.sizes[i], f2 }) end
                        end
                    end
                    fonts[key] = entry
                    break
                end
            end
        end
    end
end

-- The font object to draw `key` at `size` (old ImGui: the nearest loaded size
-- at or above it, so text is scaled down, never up).
local function pick(key, size)
    local e = fonts[key]
    if e == nil then return nil end
    if e.dynamic then return e.list[1][2] end
    for _, s in ipairs(e.list) do if s[1] >= size then return s[2] end end
    return e.list[#e.list][2]
end

local wcache, wcache_n = {}, 0
local function tw(key, size, s)
    local k = key .. size .. '|' .. s
    local v = wcache[k]
    if v then return v end
    local f = pick(key, size)
    local pushed = false
    if f then
        if fonts[key].dynamic then pushed = pcall(imgui.PushFont, f, size) else pushed = pcall(imgui.PushFont, f) end
    end
    local fs = tonumber(imgui.GetFontSize()) or size
    v = (tonumber((imgui.CalcTextSize(s))) or 0) * size / fs
    if pushed then imgui.PopFont() end
    if wcache_n > 6000 then wcache, wcache_n = {}, 0 end
    wcache[k], wcache_n = v, wcache_n + 1
    return v
end

local function tx(key, size, x, y, c, s)
    local f = pick(key, size) or imgui.GetFont()
    DL():AddText(f, size, { math.floor(x + 0.5), math.floor(y + 0.5) }, type(c) == 'table' and col(c) or c, s)
end

-- right-aligned / centred
local function txr(key, size, x, y, c, s) tx(key, size, x - tw(key, size, s), y, c, s) end
local function txc(key, size, x, y, c, s) tx(key, size, x - tw(key, size, s) * 0.5, y, c, s) end

-- Trim to a width with an ellipsis.
local function fit(key, size, s, w)
    if tw(key, size, s) <= w then return s end
    while #s > 1 and tw(key, size, s .. '..') > w do s = s:sub(1, -2) end
    return s .. '..'
end

-- The HUD window's own default font (Segoe UI 15), for ImGui widgets.
function M.push_body_font()
    local f = pick('body', 15)
    if not f then return false end
    local ok
    if fonts.body.dynamic then ok = pcall(imgui.PushFont, f, 15) else ok = pcall(imgui.PushFont, f) end
    return ok
end
function M.pop_body_font(p) if p then imgui.PopFont() end end

---------------------------------------------------------------------------- shapes
local function line(x1, y1, x2, y2, c, t) DL():AddLine({ x1, y1 }, { x2, y2 }, c, t or 1) end
local function rfill(x, y, w, h, c, r) DL():AddRectFilled({ x, y }, { x + w, y + h }, c, r or 0) end
local function rline(x, y, w, h, c, r, t) DL():AddRect({ x + 0.5, y + 0.5 }, { x + w - 0.5, y + h - 0.5 }, c, r or 0, CORNERS_ALL, t or 1) end
local function disc(cx, cy, r, c, n) DL():AddCircleFilled({ cx, cy }, r, c, n or 24) end
local function ring(cx, cy, r, c, t, n) DL():AddCircle({ cx, cy }, r, c, n or 24, t or 1) end
local function tri(a, b, c, cc) DL():AddTriangleFilled(a, b, c, cc) end

local function hit(id, x, y, w, h)
    local cx, cy = imgui.GetCursorScreenPos()
    imgui.SetCursorScreenPos({ x, y })
    local clicked = imgui.InvisibleButton(id, { math.max(1, w), math.max(1, h) })
    local hov = imgui.IsItemHovered()
    if hov then pcall(imgui.SetMouseCursor, ImGuiMouseCursor_Hand) end
    imgui.SetCursorScreenPos({ cx, cy })
    return clicked, hov
end

local function mouse_in(x, y, w, h)
    local ok, mx, my = pcall(imgui.GetMousePos)
    if not ok or type(mx) ~= 'number' then return false end
    return mx >= x and mx < x + w and my >= y and my < y + h
end

---------------------------------------------------------------------------- markers (the coloured shapes in front of sub-items)
local function marker(kind, cx, cy, c)
    local cc = col(c)
    if kind == 'dot' then
        disc(cx, cy, 4, cc, 16)
    elseif kind == 'tri' then
        tri({ cx, cy - 4.5 }, { cx + 5, cy + 4 }, { cx - 5, cy + 4 }, cc)
    elseif kind == 'square' then
        rfill(cx - 4, cy - 4, 8, 8, cc, 1.5)
    elseif kind == 'star' then
        local P_ = {}
        for i = 0, 9 do
            local a = -math.pi / 2 + i * math.pi / 5
            local r = (i % 2 == 0) and 5.5 or 2.4
            P_[i] = { cx + math.cos(a) * r, cy + math.sin(a) * r }
        end
        for i = 0, 9, 2 do tri(P_[i], P_[(i + 1) % 10], P_[(i + 9) % 10], cc) end
        disc(cx, cy, 2.4, cc, 10)
    elseif kind == 'diamond' then
        tri({ cx, cy - 5 }, { cx + 5, cy }, { cx - 5, cy }, cc)
        tri({ cx - 5, cy }, { cx + 5, cy }, { cx, cy + 5 }, cc)
    else
        rfill(cx - 4, cy - 4, 8, 8, cc, 4)
    end
end

---------------------------------------------------------------------------- icons (line drawings, about 18px)
local ICON = {}
function ICON.list(cx, cy, c)
    local cc = col(c)
    for i = -1, 1 do
        disc(cx - 6, cy + i * 5, 1.4, cc, 8)
        line(cx - 2, cy + i * 5, cx + 7, cy + i * 5, cc, 1.4)
    end
end
function ICON.target(cx, cy, c)
    local cc = col(c)
    ring(cx, cy, 7, cc, 1.4, 24); ring(cx, cy, 2.5, cc, 1.4, 12)
    line(cx - 10, cy, cx - 5, cy, cc, 1.4); line(cx + 5, cy, cx + 10, cy, cc, 1.4)
    line(cx, cy - 10, cx, cy - 5, cc, 1.4); line(cx, cy + 5, cx, cy + 10, cc, 1.4)
end
function ICON.gem(cx, cy, c)
    local cc = col(c)
    local p = { { cx - 7, cy - 2 }, { cx - 3, cy - 7 }, { cx + 3, cy - 7 }, { cx + 7, cy - 2 }, { cx, cy + 8 } }
    for i = 1, #p do line(p[i][1], p[i][2], p[i % #p + 1][1], p[i % #p + 1][2], cc, 1.4) end
    line(cx - 7, cy - 2, cx + 7, cy - 2, cc, 1.2)
end
function ICON.helm(cx, cy, c)
    local cc = col(c)
    local n = 10
    local px, py = cx - 7, cy + 1
    for i = 1, n do
        local a = math.pi + math.pi * i / n
        local qx, qy = cx + math.cos(a) * 7, cy + 1 + math.sin(a) * 7
        line(px, py, qx, qy, cc, 1.4)
        px, py = qx, qy
    end
    line(cx - 7, cy + 1, cx - 7, cy + 7, cc, 1.4); line(cx + 7, cy + 1, cx + 7, cy + 7, cc, 1.4)
    line(cx - 3, cy + 2, cx + 3, cy + 2, cc, 1.4)
end
function ICON.search(cx, cy, c)
    local cc = col(c)
    ring(cx - 1.5, cy - 1.5, 5.5, cc, 1.5, 20); line(cx + 2.5, cy + 2.5, cx + 7, cy + 7, cc, 1.8)
end
function ICON.sun(cx, cy, c)
    local cc = col(c)
    disc(cx, cy, 3.5, cc, 14)
    for i = 0, 7 do
        local a = i * math.pi / 4
        line(cx + math.cos(a) * 6, cy + math.sin(a) * 6, cx + math.cos(a) * 8.5, cy + math.sin(a) * 8.5, cc, 1.4)
    end
end
function ICON.window(cx, cy, c)
    local cc = col(c)
    rline(cx - 8, cy - 6, 16, 13, cc, 2.5, 1.4)
    line(cx - 7, cy - 2, cx + 7, cy - 2, cc, 1.2)
end
function ICON.chevrons(cx, cy, c, left)
    local cc = col(c)
    local d = left and -1 or 1
    for k = 0, 1 do
        local ox = cx + (k * 5 - 2.5) * d
        line(ox - 2.5 * d, cy - 4, ox + 2.5 * d, cy, cc, 1.5)
        line(ox + 2.5 * d, cy, ox - 2.5 * d, cy + 4, cc, 1.5)
    end
end
function ICON.updown(cx, cy, c)
    local cc = col(c)
    line(cx - 3, cy - 2, cx, cy - 5, cc, 1.3); line(cx, cy - 5, cx + 3, cy - 2, cc, 1.3)
    line(cx - 3, cy + 2, cx, cy + 5, cc, 1.3); line(cx, cy + 5, cx + 3, cy + 2, cc, 1.3)
end

-- The logo: a cube in a round badge.
local function logo(cx, cy, r)
    disc(cx, cy, r, col(P.logo), 32)
    local s = r * 0.48
    local top = { cx, cy - s }
    local l, rr = { cx - s * 0.87, cy - s * 0.5 }, { cx + s * 0.87, cy - s * 0.5 }
    local mid = { cx, cy }
    local bl, br = { cx - s * 0.87, cy + s * 0.5 }, { cx + s * 0.87, cy + s * 0.5 }
    local bot = { cx, cy + s }
    tri(top, rr, mid, col(P.text, 0.95)); tri(top, mid, l, col(P.text, 0.95))
    tri(l, mid, bl, col(P.text, 0.55)); tri(mid, bot, bl, col(P.text, 0.55))
    tri(mid, rr, br, col(P.text, 0.30)); tri(mid, br, bot, col(P.text, 0.30))
end

---------------------------------------------------------------------------- menu model
local ui = {
    log = {},
    collapsed = false,
    open = {},              -- group key -> expanded
    fly = nil,              -- collapsed rail: { group, x, y } of the pop-out card
    fly_t = 0,
    fly_hover = false,
    fly_open = { true },
}

function M.log(text, c)
    table.insert(ui.log, 1, { t = os.date('%H:%M'), text = text, c = c })
    while #ui.log > 40 do table.remove(ui.log) end
end

local MARKS = {
    vision = { 'dot', P.cyan }, scars = { 'tri', P.purple }, heroes = { 'star', P.yellow },
    other = { 'square', P.red }, sites = { 'diamond', P.green },
}

local function title_case(s) return (s:lower():gsub('^%l', string.upper)) end

-- Sub-items for each group: { id, label, badge, marker, colour, subtitle }
local function subs_for(key)
    local out = {}
    if key == 1 then
        for _, e in ipairs(C.KI_EXPANSIONS) do
            local o, t = C.ki_counts(e.key)
            local m = MARKS[e.key] or { 'dot', P.cyan }
            out[#out + 1] = { e.key, title_case(e.label), ('%d/%d'):format(o, t), m[1], m[2],
                ('%d of %d pop key items'):format(o, t) }
        end
    elseif key == 3 then
        for _, g in ipairs(C.atma_groups()) do
            local m = MARKS[g.key] or { 'dot', P.cyan }
            out[#out + 1] = { g.key, title_case(g.label), ('%d/%d'):format(g.o, g.t), m[1], m[2],
                ('%d of %d %s'):format(g.o, g.t, g.key == 'sites' and 'abyssites' or 'atmas') }
        end
    elseif key == 4 and C.empy then
        local d, t, nw = C.empy.tab_counts()
        out[#out + 1] = { 1, 'Armor', ('%d/%d'):format(d, t), 'dot', P.cyan, ('%d of %d pieces done'):format(d, t) }
        out[#out + 1] = { 2, 'NMs', nil, 'tri', P.pink, 'Seals and +2 materials' }
        out[#out + 1] = { 3, 'Weapons', nw > 0 and tostring(nw) or nil, 'star', P.yellow, 'Empyrean weapon stages' }
    end
    return out
end

local function sub_current(key)
    if key == 1 then return C.ki_get_exp()
    elseif key == 3 then return C.atma_get_group()
    elseif key == 4 and C.empy then return C.empy.get_tab() end
end

local function sub_set(key, id)
    if key == 1 then C.ki_set_exp(id)
    elseif key == 3 then C.atma_set_group(id)
    elseif key == 4 and C.empy then C.empy.set_tab(id) end
end

local MENU = {
    { kind = 'item',  key = 2,        label = 'Staggers',  icon = 'target' },
    { kind = 'item',  key = 'search', label = 'Search',    icon = 'search' },
    { kind = 'rule' },
    { kind = 'group', key = 1,        label = 'Key Items', icon = 'list' },
    { kind = 'group', key = 3,        label = 'Atma',      icon = 'gem' },
    { kind = 'group', key = 4,        label = 'Empyrean',  icon = 'helm' },
}

local function current_key()
    if M.view == 'search' then return 'search' end
    return C.state.tab
end

local function open_key(key)
    if key == 'search' then
        M.view = 'search'
    else
        M.view = 'tab'
        if C.state.tab ~= key then
            C.state.tab = key
            C.save_settings()
        end
    end
end

-- Badge text on a top-level item.
local function item_badge(key)
    if key == 2 then
        local s = C.state
        local bw = s.vana_ok and C.blue_window() or nil
        return bw and title_case(bw) or nil, P.cyan
    end
    return nil
end

---------------------------------------------------------------------------- sidebar (expanded)
M.SIDE_W, M.RAIL_W = 240, 72
function M.side_w() return ui.collapsed and M.RAIL_W or M.SIDE_W end

local ROW_H = 38

local function draw_row(id, x, y, w, icon, label, active, badge, badge_c, chevron)
    local clicked, hov = hit(id, x, y, w, ROW_H - 4)
    if active then rfill(x, y, w, ROW_H - 4, col(P.sel), 8)
    elseif hov then rfill(x, y, w, ROW_H - 4, col(P.hover), 8) end
    local ic = active and P.text or (hov and P.sub or P.muted)
    ICON[icon](x + 20, y + (ROW_H - 4) * 0.5, ic)
    tx('body', 15, x + 42, y + (ROW_H - 4 - 20) * 0.5, active and P.text or (hov and P.sub or P.muted), label)
    local rx = x + w - 12
    if chevron ~= nil then
        local cc = col(P.muted)
        local cy = y + (ROW_H - 4) * 0.5
        if chevron then
            line(rx - 9, cy + 2, rx - 5, cy - 2, cc, 1.4); line(rx - 5, cy - 2, rx - 1, cy + 2, cc, 1.4)
        else
            line(rx - 9, cy - 2, rx - 5, cy + 2, cc, 1.4); line(rx - 5, cy + 2, rx - 1, cy - 2, cc, 1.4)
        end
        rx = rx - 18
    end
    if badge then
        tx('body', 13, rx - tw('body', 13, badge), y + (ROW_H - 4 - 17) * 0.5, active and P.sub or P.muted, badge)
    end
    return clicked
end

local function draw_sidebar(x, y, w, h)
    -- panel (rounded on the left; the right edge meets the content)
    rfill(x, y, w, h, col(P.side), 12)
    rfill(x + w - 14, y, 14, h, col(P.side), 0)
    rfill(x + w - 1, y, 1, h, col(P.line), 0)

    local pad = 14
    local iw = w - pad * 2
    local cy = y + 20

    -- logo + name
    logo(x + pad + 20, cy + 20, 20)
    tx('semi', 22, x + pad + 52, cy + 6, P.text, 'Abyhub')
    cy = cy + 56

    -- character / clock box
    local bh = 52
    rfill(x + pad, cy, iw, bh, col(P.box), 8)
    local who = C.player_name()
    tx('body', 15, x + pad + 14, cy + 7, P.text, fit('body', 15, who or 'Not logged in', iw - 44))
    local s = C.state
    local line2 = C.job_string() or ''
    if s.vana_ok then
        local day = C.current_day()
        local dc = C.ELEMENT_COLOR[C.DAY_ELEMENT[day] or ''] or P.sub
        local clk = ('%02d:%02d  %s'):format(s.vana_hour, s.vana_minute, day)
        disc(x + pad + w - pad * 2 - 18, cy + bh * 0.5, 4, col(dc), 16)
        line2 = (line2 ~= '' and (line2 .. '  \194\183  ') or '') .. clk
    end
    tx('body', 13, x + pad + 14, cy + 28, P.muted, fit('body', 13, line2, iw - 44))
    cy = cy + bh + 18

    -- menu
    local cur = current_key()
    for _, it in ipairs(MENU) do
        if it.kind == 'rule' then
            rfill(x + pad, cy + 6, iw, 1, col(P.line))
            cy = cy + 18
        elseif it.kind == 'item' then
            local b, bc = item_badge(it.key)
            if draw_row('##side_' .. tostring(it.key), x + pad, cy, iw, it.icon, it.label, cur == it.key, b, bc) then
                open_key(it.key)
            end
            cy = cy + ROW_H
        else
            local open = ui.open[it.key]
            if open == nil then open = (cur == it.key) end
            local active = (cur == it.key)
            if draw_row('##side_' .. tostring(it.key), x + pad, cy, iw, it.icon, it.label, active and not open, nil, nil, open) then
                if active then ui.open[it.key] = not open
                else open_key(it.key); ui.open[it.key] = true end
            end
            cy = cy + ROW_H
            if ui.open[it.key] ~= nil then open = ui.open[it.key] end
            if open then
                local subs = subs_for(it.key)
                local sel = active and sub_current(it.key) or nil
                local top = cy
                for _, sb in ipairs(subs) do
                    local rx, rw, rh = x + pad + 20, iw - 20, 32
                    local clicked, hov = hit(('##sub_%s_%s'):format(tostring(it.key), tostring(sb[1])), rx, cy, rw, rh - 2)
                    if clicked then open_key(it.key); sub_set(it.key, sb[1]) end
                    local on = (sel == sb[1])
                    if on then rfill(rx, cy, rw, rh - 2, col(P.sel), 8)
                    elseif hov then rfill(rx, cy, rw, rh - 2, col(P.hover), 8) end
                    marker(sb[4], rx + 16, cy + (rh - 2) * 0.5, sb[5])
                    tx('body', 14, rx + 32, cy + (rh - 2 - 19) * 0.5, on and P.text or (hov and P.sub or P.muted), sb[2])
                    if sb[3] then
                        tx('body', 13, rx + rw - 10 - tw('body', 13, sb[3]), cy + (rh - 2 - 17) * 0.5, on and P.sub or P.faint, sb[3])
                    end
                    cy = cy + rh
                end
                -- the guide line on the left of the sub-items
                rfill(x + pad + 20 - 8, top + 4, 1, cy - top - 8, col(P.line))
                cy = cy + 4
            end
        end
    end

    -- bottom: lights bar, classic window, collapse
    local by = y + h - 14 - ROW_H * 3
    if cy + 10 < by then
        rfill(x + pad, by - 10, iw, 1, col(P.line))
        if draw_row('##side_lights', x + pad, by, iw, 'sun', 'Lights bar', false, s.lights_auto and 'On' or 'Off') then
            C.toggle_lights()
        end
        if draw_row('##side_classic', x + pad, by + ROW_H, iw, 'window', 'Classic window', false) then C.classic() end
        local clicked, hov = hit('##side_collapse', x + pad, by + ROW_H * 2, iw, ROW_H - 4)
        if hov then rfill(x + pad, by + ROW_H * 2, iw, ROW_H - 4, col(P.hover), 8) end
        ICON.chevrons(x + pad + 20, by + ROW_H * 2 + (ROW_H - 4) * 0.5, hov and P.sub or P.muted, true)
        tx('body', 15, x + pad + 42, by + ROW_H * 2 + (ROW_H - 4 - 20) * 0.5, hov and P.sub or P.muted, 'Collapse')
        if clicked then ui.collapsed = true end
    end
end

---------------------------------------------------------------------------- sidebar (collapsed rail)
local function rail_button(id, cx, cy, size, icon, active, tip)
    local x, y = cx - size * 0.5, cy - size * 0.5
    local clicked, hov = hit(id, x, y, size, size)
    if active then rfill(x, y, size, size, col(P.sel), 8)
    elseif hov then rfill(x, y, size, size, col(P.hover), 8) end
    ICON[icon](cx, cy, active and P.text or (hov and P.sub or P.muted))
    if hov and tip then imgui.SetTooltip(tip) end
    return clicked, hov
end

local function draw_rail(x, y, w, h)
    rfill(x, y, w, h, col(P.side), 12)
    rfill(x + w - 14, y, 14, h, col(P.side), 0)
    rfill(x + w - 1, y, 1, h, col(P.line), 0)
    local cx = x + w * 0.5
    local cy = y + 40
    logo(cx, cy, 20)
    cy = cy + 46
    -- clock square
    local s = C.state
    local bs = 40
    rfill(cx - bs * 0.5, cy, bs, bs, col(P.box), 8)
    local tip = C.player_name() or 'Not logged in'
    if s.vana_ok then
        local day = C.current_day()
        local dc = C.ELEMENT_COLOR[C.DAY_ELEMENT[day] or ''] or P.sub
        disc(cx, cy + bs * 0.5, 4.5, col(dc), 16)
        tip = tip .. '\n' .. ('%02d:%02d  %s'):format(s.vana_hour, s.vana_minute, day)
    else
        ICON.updown(cx, cy + bs * 0.5, P.muted)
    end
    if mouse_in(cx - bs * 0.5, cy, bs, bs) then imgui.SetTooltip(tip) end
    cy = cy + bs + 26

    local cur = current_key()
    local any_hover = false
    for _, it in ipairs(MENU) do
        if it.kind == 'rule' then
            rfill(x + 16, cy - 4, w - 32, 1, col(P.line))
            cy = cy + 10
        else
            local clicked, hov = rail_button('##rail_' .. tostring(it.key), cx, cy + 18, 40, it.icon, cur == it.key,
                it.kind == 'item' and it.label or nil)
            if clicked then open_key(it.key) end
            if it.kind == 'group' and hov then
                ui.fly = { key = it.key, label = it.label, x = x + w + 6, y = cy - 4 }
                ui.fly_t = os.clock()
                any_hover = true
            end
            -- a small dot on a group icon whose tab is open
            if it.kind == 'group' and cur == it.key then disc(cx + 13, cy + 6, 3, col(P.cyan), 12) end
            cy = cy + 46
        end
    end
    -- bottom: lights, classic, expand
    local by = y + h - 14 - 46 * 3
    local c1 = rail_button('##rail_lights', cx, by + 20, 40, 'sun', false, 'Lights bar: ' .. (s.lights_auto and 'on' or 'off'))
    if c1 then C.toggle_lights() end
    local c2 = rail_button('##rail_classic', cx, by + 66, 40, 'window', false, 'Classic window')
    if c2 then C.classic() end
    local ex, ey = cx - 20, by + 92
    local c3, h3 = hit('##rail_expand', ex, ey, 40, 40)
    if h3 then rfill(ex, ey, 40, 40, col(P.hover), 8); imgui.SetTooltip('Expand') end
    ICON.chevrons(cx, ey + 20, h3 and P.sub or P.muted, false)
    if c3 then ui.collapsed = false end
    return any_hover
end

-- The pop-out card for a group on the collapsed rail: its own small window so
-- it sits on top of the tab content.
local function draw_flyout(icon_hover)
    if not ui.fly then return end
    local alive = icon_hover or ui.fly_hover or (os.clock() - ui.fly_t < 0.30)
    if not alive then ui.fly = nil; return end
    local f = ui.fly
    local subs = subs_for(f.key)
    local sel = (current_key() == f.key) and sub_current(f.key) or nil
    local rw, rh = 280, 50
    imgui.SetNextWindowPos({ f.x, f.y })
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 8, 8 })
    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 10)
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1)
    imgui.PushStyleColor(ImGuiCol_WindowBg, rgba(P.box, 0.99))
    imgui.PushStyleColor(ImGuiCol_Border, rgba(P.border, 0.12))
    local flags = bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoMove,
        ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoSavedSettings or 0, ImGuiWindowFlags_AlwaysAutoResize or 0,
        ImGuiWindowFlags_NoFocusOnAppearing or 0, ImGuiWindowFlags_NoCollapse)
    ui.fly_open[1] = true
    if imgui.Begin('##abyhub_flyout', ui.fly_open, flags) then
        local ox, oy = imgui.GetCursorScreenPos()
        for i, sb in ipairs(subs) do
            local ry = oy + (i - 1) * rh
            local clicked, hov = hit(('##fly_%s'):format(tostring(sb[1])), ox, ry, rw, rh - 4)
            if clicked then open_key(f.key); sub_set(f.key, sb[1]) end
            local on = (sel == sb[1])
            if on or hov then rfill(ox, ry, rw, rh - 4, col(on and P.sel or P.hover), 8) end
            -- grip dots, then a round colour badge with the marker in it
            for gy = 0, 2 do for gx = 0, 1 do disc(ox + 10 + gx * 4, ry + (rh - 4) * 0.5 - 4 + gy * 4, 1, col(P.faint), 6) end end
            local bx, by = ox + 38, ry + (rh - 4) * 0.5
            disc(bx, by, 15, col(sb[5], 0.85), 28)
            marker(sb[4], bx, by, { 1, 1, 1, 0.95 })
            tx('semi', 15, ox + 62, ry + 4, P.text, sb[2])
            tx('body', 13, ox + 62, ry + 24, P.muted, sb[6] or '')
            if sb[3] then tx('body', 13, ox + rw - 10 - tw('body', 13, sb[3]), ry + 6, P.faint, sb[3]) end
        end
        imgui.SetCursorScreenPos({ ox, oy })
        imgui.Dummy({ rw, math.max(1, #subs * rh - 4) })
        ui.fly_hover = imgui.IsWindowHovered()
    end
    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(3)
end

---------------------------------------------------------------------------- content
local function view_title()
    local key = current_key()
    if key == 'search' then return 'Search', 'Key items, atma, abyssites, NMs and Empyrean gear' end
    if key == 2 then
        local s = C.state
        local bw = s.vana_ok and C.blue_window() or nil
        return 'Staggers', bw and ('Red, blue and yellow procs  \194\183  Blue window: ' .. title_case(bw)) or 'Red, blue and yellow procs'
    end
    local cur = sub_current(key)
    for _, it in ipairs(MENU) do
        if it.key == key then
            for _, sb in ipairs(subs_for(key)) do
                if sb[1] == cur then return it.label, sb[2] .. '  \194\183  ' .. (sb[6] or '') end
            end
            return it.label, nil
        end
    end
    return 'Abyhub', nil
end

local function search_input(id, x, y, w, h, buf, hint)
    rfill(x, y, w, h, col(P.box), 8)
    local cx, cy = imgui.GetCursorScreenPos()
    imgui.SetCursorScreenPos({ x, y })
    imgui.PushStyleColor(ImGuiCol_FrameBg, { 0, 0, 0, 0 })
    imgui.PushStyleColor(ImGuiCol_FrameBgHovered, { 0, 0, 0, 0 })
    imgui.PushStyleColor(ImGuiCol_FrameBgActive, { 0, 0, 0, 0 })
    imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 34, math.max(2, (h - 18) * 0.5) })
    imgui.PushItemWidth(w)
    imgui.InputText(id, buf, 64)
    local active = imgui.IsItemActive()
    imgui.PopItemWidth()
    imgui.PopStyleVar(1)
    imgui.PopStyleColor(3)
    imgui.SetCursorScreenPos({ cx, cy })
    rline(x, y, w, h, col(active and P.cyan or P.border, active and 0.8 or nil), 8, 1)
    ICON.search(x + 17, y + h * 0.5, (active or (buf[1] or '') ~= '') and P.cyan or P.muted)
    if (buf[1] or '') == '' and not active then tx('body', 15, x + 34, y + (h - 20) * 0.5, P.faint, hint) end
    return active
end

local function draw_content(x, y, w, h)
    -- the content card
    rfill(x, y, w, h, col(P.content), 12)
    rline(x, y, w, h, col(P.border), 12, 1)
    local pad = 22
    local title, sub = view_title()
    tx('semi', 26, x + pad, y + 18, P.text, title)
    if sub then tx('body', 14, x + pad, y + 54, P.muted, fit('body', 14, sub, w - pad * 2 - 40)) end

    -- close
    local bs = 28
    local bx, by = x + w - pad - bs + 6, y + 18
    local closed, chov = hit('##side_close', bx, by, bs, bs)
    if closed then C.close() end
    if chov then rfill(bx, by, bs, bs, col(P.hover), 8) end
    local m, cc = 9, col(chov and P.text or P.muted)
    line(bx + m, by + m, bx + bs - m, by + bs - m, cc, 1.5)
    line(bx + bs - m, by + m, bx + m, by + bs - m, cc, 1.5)

    local top = y + 86
    rfill(x + pad, top - 8, w - pad * 2, 1, col(P.line))
    local cw_avail = w - pad * 2 + 16
    imgui.SetCursorScreenPos({ x + pad - 8, top })
    imgui.PushStyleColor(ImGuiCol_ChildBg, { 0, 0, 0, 0 })
    imgui.BeginChild('##side_content', { cw_avail, y + h - 12 - top }, false)
    local pushed = C.push_classic_font()
    local cw = math.max(C.content_width(), cw_avail - 24)
    if M.view == 'search' then
        imgui.Dummy({ 1, 48 })
        local sx, sy = imgui.GetCursorScreenPos()
        search_input('##side_search', sx, sy - 46, math.min(560, cw_avail - 40), 34, C.state.search, 'Search key items, atma, NMs, Empyrean gear...')
        if (C.state.search[1] or ''):find('%S') then C.render_search(cw) else
            tx('body', 15, sx, sy + 6, P.muted, 'Type to search everything abyhub knows.')
        end
    else
        C.render_tab(C.state.tab, cw)
    end
    C.pop_classic_font(pushed)
    imgui.EndChild()
    imgui.PopStyleColor(1)
end

---------------------------------------------------------------------------- entry
function M.setup(ctx) C = ctx end

M.DEFAULT_W, M.DEFAULT_H = 1500, 940
M.MIN_W, M.MIN_H = 1100, 720

-- Draws the window into the current ImGui window (call between Begin / End).
function M.render()
    -- a search result that jumps to a tab switches the window to it
    if M.view == 'search' and ui.last_tab and C.state.tab ~= ui.last_tab and not (C.state.search[1] or ''):find('%S') then
        M.view = 'tab'
    end
    ui.last_tab = C.state.tab

    local x, y = imgui.GetWindowPos()
    local w, h = imgui.GetWindowSize()
    rfill(x, y, w, h, col(P.win), 12)
    rline(x, y, w, h, col(P.border), 12, 1)

    local sw = M.side_w()
    local icon_hover = false
    if ui.collapsed then icon_hover = draw_rail(x, y, sw, h) else draw_sidebar(x, y, sw, h); ui.fly = nil end
    draw_content(x + sw + 12, y + 12, w - sw - 24, h - 24)

    -- keep the window's content size equal to the window (no scrollbars)
    imgui.SetCursorScreenPos({ x, y })
    imgui.Dummy({ w - 1, h - 1 })

    if ui.collapsed then draw_flyout(icon_hover) end
end

return M
