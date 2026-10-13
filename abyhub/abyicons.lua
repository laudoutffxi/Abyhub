-- abyhub: item icons, read from the game's own item data (the same pictures the
-- wikis show), loaded once per item id and drawn with ImGui's draw list.
local ffi = require('ffi')
local d3d = require('d3d8')
local imgui = require('imgui')

local M = {}
local cache = {}   -- id -> { tex, ptr, tex2, ptr2 } or false (no icon)

-- The game's icons are quite dark on our navy panels, so each one is brightened
-- once when it loads: mid-tones lifted with a gamma curve (shadows stay shadows,
-- highlights don't blow out) and colours a little richer.
local GAMMA, SATURATION = 0.70, 1.25
local curve = {}
for v = 0, 255 do curve[v] = math.floor(255 * (v / 255) ^ GAMMA + 0.5) end

function M.brighten(tex)
    local w, h = 32, 32
    local dres, desc = tex:GetLevelDesc(0)
    if dres == ffi.C.S_OK and desc ~= nil then w, h = tonumber(desc.Width), tonumber(desc.Height) end
    local res, rect = tex:LockRect(0, nil, 0)
    if res ~= ffi.C.S_OK or rect == nil then error('LockRect returned ' .. tostring(res)) end
    local bits, pitch = ffi.cast('uint8_t*', rect.pBits), tonumber(rect.Pitch)
    for yy = 0, h - 1 do
        local row = bits + yy * pitch
        for xx = 0, w - 1 do
            local px = row + xx * 4
            if px[3] > 0 then
                local b, g, r = px[0], px[1], px[2]
                local l = 0.114 * b + 0.587 * g + 0.299 * r
                for c = 0, 2 do
                    local v = l + (px[c] - l) * SATURATION
                    v = v < 0 and 0 or (v > 255 and 255 or math.floor(v + 0.5))
                    px[c] = curve[v]
                end
            end
        end
    end
    tex:UnlockRect(0)
end

-- Scale2x: doubles a pixel-art image without blur. Each pixel becomes 2x2, and
-- a corner takes a neighbour's colour where two neighbours agree, so diagonal
-- edges stay smooth instead of turning into blocks. `tex` must already hold the
-- image point-upscaled to twice its size (every source pixel as a 2x2 block).
function M.scale2x(tex)
    local dres, desc = tex:GetLevelDesc(0)
    if dres ~= ffi.C.S_OK or desc == nil then error('GetLevelDesc returned ' .. tostring(dres)) end
    local W, H = tonumber(desc.Width), tonumber(desc.Height)
    local w, h = math.floor(W / 2), math.floor(H / 2)
    local res, rect = tex:LockRect(0, nil, 0)
    if res ~= ffi.C.S_OK or rect == nil then error('LockRect returned ' .. tostring(res)) end
    local bits, pitch = ffi.cast('uint8_t*', rect.pBits), tonumber(rect.Pitch)
    local function at(yy) return ffi.cast('uint32_t*', bits + yy * pitch) end
    -- source pixels = the top-left of each 2x2 block
    local src = {}
    for y = 0, h - 1 do
        local row, r = at(y * 2), {}
        for x = 0, w - 1 do r[x] = row[x * 2] end
        src[y] = r
    end
    local function px(x, y)
        if x < 0 then x = 0 elseif x >= w then x = w - 1 end
        if y < 0 then y = 0 elseif y >= h then y = h - 1 end
        return src[y][x]
    end
    for y = 0, h - 1 do
        local top, bot = at(y * 2), at(y * 2 + 1)
        for x = 0, w - 1 do
            local P = src[y][x]
            local A, B, C, D = px(x, y - 1), px(x + 1, y), px(x - 1, y), px(x, y + 1)
            local e0, e1, e2, e3 = P, P, P, P
            if A ~= D and C ~= B then
                if C == A then e0 = A end
                if A == B then e1 = B end
                if C == D then e2 = C end
                if D == B then e3 = D end
            end
            top[x * 2], top[x * 2 + 1] = e0, e1
            bot[x * 2], bot[x * 2 + 1] = e2, e3
        end
    end
    tex:UnlockRect(0)
end

local D3DX_FILTER_POINT = 2

local function load_texture(item, size, filter)
    local ptr = ffi.new('IDirect3DTexture8*[1]')
    if ffi.C.D3DXCreateTextureFromFileInMemoryEx(d3d.get_device(), item.Bitmap, item.ImageSize, size, size, 1, 0,
            ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED, filter, ffi.C.D3DX_DEFAULT, 0xFF000000, nil, nil, ptr) ~= ffi.C.S_OK then
        return nil
    end
    return d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', ptr[0]))
end

-- The sharp double-size copy, made the first time an icon is drawn bigger than 32px.
local function get2x(id, ic)
    if ic.tex2 ~= nil then return ic.tex2 or nil end
    ic.tex2 = false
    pcall(function()
        local item = AshitaCore:GetResourceManager():GetItemById(id)
        if item == nil or item.Bitmap == nil or (item.ImageSize or 0) == 0 then return end
        local tex = load_texture(item, 64, D3DX_FILTER_POINT)
        if tex == nil then return end
        if not pcall(M.scale2x, tex) then return end   -- blocky is worse than the 1x copy
        pcall(M.brighten, tex)
        ic.tex2, ic.ptr2 = tex, tonumber(ffi.cast('uint32_t', tex))
    end)
    return ic.tex2 or nil
end

function M.get(id)
    if id == nil or id == 0 or id == 65535 then return nil end
    if cache[id] ~= nil then return cache[id] or nil end
    cache[id] = false
    pcall(function()
        local item = AshitaCore:GetResourceManager():GetItemById(id)
        if item == nil or item.Bitmap == nil or (item.ImageSize or 0) == 0 then return end
        local tex = load_texture(item, 0xFFFFFFFF, ffi.C.D3DX_DEFAULT)
        if tex ~= nil then
            pcall(M.brighten, tex)   -- if it fails the icon just shows at the game's brightness
            cache[id] = { tex = tex, ptr = tonumber(ffi.cast('uint32_t', tex)) }
        end
    end)
    return cache[id] or nil
end

-- Draws item `id` as a size x size square at (x, y) on a dark tile with a thin
-- edge (edge = {r, g, b, a} 0..1, optional). alpha dims passed rows. Returns true if drawn.
function M.draw(id, x, y, size, alpha, edge)
    local ic = M.get(id)
    if ic == nil then return false end
    alpha = alpha or 1
    -- Sharpness: land on whole pixels (a half-pixel offset blurs every texel),
    -- and anything drawn bigger than the game's 32px uses the Scale2x copy.
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    local ptr = ic.ptr
    if size > 32 and get2x(id, ic) then ptr = ic.ptr2 end
    local dl = imgui.GetWindowDrawList()
    dl:AddRectFilled({ x - 1, y - 1 }, { x + size + 1, y + size + 1 },
        imgui.GetColorU32({ 0.20, 0.22, 0.30, 0.9 * alpha }), 3)
    dl:AddImage(ptr, { x, y }, { x + size, y + size }, { 0, 0 }, { 1, 1 },
        imgui.GetColorU32({ 1, 1, 1, alpha }))
    if edge then
        dl:AddRect({ x - 1, y - 1 }, { x + size + 1, y + size + 1 },
            imgui.GetColorU32({ edge[1], edge[2], edge[3], (edge[4] or 1) * 0.7 * alpha }), 3)
    end
    return true
end

-- Hovering an icon shows the item's in-game name.
function M.name(id)
    local ok, item = pcall(function() return AshitaCore:GetResourceManager():GetItemById(id) end)
    if ok and item and item.Name then return item.Name[1] end
    return nil
end

-- The item's own text from the game client: name, description (the stat lines
-- the in-game item window shows), level. nil when the client doesn't have it.
function M.info(id)
    local ok, r = pcall(function()
        local item = AshitaCore:GetResourceManager():GetItemById(id)
        if item == nil then return nil end
        local desc = item.Description and item.Description[1] or nil
        return {
            name = item.Name and item.Name[1] or nil,
            desc = (type(desc) == 'string' and desc ~= '') and desc or nil,
            level = tonumber(item.Level),
        }
    end)
    if ok then return r end
    return nil
end

return M
