-- abyhub: item icons, read from the game's own item data (the same pictures the
-- wikis show), loaded once per item id and drawn with ImGui's draw list.
local ffi = require('ffi')
local d3d = require('d3d8')
local imgui = require('imgui')

local M = {}
local cache = {}   -- id -> { tex, ptr } or false (no icon)

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

function M.get(id)
    if id == nil or id == 0 or id == 65535 then return nil end
    if cache[id] ~= nil then return cache[id] or nil end
    cache[id] = false
    pcall(function()
        local item = AshitaCore:GetResourceManager():GetItemById(id)
        if item == nil or item.Bitmap == nil or (item.ImageSize or 0) == 0 then return end
        local ptr = ffi.new('IDirect3DTexture8*[1]')
        if ffi.C.D3DXCreateTextureFromFileInMemoryEx(d3d.get_device(), item.Bitmap, item.ImageSize, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0,
                ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED, ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT, 0xFF000000, nil, nil, ptr) == ffi.C.S_OK then
            local tex = d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', ptr[0]))
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
    local dl = imgui.GetWindowDrawList()
    dl:AddRectFilled({ x - 1, y - 1 }, { x + size + 1, y + size + 1 },
        imgui.GetColorU32({ 0.20, 0.22, 0.30, 0.9 * alpha }), 3)
    dl:AddImage(ic.ptr, { x, y }, { x + size, y + size }, { 0, 0 }, { 1, 1 },
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
