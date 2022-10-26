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

-- Element definitions
local nano = elem.allocate("NANOTECH", "NANO") -- Nanobots
local snano = elem.allocate("NANOTECH", "SNANO") -- Solid nanobots
local nclne = elem.allocate("NANOTECH", "NCLNE") -- Nanobot cloner

local usns = elem.allocate("NANOTECH", "USNS") -- Universal sensor



-- NANO
elem.element(nano, elem.element(elem.DEFAULT_PT_EQVE))
elem.property(nano, "Name", "NANO")
elem.property(nano, "Description", "Nanobots. Programmable critters with several modes and customizable modifiers.")
elem.property(nano, "Colour", 0x0B2D4B)
elem.property(nano, "HighTemperature", 9000)
elem.property(nano, "HighTemperatureTransition", elem.DEFAULT_PT_BREL)
elem.property(nano, "MenuSection", elem.SC_POWERED)

elem.property(nano, "Update", function(i, x, y, s, n)
    nanobotUpdate(i, x, y)
end)

-- USNS
elem.element(usns, elem.element(elem.DEFAULT_PT_DTEC))
elem.property(usns, "Name", "USNS")
elem.property(usns, "Description", "Universal sensor. Highly configurable sensor with serialization capabilities.")
elem.property(usns, "Colour", 0x6920CF)

elem.property(usns, "Update", function(i, x, y, s, n)
    
end)



function nanobotUpdate(i, x, y)

end