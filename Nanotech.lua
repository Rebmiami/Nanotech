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
    return bit.band(elem.property(type, "Properties"), elem.PROP_CONDUCTS) ~= 0
	and not usnsNoConduct[type]
	and sim.partProperty(r, "life") == 0
end

local function boundsCheck(x, y)
    return x >= 0 and y >= 0 and x < sim.XRES and y < sim.YRES
end

local function raycast(x, y, dx, dy, range)
    local i = 0
    while i < range and (x >= 0 and y >= 0 and x < sim.XRES and y < sim.YRES) do
        x = x + dx
        y = y + dy
        local r = sim.pmap(x, y)
        if r ~= nil then
            return r
        end
        i = i + 1
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
elem.property(nano, "DefaultProperties", 
{ 
    ctype = 0x40000000 

});

elem.property(nano, "Update", function(i, x, y, s, n)
    nanoUpdate(i, x, y)
end)

-- USNS
elem.element(usns, elem.element(elem.DEFAULT_PT_DTEC))
elem.property(usns, "Name", "USNS")
elem.property(usns, "Description", "Universal sensor. Highly configurable sensor with serialization capabilities. Shift-click to configure.")
elem.property(usns, "Colour", 0x6920CF)
elem.property(usns, "Properties", elem.TYPE_SOLID + elem.PROP_NOCTYPEDRAW + elem.PROP_NOAMBHEAT)
elem.property(usns, "DefaultProperties", 
{ 
    tmp = 0x00000000,
    tmp2 = 2,
});

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
    local r
    local rx
    local ry
    local rt
    local rd = sim.partProperty(i, "tmp2")

	if rd > 25 then 
        sim.partProperty(i, "tmp2", 25)
        rd = 25
    end
	if sim.partProperty(i, "life") ~= 0 then
		sim.partProperty(i, "life", 0)
        rx = -2
		while rx <= 2 do
			ry = -2
			while ry <= 2 do
				if boundsCheck(x + rx, y + ry) and not (rx == 0 and ry == 0) then
					r = sim.pmap(x + rx, y + ry)
					if r then
						rt = sim.partProperty(r, "type");
						if acceptedConductor(r) then
							sim.partProperty(r, "life", 4);
							sim.partProperty(r, "ctype", rt);
							sim.partChangeType(r, elem.DEFAULT_PT_SPRK);
						end
                    end
				end
                ry = ry + 1
            end
            rx = rx + 1
        end
    end
	local setFilt = false
	local photonWl = 0
	rx = -rd
	while rx <= rd do
		ry = -rd
		while ry <= rd do
			if boundsCheck(x + rx, y + ry) and not (rx == 0 and ry == 0) then
				r = sim.pmap(x + rx, y + ry)
				if not r then
					r = sim.photons(x + rx, y + ry)
				end
				if r then
					if sim.partProperty(r, "type") == sim.partProperty(i, "ctype") then
						sim.partProperty(i, "life", 1)
					end
					if sim.partProperty(r, "type") == elem.DEFAULT_PT_PHOT 
					or (sim.partProperty(r, "type") == elem.DEFAULT_PT_BRAY and sim.partProperty(r, "tmp") ~= 2) then
						setFilt = true
						photonWl = sim.partProperty(r, "ctype")
					end
				end
			end
			ry = ry + 1
		end
		rx = rx + 1
	end
	if setFilt then
		local nx
		local ny
		rx = -1
		while rx < 2 do
			ry = -1
			while ry < 2 do
				if boundsCheck(x + rx, y + ry) and not (rx == 0 and ry == 0) then
					r = sim.pmap(x + rx, y + ry)
					if r then
						nx = x+rx;
						ny = y+ry;
						while (r and sim.partProperty(r, "type") == elem.DEFAULT_PT_FILT) do
							sim.partProperty(r, "ctype", photonWl);
							nx = nx + rx
							ny = ny + ry
							if not boundsCheck(nx, ny) then
								break;
							end
							r = sim.pmap(nx, ny)
						end
					end
				end
				ry = ry + 1
			end
			rx = rx + 1
		end
	end
	return 0;
end


-- Particle editing logic
-- TODO: Detect if the user shift-clicked a particle of NANO or USNS

-- TODO: NANO configuration UI

-- TODO: USNS configuration UI