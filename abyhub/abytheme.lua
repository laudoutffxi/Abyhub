-- abyhub theme: shared drawing helpers. Dark fantasy look: near-black starry
-- window, steel-blue cards, thin gold borders, gold buttons and diamond
-- ornaments. Used by abyhub.lua and abyempy.lua.
local imgui = require('imgui')

-- Base palette.
local C = {
    bg        = { 0.030, 0.035, 0.055, 1.00 },   -- window, bottom
    bg_top    = { 0.060, 0.075, 0.115, 1.00 },   -- window, top (gradient)
    card      = { 0.090, 0.115, 0.180, 0.96 },   -- steel-blue card, top
    card_lo   = { 0.050, 0.065, 0.105, 0.96 },   -- card, bottom
    inset     = { 0.035, 0.045, 0.075, 1.00 },
    frame     = { 0.120, 0.135, 0.190, 1.00 },
    gold      = { 0.86, 0.70, 0.42, 1.00 },
    gold_hi   = { 1.00, 0.88, 0.62, 1.00 },
    gold_lo   = { 0.52, 0.39, 0.20, 1.00 },
    steel     = { 0.40, 0.55, 0.82, 1.00 },      -- "Details" blue
    text      = { 0.93, 0.91, 0.86, 1.00 },      -- warm white
    muted     = { 0.58, 0.60, 0.66, 1.00 },
    ink       = { 0.13, 0.09, 0.04, 1.00 },      -- text on gold buttons
}

-- Names the rest of the addon uses.
local HUD = {
    accent      = C.gold,                         -- gold: headings, selection
    accent2     = { 0.95, 0.82, 0.56, 1.00 },
    lavender    = { 0.96, 0.87, 0.66, 1.00 },     -- titles: pale gold
    text        = C.text,
    subtext     = { 0.76, 0.76, 0.78, 1.00 },
    muted       = C.muted,
    faint       = { 0.38, 0.40, 0.46, 1.00 },
    owned       = { 0.45, 0.88, 0.55, 1.00 },
    warn        = { 1.00, 0.66, 0.30, 1.00 },
    bad         = { 1.00, 0.42, 0.38, 1.00 },
    gold        = C.gold_hi,
    yellow      = { 1.00, 0.86, 0.45, 1.00 },
    red         = { 1.00, 0.42, 0.38, 1.00 },
    blue        = { 0.48, 0.68, 1.00, 1.00 },
    purple      = { 0.74, 0.54, 1.00, 1.00 },
    edge        = C.gold,                         -- border colour (drawn at low alpha)
    edge_hi     = C.gold_hi,
    glow        = C.gold,
    window_bg   = C.bg,
    header_bg   = C.inset,
    card        = C.card,
    inset       = C.inset,
    frame       = C.frame,
    sel_fill    = { 0.24, 0.19, 0.11, 1.00 },     -- warm dark gold
    card_line   = { 0.86, 0.70, 0.42, 0.22 },
    row_line    = { 0.86, 0.70, 0.42, 0.10 },
    track       = { 1.00, 1.00, 1.00, 0.07 },
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

-- Status dot. glow > 0 adds a soft halo (used for "in progress" states).
local function dot(cx, cy, r, c, glow)
    local dl = DL()
    if glow and glow > 0 then
        dl:AddCircleFilled({ cx, cy }, r * 2.1, col(c, 0.14 * glow), 20)
    end
    dl:AddCircleFilled({ cx, cy }, r, col(c), 16)
end

-- Diamond (rhombus) marker. filled: solid; otherwise an outline with a small core.
local function diamond(cx, cy, r, c, filled, glow)
    local dl = DL()
    if glow and glow > 0 then
        local g = r * 1.7
        dl:AddQuadFilled({ cx, cy - g }, { cx + g, cy }, { cx, cy + g }, { cx - g, cy }, col(c, 0.14 * glow))
    end
    local t, rt, b, l = { cx, cy - r }, { cx + r, cy }, { cx, cy + r }, { cx - r, cy }
    if filled then
        dl:AddQuadFilled(t, rt, b, l, col(c))
    else
        dl:AddQuad(t, rt, b, l, col(c, 0.9), 1.3)
        local k = r * 0.35
        dl:AddQuadFilled({ cx, cy - k }, { cx + k, cy }, { cx, cy + k }, { cx - k, cy }, col(c, 0.9))
    end
end

-- Thin gold line that fades out at both ends, with a small diamond in the middle.
local function ornament(x, y, w, a)
    local dl = DL()
    a = a or 0.6
    local mid = x + w * 0.5
    dl:AddRectFilledMultiColor({ x, y }, { mid, y + 1 }, col(C.gold, 0), col(C.gold, a), col(C.gold, a), col(C.gold, 0))
    dl:AddRectFilledMultiColor({ mid, y }, { x + w, y + 1 }, col(C.gold, a), col(C.gold, 0), col(C.gold, 0), col(C.gold, a))
    diamond(mid, y + 0.5, 3.5, C.gold_hi, true)
end

-- Rounded box helpers (the old chamfer names stay so nothing else has to change).
-- k is the corner radius; c is an already-converted colour.
local function chamfer_fill(x, y, w, h, k, c)
    DL():AddRectFilled({ x, y }, { x + w, y + h }, c, k, CORNERS_ALL)
end

local function chamfer_line(x, y, w, h, k, c, t)
    DL():AddRect({ x, y }, { x + w, y + h }, c, k, CORNERS_ALL, t or 1)
end

-- opts: k (corner radius-ish), fill (colour or false), edge (border colour), alpha (border strength)
local function frame(x, y, w, h, opts)
    opts = opts or {}
    local r = math.min(opts.k or 4, 4)
    if opts.fill ~= false then chamfer_fill(x, y, w, h, r, col(opts.fill or HUD.inset)) end
    local e = opts.edge or HUD.edge
    local a = opts.alpha or 0.85
    chamfer_line(x + 0.5, y + 0.5, w - 1, h - 1, r, col(e, 0.28 * a / 0.85), 1)
end

-- Tag: small dark plate with a coloured border and text (like a rarity tag).
local function pill_w(s) return text_w(s) + 16 end

local function pill(x, y, s, c, fill)
    local w, h = pill_w(s), line_h() + 6
    local top = y - 3
    local dl = DL()
    dl:AddRectFilled({ x, top }, { x + w, top + h }, col(C.inset, 0.9), 3)
    dl:AddRectFilled({ x, top }, { x + w, top + h }, col(c, (fill or 0.10) * 0.8), 3)
    dl:AddRect({ x + 0.5, top + 0.5 }, { x + w - 0.5, top + h - 0.5 }, col(c, 0.55), 3, CORNERS_ALL, 1)
    text(x + 8, y, c, s)
    return w
end

-- Progress bar: dark track, colour fill with a lighter top edge.
local function bar(x, y, w, h, frac, c)
    local dl = DL()
    frac = math.max(0, math.min(1, frac))
    dl:AddRectFilled({ x, y }, { x + w, y + h }, col(HUD.track), h * 0.5)
    if frac > 0 then
        local fx = x + math.max(h, w * frac)
        dl:AddRectFilled({ x, y }, { fx, y + h }, col(c, 0.9), h * 0.5)
        if h >= 3 then dl:AddRectFilled({ x + 1, y }, { fx - 1, y + 1 }, col({ 1, 1, 1, 1 }, 0.25)) end
    end
end

-- Card: steel-blue gradient with a thin gold border; an accent recolours the
-- border (green when complete, tier colour when owned).
local function card_bg(x, y, w, h, accent, strength)
    local s = strength or 1
    local dl = DL()
    dl:AddRectFilledMultiColor({ x, y }, { x + w, y + h }, col(C.card), col(C.card), col(C.card_lo), col(C.card_lo))
    if accent then
        chamfer_line(x + 0.5, y + 0.5, w - 1, h - 1, 3, col(accent, 0.30 + 0.30 * s), 1)
    else
        chamfer_line(x + 0.5, y + 0.5, w - 1, h - 1, 3, col(HUD.card_line), 1)
    end
    -- faint highlight along the top edge
    dl:AddRectFilled({ x + 2, y + 1 }, { x + w - 2, y + 2 }, col({ 1, 1, 1, 1 }, 0.05))
end

-- Card title: title, muted subtitle, optional right text.
local function card_title(x, y, w, c, title, sub, right, right_col)
    text(x, y, c, title)
    if sub then text(x + text_w(title) + 10, y, HUD.muted, sub) end
    if right then text(x + w - text_w(right), y, right_col or HUD.faint, right) end
end

-- Divider: fading gold line.
local function rule(x, y, w, c, a)
    local dl = DL()
    local aa = 0.15 + 0.25 * (a or 0.6)
    local mid = x + w * 0.5
    dl:AddRectFilledMultiColor({ x, y }, { mid, y + 1 }, col(C.gold, 0), col(C.gold, aa), col(C.gold, aa), col(C.gold, 0))
    dl:AddRectFilledMultiColor({ mid, y }, { x + w, y + 1 }, col(C.gold, aa), col(C.gold, 0), col(C.gold, 0), col(C.gold, aa))
end

-- Clip drawing to a box. Ashita's renderer goes blank for the rest of the frame
-- if it's handed an empty clip rectangle, which is what ImGui produces when the
-- box is scrolled completely out of view. So only clip when the box is actually
-- inside the window; off-screen boxes are hidden by the window's own clipping.
-- Returns true if a clip rect was pushed (pass it to pop_clip).
local CLIP_MARGIN = 8
local function push_clip(x1, y1, x2, y2)
    local wx, wy = imgui.GetWindowPos()
    local ww, wh = imgui.GetWindowSize()
    wx, wy, ww, wh = tonumber(wx), tonumber(wy), tonumber(ww), tonumber(wh)
    if not (wx and wy and ww and wh) then return false end
    local ix1, iy1 = math.max(x1, wx + CLIP_MARGIN), math.max(y1, wy + CLIP_MARGIN)
    local ix2, iy2 = math.min(x2, wx + ww - CLIP_MARGIN), math.min(y2, wy + wh - CLIP_MARGIN)
    if ix2 - ix1 < 1 or iy2 - iy1 < 1 then return false end
    DL():PushClipRect({ x1, y1 }, { x2, y2 }, true)
    return true
end

local function pop_clip(pushed)
    if pushed then DL():PopClipRect() end
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

-- Start a window's content: reserve the full width, then step in by ui.inset.
local function begin_content(cw)
    local x, y = imgui.GetCursorScreenPos()
    ui.left_x, ui.cw = x, cw
    imgui.Dummy({ cw, 0 })
    imgui.SetCursorScreenPos({ x + ui.inset, y + ui.inset })
end

local function end_content()
    imgui.Dummy({ 0, ui.inset })
end

-- Tab row. items = { { key, label, badge, badge_col, light }, ... }
-- The selected tab is a gold button (dark text); the others are dark plates with
-- a faint gold edge. opts.width stretches the row to that width.
local SEG_PAD = 0
local SEG_GAP = 4
local function seg_item_w(t, pad) return text_w(t[2]) + (t[3] and (text_w(t[3]) + 8) or 0) + (t[5] and 14 or 0) + pad * 2 end

local function gold_button_bg(x, y, w, h, hov)
    local dl = DL()
    local top = hov and C.gold_hi or { 0.92, 0.78, 0.50, 1 }
    local bot = hov and C.gold or { 0.62, 0.47, 0.25, 1 }
    dl:AddRectFilledMultiColor({ x, y }, { x + w, y + h }, col(top), col(top), col(bot), col(bot))
    dl:AddRect({ x + 0.5, y + 0.5 }, { x + w - 0.5, y + h - 0.5 }, col(C.gold_hi, 0.9), 2, CORNERS_ALL, 1)
    dl:AddRectFilled({ x + 1, y + 1 }, { x + w - 1, y + 2 }, col({ 1, 1, 1, 1 }, 0.35))
end

local function seg_tabs(id, items, active, x, y, color, small, opts)
    opts = opts or {}
    local dl = DL()
    local lh = line_h()
    local ih = lh + (small and 8 or 10)
    local pad = small and 11 or 14
    local natural = 0
    for _, t in ipairs(items) do natural = natural + seg_item_w(t, pad) end
    natural = natural + SEG_GAP * (#items - 1)
    local extra = 0
    if opts.width then extra = math.max(0, (opts.width - natural) / #items) end
    local total = natural + extra * #items

    local tx = x
    local clicked_key = nil
    for i, t in ipairs(items) do
        local key, label, badge = t[1], t[2], t[3]
        local on = active == key
        local tw = seg_item_w(t, pad) + extra
        local clicked, hov = hit(('##%s_%s'):format(id, tostring(key)), tx, y, tw, ih)
        if clicked then clicked_key = key end
        if on then
            gold_button_bg(tx, y, tw, ih, hov)
        else
            dl:AddRectFilledMultiColor({ tx, y }, { tx + tw, y + ih },
                col(hov and C.frame or C.card), col(hov and C.frame or C.card), col(C.inset), col(C.inset))
            dl:AddRect({ tx + 0.5, y + 0.5 }, { tx + tw - 0.5, y + ih - 0.5 }, col(C.gold, hov and 0.45 or 0.22), 2, CORNERS_ALL, 1)
        end
        local light = t[5]
        local cw = text_w(label) + (badge and (text_w(badge) + 8) or 0) + (light and 14 or 0)
        local lx = tx + (tw - cw) * 0.5
        local ty = y + (ih - lh) * 0.5
        if light then
            dot(lx + 4, ty + lh * 0.5, 3.5, light, on and 0 or (0.4 + pulse(2) * 0.6))
            lx = lx + 14
        end
        text(lx, ty, on and C.ink or (hov and HUD.text or HUD.subtext), label)
        if badge then
            local bc = t[4] or (on and { 0.30, 0.20, 0.08, 1 } or HUD.accent)
            if on and t[4] then bc = { 0.25, 0.16, 0.06, 1 } end
            text(lx + text_w(label) + 8, ty, bc, badge)
        end
        tx = tx + tw + SEG_GAP
    end
    return clicked_key, total, ih
end

local function seg_width(items, small)
    local pad = small and 11 or 14
    local w = 0
    for _, t in ipairs(items) do w = w + seg_item_w(t, pad) end
    return w + SEG_GAP * (#items - 1)
end

-- Pill switch with a label to its right. Returns clicked, width.
local function toggle_w(label) return 34 + 8 + text_w(label) + 6 end

local function toggle_chip(id, label, on, x, y, c)
    local dl = DL()
    local lh = line_h()
    local h = lh + 10
    local sw, sh = 34, 18
    local w = toggle_w(label)
    local clicked, hov = hit(id, x, y, w, h)
    local sx, sy = x, y + (h - sh) * 0.5
    dl:AddRectFilled({ sx, sy }, { sx + sw, sy + sh }, on and col(C.gold_lo) or col(C.inset), sh * 0.5)
    dl:AddRect({ sx + 0.5, sy + 0.5 }, { sx + sw - 0.5, sy + sh - 0.5 }, col(C.gold, on and 0.9 or (hov and 0.5 or 0.3)), sh * 0.5, CORNERS_ALL, 1)
    local kr = sh * 0.5 - 3
    local kx = on and (sx + sw - sh * 0.5) or (sx + sh * 0.5)
    dl:AddCircleFilled({ kx, sy + sh * 0.5 }, kr, on and col(C.gold_hi) or col(HUD.muted), 16)
    text(sx + sw + 8, y + (h - lh) * 0.5, on and HUD.text or (hov and HUD.subtext or HUD.muted), label)
    return clicked, w
end

-- Panel wrapper: card sized from last frame's measurement.
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

-- Row of controls on the window background; draw_fn(x, y, w) returns its height.
-- opts.line draws a hairline under it (the header uses this).
local function band(id, draw_fn, opts)
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()
    local h = ui.h[id] or 40
    local ch = draw_fn(x + 2, y + 4, w - 4)
    ui.h[id] = ch + 8
    if opts and opts.line then
        ornament(x - ui.inset, y + h + 2, w + ui.inset * 2, 0.55)
        advance(w, h + 6)
    else
        advance(w, h)
    end
    imgui.Dummy({ 0, 2 })
end

-- Title: gold serif (Palatino / Georgia from the Windows Fonts folder), letter
-- spaced, with a small diamond either side. Falls back to the body font.
local TITLE_SCALE = 1.5
local title_font = nil
local TITLE_PX = 26

local function with_title_font(fn)
    local pushed = false
    if title_font ~= nil then
        if title_font.LegacySize ~= nil then pushed = pcall(imgui.PushFont, title_font, TITLE_PX)
        else pushed = pcall(imgui.PushFont, title_font) end
    end
    local ok, r = pcall(fn, pushed)
    if pushed then imgui.PopFont() end
    if not ok then error(r, 0) end
    return r
end

-- Letter-spaced words, drawn one by one so the word gap stays visible.
local function spaced(s) return (s:gsub('(.)', '%1 '):gsub(' $', '')) end
local function words(s) local t = {} for w in s:gmatch('%S+') do t[#t + 1] = spaced(w) end return t end

local function title_w(s)
    return with_title_font(function(pushed)
        local sc = pushed and 1 or TITLE_SCALE
        local w = 0
        for i, wd in ipairs(words(s)) do w = w + text_w(wd) * sc + (i > 1 and text_w('   ') * sc or 0) end
        return w + 32
    end)
end

local function title_text(x, y, h, s, c)
    with_title_font(function(pushed)
        local sc = pushed and 1 or TITLE_SCALE
        local lh = line_h()
        local ty = y + (h - lh * sc) * 0.5
        diamond(x + 6, y + h * 0.5, 5, C.gold, false)
        local tx = x + 18
        for i, wd in ipairs(words(s)) do
            if i > 1 then tx = tx + text_w('   ') * sc end
            text(tx + 1, ty + 1, { 0, 0, 0, 0.6 }, wd, sc)
            text(tx, ty, C.gold_hi, wd, sc)
            tx = tx + text_w(wd) * sc
        end
        diamond(tx + 12, y + h * 0.5, 5, C.gold, false)
    end)
end

-- No separate logo in this style (kept so callers don't break).
local function logo() end

-- Round gold-ringed close button. Returns true when clicked.
local function close_button(x, y, s)
    local dl = DL()
    local clicked, hov = hit('##aby_close', x, y, s, s)
    local cx, cy, r = x + s * 0.5, y + s * 0.5, s * 0.5
    dl:AddCircleFilled({ cx, cy }, r, col(hov and C.frame or C.inset), 24)
    dl:AddCircle({ cx, cy }, r - 0.5, col(C.gold, hov and 0.9 or 0.5), 24, 1.2)
    local m, c = s * 0.34, hov and C.gold_hi or C.gold
    dl:AddLine({ x + m, y + m }, { x + s - m, y + s - m }, col(c), 1.5)
    dl:AddLine({ x + s - m, y + m }, { x + m, y + s - m }, col(c), 1.5)
    return clicked
end

-- Window: dark gradient with faint stars, a gold double border and diamond
-- studs in the corners. Call right after Begin.
local STARS = {}
do
    local seed = 7
    local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
    for i = 1, 70 do STARS[i] = { rnd(), rnd(), 0.4 + rnd() * 0.9, 0.10 + rnd() * 0.35 } end
end

local function draw_window_frame()
    local wx, wy = imgui.GetWindowPos()
    local ww, wh = imgui.GetWindowSize()
    wx, wy, ww, wh = tonumber(wx), tonumber(wy), tonumber(ww), tonumber(wh)
    if not (wx and wy and ww and wh) then return end
    local dl = DL()
    dl:PushClipRect({ wx, wy }, { wx + ww, wy + wh }, false)
    dl:AddRectFilledMultiColor({ wx, wy }, { wx + ww, wy + wh }, col(C.bg_top), col(C.bg_top), col(C.bg), col(C.bg))
    for _, st in ipairs(STARS) do
        dl:AddCircleFilled({ wx + st[1] * ww, wy + st[2] * wh }, st[3], col({ 0.75, 0.82, 1.0, st[4] }), 6)
    end
    dl:AddRect({ wx + 1.5, wy + 1.5 }, { wx + ww - 1.5, wy + wh - 1.5 }, col(C.gold, 0.55), 4, CORNERS_ALL, 1)
    dl:AddRect({ wx + 5.5, wy + 5.5 }, { wx + ww - 5.5, wy + wh - 5.5 }, col(C.gold, 0.16), 3, CORNERS_ALL, 1)
    for _, p in ipairs({ { wx + 6, wy + 6 }, { wx + ww - 6, wy + 6 }, { wx + 6, wy + wh - 6 }, { wx + ww - 6, wy + wh - 6 } }) do
        diamond(p[1], p[2], 3.5, C.gold, true)
    end
    dl:PopClipRect()
end

-- Dark plate with a gold edge and a dot (clock / job). Returns clicked, hovered, width.
local function dot_pill(id, x, y, label, c, label2, c2, glowing)
    local dl = DL()
    local lh = line_h()
    local w = text_w(label) + (label2 and (text_w(label2) + 8) or 0) + 32
    local h = lh + 8
    local clicked, hov = false, false
    if id then clicked, hov = hit(id, x, y, w, h) end
    dl:AddRectFilledMultiColor({ x, y }, { x + w, y + h }, col(C.card), col(C.card), col(C.inset), col(C.inset))
    dl:AddRect({ x + 0.5, y + 0.5 }, { x + w - 0.5, y + h - 0.5 }, col(C.gold, hov and 0.7 or 0.4), 3, CORNERS_ALL, 1)
    diamond(x + 13, y + h * 0.5, 3.5, c, true, glowing and (0.3 + pulse(2) * 0.5) or 0)
    text(x + 22, y + (h - lh) * 0.5, label2 and HUD.text or c, label)
    if label2 then text(x + 22 + text_w(label) + 8, y + (h - lh) * 0.5, c2 or c, label2) end
    return clicked, hov, w
end

local function dot_pill_w(label, label2)
    return text_w(label) + (label2 and (text_w(label2) + 8) or 0) + 32
end

-- Segoe UI 17 (the font VanaCore / YunaGearOpt use). Windows ships it, so nothing is
-- bundled; if it can't be loaded the game's ImGui font is kept.
local font = nil
local function add_font(names, px)
    if type(imgui.AddFontFromFileTTF) ~= 'function' then return nil end
    local dir = (os.getenv('WINDIR') or 'C:\\Windows') .. '\\Fonts\\'
    for _, name in ipairs(names) do
        local f = io.open(dir .. name, 'rb')
        if f then
            f:close()
            local ok, fnt = pcall(imgui.AddFontFromFileTTF, dir .. name, px)
            if ok and fnt then return fnt end
        end
    end
    return nil
end

local function load_font()
    font = add_font({ 'segoeui.ttf', 'SegUIVar.ttf' }, 17)
    title_font = add_font({ 'palab.ttf', 'pala.ttf', 'georgiab.ttf', 'georgia.ttf' }, TITLE_PX)   -- serif for the title
end

-- Push the font; newer ImGui (fonts with LegacySize) wants a size. Returns true if pushed.
local function push_font()
    if font == nil then return false end
    local ok
    if font.LegacySize ~= nil then ok = pcall(imgui.PushFont, font, 17) else ok = pcall(imgui.PushFont, font) end
    return ok and true or false
end

local function pop_font(pushed)
    if pushed then imgui.PopFont() end
end

-- Pushed only when the ImGui build has the slot, and counted so pops always match.
local pushed_c, pushed_v = {}, {}
local function pc(idx, c) if idx ~= nil then imgui.PushStyleColor(idx, c); pushed_c[#pushed_c] = pushed_c[#pushed_c] + 1 end end
local function pv(idx, v) if idx ~= nil then imgui.PushStyleVar(idx, v); pushed_v[#pushed_v] = pushed_v[#pushed_v] + 1 end end

local function push_style()
    pushed_c[#pushed_c + 1], pushed_v[#pushed_v + 1] = 0, 0
    pc(ImGuiCol_WindowBg, C.bg)
    pc(ImGuiCol_Border, rgba(C.gold, 0.45))
    pc(ImGuiCol_Text, HUD.text)
    pc(ImGuiCol_PopupBg, { 0.040, 0.050, 0.080, 0.98 })
    pc(ImGuiCol_ScrollbarBg, { 0, 0, 0, 0 })
    pc(ImGuiCol_ScrollbarGrab, { 1, 1, 1, 0.08 })
    pc(ImGuiCol_ScrollbarGrabHovered, { 1, 1, 1, 0.16 })
    pc(ImGuiCol_ScrollbarGrabActive, { 1, 1, 1, 0.22 })
    pc(ImGuiCol_ResizeGrip, { 1, 1, 1, 0.06 })
    pc(ImGuiCol_ResizeGripHovered, rgba(C.gold, 0.55))
    pc(ImGuiCol_ResizeGripActive, rgba(C.gold, 0.85))
    pc(ImGuiCol_Button, { 1, 1, 1, 0.035 })
    pc(ImGuiCol_ButtonHovered, rgba(C.gold, 0.25))
    pc(ImGuiCol_ButtonActive, rgba(C.gold, 0.40))
    pc(ImGuiCol_Separator, HUD.row_line)
    pv(ImGuiStyleVar_WindowRounding, 4.0)
    pv(ImGuiStyleVar_WindowBorderSize, 1.0)
    pv(ImGuiStyleVar_WindowPadding, { 14, 12 })
    pv(ImGuiStyleVar_ItemSpacing, { 8, 6 })
    pv(ImGuiStyleVar_ScrollbarSize, 6.0)
    pv(ImGuiStyleVar_ScrollbarRounding, 6.0)
    pv(ImGuiStyleVar_ChildRounding, 3.0)
    pv(ImGuiStyleVar_FrameRounding, 3.0)
    pv(ImGuiStyleVar_PopupRounding, 4.0)
end

local function pop_style()
    local nv, nc = table.remove(pushed_v) or 0, table.remove(pushed_c) or 0
    if nv > 0 then imgui.PopStyleVar(nv) end
    if nc > 0 then imgui.PopStyleColor(nc) end
end

return {
    HUD = HUD, C = C, ui = ui, CORNERS_ALL = CORNERS_ALL,
    ornament = ornament, gold_button_bg = gold_button_bg,
    rgba = rgba, col = col, pulse = pulse, line_h = line_h, text_w = text_w, DL = DL,
    text = text, rtext = rtext, fit = fit, dot = dot, diamond = diamond,
    chamfer_fill = chamfer_fill, chamfer_line = chamfer_line, frame = frame,
    pill_w = pill_w, pill = pill, bar = bar, card_bg = card_bg, card_title = card_title, rule = rule,
    push_clip = push_clip, pop_clip = pop_clip,
    hit = hit, advance = advance, avail_w = avail_w, begin_content = begin_content, end_content = end_content,
    seg_tabs = seg_tabs, seg_width = seg_width, toggle_chip = toggle_chip, toggle_w = toggle_w, panel = panel, band = band,
    title_w = title_w, title_text = title_text, logo = logo, close_button = close_button,
    draw_window_frame = draw_window_frame, dot_pill = dot_pill, dot_pill_w = dot_pill_w,
    load_font = load_font, push_font = push_font, pop_font = pop_font,
    push_style = push_style, pop_style = pop_style,
}
