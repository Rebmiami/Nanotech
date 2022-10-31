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

-- Writes ctype data to a line of FILT particles
local function writeFiltLine(x, y, rx, ry, wl)
	if boundsCheck(x + rx, y + ry) and not (rx == 0 and ry == 0) then
		r = sim.pmap(x + rx, y + ry)
		if r then
			local nx = x + rx;
			local ny = y + ry;
			-- Trace a line of FILT
			while (r and sim.partProperty(r, "type") == elem.DEFAULT_PT_FILT) do
				sim.partProperty(r, "ctype", wl);
				nx = nx + rx
				ny = ny + ry
				if not boundsCheck(nx, ny) then
					break;
				end
				r = sim.pmap(nx, ny)
			end
		end
	end
end

local function sparkInRange(x, y)
	local r
	local rt
	local rx = -2
	while rx <= 2 do
		local ry = -2
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

local function maskAndDivide(num, mask, floor)
	return bit.band(num, mask) / floor
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


local usnsDetectIgnore = {
	[elem.DEFAULT_PT_METL] = true,

}
local usnsSerializeIgnore = {
	[elem.DEFAULT_PT_FILT] = true,
}

local function usnsIgnore(type, dm)
	if dm == 4 then
		return usnsSerializeIgnore[type]
	end
	return usnsDetectIgnore[type]
end

local propertyNames = {
	[0x0] = "type",
	[0x1] = "life",
	[0x2] = "ctype",
	[0x3] = "temp",
	[0x4] = "tmp",
	[0x5] = "tmp2",
	[0x6] = tmp3,
	[0x7] = tmp4
}

-- Used when USNS decides if it should release a spark
local comparisonOperators = {
	[0x0] = function(a, b) return a >= b end,
	[0x1] = function(a, b) return a < b end,
	[0x2] = function(a, b) return a == b end,
	[0x3] = function(a, b) return a ~= b end,
	[0x4] = nil, -- Not a comparison operator
	[0x5] = nil, -- Not a comparison operator
}

local searchParticleFunctions = {
	[0x0] = function(plist, prop) -- Highest
		local val = nil
		for i, j in pairs(plist) do
			local a = sim.partProperty(j, prop)
			if not val or a > val then
				val = a
			end
		end
		return val
	end,
	[0x1] = function(plist, prop) -- Lowest
		local val = nil
		for i, j in pairs(plist) do
			local a = sim.partProperty(j, prop)
			if not val or a < val then
				val = a
			end
		end
		return val
	end,
	[0x2] = function(plist, prop) -- First by position
		local val = nil
		for i, j in pairs(plist) do
			val = sim.partProperty(j, prop)
			break
		end
		return val
	end,
	[0x3] = function(plist, prop) -- Last position
		local val = nil
		for i, j in pairs(plist) do
			val = sim.partProperty(j, prop)
		end
		return val
	end,
}


-- USNS logic
function usnsUpdate(i, x, y)
	local tmp = sim.partProperty(i, "tmp")
	local dm = maskAndDivide(tmp, 0x000F, 0x0001) -- Detection Mode
	local sm = maskAndDivide(tmp, 0x00F0, 0x0010) -- Search Mode
	local ds = maskAndDivide(tmp, 0x0F00, 0x0100) -- Detection Shape
	local prop = propertyNames[maskAndDivide(tmp, 0xF000, 0x1000)]

	local ctype = sim.partProperty(i, "ctype")
	local ts = math.floor(math.max(sim.partProperty(i, "temp") - 273.15, 0)) -- ThreShold


    local rx
    local ry
    local rd = sim.partProperty(i, "tmp2")

	if rd > 25 then 
        sim.partProperty(i, "tmp2", 25)
        rd = 25
    end

	-- Search for all particles in range
	local particles = {}

	-- TODO: Search Mode 0x5
	-- if sm == 5 then
	-- 	value = ts - dm % 2
	-- end

	-- Look for nearby particles and them add them to a list
	rx = -rd
	while rx <= rd do
		ry = -rd
		while ry <= rd do
			if boundsCheck(x + rx, y + ry) and not (rx == 0 and ry == 0) then
				r = sim.pmap(x + rx, y + ry) or sim.photons(x + rx, y + ry)
				if r then
					local type = sim.partProperty(r, "type")
					if (ctype == 0 or type == ctype) and not usnsIgnore(type, dm) then
						table.insert(particles, r)
					end
				end
			end
			ry = ry + 1
		end
		rx = rx + 1
	end

	-- Extract a numerical value from the list of particles obtained
	local val = searchParticleFunctions[sm](particles, prop)
	-- print(val)

	-- Perform an action based on the numerical value
	if val then
		if comparisonOperators[dm] then
			-- Classic detection
			if prop == "type" or comparisonOperators[dm](val, ts) then
				sparkInRange(x, y)
			end
		elseif dm == 4 then
			-- Serialization
			local wl = 0x10000000 + val
			rx = -1
			while rx <= 1 do
				ry = -1
				while ry <= 1 do
					writeFiltLine(x, y, rx, ry, wl)
					ry = ry + 1
				end
				rx = rx + 1
			end
		elseif dm == 5 then
			-- Deserialization TODO
		end
	end
end


-- Particle editing logic
-- TODO: Detect if the user shift-clicked a particle of NANO or USNS

-- TODO: NANO configuration UI

-- TODO: USNS configuration UI