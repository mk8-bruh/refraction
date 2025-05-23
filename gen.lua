local vec = require "vec"

function circumcenter(a, b, c)
    return vec(
        (a:dot(a) * (b.y - c.y) + b:dot(b) * (c.y - a.y) + c:dot(c) * (a.y - b.y)),
        (a:dot(a) * (c.x - b.x) + b:dot(b) * (a.x - c.x) + c:dot(c) * (b.x - a.x))
    ) / 2 / (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
end

function circumradius(a, b, c)
    local A, B, C = (b - c).len, (a - c).len, (a - b).len
    return (A * B * C) / math.sqrt((A + B + C) * (A + B - C) * (A + C - B) * (B + C - A))
end

function circumCircleContains(p, a, b, c)
    return (p - circumcenter(a, b, c)).len <= circumradius(a, b, c)
end

function superTriangle(points)
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge
    for _, p in ipairs(points) do
        if p.x < min_x then min_x = p.x end
        if p.y < min_y then min_y = p.y end
        if p.x > max_x then max_x = p.x end
        if p.y > max_y then max_y = p.y end
    end
    local dx, dy = max_x - min_x, max_y - min_y
    local delta_max = math.max(dx, dy) * 10
    local p1 = vec(min_x - delta_max, min_y - delta_max)
    local p2 = vec(min_x + delta_max * 2, min_y - delta_max)
    local p3 = vec(min_x - delta_max, min_y + delta_max * 2)
    return {p1, p2, p3}
end

function merge(a, b)
    local t = {}
    for k, v in pairs(a) do t[k] = v end
    for k, v in pairs(b) do t[k] = v end
    return t
end

function filter(t, f)
    for i = #t, 1, -1 do
        if not f(t[i]) then
            table.remove(t, i)
        end
    end
end

function triangle(a, b, c)
    if a ~= b and b ~= c and c ~= a then
        return {a, b, c, points = {[a] = 1, [b] = 2, [c] = 3}}
    end
end

function delaunay(points)
    local r, n = {}, {}
    local st = superTriangle(points)
    local p = merge(points, {[-2] = st[1], [-1] = st[2], [0] = st[3]})
    table.insert(r, triangle(-2, -1, 0))
    for i, v in ipairs(p) do
        local bt, b = {}, {}
        for j = #r, 1, -1 do
            if circumCircleContains(v, p[r[j][1]], p[r[j][2]], p[r[j][3]]) then
                table.insert(bt, table.remove(r, j))
            end
        end
        for _, t in ipairs(bt) do
            local e = {false, false, false}
            for _, o in ipairs(bt) do
                if t ~= o then
                    e[1], e[2], e[3] = e[1] or (o.points[t[1]] and o.points[t[2]]), e[2] or (o.points[t[2]] and o.points[t[3]]), e[3] or (o.points[t[3]] and o.points[t[1]])
                end
            end
            if not e[1] then table.insert(b, {t[1], t[2]}) end
            if not e[2] then table.insert(b, {t[2], t[3]}) end
            if not e[3] then table.insert(b, {t[3], t[1]}) end
        end
        for _, e in ipairs(b) do
            table.insert(r, triangle(i, unpack(e)))
        end
    end
    for i = #r, 1, -1 do
        local t = r[i]
        if t.points[-2] or t.points[-1] or t.points[0] then
            table.remove(r, i)
        else
            for j = 1, 3 do
                n[t[j]] = n[t[j]] or {}
                for k = 1, 3 do
                    if j ~= k then
                        n[t[j]][t[k]] = true
                    end
                end
            end
        end
    end
    return r, n
end

function fractalNoise(x, y, seed, layers)   
    local v = 0
    for l = 0, (layers or 1) - 1 do
        v = v + love.math.noise((2^l + seed) * x, (2^l + seed) * y) / 2^(l+1)
    end
    return v
end

function hash(n)
    n = bit.bxor(n, bit.rshift(n, 16))
    n = bit.band(n * 0x45d9f3b, 0xFFFFFFFF)
    n = bit.bxor(n, bit.rshift(n, 16))
    n = bit.band(n * 0x45d9f3b, 0xFFFFFFFF)
    n = bit.bxor(n, bit.rshift(n, 16))
    return n
end

function hashNoise2D(seed, x, y)
    return vec(
        hash(x * 3747613932 + y * 6682652638 + seed * 921451653) / 0xFFFFFFFF,
        hash(x * 1443055738 + y * 1274126177 + seed * 362827313) / 0xFFFFFFFF
    )
end

local genRadius = 1
local offsetRange = 0.5

function generateVoronoiCell(seed, x, y)
    x, y = math.floor(x), math.floor(y)
    local r = {
        position = vec(x, y),
        anchor = nil,
        vertices = {},
        edges = {},
        neighbors = {}
    }
    r.anchor = vec(x, y) + ((1 - offsetRange)/2 * vec.one) + (offsetRange * hashNoise2D(seed, x, y))
    local p, cp = {}, {}
    for x = x - genRadius, x + genRadius do
        for y = y - genRadius, y + genRadius do
            table.insert(p, vec(x, y) + ((1 - offsetRange)/2 * vec.one) + (offsetRange * hashNoise2D(seed, x, y)))
            table.insert(cp, vec(x, y))
        end
    end
    local d = delaunay(p)
    filter(d, function(t) return t.points[2*genRadius^2 + 2*genRadius + 1] end)
    local cc = {}
    local angle = {}
    for _, t in ipairs(d) do
        cc[t] = circumcenter(p[t[1]], p[t[2]], p[t[3]])
        angle[t] = (cc[t] - r.anchor).ang
    end
    table.sort(d, function(a, b) return angle[a] < angle[b] end)
    for i, t in ipairs(d) do
        table.insert(r.vertices, cc[t])
        local edge = {cc[t], cc[d[i % #d + 1]]}
        table.insert(r.edges, edge)
        table.remove(t, t.points[2*genRadius^2 + 2*genRadius + 1])
        r.neighbors[edge] = cp[d[i % #d + 1].points[t[1]] and t[1] or t[2]]
    end
    return r
end

function nearestPoint(x, type, o, p)
    local v = type:match("vector") and p or (p - o)
    local d = x - o
    local t = v:dot(d) / v.sqrLen
    if type:match("segment") then
        t = math.max(0, math.min(1, t))
    elseif type:match("ray") then
        t = math.max(0, t)
    end
    return o + t * v
end

function intersect(type1, o1, p1, type2, o2, p2)
    local v1, v2 = type1:match("vector") and p1 or (p1 - o1), type2:match("vector") and p2 or (p2 - o2)
    local v3 = o1 - o2
    local d = v1:det(v2)
    if d == 0 then return end
    local t1 = v2:det(v3) / d
    if (type1:match("segment") and (t1 < 0 or t1 > 1)) or (type1:match("ray") and t1 < 0) then return end
    local t2 = v1:det(v3) / d
    if (type2:match("segment") and (t2 < 0 or t2 > 1)) or (type2:match("ray") and t2 < 0) then return end
    return (o1 + t1 * v1 + o2 + t2 * v2) / 2
end

function intersectCircle(type, o, p, c, r)
    local v = type:match("vector") and p or (p - o)
    local d = c - o
    local f = math.abs(v.norm:det(d))
    if f > r then return end
    local t = v:dot(d) / v.sqrLen - math.sqrt(r^2 - f^2) / v.len
    if (type:match("segment") and (t < 0 or t > 1)) or (type:match("ray") and t < 0) then return end
    return o + t * v
end

function insidePolygon(p, poly)
    for i = 1, #poly do
        local v1, v2 = poly[i], poly[i % #poly + 1]
        if (p - v1):det(v2 - v1) > 0 then
            return false
        end
    end
    return true
end