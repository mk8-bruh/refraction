local floor = math.floor
local round = function(n) return floor(n + 0.5) end
local sqrt, abs, sin, cos, asin, acos, atan2 = math.sqrt, math.abs, math.sin, math.cos, math.asin, math.acos, math.atan2
local fstr = string.format
local str = function(v) return type(v) == "string" and '"'..v..'"' or tostring(v) end
local isn, nbetween = function(x) return type(x) == 'number' end, function(x, a, b) return x >= a and x <= b end
local ang = function(x) return math.pi - ((math.pi - x) % (2*math.pi)) end

local reg, repr = setmetatable({}, {__mode = "v"}), setmetatable({}, {__mode = "k"})

local vec, mt = {}, {}

local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        const double x, y, sqrLen, len, atan2;
    } vec;
]]

local constr = ffi.metatype("vec", mt)

local function coordStr(x, y)
    return fstr("(%s, %s)", str(x), str(y))
end

local function new(x, y)
    if not isn(x) and isn(y) or tostring(x):match("nan") or tostring(y):match("nan") then
        error(fstr("Both vector components must be numbers (got: %s, %s)", str(x), str(y)), 3)
    end
    if vec.precision then
        x, y = round(x / vec.minStep) * vec.minStep, round(y / vec.minStep) * vec.minStep
    end

    local k = coordStr(x, y)
    if reg[k] then
        return reg[k]
    end

    local sqrLen = x * x + y * y
    local len = sqrt(sqrLen)
    local ang = atan2(y, x)

    local p = constr(x, y, sqrLen, len, ang)
    reg[k] = p
    repr[p] = k

    return p
end

function vec.is(v)
    return repr[v] ~= nil
end

function vec.unpack(v)
    if vec.is(v) then
        return v.x, v.y
    end
end

function vec.fromString(s)
    if type(s) == 'string' then
        local x, y = s:match('^%s*[%(%{%[]?(.-)[,;](.-)[%)%}%]]?%s*$')
        if tonumber(x) and tonumber(y) then
            return new(tonumber(x), tonumber(y))
        else
            error(fstr("Attempted to convert invalid string to vector (%q)", s), 2)
        end
    else
        error(fstr("Attempted to convert non-string value to vector (%s)", str(s)), 2)
    end
end

function vec.flattenArray(a)
    if type(a) ~= "table" then return end
    local t = {}
    for i, v in ipairs(a) do
        if not vec.is(v) then
            error(fstr("Attempted to flatten array with non-vector values (%s)", str(v)), 2)
        end
        table.insert(t, v.x)
        table.insert(t, v.y)
    end
    return t
end

function vec.normal(v)
    if vec.is(v) then
        return v == vec.zero and vec.zero or v / v.len
    else
        error(fstr("Normalization only supported on operands of type: [vector] (got: %s)", str(v)), 2)
    end
end

function vec.dot(a, b)
    if vec.is(a) and vec.is(b) then
        return a.x * b.x + a.y * b.y
    else
        error(fstr("Dot product only supported on operands of type: [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function vec.det(a, b)
    if vec.is(a) and vec.is(b) then
        return a.x * b.y - a.y * b.x
    else
        error(fstr("Cross product only supported on operands of type: [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function vec.angle(a, b)
    if vec.is(a) and vec.is(b) then
        return asin(a:normal():dot(b:normal()))
    else
        error(fstr("Angle measurement only supported on operands of type: [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function vec.signedAngle(a, b)
    if vec.is(a) and vec.is(b) then
        return asin(a:normal():det(b:normal()))
    else
        error(fstr("Signed angle measurement only supported on operands of type: [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function vec.polar(a, l)
    if isn(a) and (isn(l) or l == nil) then
        return new(cos(a), sin(a)) * (l or 1)
    else
        error(fstr("Both direction and length must be numbers (got: %s, %s)", str(a), str(b)), 2)
    end
end

function vec.rotate(v, a)
    if vec.is(v) and isn(a) then
        local s, c = sin(a), cos(a)
        return new(v.x * c - v.y * s, v.x * s + v.y * c)
    else
        error(fstr("Rotation only supported on operands of type: [vector, number] (got: %s, %s)", str(v), str(a)), 2)
    end
end

function vec.lerp(a, b, t)
    if vec.is(a) and vec.is(b) and isn(t) then
        return a + (b - a) * t
    else
        error(fstr("Linear interpolation only supported on operands of type: [vector, vector, number] (got: %s, %s, %s)", str(a), str(b), str(t)), 2)
    end
end

function vec.moveTo(a, b, d)
    if vec.is(a) and vec.is(b) and isn(d) then
        return a + (b - a):normal() * d
    else
        error(fstr("Absolute interpolation only supported on operands of type: [vector, vector, number] (got: %s, %s, %s)", str(a), str(b), str(d)), 2)
    end
end

function vec.project(a, b)
    if vec.is(a) and vec.is(b) then
        if a.len == 0 or b.len == 0 then return vec.zero end
        return vec.dot(a, b) / b.sqrLen * b
    else
        error(fstr("Projection only supported on operands of type: [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function vec.setLen(v, l)
    if vec.is(v) and isn(l) then
        return v:normal() * l
    else
        error(fstr("Length modification only supported on operands of type: [vector, number] (got: %s, %s)", str(v), str(l)), 2)
    end
end

function vec.maxLen(v, l)
    if vec.is(v) and isn(l) then
        return v:normal() * math.min(v.len, l)
    else
        error(fstr("Length capping only supported on operands of type: [vector, number] (got: %s, %s)", str(v), str(l)), 2)
    end
end

function vec.minLen(v, l)
    if vec.is(v) and isn(l) then
        return v:normal() * math.max(v.len, l)
    else
        error(fstr("Length flooring only supported on operands of type: [vector, number] (got: %s, %s)", str(v), str(l)), 2)
    end
end

function vec.clampLen(v, a, b)
    if vec.is(v) and isn(a) and isn(b) then
        a, b = math.min(a, b), math.max(a, b)
        return v:normal() * math.max(a, math.min(b, v.len))
    else
        error(fstr("Length clamping only supported on operands of type: [vector, number, number] (got: %s, %s, %s)", str(v), str(a), str(b)), 2)
    end
end

function mt.__add(a, b)
    if vec.is(a) and vec.is(b) then
        return new(a.x + b.x, a.y + b.y)
    else
        error(fstr("Vector addition only supported on operands of type: [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function mt.__sub(a, b)
    if vec.is(a) and vec.is(b) then
        return new(a.x - b.x, a.y - b.y)
    else
        error(fstr("Vector subtraction only supported on operands of type: [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function mt.__mul(a, b)
    if vec.is(a) and vec.is(b) then
        return new(a.x * b.x, a.y * b.y)
    elseif vec.is(a) and isn(b) then
        return new(a.x * b, a.y * b)
    elseif isn(a) and vec.is(b) then
        return new(a * b.x, a * b.y)
    else
        error(fstr("Vector multiplication only supported on operands of type: [vector, vector], [vector, scalar], [scalar, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function mt.__div(a, b)
    if vec.is(a) and vec.is(b) then
        return new(a.x / b.x, a.y / b.y)
    elseif vec.is(a) and isn(b) then
        return new(a.x / b, a.y / b)
    elseif isn(a) and vec.is(b) then
        return new(a / b.x, a / b.y)
    else
        error(fstr("Vector division only supported on operands of type: [vector, vector], [vector, scalar], [scalar, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function mt.__pow(a, b)
    if vec.is(a) and isn(b) then
        return new(a.x ^ b, a.y ^ b)
    elseif vec.is(a) and vec.is(b) then
        return new(a.x ^ b.x, a.y ^ b.y)
    else
        error(fstr("Vector exponentiation only supported on operands of type: [vector, scalar], [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function mt.__mod(a, b)
    if vec.is(a) and isn(b) then
        return new(a.x % b, a.y % b)
    elseif vec.is(a) and vec.is(b) then
        return new(a.x % b.x, a.y % b.y)
    else
        error(fstr("Vector modulo only supported on operands of type: [vector, scalar], [vector, vector] (got: %s, %s)", str(a), str(b)), 2)
    end
end

function mt.__unm(v)
    return new(-v.x, -v.y)
end

function mt.__tostring(v)
    return repr[v]
end

mt.__index = vec

function mt.__newindex(v, k, n)
    error("Attempted to index a vector value", 2)
end

mt.__metatable = {}

vec.zero  = new( 0,  0)
vec.one   = new( 1,  1)
vec.left  = new(-1,  0)
vec.right = new( 1,  0)
vec.up	  = new( 0, -1)
vec.down  = new( 0,  1)

local p = newproxy(true)
local lib = getmetatable(p)

lib.__index = vec

function lib.__newindex(t, k, v)
    if k == "precision" then
        if not isn(v) or v % 1 > 0 then
            error("Vector decimal precision value must be an integer", 2)
        end
        vec.precision = v
        vec.minStep = 10 ^ (-v)
    end
end

function lib.__call(t, ...)
    return new(...)
end

lib.__metatable = {}

function lib.__tostring(t)
    return '<2D vector module>'
end


return p