-- abyhub: item icons, read from the game's own item data (the same pictures the
-- wikis show), loaded once per item id and drawn with ImGui's draw list.
local ffi = require('ffi')
local d3d = require('d3d8')
local imgui = require('imgui')

local M = {}
local cache = {}   -- id -> { tex, ptr } or false (no icon)

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
        imgui.GetColorU32({ 0.02, 0.04, 0.09, 0.75 * alpha }), 3)
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

return M
