-- Welcome to Nanotech!

-- Check if the current snapshot supports tmp3/tmp4
-- Otherwise, use pavg0/1
local tmp3 = "pavg0"
local tmp4 = "pavg1"
if sim.FIELD_TMP3 then -- Returns nil if tmp3 is not part of the current snapshot
	tmp3 = "tmp3"
	tmp4 = "tmp4"
end

if not nanotech then
    nanotech = {}
end

-- Tables and utility functions
local photDataTypes = {
    [elem.DEFAULT_PT_FILT] = true,
    [elem.DEFAULT_PT_PHOT] = true,
    [elem.DEFAULT_PT_BRAY] = true,
}

local usnsNoConduct = {
    [elem.DEFAULT_PT_WATR] = true,
    [elem.DEFAULT_PT_SLTW] = true,
    [elem.DEFAULT_PT_NTCT] = true,
    [elem.DEFAULT_PT_PTCT] = true,
    [elem.DEFAULT_PT_INWR] = true,
}

local function acceptedConductor(r)
    local type = sim.partProperty(r, "type")
    return bit.band(elem.property(type, "Properties"), elem.PROP_CONDUCTS) and not usnsNoConduct(type) and sim.partProperty(r, "life") == 0
end

local function raycast(x, y, dx, dy, range)
    local i = 0
    while i < range && (x >= 0 && y >= 0 && x < sim.XRES && y < sim.YRES) do
        x = x + dx
        y = y + dy
        local r = sim.pmap(x, y)
        if r ~= nil then
            return r
        end
        i++
    end
    return nil
end

-- Element definitions
local nano = elem.allocate("NANOTECH", "NANO") -- Nanobots
local snano = elem.allocate("NANOTECH", "SNANO") -- Solid nanobots
local nclne = elem.allocate("NANOTECH", "NCLNE") -- Nanobot cloner

local usns = elem.allocate("NANOTECH", "USNS") -- Universal sensor



-- NANO
elem.element(nano, elem.element(elem.DEFAULT_PT_EQVE))
elem.property(nano, "Name", "NANO")
elem.property(nano, "Description", "Nanobots. Programmable critters with several modes and flexible modifiers. Shift-click to program.")
elem.property(nano, "Colour", 0x0B2D4B)
elem.property(nano, "HighTemperature", 6000)
elem.property(nano, "HighTemperatureTransition", elem.DEFAULT_PT_BREL)
elem.property(nano, "MenuVisible", 1)
elem.property(nano, "MenuSection", elem.SC_POWERED)
elem.property(nano, "Diffusion", 0.1)
elem.property(nano, "HeatConduct", 5)

elem.property(nano, "Update", function(i, x, y, s, n)
    nanoUpdate(i, x, y)
end)

-- USNS
elem.element(usns, elem.element(elem.DEFAULT_PT_DTEC))
elem.property(usns, "Name", "USNS")
elem.property(usns, "Description", "Universal sensor. Highly configurable sensor with serialization capabilities. Shift-click to configure.")
elem.property(usns, "Colour", 0x6920CF)

elem.property(usns, "Update", function(i, x, y, s, n)
    usnsUpdate(i, x, y)
end)

elem.property(usns, "CtypeDraw", function(i, t)
	if bit.band( elem.property(t, "Properties"), elem.PROP_NOCTYPEDRAW) == 0 then
		sim.partProperty(i, "ctype", t)
	end
end)

-- NANO logic
function nanoUpdate(i, x, y)

end

-- USNS logic
function usnsUpdate(i, x, y)

end


-- Particle editing logic
-- TODO: Detect if the user shift-clicked a particle of NANO or USNS

-- TODO: NANO configuration UI

-- TODO: USNS configuration UI