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

function mergetables(a, b)
    local t = {}
    for k, v in pairs(a) do t[k] = v end
    for k, v in pairs(b) do t[k] = v end
    return t
end

function triangle(a, b, c)
    if a ~= b and b ~= c and c ~= a then
        return {a, b, c, points = {[a] = 1, [b] = 2, [c] = 3}}
    end
end

function delaunay(points)
    local n, r = {}, {}
    local st = superTriangle(points)
    local p = mergetables(points, {[-2] = st[1], [-1] = st[2], [0] = st[3]})
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
    return n, r
end