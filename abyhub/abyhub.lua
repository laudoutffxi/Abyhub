addon.name = 'abyhub'
addon.author = 'Laudout'
addon.version = '1.4.5'
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

-- Generated from LandSandBoat data/enums/key_item.yaml and scripts/globals/abyssea.lua
-- { key item id, name, NM that drops it or false, zone id or 0 }
local ATMA = {
    { 1279, "Lion", "Hadhayosh", 132 },
    { 1280, "Stout Arm", "Briareus", 132 },
    { 1281, "Twin Claw", "Karkinos", 132 },
    { 1282, "Allure", "Carabosse", 132 },
    { 1283, "Eternity", "Ruminator", 132 },
    { 1284, "Heavens", "Ovni", 132 },
    { 1285, "Baying Moon", "Lugarhoo", 132 },
    { 1286, "Ebon Hoof", "Dozing Dorian", 132 },
    { 1287, "Tremors", "Megamaw Mikey", 132 },
    { 1288, "Savage Tiger", "Megantereon", 132 },
    { 1289, "Voracious Violet", "Eccentric Eve", 15 },
    { 1290, "Cloak and Dagger", "Bloodeye Vileberry", 15 },
    { 1291, "Stormbird", "Turul", 15 },
    { 1292, "Noxious Fang", "Kukulkan", 15 },
    { 1293, "Vicissitude", "Fistule", 15 },
    { 1294, "Beyond", "Hadal Satiator", 15 },
    { 1295, "Stormbreath", "Balaur", 15 },
    { 1296, "Gales", "Alkonost", 15 },
    { 1297, "Thrashing Tendrils", "Raskovnik", 15 },
    { 1298, "Drifter", "Khalamari", 15 },
    { 1299, "Stronghold", "Lacovie", 45 },
    { 1300, "Harvester", "Chloris", 45 },
    { 1301, "Dunes", "Glavoid", 45 },
    { 1302, "Cosmos", "Iratham", 45 },
    { 1303, "Siren Shadow", "Usurper", 45 },
    { 1304, "Impaler", "Myrmecoleon", 45 },
    { 1305, "Adamantine", "Chukwa", 45 },
    { 1306, "Calamity", "Adze", 45 },
    { 1307, "Claw", "Cuelebre", 45 },
    { 1308, "Baleful Bones", "Mictlantecuhtli", 45 },
    { 1309, "Clawed Butterfly", "Itzpapalotl", 215 },
    { 1310, "Desert Worm", "Ulhuadshi", 215 },
    { 1311, "Undying", "Titlacauan", 215 },
    { 1312, "Impregnable Tower", "Yaanei", 215 },
    { 1313, "Smoldering Sky", "Smok", 215 },
    { 1314, "Demonic Skewer", "Lusca", 215 },
    { 1315, "Golden Claw", "Kampe", 215 },
    { 1316, "Glutinous Ooze", "Berstuk", 215 },
    { 1317, "Lightning Beast", "Maahes", 215 },
    { 1318, "Noxious Bloom", "Nightshade", 215 },
    { 1319, "Gnarled Horn", "Sobek", 216 },
    { 1320, "Strangling Wind", "Amhuluk", 216 },
    { 1321, "Deep Devourer", "Cirein-croin", 216 },
    { 1322, "Mounted Champion", "Kutharei", 216 },
    { 1323, "Razed Ruins", "Ironclad Pulverizer", 216 },
    { 1324, "Bludgeoning Brute", "Tristitia", 216 },
    { 1325, "Rapid Reptilian", "Nehebkau", 216 },
    { 1326, "Winged Enigma", "Avalerion", 216 },
    { 1327, "Cradle", "Karkatakam", 216 },
    { 1328, "Untouched", "Nonno", 216 },
    { 1329, "Sanguine Scythe", "Bukhis", 217 },
    { 1330, "Tusked Terror", "Sedna", 217 },
    { 1331, "Minikin Monstrosity", "Durinn", 217 },
    { 1332, "Would-be King", "Sippoy", 217 },
    { 1333, "Blinding Horn", "Karkadann", 217 },
    { 1334, "Demonic Lash", "Ketea", 217 },
    { 1335, "Apparitions", "Seps", 217 },
    { 1336, "Shimmering Shell", "Xan", 217 },
    { 1337, "Murky Miasma", "Chhir Batti", 217 },
    { 1338, "Avaricious Ape", "Hanuman", 217 },
    { 1339, "Merciless Matriarch", "Rani", 218 },
    { 1340, "Brother Wolf", "Orthrus", 218 },
    { 1341, "Earth Wyrm", "Dragua", 218 },
    { 1342, "Ascending One", "Bennu", 218 },
    { 1343, "Scorpion Queen", "Hedjedjet", 218 },
    { 1344, "A Thousand Needles", "Cuijatender", 218 },
    { 1345, "Burning Effigy", "Brulo", 218 },
    { 1346, "Smiting Blow", "Ironclad Smiter", 218 },
    { 1347, "Lone Wolf", "Amarok", 218 },
    { 1348, "Crimson Scale", "Hazhdiha", 218 },
    { 1349, "Scarlet Wing", "Ouzelum", 218 },
    { 1350, "Raised Tail", "Shaula", 218 },
    { 1351, "Sand Emperor", "Emperador de Altepa", 218 },
    { 1352, "Omnipotent", "Pantokrator", 253 },
    { 1353, "War Lion", "Apademak", 253 },
    { 1354, "Frozen Fetters", "Isgebind", 253 },
    { 1355, "Plaguebringer", "Resheph", 253 },
    { 1356, "Shrieking One", "Empousa", 253 },
    { 1357, "Holy Mountain", "Indrik", 253 },
    { 1358, "Lake Lurker", "Ogopogo", 253 },
    { 1359, "Crushing Cudgel", "Ironclad Triturator", 253 },
    { 1360, "Purgatory", "Dhorme Khimaira", 253 },
    { 1361, "Blighted Breath", "Kur", 253 },
    { 1362, "Persistent Predator", "Awahondo", 253 },
    { 1363, "Stone God", "Blanga", 253 },
    { 1364, "Sun Eater", "Yaguarogui", 253 },
    { 1365, "Despot", "Raja", 254 },
    { 1366, "Solitary One", "Alfard", 254 },
    { 1367, "Winged Gloom", "Azdaja", 254 },
    { 1368, "Sea Daughter", "Amphitrite", 254 },
    { 1369, "Hateful Stream", "Fuath", 254 },
    { 1370, "Foe Flayer", "Fleshflayer Killakriq", 254 },
    { 1371, "Endless Nightmare", "Maere", 254 },
    { 1372, "Sundering Slash", "Ironclad Sunderer", 254 },
    { 1373, "Entwined Serpents", "Ningishzida", 254 },
    { 1374, "Horned Beast", "Deelgeed", 254 },
    { 1375, "Aquatic Ardor", "Melo Melo", 254 },
    { 1376, "Fallen One", "Teugghia", 254 },
    { 1377, "Fires and Flares", "Bomblix Flamefinger", 254 },
    { 1378, "Apocalypse", false, 0 },
    { 1655, "Heir", false, 0 },
    { 1656, "Hero", false, 0 },
    { 1657, "Full Moon", false, 0 },
    { 1658, "Illusions", false, 0 },
    { 1659, "Banisher", false, 0 },
    { 1660, "Sellsword", false, 0 },
    { 1661, "A Future Fabulous", false, 0 },
    { 1662, "Camaraderie", false, 0 },
    { 1663, "Truthseeker", false, 0 },
    { 1664, "Azure Sky", false, 0 },
    { 1665, "Echoes", false, 0 },
    { 1666, "Dread", false, 0 },
    { 1667, "Ambition", false, 0 },
    { 1668, "Beast King", false, 0 },
    { 1669, "Kirin", false, 0 },
    { 1670, "Hell's Guardian", false, 0 },
    { 1671, "Luminous Wings", false, 0 },
    { 1672, "Dragon Rider", false, 0 },
    { 1673, "Impenetrable", false, 0 },
    { 1674, "Alpha and Omega", false, 0 },
    { 1675, "Ultimate", false, 0 },
    { 1676, "Hybrid Beast", false, 0 },
    { 1677, "Dark Depths", false, 0 },
    { 1678, "Zenith", false, 0 },
    { 1679, "Perfect Attendance", false, 0 },
    { 1680, "Rescuer", false, 0 },
    { 1681, "Nightmares", false, 0 },
    { 1682, "Einherjar", false, 0 },
    { 1683, "Illuminator", false, 0 },
    { 1684, "Bushin", false, 0 },
    { 1685, "Ace Angler", false, 0 },
    { 1686, "Master Crafter", false, 0 },
    { 1687, "Ingenuity", false, 0 },
    { 1688, "Griffon's Claw", false, 0 },
    { 1689, "Fetching Footpad", false, 0 },
    { 1690, "Undying Loyalty", false, 0 },
    { 1691, "Royal Lineage", false, 0 },
    { 1692, "Shattering Star", false, 0 },
    { 1693, "Cobra Commander", false, 0 },
    { 1694, "Roaring Laughter", false, 0 },
    { 1695, "Dark Blade", false, 0 },
    { 1696, "Ducal Guard", false, 0 },
    { 1697, "Harmony", false, 0 },
    { 1698, "Revelations", false, 0 },
    { 1699, "Savior", false, 0 },
}

-- { group, { { key item id, gem colour }, ... } }
local ABYSSITES = {
    { 'Sojourn', { { 1379, 'ivory' }, { 1380, 'scarlet' }, { 1381, 'jade' }, { 1382, 'sapphire' }, { 1383, 'indigo' }, { 1384, 'emerald' } } },
    { 'Celerity', { { 1385, 'azure' }, { 1386, 'crimson' }, { 1387, 'ivory' } } },
    { 'Avarice', { { 1388, 'viridian' }, { 1389, 'ivory' }, { 1390, 'vermillion' } } },
    { 'Confluence', { { 1391, 'ivory' }, { 1392, 'crimson' }, { 1393, 'indigo' } } },
    { 'Expertise', { { 1394, 'ivory' }, { 1395, 'jade' }, { 1396, 'emerald' } } },
    { 'Fortune', { { 1397, 'ivory' }, { 1398, 'sapphire' }, { 1399, 'emerald' } } },
    { 'Kismet', { { 1400, 'scarlet' }, { 1401, 'ivory' }, { 1402, 'vermillion' } } },
    { 'Prosperity', { { 1403, 'azure' }, { 1404, 'jade' }, { 1405, 'ivory' } } },
    { 'Destiny', { { 1406, 'viridian' }, { 1407, 'crimson' }, { 1408, 'ivory' } } },
    { 'Acumen', { { 1409, 'ivory' }, { 1410, 'crimson' }, { 1411, 'emerald' } } },
    { 'Lenity', { { 1412, 'scarlet' }, { 1413, 'azure' }, { 1414, 'viridian' }, { 1415, 'jade' }, { 1416, 'sapphire' }, { 1417, 'crimson' }, { 1418, 'vermillion' }, { 1419, 'indigo' }, { 1420, 'emerald' } } },
    { 'Perspicacity', { { 1421, 'scarlet' }, { 1422, 'ivory' }, { 1423, 'vermillion' } } },
    { 'Reaper', { { 1424, 'azure' }, { 1425, 'ivory' }, { 1426, 'indigo' } } },
    { 'Guerdon', { { 1427, 'viridian' }, { 1428, 'ivory' }, { 1429, 'vermillion' } } },
    { 'Furtherance', { { 1430, 'scarlet' }, { 1431, 'sapphire' }, { 1432, 'ivory' } } },
    { 'Merit', { { 1433, 'azure' }, { 1434, 'viridian' }, { 1435, 'jade' }, { 1436, 'sapphire' }, { 1437, 'ivory' }, { 1438, 'indigo' } } },
    { 'Lunar', { { 1439, 'lunar' }, { 1440, 'lunar' }, { 1441, 'lunar' } } },
    { 'Discernment', { { 1442, 'ivory' } } },
    { 'Cosmos', { { 1443, 'azure' } } },
}

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

--------------------------------------------------------------------------------
-- Abyssea lights
--
-- LandSandBoat keeps lights server-side. The client only learns about them from:
--   * 0x027 LIGHTS_MESSAGE_1 / _2 (/heal in Abyssea with Visitant, or a
--     Conflux Surveyor check)                                -> exact totals
--   * 0x02A BODY_EMITS_OFFSET + light (on gain)             -> intensity tier only
-- Exact totals are taken from the check; gains in between are estimated from the
-- tier and flagged with "~" until the next check.
--------------------------------------------------------------------------------

-- Order matches xi.abyssea.lightType on the server.
local LIGHTS = {
    { key = 'pearl',   name = 'Pearlescent', label = 'PEARL',   cap = 230, max_tier = 2, color = { 0.93, 0.93, 0.98, 1 } },
    { key = 'golden',  name = 'Golden',      label = 'GOLDEN',  cap = 200, max_tier = 2, color = { 1.00, 0.80, 0.30, 1 } },
    { key = 'silvery', name = 'Silvery',     label = 'SILVERY', cap = 200, max_tier = 2, color = { 0.74, 0.80, 0.88, 1 } },
    { key = 'ebon',    name = 'Ebon',        label = 'EBON',    cap = 200, max_tier = 2, color = { 0.56, 0.48, 0.70, 1 } },
    { key = 'azure',   name = 'Azure',       label = 'AZURE',   cap = 255, max_tier = 4, color = { 0.34, 0.62, 1.00, 1 } },
    { key = 'ruby',    name = 'Ruby',        label = 'RUBY',    cap = 255, max_tier = 4, color = { 1.00, 0.34, 0.38, 1 } },
    { key = 'amber',   name = 'Amber',       label = 'AMBER',   cap = 255, max_tier = 4, color = { 1.00, 0.62, 0.22, 1 } },
}
local LIGHT_DISPLAY_ORDER = { 1, 4, 2, 3, 5, 6, 7 } -- pearl, ebon, golden, silvery, azure, ruby, amber

-- Per-zone dialog message IDs from LSB scripts/zones/Abyssea-*/IDs.lua
-- { LIGHTS_MESSAGE_1, LIGHTS_MESSAGE_2, BODY_EMITS_OFFSET }
local LIGHT_MSG_A = { 7339, 7340, 7522 }
local LIGHT_MSG_B = { 7238, 7239, 7421 }
local ABYSSEA_ZONES = {
    [15]  = LIGHT_MSG_A, -- Konschtat
    [45]  = LIGHT_MSG_A, -- Tahrongi
    [132] = LIGHT_MSG_A, -- La Theine
    [215] = LIGHT_MSG_B, -- Attohwa
    [216] = LIGHT_MSG_A, -- Misareaux
    [217] = LIGHT_MSG_A, -- Vunkerl
    [218] = LIGHT_MSG_A, -- Altepa
    [253] = LIGHT_MSG_B, -- Uleguerand
    [254] = LIGHT_MSG_A, -- Grauberg
}

-- Estimated gain per intensity tier (LSB drops are 5/8/16 or 16 x 1-4).
local TIER_GAIN = { [0] = 8, [1] = 16, [2] = 32, [3] = 48, [4] = 128 }

state.lights = { 0, 0, 0, 0, 0, 0, 0 }
state.lights_known = false      -- any data at all (check or saved)
state.lights_approx = {}        -- [index] = true when estimated since last check
state.lights_checked = nil      -- os.time() of last exact check
state.lights_owner = nil        -- character name the values belong to

local function player_zone()
    local party = AshitaCore:GetMemoryManager():GetParty()
    if party == nil then return 0 end
    return tonumber(party:GetMemberZone(0)) or 0
end

local function player_name()
    local party = AshitaCore:GetMemoryManager():GetParty()
    if party == nil then return nil end
    local n = party:GetMemberName(0)
    if n == nil or n == '' then return nil end
    return n
end

local function in_abyssea()
    return ABYSSEA_ZONES[player_zone()] ~= nil
end

local function lights_file()
    return ('%s/lights_%s.lua'):format(addon.path, state.lights_owner or 'unknown')
end

local function save_lights()
    if not state.lights_owner then return end
    pcall(function()
        local f = io.open(lights_file(), 'w')
        if not f then return end
        local approx = {}
        for i = 1, 7 do approx[i] = state.lights_approx[i] and 'true' or 'false' end
        f:write(('return { values = { %s }, approx = { %s }, checked = %s }\n'):format(
            table.concat(state.lights, ', '), table.concat(approx, ', '), tostring(state.lights_checked or 'nil')))
        f:close()
    end)
end

local function load_lights()
    local name = player_name()
    if name == nil or name == state.lights_owner then return end
    state.lights_owner = name
    state.lights = { 0, 0, 0, 0, 0, 0, 0 }
    state.lights_approx = {}
    state.lights_checked = nil
    state.lights_known = false
    local ok, data = pcall(dofile, lights_file())
    if ok and type(data) == 'table' and type(data.values) == 'table' then
        for i = 1, 7 do
            state.lights[i] = tonumber(data.values[i]) or 0
            state.lights_approx[i] = data.approx and data.approx[i] == true or nil
        end
        state.lights_checked = tonumber(data.checked)
        state.lights_known = true
    end
end

local function set_exact(index, value)
    state.lights[index] = math.max(0, math.min(LIGHTS[index].cap, value))
    state.lights_approx[index] = nil
end

local function add_estimated(index, tier)
    local def = LIGHTS[index]
    local gain = TIER_GAIN[tier] or 8
    local ambiguous = tier >= 3 or tier >= def.max_tier
    if index == 1 then -- pearl: 5 from normal mobs, 10 or 16 otherwise
        if tier == 0 then gain, ambiguous = 5, false else gain, ambiguous = 16, true end
    end
    state.lights[index] = math.min(def.cap, state.lights[index] + gain)
    if ambiguous then state.lights_approx[index] = true end
    state.lights_known = true
end

local function read_u16_packet(b, offset)
    local i = offset + 1
    return (b[i] or 0) + ((b[i + 1] or 0) * 0x100)
end

local function capture_lights_packet(e)
    if e.id ~= 0x027 and e.id ~= 0x02A then return end
    local ids = ABYSSEA_ZONES[player_zone()]
    if not ids then return end

    local b = e.data:bytes()
    if not b then return end

    if e.id == 0x027 then
        -- GP_SERV_COMMAND_TALKNUMWORK2: MesNum @0x0A, Num1[4] @0x10
        local mes = bit.band(read_u16_packet(b, 0x0A), 0x7FFF)
        local n = {
            read_u32_packet(b, 0x10), read_u32_packet(b, 0x14),
            read_u32_packet(b, 0x18), read_u32_packet(b, 0x1C),
        }
        if mes == ids[1] then
            set_exact(1, n[1]); set_exact(4, n[2]); set_exact(2, n[3]); set_exact(3, n[4])
        elseif mes == ids[2] then
            set_exact(5, n[1]); set_exact(6, n[2]); set_exact(7, n[3])
        else
            return
        end
        state.lights_known = true
        state.lights_checked = os.time()
        save_lights()
    else
        -- GP_SERV_COMMAND_TALKNUMWORK: num[4] @0x08, MesNum @0x1A
        local mes = bit.band(read_u16_packet(b, 0x1A), 0x7FFF)
        local offset = mes - ids[3]
        if offset >= 0 and offset <= 6 then
            add_estimated(offset + 1, read_u32_packet(b, 0x08))
            save_lights()
        end
    end
end

-- Fallback: read the light totals from the chat text if the IDs ever shift.
local TEXT_LIGHTS = {
    { 'pearlescent', 1 }, { 'ebon', 4 }, { 'golden', 2 }, { 'silvery', 3 },
    { 'azure', 5 }, { 'ruby', 6 }, { 'amber', 7 },
}

local function capture_lights_text(e)
    local msg = e.message
    if type(msg) ~= 'string' or not in_abyssea() then return end
    local lower = msg:lower()
    local found = 0
    for _, t in ipairs(TEXT_LIGHTS) do
        local v = lower:match(t[1] .. '%s*:%s*(%d+)')
        if v then found = found + 1 end
    end
    if found < 2 then return end
    for _, t in ipairs(TEXT_LIGHTS) do
        local v = lower:match(t[1] .. '%s*:%s*(%d+)')
        if v then set_exact(t[2], tonumber(v)) end
    end
    state.lights_known = true
    state.lights_checked = os.time()
    save_lights()
end

--------------------------------------------------------------------------------
-- Atma / abyssite ownership
--------------------------------------------------------------------------------

local function count_atma()
    local owned = 0
    for _, a in ipairs(ATMA) do
        if has_key_item(a[1]) then owned = owned + 1 end
    end
    return owned, #ATMA
end

local function count_abyssites()
    local owned, total = 0, 0
    for _, g in ipairs(ABYSSITES) do
        for _, gem in ipairs(g[2]) do
            total = total + 1
            if has_key_item(gem[1]) then owned = owned + 1 end
        end
    end
    return owned, total
end

--------------------------------------------------------------------------------
-- Stagger alerts
--
-- LSB's mobutils::WeaknessTrigger sends a 0x028 action packet where the mob is
-- both actor and target, category 11 (MobSkillFinish), with a trigger animation:
--   1806 = red, 1807 = yellow, 1808 = blue, 1946 = white
-- The server also gives the mob 30s of Terror when a stagger lands.
--------------------------------------------------------------------------------

local STAGGER_TYPES = {
    [1806] = { key = 'red',    label = 'RED STAGGER!!',    desc = 'Frozen in its tracks',          color = { 1.00, 0.30, 0.26, 1 } },
    [1807] = { key = 'yellow', label = 'YELLOW STAGGER!!', desc = 'Unable to cast magic',          color = { 1.00, 0.84, 0.22, 1 } },
    [1808] = { key = 'blue',   label = 'BLUE STAGGER!!',   desc = 'Unable to use special attacks', color = { 0.36, 0.64, 1.00, 1 } },
    [1946] = { key = 'white',  label = 'WHITE STAGGER!!',  desc = 'Weakness triggered',            color = { 0.92, 0.94, 1.00, 1 } },
}
local STAGGER_BY_KEY = {}
for anim, def in pairs(STAGGER_TYPES) do STAGGER_BY_KEY[def.key] = anim end

local ALERT_POPUP_TIME = 5.0   -- seconds the big popup stays up
local ALERT_TERROR_TIME = 30.0 -- server applies 30s Terror on stagger

state.alerts = {}               -- { def, mob_id, mob_name, t0 }
state.alert_mode = 'target'     -- 'target' | 'any' | 'off'
state.target_id = 0
state.last_target_id = 0

-- Little-endian bit reader for action packets (bit 0 = LSB of byte 0).
local function read_bits(b, bit_offset, count)
    local value = 0
    for i = 0, count - 1 do
        local pos = bit_offset + i
        local byte = b[math.floor(pos / 8) + 1] or 0
        if bit.band(bit.rshift(byte, pos % 8), 1) == 1 then
            value = value + 2 ^ i
        end
    end
    return value
end

local function entity_name_by_id(server_id)
    local ok, name = pcall(function()
        local em = AshitaCore:GetMemoryManager():GetEntity()
        local index = bit.band(server_id, 0xFFF)
        if (tonumber(em:GetServerId(index)) or 0) == server_id then
            return em:GetName(index)
        end
        for i = 0, 2303 do
            if (tonumber(em:GetServerId(i)) or 0) == server_id then return em:GetName(i) end
        end
        return nil
    end)
    if ok and name and name ~= '' then return name end
    return 'Target'
end

local function entity_hpp_by_id(server_id)
    local ok, hpp = pcall(function()
        local em = AshitaCore:GetMemoryManager():GetEntity()
        local index = bit.band(server_id, 0xFFF)
        if (tonumber(em:GetServerId(index)) or 0) ~= server_id then return nil end
        return tonumber(em:GetHPPercent(index))
    end)
    if ok then return hpp end
    return nil
end

local function push_alert(def, mob_id, mob_name)
    -- Replace an older alert of the same colour on the same mob.
    for i = #state.alerts, 1, -1 do
        local a = state.alerts[i]
        if a.def == def and a.mob_id == mob_id then table.remove(state.alerts, i) end
    end
    table.insert(state.alerts, 1, { def = def, mob_id = mob_id, mob_name = mob_name, t0 = os.clock() })
    while #state.alerts > 4 do table.remove(state.alerts) end
end

local function capture_stagger_packet(e)
    if e.id ~= 0x028 or state.alert_mode == 'off' then return end
    local b = e.data:bytes()
    if not b then return end

    local actor = read_bits(b, 40, 32)
    local targets = read_bits(b, 72, 6)
    local category = read_bits(b, 82, 4)
    if category ~= 11 or targets < 1 then return end
    if read_bits(b, 150, 32) ~= actor then return end

    local def = STAGGER_TYPES[read_bits(b, 191, 12)]
    if not def then return end

    if state.alert_mode == 'target' and actor ~= state.target_id and actor ~= state.last_target_id then
        return
    end

    push_alert(def, actor, entity_name_by_id(actor))
end

local function update_target_id()
    local ok, sid = pcall(function()
        local mm = AshitaCore:GetMemoryManager()
        local index = mm:GetTarget():GetTargetIndex(0)
        if not index or index == 0 then return 0 end
        return tonumber(mm:GetEntity():GetServerId(index)) or 0
    end)
    sid = ok and sid or 0
    if sid ~= 0 then state.last_target_id = sid end
    state.target_id = sid
end

ashita.events.register('packet_in', 'abyhub_packet_cb', function(e)
    capture_ki_packet(e)
    capture_lights_packet(e)
    capture_stagger_packet(e)
end)

ashita.events.register('text_in', 'abyhub_text_cb', function(e)
    capture_lights_text(e)
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
    elseif cmd == 'atma' or cmd == 'abyssite' or cmd == 'abyssites' then
        state.tab = 3
        state.visible[1] = true
    elseif cmd == 'alerts' or cmd == 'popups' then
        local want = args[3] and args[3]:lower()
        if want == 'target' or want == 'any' or want == 'off' then
            state.alert_mode = want
        else
            local nxt = { target = 'any', any = 'off', off = 'target' }
            state.alert_mode = nxt[state.alert_mode] or 'target'
        end
        print(chat.header(addon.name):append(chat.message('Stagger popups: ' .. state.alert_mode)))
    elseif cmd == 'testalert' or cmd == 'test' then
        local key = args[3] and args[3]:lower() or 'red'
        local anim = STAGGER_BY_KEY[key] or STAGGER_BY_KEY.red
        push_alert(STAGGER_TYPES[anim], 0, state.target ~= 'No target' and state.target or 'Test Fiend')
    elseif cmd == 'lights' then
        state.visible[1] = true
        local parts = {}
        for _, i in ipairs(LIGHT_DISPLAY_ORDER) do
            parts[#parts + 1] = ('%s %s%d'):format(LIGHTS[i].name, state.lights_approx[i] and '~' or '', state.lights[i])
        end
        print(chat.header(addon.name):append(chat.message(table.concat(parts, ' | '))))
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
            'Commands: /aby, /aby show, /aby hide, /aby ki, /aby stagger, /aby atma, /aby lights, /aby alerts [target|any|off], /aby testalert [red|yellow|blue], /aby all, /aby compact'
        )))
    end
end)

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------

local HUD = {
    accent      = { 0.30, 0.76, 1.00, 1.00 },
    accent2     = { 0.48, 0.86, 1.00, 1.00 },
    text        = { 0.94, 0.95, 0.98, 1.00 },
    subtext     = { 0.72, 0.76, 0.82, 1.00 },
    muted       = { 0.52, 0.57, 0.65, 1.00 },
    faint       = { 0.34, 0.39, 0.46, 1.00 },
    owned       = { 0.40, 0.95, 0.58, 1.00 },
    warn        = { 1.00, 0.68, 0.28, 1.00 },
    gold        = { 1.00, 0.80, 0.36, 1.00 },
    red         = { 1.00, 0.38, 0.32, 1.00 },
    blue        = { 0.40, 0.66, 1.00, 1.00 },
    yellow      = { 1.00, 0.84, 0.26, 1.00 },
    window_bg   = { 0.028, 0.036, 0.052, 0.96 },
    header_bg   = { 0.042, 0.068, 0.100, 1.00 },
    card        = { 0.062, 0.076, 0.104, 0.97 },
    card_line   = { 1.00, 1.00, 1.00, 0.07 },
    track       = { 1.00, 1.00, 1.00, 0.08 },
}

local ELEMENT_COLOR = {
    Fire = { 1.00, 0.42, 0.24, 1 }, Ice = { 0.58, 0.84, 1.00, 1 }, Wind = { 0.40, 0.94, 0.62, 1 },
    Earth = { 0.86, 0.72, 0.34, 1 }, Lightning = { 0.80, 0.58, 1.00, 1 }, Water = { 0.36, 0.58, 1.00, 1 },
    Light = { 1.00, 0.95, 0.76, 1 }, Dark = { 0.66, 0.44, 0.80, 1 },
}
local ELEMENT_LABEL = {
    Fire = 'FIRE', Ice = 'ICE', Wind = 'WIND', Earth = 'EARTH', Lightning = 'THUNDER',
    Water = 'WATER', Light = 'LIGHT', Dark = 'DARK',
}
local DAY_ELEMENT = {
    Firesday = 'Fire', Earthsday = 'Earth', Watersday = 'Water', Windsday = 'Wind',
    Iceday = 'Ice', Lightningday = 'Lightning', Lightsday = 'Light', Darksday = 'Dark',
}

local ui = { h = {} }

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

local function dot(cx, cy, r, c, glow)
    local dl = DL()
    if glow and glow > 0 then
        dl:AddCircleFilled({ cx, cy }, r * 2.4, col(c, 0.10 * glow), 20)
        dl:AddCircleFilled({ cx, cy }, r * 1.6, col(c, 0.22 * glow), 20)
    end
    dl:AddCircleFilled({ cx, cy }, r, col(c), 16)
end

local function pill_w(s) return text_w(s) + 14 end

local function pill(x, y, s, c, fill)
    local dl = DL()
    local w, h = pill_w(s), line_h() + 3
    local top = y - 1.5
    dl:AddRectFilled({ x, top }, { x + w, top + h }, col(c, fill or 0.15), h * 0.5)
    dl:AddRect({ x, top }, { x + w, top + h }, col(c, 0.50), h * 0.5, CORNERS_ALL, 1.0)
    dl:AddText({ x + 7, y }, col(c), s)
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
    local dl = DL()
    dl:AddRectFilled({ x, y }, { x + w, y + h }, col(HUD.card), 8)
    if accent then
        dl:AddRectFilledMultiColor({ x + 1, y + 1 }, { x + w * 0.6, y + h - 1 },
            col(accent, 0.07 * (strength or 1)), col(accent, 0), col(accent, 0), col(accent, 0.03 * (strength or 1)))
        dl:AddRect({ x, y }, { x + w, y + h }, col(accent, 0.28 * (strength or 1)), 8, CORNERS_ALL, 1.0)
    else
        dl:AddRect({ x, y }, { x + w, y + h }, col(HUD.card_line), 8, CORNERS_ALL, 1.0)
    end
end

-- Title row used by every panel: stripe, title, optional subtitle and right-side text.
local function card_title(x, y, w, c, title, sub, right, right_col)
    local dl = DL()
    local lh = line_h()
    dl:AddRectFilled({ x, y + 2 }, { x + 3, y + lh - 2 }, col(c), 1.5)
    text(x + 10, y, c, title)
    if sub then text(x + 10 + text_w(title) + 10, y, HUD.muted, sub) end
    if right then text(x + w - text_w(right), y, right_col or HUD.faint, right) end
end

local function fmt_earth(seconds)
    seconds = math.max(0, math.floor(seconds + 0.5))
    if seconds >= 3600 then
        return ('%dh %02dm'):format(math.floor(seconds / 3600), math.floor(seconds / 60) % 60)
    end
    return ('%dm %02ds'):format(math.floor(seconds / 60), seconds % 60)
end

-- Click target placed at an absolute position; leaves the layout cursor alone.
local function hit(id, x, y, w, h)
    local cx, cy = imgui.GetCursorScreenPos()
    imgui.SetCursorScreenPos({ x, y })
    local clicked = imgui.InvisibleButton(id, { w, h })
    local hov = imgui.IsItemHovered()
    if hov then imgui.SetMouseCursor(ImGuiMouseCursor_Hand) end
    imgui.SetCursorScreenPos({ cx, cy })
    return clicked, hov
end

-- Reserve a block of the given height at the current cursor.
local function advance(w, h)
    imgui.Dummy({ w, h })
end

--------------------------------------------------------------------------------
-- Header + tabs
--------------------------------------------------------------------------------

-- Fixed layout width: the window auto-sizes around content laid out to this width.
ui.cw = ui.cw or 760
ui.left_x = ui.left_x or 0
local function avail_w()
    local cx = imgui.GetCursorScreenPos()
    return ui.cw - (cx - ui.left_x)
end

-- Width the content needs: one-row header, three key item columns, readable lists.
local function content_width()
    local u = text_w('0')
    local longest = 0
    for _, area in ipairs(AREAS) do
        for _, ki in ipairs(area.kis) do longest = math.max(longest, text_w(ki[2])) end
    end
    local ki_need = 3 * (longest + 44) + 20
    return math.max(ui.header_need or 0, ki_need, 64 * u)
end

-- Segmented tab strip. items = { { key, label, badge }, ... }
-- Returns the clicked key (or nil), the strip width and height.
local function seg_tabs(id, items, active, x, y, color, small)
    local dl = DL()
    local lh = line_h()
    local th = lh + (small and 6 or 8)
    local pad = small and 9 or 11
    local tx = x
    local clicked_key = nil
    for _, t in ipairs(items) do
        local key, label, badge = t[1], t[2], t[3]
        local on = active == key
        local tw = text_w(label) + (badge and (text_w(badge) + 8) or 0) + pad * 2
        local clicked, hov = hit(('##%s_%s'):format(id, tostring(key)), tx, y, tw, th)
        if clicked then clicked_key = key end
        if on then
            dl:AddRectFilled({ tx, y }, { tx + tw, y + th }, col(color, 0.16), 5)
            dl:AddRect({ tx, y }, { tx + tw, y + th }, col(color, 0.55), 5, CORNERS_ALL, 1.0)
        elseif hov then
            dl:AddRectFilled({ tx, y }, { tx + tw, y + th }, col(HUD.text, 0.06), 5)
        end
        local ty = y + (th - lh) * 0.5
        text(tx + pad, ty, on and HUD.text or (hov and HUD.subtext or HUD.muted), label)
        if badge then
            text(tx + pad + text_w(label) + 8, ty, on and (t[4] or color) or HUD.faint, badge)
        end
        tx = tx + tw + 4
    end
    return clicked_key, tx - x - 4, th
end

local function render_header()
    local dl = DL()
    local wx, wy = imgui.GetWindowPos()
    local ww, wh = imgui.GetWindowSize()
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()
    local lh = line_h()

    local total = 0
    for _, area in ipairs(AREAS) do total = total + #area.kis end
    local have = has_required_page()
    local tabs = {
        { 1, 'KEY ITEMS', have and ('%d/%d'):format(count_owned(), total) or nil },
        { 2, 'STAGGERS', state.vana_ok and blue_window():upper() or nil },
        { 3, 'ATMA', have and ('%d/%d'):format(count_atma()) or nil },
    }

    -- Measure the pieces so the header can collapse to one row.
    local title_scale = 1.15
    local title_w = text_w('ABYSSEA TOOLKIT') * title_scale
    local tabs_w = 0
    for _, t in ipairs(tabs) do tabs_w = tabs_w + text_w(t[2]) + (t[3] and (text_w(t[3]) + 8) or 0) + 22 + 4 end
    local bs = lh + 4
    local clock_w = 0
    local day, clock, ec
    if state.vana_ok then
        day = current_day()
        ec = ELEMENT_COLOR[DAY_ELEMENT[day] or ''] or HUD.text
        clock = ('%02d:%02d'):format(state.vana_hour, state.vana_minute)
        clock_w = 20 + text_w(clock) + 8 + text_w(day) + 10
    end
    ui.header_need = title_w + 16 + tabs_w + 12 + clock_w + 8 + bs
    local one_row = ui.header_need <= w + 0.5
    local row_h = lh + 8
    local head_h = one_row and row_h or (row_h * 2 + 6)

    -- Band
    local band_top, band_bot = y - 30, y + head_h + 5
    dl:PushClipRect({ wx, wy }, { wx + ww, math.min(wy + wh, band_bot) }, true)
    dl:AddRectFilled({ wx, band_top }, { wx + ww, band_bot + 12 }, col(HUD.header_bg), 10)
    dl:AddRectFilledMultiColor({ wx, band_top + 12 }, { wx + ww * 0.7, band_bot },
        col(HUD.accent, 0.10), col(HUD.accent, 0), col(HUD.accent, 0), col(HUD.accent, 0.04))
    dl:PopClipRect()
    dl:PushClipRect({ wx, wy }, { wx + ww, wy + wh }, true)
    dl:AddRectFilledMultiColor({ wx, band_bot - 1 }, { wx + ww, band_bot },
        col(HUD.accent, 0.8), col(HUD.accent, 0), col(HUD.accent, 0), col(HUD.accent, 0.8))
    dl:PopClipRect()

    -- Title
    local ty = y + (row_h - lh * title_scale) * 0.5
    text(x, ty, HUD.accent, 'ABYSSEA TOOLKIT', title_scale)

    -- Close
    local bx, by = x + w - bs, y + (row_h - bs) * 0.5
    local clicked, hov = hit('##aby_close', bx, by, bs, bs)
    if clicked then state.visible[1] = false end
    if hov then dl:AddRectFilled({ bx, by }, { bx + bs, by + bs }, col(HUD.text, 0.10), 5) end
    local m, c = bs * 0.32, hov and HUD.text or HUD.muted
    dl:AddLine({ bx + m, by + m }, { bx + bs - m, by + bs - m }, col(c), 1.5)
    dl:AddLine({ bx + bs - m, by + m }, { bx + m, by + bs - m }, col(c), 1.5)

    -- Clock pill
    if state.vana_ok then
        local cx, cy = bx - 8 - clock_w, y + (row_h - lh) * 0.5
        dl:AddRectFilled({ cx, cy - 2 }, { cx + clock_w, cy + lh + 2 }, col(ec, 0.10), (lh + 4) * 0.5)
        dl:AddRect({ cx, cy - 2 }, { cx + clock_w, cy + lh + 2 }, col(ec, 0.40), (lh + 4) * 0.5, CORNERS_ALL, 1.0)
        dot(cx + 10, cy + lh * 0.5, 3, ec, 0.5 + pulse(2) * 0.5)
        text(cx + 20, cy, HUD.text, clock)
        text(cx + 20 + text_w(clock) + 8, cy, ec, day)
    end

    -- Tabs
    local tab_x = one_row and (x + title_w + 16) or x
    local tab_y = one_row and (y + (row_h - (lh + 8)) * 0.5) or (y + row_h + 6)
    local picked = seg_tabs('aby_tab', tabs, state.tab, tab_x, tab_y, HUD.accent, false)
    if picked then state.tab = picked end

    advance(w, head_h)
    imgui.Dummy({ 0, 4 })
end

--------------------------------------------------------------------------------
-- Key items tab
--------------------------------------------------------------------------------

local function boss_owned(boss)
    local owned = 0
    for _, id in ipairs(boss.kis) do
        if has_key_item(id) then owned = owned + 1 end
    end
    return owned
end

local function draw_check(cx, cy, r, owned)
    local dl = DL()
    if owned then
        dl:AddCircleFilled({ cx, cy }, r, col(HUD.owned, 0.95), 16)
        dl:AddLine({ cx - r * 0.45, cy + r * 0.02 }, { cx - r * 0.1, cy + r * 0.38 }, col(HUD.window_bg), 1.6)
        dl:AddLine({ cx - r * 0.1, cy + r * 0.38 }, { cx + r * 0.5, cy - r * 0.35 }, col(HUD.window_bg), 1.6)
    else
        dl:AddCircle({ cx, cy }, r - 0.5, col(HUD.faint), 16, 1.2)
    end
end

-- Draws one zone card at (x, y) with width w and fixed height h. Returns content height.
local function draw_zone_card(area, x, y, w, h)
    local dl = DL()
    local lh = line_h()
    local owned = count_area_owned(area)
    local done = owned == #area.kis
    card_bg(x, y, w, h, done and HUD.owned or nil)
    dl:PushClipRect({ x, y }, { x + w, y + h }, true)

    local px, py, pw = x + 10, y + 9, w - 20
    local count = ('%d/%d'):format(owned, #area.kis)
    text(px, py, HUD.accent2, area.name)
    text(px + pw - text_w(count), py, done and HUD.owned or HUD.muted, count)
    py = py + lh + 6
    bar(px, py, pw, 4, owned / math.max(1, #area.kis), done and HUD.owned or HUD.accent)
    py = py + 4 + 9

    for _, boss in ipairs(BOSSES) do
        if boss.area == area.name then
            local bo = boss_owned(boss)
            local ready = bo == #boss.kis
            local block_h = (lh + 6) + #boss.kis * (lh + 2)
            if ready then
                local g = 0.6 + pulse(2.5) * 0.4
                dl:AddRectFilled({ px - 6, py - 4 }, { px + pw + 6, py + block_h }, col(HUD.gold, 0.07 * g), 6)
                dl:AddRect({ px - 6, py - 4 }, { px + pw + 6, py + block_h }, col(HUD.gold, 0.35 * g), 6, CORNERS_ALL, 1.0)
            end
            text(px, py, ready and HUD.gold or HUD.text, boss.name)
            if ready then
                pill(px + pw - pill_w('READY'), py, 'READY', HUD.gold, 0.18)
            else
                local bc = ('%d/%d'):format(bo, #boss.kis)
                text(px + pw - text_w(bc), py, bo > 0 and HUD.subtext or HUD.faint, bc)
            end
            py = py + lh + 6
            for _, id in ipairs(boss.kis) do
                local has = has_key_item(id)
                draw_check(px + 6, py + lh * 0.5, 5, has)
                text(px + 18, py, has and HUD.owned or HUD.muted, get_ki_name(area, id))
                py = py + lh + 2
            end
            py = py + 7
        end
    end

    dl:PopClipRect()
    return (py - y) + 2
end

local function render_key_items()
    local dl = DL()
    local lh = line_h()
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()

    if not has_required_page() then
        local h = lh * 2 + 34
        card_bg(x, y, w, h, HUD.warn, 0.6 + pulse(2) * 0.4)
        dot(x + 18, y + 14 + lh * 0.5, 4, HUD.warn, 0.4 + pulse(2) * 0.6)
        text(x + 30, y + 14, HUD.warn, 'WAITING FOR KEY ITEM DATA')
        text(x + 30, y + 18 + lh, HUD.muted, 'Zone once after loading the addon.')
        advance(w, h)
        return
    end

    -- Summary strip (single row)
    local total, owned, ready = 0, count_owned(), 0
    for _, area in ipairs(AREAS) do total = total + #area.kis end
    for _, boss in ipairs(BOSSES) do
        if boss_owned(boss) == #boss.kis then ready = ready + 1 end
    end
    local sh = lh + 16
    card_bg(x, y, w, sh, HUD.accent, 0.6)
    local tx = x + 10
    text(tx, y + 8, HUD.muted, 'POP KEY ITEMS')
    tx = tx + text_w('POP KEY ITEMS') + 10
    local cnt = ('%d / %d'):format(owned, total)
    text(tx, y + 8, HUD.text, cnt)
    tx = tx + text_w(cnt) + 12
    local ready_label = ready > 0 and ('%d READY'):format(ready) or nil
    local pct = ('%d%%'):format(math.floor(owned / math.max(1, total) * 100 + 0.5))
    local right = x + w - 10 - (ready_label and (pill_w(ready_label) + 10) or 0)
    local bw = right - tx - text_w(pct) - 10
    bar(tx, y + sh * 0.5 - 2, bw, 4, owned / math.max(1, total), HUD.owned)
    text(tx + bw + 8, y + 8, HUD.faint, pct)
    if ready_label then
        pill(x + w - 10 - pill_w(ready_label), y + 8, ready_label, HUD.gold, 0.12 + pulse(2.5) * 0.10)
    end
    advance(w, sh)

    -- Zone cards: three columns on wide windows, stacked when narrow.
    x, y = imgui.GetCursorScreenPos()
    local gap = 10
    local cols = (w >= 600) and 3 or 1
    local cw = (w - gap * (cols - 1)) / cols
    if cols == 3 then
        local h = ui.h.ki_row or 200
        local max_h = 0
        for i, area in ipairs(AREAS) do
            max_h = math.max(max_h, draw_zone_card(area, x + (i - 1) * (cw + gap), y, cw, h))
        end
        ui.h.ki_row = max_h
        advance(w, h)
    else
        for i, area in ipairs(AREAS) do
            local key = 'ki_' .. i
            local h = ui.h[key] or 200
            local cx, cy = imgui.GetCursorScreenPos()
            ui.h[key] = draw_zone_card(area, cx, cy, cw, h)
            advance(w, h)
        end
    end
end

--------------------------------------------------------------------------------
-- Staggers tab
--------------------------------------------------------------------------------

local BLUE_WINDOWS = {
    { name = 'Piercing', start = 6 * 60,  stop = 14 * 60, next = 'Slashing' },
    { name = 'Slashing', start = 14 * 60, stop = 22 * 60, next = 'Blunt' },
    { name = 'Blunt',    start = 22 * 60, stop = 30 * 60, next = 'Piercing' },
}

-- Earth seconds per Vana'diel minute (25x speed).
local VANA_MIN_TO_EARTH_SEC = 60 / 25

local function blue_window_info()
    local now = state.vana_hour * 60 + state.vana_minute
    local active = blue_window()
    for _, wnd in ipairs(BLUE_WINDOWS) do
        if wnd.name == active then
            local t = now
            if t < wnd.start then t = t + 1440 end
            local elapsed = t - wnd.start
            local remaining = wnd.stop - t
            return wnd, elapsed / (wnd.stop - wnd.start), remaining * VANA_MIN_TO_EARTH_SEC
        end
    end
    return BLUE_WINDOWS[1], 0, 0
end

local function render_status_tiles()
    local dl = DL()
    local lh = line_h()
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()
    local gap = 10
    local th = lh * 2.6 + 22
    local tw = (w - gap * 2) / 3

    -- Target
    local has_target = state.target ~= 'No target'
    card_bg(x, y, tw, th, has_target and HUD.owned or nil, 0.8)
    text(x + 12, y + 8, HUD.muted, 'TARGET')
    dl:PushClipRect({ x, y }, { x + tw - 8, y + th }, true)
    text(x + 12, y + 10 + lh, has_target and HUD.text or HUD.faint, state.target, 1.25)
    dl:PopClipRect()
    if has_target then dot(x + tw - 14, y + 8 + lh * 0.5, 3.5, HUD.owned, 0.5 + pulse(3) * 0.5) end

    -- Vana'diel time + day
    local tx = x + tw + gap
    local day = current_day()
    local element = DAY_ELEMENT[day]
    local ec = ELEMENT_COLOR[element or ''] or HUD.text
    card_bg(tx, y, tw, th, state.vana_ok and ec or nil, 0.7)
    text(tx + 12, y + 8, HUD.muted, "VANA'DIEL")
    if state.vana_ok then
        local clock = ('%02d:%02d'):format(state.vana_hour, state.vana_minute)
        text(tx + 12, y + 9 + lh, HUD.text, clock, 1.5)
        text(tx + 12 + text_w(clock) * 1.5 + 10, y + 15 + lh, ec, day)
        local day_left = (1440 - (state.vana_hour * 60 + state.vana_minute)) * VANA_MIN_TO_EARTH_SEC
        bar(tx + 12, y + th - 9, tw - 24, 4, (state.vana_hour * 60 + state.vana_minute) / 1440, ec)
        local nd = fmt_earth(day_left)
        text(tx + tw - 12 - text_w(nd), y + 8, HUD.faint, nd)
    else
        text(tx + 12, y + 10 + lh, HUD.warn, 'Clock unavailable')
    end

    -- Blue window
    local bx = x + (tw + gap) * 2
    local wnd, frac, left = blue_window_info()
    card_bg(bx, y, tw, th, state.vana_ok and HUD.blue or nil, 0.8)
    text(bx + 12, y + 8, HUD.muted, 'BLUE WINDOW')
    if state.vana_ok then
        text(bx + 12, y + 10 + lh, HUD.blue, wnd.name:upper(), 1.25)
        local nxt = ('%s %s'):format(wnd.next, fmt_earth(left))
        text(bx + tw - 12 - text_w(nxt), y + 8, HUD.faint, nxt)
        bar(bx + 12, y + th - 9, tw - 24, 4, frac, HUD.blue)
    else
        text(bx + 12, y + 10 + lh, HUD.faint, '--')
    end

    advance(w, th)
end

local function toggle_chip(id, label, on, x, y, c)
    local dl = DL()
    local lh = line_h()
    local w, h = text_w(label) + 34, lh + 10
    local clicked, hov = hit(id, x, y, w, h)
    dl:AddRectFilled({ x, y }, { x + w, y + h }, col(on and c or HUD.text, on and 0.16 or (hov and 0.07 or 0.04)), h * 0.5)
    dl:AddRect({ x, y }, { x + w, y + h }, col(on and c or HUD.faint, on and 0.6 or 0.5), h * 0.5, CORNERS_ALL, 1.0)
    -- switch knob
    local kx, ky = x + 13, y + h * 0.5
    dl:AddCircle({ kx, ky }, 5, col(on and c or HUD.muted), 16, 1.2)
    if on then dl:AddCircleFilled({ kx, ky }, 3, col(c), 12) end
    text(x + 24, y + 5, on and HUD.text or (hov and HUD.subtext or HUD.muted), label)
    return clicked, w
end

local function render_controls()
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()
    local c1, w1 = toggle_chip('##aby_all', 'Show all', state.show_all[1], x, y, HUD.accent)
    if c1 then state.show_all[1] = not state.show_all[1] end
    local c2, w2 = toggle_chip('##aby_compact', 'Compact', state.compact[1], x + w1 + 8, y, HUD.accent)
    if c2 then state.compact[1] = not state.compact[1] end
    local label3 = state.alert_mode == 'any' and 'Stagger popups (any mob)' or 'Stagger popups'
    local c3 = toggle_chip('##aby_alerts', label3, state.alert_mode ~= 'off', x + w1 + w2 + 16, y, HUD.gold)
    if c3 then state.alert_mode = (state.alert_mode == 'off') and 'target' or 'off' end
    advance(w, line_h() + 10)
end

-- Panel wrapper: background sized from last frame's measurement.
local function panel(id, accent, draw_fn)
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()
    local h = ui.h[id] or 120
    card_bg(x, y, w, h, accent, 0.9)
    local content_h = draw_fn(x + 12, y + 9, w - 24)
    ui.h[id] = content_h + 18
    advance(w, h)
    imgui.Dummy({ 0, 2 })
end

local function render_red()
    panel('red', HUD.red, function(x, y, w)
        local lh = line_h()
        card_title(x, y, w, HUD.red, 'RED', 'Elemental weapon skills', ('%d skills'):format(#RED))
        local py = y + lh + 8
        local gap = 14
        local need = 0
        for _, r in ipairs(RED) do
            need = math.max(need, 18 + text_w(r[2]) + 8 + text_w(r[1]) + 12 + text_w(ELEMENT_LABEL[r[4]] or r[4]) + 6)
        end
        local cols = math.max(1, math.min(3, math.floor((w + gap) / (need + gap))))
        local cw = (w - gap * (cols - 1)) / cols
        local rh = lh + (state.compact[1] and 4 or 6)
        local rows = math.ceil(#RED / cols)
        for i, s in ipairs(RED) do
            local c = math.floor((i - 1) / rows)
            local r = (i - 1) % rows
            local cx, cy = x + c * (cw + gap), py + r * rh
            local ec = ELEMENT_COLOR[s[4]] or HUD.text
            local tag = ELEMENT_LABEL[s[4]] or s[4]
            DL():AddRectFilled({ cx, cy - 2 }, { cx + cw, cy + lh + 2 }, col(ec, 0.05), 4)
            dot(cx + 8, cy + lh * 0.5, 3.5, ec)
            text(cx + 18, cy, HUD.text, s[2])
            text(cx + 18 + text_w(s[2]) + 8, cy, HUD.faint, s[1])
            text(cx + cw - 6 - text_w(tag), cy, ec, tag)
        end
        return (py - y) + rows * rh - 4
    end)
end

local function render_blue()
    local active = blue_window()
    panel('blue', HUD.blue, function(x, y, w)
        local lh = line_h()
        card_title(x, y, w, HUD.blue, 'BLUE', 'Physical weapon skills')
        pill(x + w - pill_w(active:upper()), y, active:upper(), HUD.blue, 0.16 + pulse(2) * 0.08)
        local py = y + lh + 9
        local gap = 14
        local need = 0
        for _, b in ipairs(BLUE) do need = math.max(need, 14 + text_w(b[3]) + 8 + text_w(b[2]) + 10) end
        local cols = math.max(1, math.min(3, math.floor((w + gap) / (need + gap))))
        local cw = (w - gap * (cols - 1)) / cols
        local rh = lh + (state.compact[1] and 3 or 5)

        for _, wnd in ipairs(BLUE_WINDOWS) do
            local is_active = wnd.name == active
            if state.show_all[1] or is_active then
                local list = {}
                for _, s in ipairs(BLUE) do if s[1] == wnd.name then list[#list + 1] = s end end
                if state.show_all[1] then
                    local hc = is_active and HUD.blue or HUD.faint
                    text(x, py, hc, wnd.name:upper())
                    local hrs = ('%02d:00 - %02d:59'):format(wnd.start / 60, (wnd.stop / 60 - 1) % 24)
                    text(x + text_w(wnd.name:upper()) + 10, py, HUD.faint, hrs)
                    if is_active then
                        pill(x + text_w(wnd.name:upper()) + 10 + text_w(hrs) + 10, py, 'ACTIVE', HUD.blue, 0.12)
                    end
                    py = py + lh + 6
                end
                local rows = math.ceil(#list / cols)
                for i, s in ipairs(list) do
                    local c = math.floor((i - 1) / rows)
                    local r = (i - 1) % rows
                    local cx, cy = x + c * (cw + gap), py + r * rh
                    local tc = is_active and HUD.text or HUD.muted
                    dot(cx + 4, cy + lh * 0.5, 3, is_active and HUD.blue or HUD.faint)
                    text(cx + 14, cy, tc, s[3])
                    text(cx + 14 + text_w(s[3]) + 8, cy, HUD.faint, s[2])
                end
                py = py + rows * rh + 8
            end
        end
        return (py - y) - 12
    end)
end

local function render_yellow()
    local prev_i = ((state.vana_weekday - 1) % 8) + 1
    local cur_i = state.vana_weekday + 1
    local next_i = ((state.vana_weekday + 1) % 8) + 1
    local tags = { [prev_i] = 'PREV', [cur_i] = 'TODAY', [next_i] = 'NEXT' }

    panel('yellow', HUD.yellow, function(x, y, w)
        local dl = DL()
        local lh = line_h()
        card_title(x, y, w, HUD.yellow, 'YELLOW', 'Magic by day element', 'previous / current / next day')
        local py = y + lh + 9
        local tag_w = text_w('TODAY') + 10
        local day_w = 0
        for _, d in ipairs(YELLOW) do day_w = math.max(day_w, text_w(d[1])) end
        local left_w = tag_w + 12 + day_w + 16
        local order = state.show_all[1] and { 1, 2, 3, 4, 5, 6, 7, 8 } or { prev_i, cur_i, next_i }

        for _, i in ipairs(order) do
            local s = YELLOW[i]
            local tag = tags[i]
            local ec = ELEMENT_COLOR[s[2]] or HUD.text
            local today = i == cur_i
            local dim = tag == nil

            -- Day label
            local row_top = py
            if tag then
                text(x, py, today and HUD.yellow or HUD.muted, tag)
            end
            dot(x + tag_w + 3, py + lh * 0.5, 3.5, ec, today and (0.5 + pulse(2) * 0.5) or nil)
            text(x + tag_w + 12, py, dim and HUD.faint or (today and HUD.text or HUD.subtext), s[1])

            -- Spell chips (wrap inside the right column)
            local cx, cy = x + left_w, py
            local right = x + w
            for spell in s[3]:gmatch('[^,]+') do
                spell = spell:gsub('^%s+', ''):gsub('%s+$', '')
                local sw = text_w(spell) + 14
                if cx + sw > right and cx > x + left_w then
                    cx, cy = x + left_w, cy + lh + 6
                end
                if not state.compact[1] or today then
                    dl:AddRectFilled({ cx, cy - 1.5 }, { cx + sw, cy + lh + 1.5 }, col(ec, dim and 0.04 or (today and 0.16 or 0.08)), (lh + 3) * 0.5)
                    if today then
                        dl:AddRect({ cx, cy - 1.5 }, { cx + sw, cy + lh + 1.5 }, col(ec, 0.45), (lh + 3) * 0.5, CORNERS_ALL, 1.0)
                    end
                end
                text(cx + 7, cy, dim and HUD.faint or (today and HUD.text or HUD.subtext), spell)
                cx = cx + sw + 6
            end
            py = cy + lh + (state.compact[1] and 6 or 9)

            if today then
                dl:AddRectFilled({ x - 14, row_top - 4 }, { x - 11, py - 8 }, col(HUD.yellow, 0.9), 1.5)
            end
        end
        return (py - y) - 12
    end)
end

local function render_staggers()
    render_status_tiles()
    imgui.Dummy({ 0, 2 })
    render_controls()
    imgui.Dummy({ 0, 2 })
    render_red()
    render_blue()
    render_yellow()

end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Lights bar (compact: one row of seven mini meters)
--------------------------------------------------------------------------------

local function fmt_ago(t)
    if not t then return nil end
    local s = math.max(0, os.time() - t)
    if s < 60 then return 'just now' end
    if s < 3600 then return ('%dm ago'):format(math.floor(s / 60)) end
    if s < 86400 then return ('%dh ago'):format(math.floor(s / 3600)) end
    return ('%dd ago'):format(math.floor(s / 86400))
end

local function render_lights_bar()
    local here = in_abyssea()
    if not here and not state.lights_known then return end

    local dl = DL()
    local lh = line_h()
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()

    local any_approx = false
    for i = 1, 7 do if state.lights_approx[i] then any_approx = true end end

    local status, status_col
    if not state.lights_known then
        status, status_col = '/heal in Abyssea to read your lights', HUD.warn
    elseif any_approx then
        status, status_col = ('Estimated since last sync (%s). /heal to resync.'):format(fmt_ago(state.lights_checked) or 'never'), HUD.warn
    elseif state.lights_checked then
        status, status_col = ('Exact - synced %s'):format(fmt_ago(state.lights_checked)), HUD.owned
    else
        status, status_col = 'Saved values', HUD.muted
    end

    local label_w = text_w('LIGHTS') + 22
    local avail = w - 20 - label_w
    local per_row = (avail / 7 >= text_w('SILVERY') + text_w('~255') + 6) and 7 or 4
    local rows = math.ceil(7 / per_row)
    local cell_h = lh + 9
    local h = 8 + rows * cell_h + 4
    card_bg(x, y, w, h, here and HUD.accent or nil, 0.5)

    -- Label + status dot (hover for details)
    local lx, ly = x + 10, y + 8
    text(lx, ly, here and HUD.accent2 or HUD.muted, 'LIGHTS')
    dot(lx + text_w('LIGHTS') + 8, ly + lh * 0.5, 3, status_col, any_approx and (0.4 + pulse(2) * 0.6) or nil)
    local _, hov = hit('##lights_status', x, y, label_w + 10, h)
    if hov then imgui.SetTooltip(status .. (here and '' or '\n(last known - outside Abyssea)')) end

    local gx = x + 10 + label_w
    local gap = 10
    local cw = (avail - gap * (per_row - 1)) / per_row
    for n, i in ipairs(LIGHT_DISPLAY_ORDER) do
        local def = LIGHTS[i]
        local r = math.floor((n - 1) / per_row)
        local c = (n - 1) % per_row
        local cx, cy = gx + c * (cw + gap), y + 8 + r * cell_h
        local v = state.lights[i] or 0
        local full = v >= def.cap
        local tone = state.lights_known and def.color or HUD.faint
        text(cx, cy, tone, def.label)
        local val = (state.lights_approx[i] and '~' or '') .. tostring(v)
        text(cx + cw - text_w(val), cy, full and HUD.gold or (v > 0 and HUD.text or HUD.faint), val)
        bar(cx, cy + lh + 2, cw, 3, v / def.cap, def.color)
        local _, chov = hit(('##light_%d'):format(i), cx, cy, cw, cell_h - 2)
        if chov then
            imgui.SetTooltip(('%s light: %s%d / %d%s'):format(def.name, state.lights_approx[i] and '~' or '', v, def.cap,
                state.lights_approx[i] and '\nEstimated - /heal to sync' or ''))
        end
    end

    advance(w, h)
end

--------------------------------------------------------------------------------
-- Atma & abyssites tab: expansion -> zone sub-tabs
--------------------------------------------------------------------------------

local GEM_COLOR = {
    ivory = { 0.95, 0.92, 0.82, 1 }, scarlet = { 1.00, 0.36, 0.30, 1 }, jade = { 0.56, 0.86, 0.62, 1 },
    sapphire = { 0.30, 0.50, 1.00, 1 }, indigo = { 0.50, 0.44, 0.92, 1 }, emerald = { 0.16, 0.78, 0.46, 1 },
    azure = { 0.42, 0.76, 1.00, 1 }, crimson = { 0.86, 0.16, 0.28, 1 }, viridian = { 0.26, 0.66, 0.58, 1 },
    vermillion = { 1.00, 0.48, 0.22, 1 }, lunar = { 0.82, 0.86, 1.00, 1 },
}
local function gem_name(gem, group)
    if gem == 'lunar' then return 'Lunar Abyssite' end
    if group == 'Discernment' then return 'Abyssite of Discernment' end
    if group == 'Cosmos' then return 'Abyssite of the Cosmos' end
    local suffix = group == 'Reaper' and 'the Reaper' or group
    return ('%s%s Abyssite of %s'):format(gem:sub(1, 1):upper(), gem:sub(2), suffix)
end

local EXPANSIONS = {
    { key = 'vision', label = 'VISION', color = { 0.48, 0.86, 1.00, 1 },
      zones = { { 15, 'Konschtat' }, { 45, 'Tahrongi' }, { 132, 'La Theine' } } },
    { key = 'scars',  label = 'SCARS',  color = { 1.00, 0.52, 0.42, 1 },
      zones = { { 215, 'Attohwa' }, { 216, 'Misareaux' }, { 217, 'Vunkerl' } } },
    { key = 'heroes', label = 'HEROES', color = { 1.00, 0.80, 0.36, 1 },
      zones = { { 218, 'Altepa' }, { 253, 'Uleguerand' }, { 254, 'Grauberg' } } },
}
local ZONE_EXPANSION = {}
for _, e in ipairs(EXPANSIONS) do for _, z in ipairs(e.zones) do ZONE_EXPANSION[z[1]] = e.key end end

ui.atma_group = ui.atma_group or 'vision'
ui.atma_zone = ui.atma_zone or { vision = 15, scars = 215, heroes = 218 }
ui.atma_filter = ui.atma_filter or 'all'
ui.atma_last_zone = ui.atma_last_zone or -1

-- Follow the player into whichever Abyssea zone they enter.
local function follow_zone()
    local z = player_zone()
    if z == ui.atma_last_zone then return end
    ui.atma_last_zone = z
    local g = ZONE_EXPANSION[z]
    if g then
        ui.atma_group = g
        ui.atma_zone[g] = z
    end
end

local function atma_count_where(pred)
    local owned, total = 0, 0
    for _, a in ipairs(ATMA) do
        if pred(a) then
            total = total + 1
            if has_key_item(a[1]) then owned = owned + 1 end
        end
    end
    return owned, total
end

local function count_badge(o, t) return ('%d/%d'):format(o, t) end
local function badge_col(o, t) return (t > 0 and o == t) and HUD.owned or nil end

local function render_atma_list(pred, accent)
    panel('atma_list', accent, function(x, y, w)
        local dl = DL()
        local lh = line_h()
        local list = {}
        for _, a in ipairs(ATMA) do
            if pred(a) then
                local has = has_key_item(a[1])
                if ui.atma_filter == 'all' or (ui.atma_filter == 'owned') == has then
                    list[#list + 1] = { a, has }
                end
            end
        end
        if #list == 0 then
            local msg = ui.atma_filter == 'owned' and 'None owned here yet.' or 'All collected here!'
            text(x, y, ui.atma_filter == 'owned' and HUD.muted or HUD.owned, msg)
            return lh
        end
        local gap = 18
        local need = 0
        for _, item in ipairs(list) do
            local a = item[1]
            need = math.max(need, 16 + text_w(a[2]) + (a[3] and (12 + text_w(a[3])) or 0) + 8)
        end
        local cols = math.max(1, math.min(3, math.floor((w + gap) / (need + gap))))
        local cw = (w - gap * (cols - 1)) / cols
        local rh = lh + 5
        local rows = math.ceil(#list / cols)
        for i, item in ipairs(list) do
            local a, has = item[1], item[2]
            local c = math.floor((i - 1) / rows)
            local r = (i - 1) % rows
            local cx, cy = x + c * (cw + gap), y + r * rh
            if r % 2 == 0 then dl:AddRectFilled({ cx - 4, cy - 2 }, { cx + cw + 4, cy + lh + 2 }, col(HUD.text, 0.025), 4) end
            draw_check(cx + 5, cy + lh * 0.5, 5, has)
            text(cx + 16, cy, has and HUD.text or HUD.muted, a[2])
            if a[3] then
                -- NM name right-aligned; shortened rather than clipped if space is tight.
                local nm = a[3]
                local room = cw - 16 - text_w(a[2]) - 12
                while #nm > 3 and text_w(nm) > room do nm = nm:sub(1, -2) end
                if nm ~= a[3] then nm = nm:sub(1, -2) .. '.' end
                if text_w(nm) <= room then
                    text(cx + cw - text_w(nm), cy, has and HUD.faint or HUD.subtext, nm)
                end
            end
        end
        return rows * rh - 5
    end)
end

local function render_abyssite_grid()
    panel('abyssites', HUD.accent, function(x, y, w)
        local dl = DL()
        local lh = line_h()
        local name_w = 0
        for _, g in ipairs(ABYSSITES) do name_w = math.max(name_w, text_w(g[1])) end
        local gap = 26
        local col_need = name_w + 12 + 9 * 15 + 10 + text_w('0/9')
        local cols = math.max(1, math.min(3, math.floor((w + gap) / (col_need + gap))))
        local cw = (w - gap * (cols - 1)) / cols
        local rh = lh + 6
        local rows = math.ceil(#ABYSSITES / cols)
        for gi, g in ipairs(ABYSSITES) do
            local c = math.floor((gi - 1) / rows)
            local r = (gi - 1) % rows
            local cx, cy = x + c * (cw + gap), y + r * rh
            local owned = 0
            for _, gem in ipairs(g[2]) do if has_key_item(gem[1]) then owned = owned + 1 end end
            local all = owned == #g[2]
            text(cx, cy, all and HUD.owned or (owned > 0 and HUD.text or HUD.muted), g[1])
            local gx = cx + name_w + 12
            for k, gem in ipairs(g[2]) do
                local gc = GEM_COLOR[gem[2]] or HUD.text
                local has = has_key_item(gem[1])
                local dx, dy = gx + (k - 1) * 15 + 5, cy + lh * 0.5
                local _, hov = hit(('##gem%d'):format(gem[1]), dx - 6, dy - 6, 12, 12)
                if has then
                    dl:AddCircleFilled({ dx, dy }, 7, col(gc, 0.16), 16)
                    dl:AddCircleFilled({ dx, dy }, 4.5, col(gc), 16)
                else
                    dl:AddCircle({ dx, dy }, 4.5, col(gc, 0.45), 16, 1.1)
                end
                if hov then
                    dl:AddCircle({ dx, dy }, 7.5, col(HUD.text, 0.8), 16, 1.1)
                    imgui.SetTooltip(gem_name(gem[2], g[1]) .. (has and '  (owned)' or '  (missing)'))
                end
            end
            local cnt = ('%d/%d'):format(owned, #g[2])
            text(gx + 9 * 15 + 8, cy, all and HUD.owned or HUD.faint, cnt)
        end
        return rows * rh - 6
    end)
end

local function render_atma_tab()
    if not has_required_page() then
        local x, y = imgui.GetCursorScreenPos()
        local w = avail_w()
        local lh = line_h()
        local h = lh * 2 + 24
        card_bg(x, y, w, h, HUD.warn, 0.6 + pulse(2) * 0.4)
        dot(x + 16, y + 10 + lh * 0.5, 4, HUD.warn, 0.4 + pulse(2) * 0.6)
        text(x + 28, y + 10, HUD.warn, 'WAITING FOR KEY ITEM DATA')
        text(x + 28, y + 13 + lh, HUD.muted, 'Zone once after loading the addon.')
        advance(w, h)
        return
    end

    follow_zone()
    local lh = line_h()
    local x, y = imgui.GetCursorScreenPos()
    local w = avail_w()

    -- Level 1: expansions + other + abyssites
    local items = {}
    for _, e in ipairs(EXPANSIONS) do
        local zs = {}
        for _, z in ipairs(e.zones) do zs[z[1]] = true end
        local o, t = atma_count_where(function(a) return zs[a[4]] end)
        items[#items + 1] = { e.key, e.label, count_badge(o, t), badge_col(o, t) }
    end
    local oo, ot = atma_count_where(function(a) return a[4] == 0 end)
    items[#items + 1] = { 'other', 'OTHER', count_badge(oo, ot), badge_col(oo, ot) }
    local ao, at = count_abyssites()
    items[#items + 1] = { 'sites', 'ABYSSITES', count_badge(ao, at), badge_col(ao, at) }

    local picked, _, th = seg_tabs('atma_grp', items, ui.atma_group, x, y, HUD.gold, true)
    if picked then ui.atma_group = picked end
    local row_y = y + th + 6

    -- Level 2: zones (for expansions) + filter, on one row
    local exp = nil
    for _, e in ipairs(EXPANSIONS) do if e.key == ui.atma_group then exp = e end end
    local zh = th
    if exp then
        local zitems = {}
        for _, z in ipairs(exp.zones) do
            local o, t = atma_count_where(function(a) return a[4] == z[1] end)
            local here = player_zone() == z[1]
            zitems[#zitems + 1] = { z[1], (here and '> ' or '') .. z[2], count_badge(o, t), badge_col(o, t) }
        end
        local zp
        zp, _, zh = seg_tabs('atma_zone', zitems, ui.atma_zone[exp.key], x, row_y, exp.color, true)
        if zp then ui.atma_zone[exp.key] = zp end
    end

    if ui.atma_group ~= 'sites' then
        local fitems = { { 'all', 'All' }, { 'owned', 'Owned' }, { 'missing', 'Missing' } }
        local fw = 0
        for _, f in ipairs(fitems) do fw = fw + text_w(f[2]) + 18 + 4 end
        local fy = exp and row_y or row_y
        local fp = seg_tabs('atma_filter', fitems, ui.atma_filter, x + w - fw + 4, fy, HUD.accent, true)
        if fp then ui.atma_filter = fp end
    end

    local used = (exp or ui.atma_group ~= 'sites') and (th + 6 + zh + 6) or (th + 6)
    advance(w, used - 6)

    if ui.atma_group == 'sites' then
        render_abyssite_grid()
    elseif ui.atma_group == 'other' then
        render_atma_list(function(a) return a[4] == 0 end, HUD.muted)
    else
        local zid = ui.atma_zone[exp.key]
        render_atma_list(function(a) return a[4] == zid end, exp.color)
    end
end

--------------------------------------------------------------------------------
-- Stagger alert overlay (its own window, centred on screen, click-through)
--------------------------------------------------------------------------------

local function ease_out_back(t)
    local c1, c3 = 1.70158, 2.70158
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local function render_alerts()
    if #state.alerts == 0 then return end
    local now = os.clock()

    -- Popups only: each alert lives for ALERT_POPUP_TIME, then is gone.
    for i = #state.alerts, 1, -1 do
        if now - state.alerts[i].t0 > ALERT_POPUP_TIME then
            table.remove(state.alerts, i)
        end
    end
    if #state.alerts == 0 then return end

    local io_ok, io = pcall(imgui.GetIO)
    local sw = (io_ok and io and io.DisplaySize and io.DisplaySize.x) or 1920
    local sh = (io_ok and io and io.DisplaySize and io.DisplaySize.y) or 1080

    local ww, wh = 900, 360
    imgui.SetNextWindowPos({ (sw - ww) * 0.5, sh * 0.20 }, ImGuiCond_Always)
    imgui.SetNextWindowSize({ ww, wh }, ImGuiCond_Always)
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 0, 0 })
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0)
    imgui.PushStyleColor(ImGuiCol_WindowBg, { 0, 0, 0, 0 })

    local flags = bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoMove,
        ImGuiWindowFlags_NoInputs, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoSavedSettings,
        ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav, ImGuiWindowFlags_NoBackground or 0)

    if imgui.Begin('##abyhub_stagger_alerts', true, flags) then
        local wx, wy = imgui.GetWindowPos()
        local lh = line_h()
        local y = wy

        for _, a in ipairs(state.alerts) do
            local age = now - a.t0
            local c = a.def.color
            local appear = math.min(1, age / 0.22)
            local fade = age > ALERT_POPUP_TIME - 0.7 and math.max(0, (ALERT_POPUP_TIME - age) / 0.7) or 1
            local alpha = math.min(1, appear * 1.3) * fade
            local scale = 2.6 * (0.85 + 0.15 * ease_out_back(appear))

            local label = a.def.label
            local tw = text_w(label) * scale
            local tx, ty = wx + (ww - tw) * 0.5, y

            -- Dark outline for readability, soft coloured glow, then the text.
            for _, o in ipairs({ { -2, 0 }, { 2, 0 }, { 0, -2 }, { 0, 2 }, { -1, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 } }) do
                text(tx + o[1], ty + o[2], { 0, 0, 0, 0.75 * alpha }, label, scale)
            end
            local glow = (0.25 + pulse(6) * 0.15) * alpha
            for _, o in ipairs({ { -4, 0 }, { 4, 0 }, { 0, -4 }, { 0, 4 } }) do
                text(tx + o[1], ty + o[2], rgba(c, glow * 0.5), label, scale)
            end
            text(tx, ty, rgba(c, alpha), label, scale)

            y = y + lh * scale + 10
        end
    end
    imgui.End()

    imgui.PopStyleColor(1)
    imgui.PopStyleVar(2)
end

local function push_style()
    imgui.PushStyleColor(ImGuiCol_WindowBg, HUD.window_bg)
    imgui.PushStyleColor(ImGuiCol_Border, { 0.30, 0.76, 1.00, 0.22 })
    imgui.PushStyleColor(ImGuiCol_Text, HUD.text)
    imgui.PushStyleColor(ImGuiCol_ScrollbarBg, { 0, 0, 0, 0 })
    imgui.PushStyleColor(ImGuiCol_ScrollbarGrab, { 0.30, 0.76, 1.00, 0.25 })
    imgui.PushStyleColor(ImGuiCol_ScrollbarGrabHovered, { 0.30, 0.76, 1.00, 0.45 })
    imgui.PushStyleColor(ImGuiCol_ScrollbarGrabActive, { 0.30, 0.76, 1.00, 0.65 })
    imgui.PushStyleColor(ImGuiCol_ResizeGrip, { 0.30, 0.76, 1.00, 0.10 })
    imgui.PushStyleColor(ImGuiCol_ResizeGripHovered, { 0.30, 0.76, 1.00, 0.35 })
    imgui.PushStyleColor(ImGuiCol_ResizeGripActive, { 0.30, 0.76, 1.00, 0.60 })

    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 10.0)
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.0)
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 10, 8 })
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 6, 5 })
    imgui.PushStyleVar(ImGuiStyleVar_ScrollbarSize, 8.0)
    imgui.PushStyleVar(ImGuiStyleVar_ScrollbarRounding, 6.0)
end

local function pop_style()
    imgui.PopStyleVar(6)
    imgui.PopStyleColor(10)
end

ashita.events.register('d3d_present', 'abyhub_present_cb', function()
    update_vana_time()
    update_target()
    update_target_id()
    load_lights()
    render_alerts()

    if not state.visible[1] then return end

    push_style()

    -- The window fits its content; only height is capped (then it scrolls).
    local io_ok, io = pcall(imgui.GetIO)
    local sh = (io_ok and io and io.DisplaySize and io.DisplaySize.y) or 1080
    if type(imgui.SetNextWindowSizeConstraints) == 'function' then
        imgui.SetNextWindowSizeConstraints({ 0, 0 }, { 4096, sh * 0.85 })
    end

    local flags = bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_AlwaysAutoResize)
    if imgui.Begin('Abyssea Toolkit##abyhub_combined', state.visible, flags) then
        ui.left_x = imgui.GetCursorScreenPos()
        ui.cw = content_width()
        render_header()
        render_lights_bar()
        if state.tab == 1 then
            render_key_items()
        elseif state.tab == 3 then
            render_atma_tab()
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
        ('v%s loaded - combined Key Items + Staggers. Use /aby.'):format(addon.version)
    )))
end)
