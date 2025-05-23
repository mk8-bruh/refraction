local sqrt, abs, sin, cos, asin, acos, atan2 = math.sqrt, math.abs, math.sin, math.cos, math.asin, math.acos, math.atan2
local fstr = string.format
local isn, nbetween = function(x) return type(x) == 'number' end, function(x, a, b) return x >= a and x <= b end
local ang = function(x) return math.pi - ((math.pi - x) % (2*math.pi)) end

local vecs = setmetatable({}, {__mode = "k"})
local lib, mt
lib = {
	new = function(x, y)
		if isn(x) and isn(y) then
			local v = {x = x, y = y}
			vecs[v] = true
			return setmetatable(v, mt)
		end
	end,
	is = function(v) return type(v) == "table" and isn(v.x) and isn(v.y) and vecs[v] and getmetatable(v) == mt end,
	unpack = function(v)
		if lib.is(v) then
			return v.x, v.y
		end
	end,
	clone = function(v)
		if lib.is(v) then
			return lib.new(v.x, v.y)
		end
	end,
	fromString = function(s)
		if type(s) == 'string' then
			local x, y = s:match('^%s*[%(%{%[]?(.-)[,;](.-)[%)%}%]]?%s*$')
			if tonumber(x) and tonumber(y) then
				return lib.new(tonumber(x), tonumber(y))
			end
		end
	end,
	convertArray = function(a)
		if type(a) ~= "table" then return end
		local t = {}
		for i,v in ipairs(a) do
			if not lib.is(v) then break end
			table.insert(t, v.x)
			table.insert(t, v.y)
		end
		return t
	end,
	normal = function(v)
		if lib.is(v) then
			return v.len > 0 and v/v.len or vec(0, 0)
		end
	end,
	dot = function(a, b)
		if lib.is(a) and lib.is(b) then
			return a.x * b.x + a.y * b.y
		end
	end,
	det = function(a, b)
		if lib.is(a) and lib.is(b) then
			return a.x * b.y - a.y * b.x
		end
	end,
	angle = function(v)
		if lib.is(v) then
			return ang(atan2(v.y, v.x))
		end
	end,
	angleBetween = function(a, b)
		if lib.is(a) and lib.is(b) then
			return asin(a.norm:dot(b.norm))
		end
	end,
	angleTo = function(a, b)
		if lib.is(a) and lib.is(b) then
			return asin(a.norm:det(b.norm))
		end
	end,
	polar = function(a)
		if isn(a) then
			return lib.new(cos(a), sin(a))
		end
	end,
	rotate = function(v, a)
		if lib.is(v) and isn(a) then
			local s, c = sin(a), cos(a)
			return lib.new(v.x * c - v.y * s, v.x * s + v.y * c)
		end
	end,
	lerp = function(a, b, t)
		if lib.is(a) and lib.is(b) and isn(t) then
			return a + (b - a) * t
		end
	end,
	moveTo = function(a, b, d)
		if lib.is(a) and lib.is(b) and isn(d) then
			return a + lib.normal(b - a) * d
		end
	end,
	project = function(a, b)
		if lib.is(a) and lib.is(b) then
			if a.len == 0 or b.len == 0 then return vec(0, 0) end
			return lib.dot(a, b) / b.sqrLen * b
		end
	end,
	setLen = function(v, l)
		if lib.is(v) and isn(l) then
			return v.norm * l
		end
	end,
	maxLen = function(v, l)
		if lib.is(v) and isn(l) then
			return v.norm * math.min(v.len, l)
		end
	end,
	minLen = function(v, l)
		if lib.is(v) and isn(l) then
			return v.norm * math.max(v.len, l)
		end
	end,
	clampLen = function(v, a, b)
		if lib.is(v) and isn(a) and isn(b) then
			a, b = math.min(a, b), math.max(a, b)
			return v.norm * math.max(a, math.min(b, v.len))
		end
	end
}

mt = {
	__add = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x+b.x, a.y+b.y)
		end
	end,
	__sub = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x-b.x, a.y-b.y)
		end
	end,
	__mul = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x*b.x, a.y*b.y)
		elseif lib.is(a) and isn(b) then
			return lib.new(a.x*b, a.y*b)
		elseif isn(a) and lib.is(b) then
			return lib.new(a*b.x, a*b.y)
		end
	end,
	__div = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x/b.x, a.y/b.y)
		elseif lib.is(a) and isn(b) then
			return lib.new(a.x/b, a.y/b)
		elseif isn(a) and lib.is(b) then
			return lib.new(a/b.x, a/b.y)
		end
	end,
	__pow = function(a, b)
		if lib.is(a) and isn(b) then
			return lib.new(a.x^b, a.y^b)
		elseif lib.is(a) and lib.is(b) then
			return lib.new(a.x^b.x, a.y^b.y)
		end
	end,
	__mod = function(a, b)
		if lib.is(a) and isn(b) then
			return lib.new(a.x%b, a.y%b)
		elseif lib.is(a) and lib.is(b) then
			return lib.new(a.x%b.x, a.y%b.y)
		end
	end,
	__unm = function(v) return lib.new(-v.x, -v.y) end,
	__len = function(v) return v.len end,
	__tostring = function(v) return fstr('(%s, %s)', tostring(v.x), tostring(v.y)) end,
	__index = function(v, k) if k == "len" then return sqrt(v:dot(v)) elseif k == "sqrLen" then return v:dot(v) elseif k == "norm" then return v:normal() elseif k == "ang" then return v:angle() elseif k == "str" then return tostring(v) else return lib[k] end end
}

local consts = {
	zero  = function() return lib.new( 0,  0) end,
	one   = function() return lib.new( 1,  1) end,
	left  = function() return lib.new(-1,  0) end,
	right = function() return lib.new( 1,  0) end,
	up	  = function() return lib.new( 0, -1) end,
	down  = function() return lib.new( 0,  1) end
}

return setmetatable({}, {
	__index = function(t, k)
		if consts[k] then
			return consts[k]()
		else
			return lib[k]
		end
	end,
	__newindex = function() end,
	__call = function(t,...) return lib.new(...) end,
	__metatable = {},
	__tostring = function() return '<2D vector module>' end
})