-- abyhub theme: shared drawing helpers (navy panels, glowing blue chamfered
-- frames, diamond markers, tab strips). Used by abyhub.lua and abyempy.lua.
local imgui = require('imgui')

-- Palette: deep navy panels, glowing blue edges, gold for owned / ready.
local HUD = {
    accent      = { 0.42, 0.72, 1.00, 1.00 },   -- blue: links, inactive tabs, headings
    accent2     = { 0.62, 0.84, 1.00, 1.00 },
    lavender    = { 0.58, 0.82, 1.00, 1.00 },   -- titles (ice blue in this theme)
    text        = { 0.90, 0.94, 1.00, 1.00 },
    subtext     = { 0.70, 0.79, 0.94, 1.00 },
    muted       = { 0.50, 0.60, 0.78, 1.00 },
    faint       = { 0.32, 0.40, 0.58, 1.00 },
    owned       = { 0.42, 0.95, 0.58, 1.00 },
    warn        = { 1.00, 0.68, 0.28, 1.00 },
    bad         = { 1.00, 0.38, 0.32, 1.00 },
    gold        = { 1.00, 0.80, 0.32, 1.00 },
    yellow      = { 1.00, 0.87, 0.40, 1.00 },
    red         = { 1.00, 0.38, 0.32, 1.00 },
    blue        = { 0.40, 0.66, 1.00, 1.00 },
    purple      = { 0.74, 0.56, 1.00, 1.00 },
    edge        = { 0.20, 0.52, 1.00, 1.00 },   -- frame line
    edge_hi     = { 0.42, 0.76, 1.00, 1.00 },   -- active frame line
    glow        = { 0.16, 0.50, 1.00, 1.00 },
    window_bg   = { 0.010, 0.030, 0.080, 0.97 },
    header_bg   = { 0.018, 0.050, 0.130, 1.00 },
    card        = { 0.016, 0.042, 0.110, 0.98 },
    inset       = { 0.010, 0.028, 0.080, 1.00 },
    sel_fill    = { 0.05, 0.17, 0.42, 1.00 },
    card_line   = { 0.20, 0.52, 1.00, 0.45 },
    row_line    = { 0.30, 0.55, 1.00, 0.16 },
    track       = { 0.40, 0.62, 1.00, 0.12 },
}

local ui = { h = {} }   -- shared layout state (panel heights, content width)

local CORNERS_ALL = ImDrawFlags_RoundCornersAll or ImDrawCornerFlags_All or 15

local function rgba(c, a) return { c[1], c[2], c[3], a or c[4] } end
local function col(c, a) return imgui.GetColorU32(rgba(c, a)) end
local function pulse(speed) return (math.sin(os.clock() * (speed or 3.0)) + 1.0) * 0.5 end
local function line_h() return tonumber(imgui.GetTextLineHeight()) or 13 end
local function text_w(s) return tonumber((imgui.CalcTextSize(s))) or 0 end
local function DL() return imgui.GetWindowDrawList() end

local function text(x, y, c, s, scale)
    local dl = DL()
    if scale and scale ~= 1 and type(imgui.GetFont) == 'function' and type(imgui.GetFontSize) == 'function' then
        local ok = pcall(function() dl:AddText(imgui.GetFont(), imgui.GetFontSize() * scale, { x, y }, col(c), s) end)
        if ok then return end
    end
    dl:AddText({ x, y }, col(c), s)
end

-- Right-aligned text ending at x.
local function rtext(x, y, c, s) text(x - text_w(s), y, c, s) end

-- Shorten s with a trailing '.' until it fits in w.
local function fit(s, w)
    if text_w(s) <= w then return s end
    while #s > 2 and text_w(s .. '.') > w do s = s:sub(1, -2) end
    return s .. '.'
end

local function dot(cx, cy, r, c, glow)
    local dl = DL()
    if glow and glow > 0 then
        dl:AddCircleFilled({ cx, cy }, r * 2.4, col(c, 0.10 * glow), 20)
        dl:AddCircleFilled({ cx, cy }, r * 1.6, col(c, 0.22 * glow), 20)
    end
    dl:AddCircleFilled({ cx, cy }, r, col(c), 16)
end

-- Diamond marker. filled: solid; otherwise outline with a small core.
local function diamond(cx, cy, r, c, filled, glow)
    local dl = DL()
    local t, rt, b, l = { cx, cy - r }, { cx + r, cy }, { cx, cy + r }, { cx - r, cy }
    if glow and glow > 0 then
        local g = r * 1.9
        dl:AddTriangleFilled({ cx, cy - g }, { cx + g, cy }, { cx, cy + g }, col(c, 0.10 * glow))
        dl:AddTriangleFilled({ cx, cy - g }, { cx, cy + g }, { cx - g, cy }, col(c, 0.10 * glow))
    end
    if filled then
        dl:AddTriangleFilled(t, rt, b, col(c))
        dl:AddTriangleFilled(t, b, l, col(c))
    else
        dl:AddLine(t, rt, col(c), 1.3); dl:AddLine(rt, b, col(c), 1.3)
        dl:AddLine(b, l, col(c), 1.3); dl:AddLine(l, t, col(c), 1.3)
        local k = r * 0.38
        dl:AddTriangleFilled({ cx, cy - k }, { cx + k, cy }, { cx, cy + k }, col(c, 0.85))
        dl:AddTriangleFilled({ cx, cy - k }, { cx, cy + k }, { cx - k, cy }, col(c, 0.85))
    end
end

-- Chamfered (cut-corner) box: fill, soft outer glow, crisp edge.
local function chamfer_pts(x, y, w, h, k)
    return {
        { x + k, y }, { x + w - k, y }, { x + w, y + k }, { x + w, y + h - k },
        { x + w - k, y + h }, { x + k, y + h }, { x, y + h - k }, { x, y + k },
    }
end

local function chamfer_fill(x, y, w, h, k, c)
    local dl = DL()
    dl:AddRectFilled({ x + k, y }, { x + w - k, y + h }, c)
    dl:AddRectFilled({ x, y + k }, { x + k, y + h - k }, c)
    dl:AddRectFilled({ x + w - k, y + k }, { x + w, y + h - k }, c)
    dl:AddTriangleFilled({ x + k, y }, { x + k, y + k }, { x, y + k }, c)
    dl:AddTriangleFilled({ x + w - k, y }, { x + w, y + k }, { x + w - k, y + k }, c)
    dl:AddTriangleFilled({ x, y + h - k }, { x + k, y + h - k }, { x + k, y + h }, c)
    dl:AddTriangleFilled({ x + w, y + h - k }, { x + w - k, y + h }, { x + w - k, y + h - k }, c)
end

local function chamfer_line(x, y, w, h, k, c, t)
    local dl = DL()
    local p = chamfer_pts(x, y, w, h, k)
    for i = 1, 8 do dl:AddLine(p[i], p[i % 8 + 1], c, t) end
end

-- opts: k (corner cut), fill, edge, glow (0..1), active
local function frame(x, y, w, h, opts)
    opts = opts or {}
    local k = opts.k or 6
    local e = opts.edge or HUD.edge
    if opts.fill ~= false then chamfer_fill(x, y, w, h, k, col(opts.fill or HUD.card)) end
    local g = opts.glow or 0.6
    if g > 0 then
        chamfer_line(x - 1.5, y - 1.5, w + 3, h + 3, k + 1, col(HUD.glow, 0.10 * g), 4)
        chamfer_line(x, y, w, h, k, col(HUD.glow, 0.22 * g), 2.6)
    end
    chamfer_line(x, y, w, h, k, col(e, opts.alpha or 0.85), 1.2)
end

-- Tag (status pill): small chamfered outline box.
local function pill_w(s) return text_w(s) + 18 end

local function pill(x, y, s, c, fill)
    local w, h = pill_w(s), line_h() + 6
    local top = y - 3
    frame(x, top, w, h, { k = 4, fill = rgba(c, fill or 0.10), edge = c, glow = 0.3, alpha = 0.7 })
    text(x + 9, y, c, s)
    return w
end

local function bar(x, y, w, h, frac, c)
    local dl = DL()
    frac = math.max(0, math.min(1, frac))
    dl:AddRectFilled({ x, y }, { x + w, y + h }, col(HUD.track), h * 0.5)
    if frac > 0 then
        dl:AddRectFilled({ x, y }, { x + math.max(h, w * frac), y + h }, col(c, 0.9), h * 0.5)
    end
end

local function card_bg(x, y, w, h, accent, strength)
    local s = strength or 1
    frame(x, y, w, h, { fill = HUD.card, edge = accent and HUD.edge_hi or HUD.edge,
        glow = accent and 0.7 * s or 0.35, alpha = accent and 0.55 + 0.35 * s or 0.6 })
    if accent then
        DL():AddRectFilledMultiColor({ x + 2, y + 7 }, { x + w * 0.55, y + h - 7 },
            col(accent, 0.06 * s), col(accent, 0), col(accent, 0), col(accent, 0.02 * s))
    end
end

-- Card title: diamond, title, optional subtitle, optional right text.
local function card_title(x, y, w, c, title, sub, right, right_col)
    local lh = line_h()
    diamond(x + 6, y + lh * 0.5, 5, c, false)
    text(x + 18, y, c, title)
    if sub then text(x + 18 + text_w(title) + 12, y, HUD.muted, sub) end
    if right then text(x + w - text_w(right), y, right_col or HUD.faint, right) end
end

-- Thin horizontal rule with fading ends.
local function rule(x, y, w, c, a)
    DL():AddRectFilledMultiColor({ x, y }, { x + w * 0.5, y + 1 }, col(c, 0), col(c, a or 0.6), col(c, a or 0.6), col(c, 0))
    DL():AddRectFilledMultiColor({ x + w * 0.5, y }, { x + w, y + 1 }, col(c, a or 0.6), col(c, 0), col(c, 0), col(c, a or 0.6))
end

local function hit(id, x, y, w, h)
    local cx, cy = imgui.GetCursorScreenPos()
    imgui.SetCursorScreenPos({ x, y })
    local clicked = imgui.InvisibleButton(id, { w, h })
    local hov = imgui.IsItemHovered()
    if hov then imgui.SetMouseCursor(ImGuiMouseCursor_Hand) end
    imgui.SetCursorScreenPos({ cx, cy })
    return clicked, hov
end

local function advance(w, h) imgui.Dummy({ w, h }) end

ui.cw = ui.cw or 760
ui.left_x = ui.left_x or 0
ui.inset = 4   -- keeps panel edges off the window's clip line
local function avail_w()
    local cx = imgui.GetCursorScreenPos()
    return ui.cw - (cx - ui.left_x) - ui.inset
end

-- Start a window's content: reserve the full width, then step in by ui.inset
-- so frames and their glow aren't half-clipped at the window edge.
local function begin_content(cw)
    local x, y = imgui.GetCursorScreenPos()
    ui.left_x, ui.cw = x, cw
    imgui.Dummy({ cw, 0 })
    imgui.SetCursorScreenPos({ x + ui.inset, y + ui.inset })
end

-- Finish a window's content: room below the last panel for its bottom edge.
local function end_content()
    imgui.Dummy({ 0, ui.inset })
end

-- Tab strip. items = { { key, label, badge, badge_col }, ... }
-- Active item: framed, filled, glowing. Others: blue text.
-- opts.width stretches the strip to that width; opts.dividers draws separators.
local function seg_item_w(t, pad) return text_w(t[2]) + (t[3] and (text_w(t[3]) + 8) or 0) + (t[5] and 14 or 0) + pad * 2 end

local function seg_tabs(id, items, active, x, y, color, small, opts)
    opts = opts or {}
    local dl = DL()
    local lh = line_h()
    local th = lh + (small and 10 or 12)
    local pad = small and 10 or 13
    local gap = opts.dividers and 0 or 6
    local extra = 0
    if opts.width then
        local natural = 0
        for _, t in ipairs(items) do natural = natural + seg_item_w(t, pad) end
        natural = natural + gap * (#items - 1)
        extra = math.max(0, (opts.width - natural) / #items)
    end
    local tx = x
    local clicked_key = nil
    for i, t in ipairs(items) do
        local key, label, badge = t[1], t[2], t[3]
        local on = active == key
        local tw = seg_item_w(t, pad) + extra
        local clicked, hov = hit(('##%s_%s'):format(id, tostring(key)), tx, y, tw, th)
        if clicked then clicked_key = key end
        if on then
            frame(tx, y, tw, th, { k = 5, fill = HUD.sel_fill, edge = HUD.edge_hi, glow = 1.0, alpha = 1.0 })
        elseif hov then
            frame(tx, y, tw, th, { k = 5, fill = rgba(HUD.sel_fill, 0.45), edge = HUD.edge, glow = 0, alpha = 0.35 })
        end
        if opts.dividers and i > 1 and not on and active ~= items[i - 1][1] then
            dl:AddLine({ tx, y + 5 }, { tx, y + th - 5 }, col(HUD.edge, 0.35), 1)
        end
        local light = t[5]
        local cw = text_w(label) + (badge and (text_w(badge) + 8) or 0) + (light and 14 or 0)
        local lx = tx + (tw - cw) * 0.5
        local ty = y + (th - lh) * 0.5
        if light then
            dot(lx + 4, ty + lh * 0.5, 3.5, light, 0.6 + pulse(2) * 0.4)
            lx = lx + 14
        end
        text(lx, ty, on and HUD.text or (hov and HUD.accent2 or HUD.accent), label)
        if badge then
            text(lx + text_w(label) + 8, ty, t[4] or (on and HUD.text or HUD.accent2), badge)
        end
        tx = tx + tw + gap
    end
    return clicked_key, tx - x - gap, th
end

local function seg_width(items, small)
    local pad = small and 10 or 13
    local w = 0
    for _, t in ipairs(items) do w = w + seg_item_w(t, pad) + 6 end
    return w - 6
end

local function toggle_chip(id, label, on, x, y, c)
    local dl = DL()
    local lh = line_h()
    local w, h = text_w(label) + 34, lh + 10
    local clicked, hov = hit(id, x, y, w, h)
    frame(x, y, w, h, { k = 5, fill = on and HUD.sel_fill or rgba(HUD.sel_fill, hov and 0.4 or 0.2),
        edge = on and HUD.edge_hi or HUD.edge, glow = on and 0.8 or 0, alpha = on and 1 or 0.5 })
    diamond(x + 13, y + h * 0.5, 4.5, on and c or HUD.muted, on)
    text(x + 24, y + 5, on and HUD.text or (hov and HUD.subtext or HUD.muted), label)
    return clicked, w
end

-- Panel wrapper: background sized from last frame's measurement.
local function panel(id, accent, draw_fn, strength)
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()
    local h = ui.h[id] or 120
    card_bg(x, y, w, h, accent, strength or 0.9)
    local content_h = draw_fn(x + 14, y + 11, w - 28)
    ui.h[id] = content_h + 22
    advance(w, h)
    imgui.Dummy({ 0, 2 })
end

-- Framed band holding one row of controls; draw_fn(x, y, w) returns its height.
local function band(id, draw_fn)
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()
    local h = ui.h[id] or 40
    frame(x, y, w, h, { fill = HUD.header_bg, glow = 0.5 })
    local ch = draw_fn(x + 8, y + 6, w - 16)
    ui.h[id] = ch + 12
    advance(w, h)
    imgui.Dummy({ 0, 2 })
end


-- "EMPYREAN TOOLKIT" in small caps: first letter of each word larger.
local TITLE_BIG, TITLE_SMALL = 1.55, 1.18
local function title_w(s)
    local w = 0
    for word in s:gmatch('%S+') do
        w = w + text_w(word:sub(1, 1)) * TITLE_BIG + text_w(word:sub(2)) * TITLE_SMALL + text_w(' ') * TITLE_SMALL * 1.4
    end
    return w - text_w(' ') * TITLE_SMALL * 1.4
end

local function title_text(x, y, h, s, c)
    local lh = line_h()
    local base = y + (h + lh * TITLE_BIG) * 0.5   -- shared baseline
    for word in s:gmatch('%S+') do
        local a, rest = word:sub(1, 1), word:sub(2)
        text(x, base - lh * TITLE_BIG * 0.92, c, a, TITLE_BIG)
        x = x + text_w(a) * TITLE_BIG
        text(x, base - lh * TITLE_SMALL * 0.92, c, rest, TITLE_SMALL)
        x = x + text_w(rest) * TITLE_SMALL + text_w(' ') * TITLE_SMALL * 1.4
    end
end

-- Logo: a framed diamond with a smaller solid one inside.
local function logo(cx, cy, r)
    diamond(cx, cy, r, HUD.edge_hi, false, 0.8 + pulse(1.5) * 0.4)
    diamond(cx, cy, r * 0.45, HUD.lavender, true)
end

-- Returns true when clicked.
local function close_button(x, y, s)
    local dl = DL()
    local clicked, hov = hit('##aby_close', x, y, s, s)
    if hov then frame(x, y, s, s, { k = 4, fill = HUD.sel_fill, edge = HUD.edge_hi, glow = 0.6 }) end
    local m, c = s * 0.3, hov and HUD.text or HUD.subtext
    dl:AddLine({ x + m, y + m }, { x + s - m, y + s - m }, col(c), 1.6)
    dl:AddLine({ x + s - m, y + m }, { x + m, y + s - m }, col(c), 1.6)
    return clicked
end


-- Outer window: navy fill, glowing chamfered double edge, diamond studs.
local function draw_window_frame()
    local wx, wy = imgui.GetWindowPos()
    local ww, wh = imgui.GetWindowSize()
    local x, y, w, h, k = wx + 2, wy + 2, ww - 4, wh - 4, 12
    -- ImGui clips the window draw list to the padded inner area; widen it so the
    -- outer edge and glow aren't cut off.
    local dl = DL()
    dl:PushClipRect({ wx, wy }, { wx + ww, wy + wh }, false)
    frame(x, y, w, h, { k = k, fill = HUD.window_bg, edge = HUD.edge_hi, glow = 1.0, alpha = 0.9 })
    chamfer_line(x + 4, y + 4, w - 8, h - 8, k - 2, col(HUD.edge, 0.30), 1)
    for _, p in ipairs({ { x + k * 0.5, y + k * 0.5 }, { x + w - k * 0.5, y + k * 0.5 },
                         { x + k * 0.5, y + h - k * 0.5 }, { x + w - k * 0.5, y + h - k * 0.5 } }) do
        diamond(p[1], p[2], 3.5, HUD.edge_hi, true, 0.6)
    end
    dl:PopClipRect()
end

-- Rounded outline pill with a glowing dot (job / clock). Returns clicked, hovered, width.
local function dot_pill(id, x, y, label, c, label2, c2, glowing)
    local dl = DL()
    local lh = line_h()
    local w = text_w(label) + (label2 and (text_w(label2) + 8) or 0) + 36
    local h = lh + 10
    local clicked, hov = false, false
    if id then clicked, hov = hit(id, x, y, w, h) end
    dl:AddRectFilled({ x, y }, { x + w, y + h }, col(c, hov and 0.16 or 0.07), h * 0.5)
    dl:AddRect({ x - 1, y - 1 }, { x + w + 1, y + h + 1 }, col(c, 0.15), h * 0.5, CORNERS_ALL, 3)
    dl:AddRect({ x, y }, { x + w, y + h }, col(c, 0.8), h * 0.5, CORNERS_ALL, 1.2)
    dot(x + 14, y + h * 0.5, 3, c, glowing and (0.4 + pulse(2) * 0.6) or 0)
    text(x + 24, y + 5, label2 and HUD.text or c, label)
    if label2 then text(x + 24 + text_w(label) + 8, y + 5, c2 or c, label2) end
    return clicked, hov, w
end

local function dot_pill_w(label, label2)
    return text_w(label) + (label2 and (text_w(label2) + 8) or 0) + 36
end

local function push_style()
    imgui.PushStyleColor(ImGuiCol_WindowBg, { 0, 0, 0, 0 })      -- frame is drawn by draw_window_frame
    imgui.PushStyleColor(ImGuiCol_Border, { 0, 0, 0, 0 })
    imgui.PushStyleColor(ImGuiCol_Text, HUD.text)
    imgui.PushStyleColor(ImGuiCol_ScrollbarBg, { 0, 0, 0, 0 })
    imgui.PushStyleColor(ImGuiCol_ScrollbarGrab, rgba(HUD.edge, 0.30))
    imgui.PushStyleColor(ImGuiCol_ScrollbarGrabHovered, rgba(HUD.edge, 0.50))
    imgui.PushStyleColor(ImGuiCol_ScrollbarGrabActive, rgba(HUD.edge_hi, 0.70))
    imgui.PushStyleColor(ImGuiCol_ResizeGrip, rgba(HUD.edge, 0.12))
    imgui.PushStyleColor(ImGuiCol_ResizeGripHovered, rgba(HUD.edge, 0.35))
    imgui.PushStyleColor(ImGuiCol_ResizeGripActive, rgba(HUD.edge_hi, 0.60))
    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0)
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0)
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 14, 12 })
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 6, 5 })
    imgui.PushStyleVar(ImGuiStyleVar_ScrollbarSize, 8.0)
    imgui.PushStyleVar(ImGuiStyleVar_ScrollbarRounding, 6.0)
end

local function pop_style()
    imgui.PopStyleVar(6)
    imgui.PopStyleColor(10)
end

return {
    HUD = HUD, ui = ui, CORNERS_ALL = CORNERS_ALL,
    rgba = rgba, col = col, pulse = pulse, line_h = line_h, text_w = text_w, DL = DL,
    text = text, rtext = rtext, fit = fit, dot = dot, diamond = diamond,
    chamfer_fill = chamfer_fill, chamfer_line = chamfer_line, frame = frame,
    pill_w = pill_w, pill = pill, bar = bar, card_bg = card_bg, card_title = card_title, rule = rule,
    hit = hit, advance = advance, avail_w = avail_w, begin_content = begin_content, end_content = end_content,
    seg_tabs = seg_tabs, seg_width = seg_width, toggle_chip = toggle_chip, panel = panel, band = band,
    title_w = title_w, title_text = title_text, logo = logo, close_button = close_button,
    draw_window_frame = draw_window_frame, dot_pill = dot_pill, dot_pill_w = dot_pill_w,
    push_style = push_style, pop_style = pop_style,
}
