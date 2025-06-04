math.sign = function(x) return x > 0 and 1 or x < 0 and -1 or 0 end
vec = require "vec2"
vec.precision = 4
require "gen"

function love.load(args)
    love.mouse.setRelativeMode(true)

    -- light types
    light = {
        white = {
            color = {1, 1, 1}
        },
        red = {
            color = {1, 0, 0}
        },
        green = {
            color = {0, 1, 0}
        },
        blue = {
            color = {0, 0, 1}
        },
        yellow = {
            color = {1, 1, 0}
        },
        cyan = {
            color = {0, 1, 1}
        },
        magenta = {
            color = {1, 0, 1}
        }
    }

    material = { -- { density, refract, reflect }
        wall = {
            refract = false,
            reflect = false
        },
        metal = {
            refract = false,
            reflect = true
        },
        glass = {
            density = 2,
            refract = true,
            reflect = true
        }
    }

    textures = {
        floor = love.graphics.newImage("floor.png"),
        wall  = love.graphics.newImage("wall.png" ),
        metal = love.graphics.newImage("metal.png"),
        glass = love.graphics.newImage("glass.png"),
    }
    meshSize = 30
    for k, t in pairs(textures) do
        t:setWrap("repeat")
        local mesh = love.graphics.newMesh({
            {-meshSize/2, -meshSize/2, -meshSize/2, -meshSize/2},
            { meshSize/2, -meshSize/2,  meshSize/2, -meshSize/2},
            { meshSize/2,  meshSize/2,  meshSize/2,  meshSize/2},
            {-meshSize/2,  meshSize/2, -meshSize/2,  meshSize/2}
        }, "fan")
        mesh:setTexture(t)
        textures[k] = mesh
    end

    -- game properties
    mapSize = 12
    outerThickness = 2
    innerMapSize = mapSize - outerThickness

    -- wall types
    wallTypes = { -- { tint, thickness, texture, material, split[ light -> { reflect, refract } ] }
        { -- wall
            tint = {1, 1, 1},
            thickness = 0.1,
            texture = textures.wall,
            material = material.wall
        },
        { -- metal
            tint = {1, 1, 1},
            thickness = 0.1,
            texture = textures.metal,
            material = material.metal
        },
        { -- white
            tint = {1, 1, 1},
            thickness = 0.1,
            texture = textures.glass,
            material = material.glass
        },
        { -- red
            tint = {1, 0, 0},
            thickness = 0.1,
            texture = textures.glass,
            material = material.glass,
            split = {
                [light.white] = {
                    refract = light.red,
                    reflect = light.cyan
                },
                [light.green] = {
                    reflect = light.green
                },
                [light.blue] = {
                    reflect = light.blue
                },
                [light.yellow] = {
                    refract = light.red,
                    reflect = light.green
                },
                [light.cyan] = {
                    reflect = light.cyan
                },
                [light.magenta] = {
                    refract = light.red,
                    reflect = light.blue
                }
            }
        },
        { -- green
            tint = {0, 1, 0},
            thickness = 0.1,
            texture = textures.glass,
            material = material.glass,
            split = {
                [light.white] = {
                    refract = light.green,
                    reflect = light.magenta
                },
                [light.red] = {
                    reflect = light.red
                },
                [light.blue] = {
                    reflect = light.blue
                },
                [light.yellow] = {
                    refract = light.green,
                    reflect = light.red
                },
                [light.cyan] = {
                    refract = light.green,
                    reflect = light.blue
                },
                [light.magenta] = {
                    reflect = light.magenta
                }
            }
        },
        { -- blue
            tint = {0, 0, 1},
            thickness = 0.1,
            texture = textures.glass,
            material = material.glass,
            split = {
                [light.white] = {
                    refract = light.blue,
                    reflect = light.yellow
                },
                [light.red] = {
                    reflect = light.red
                },
                [light.green] = {
                    reflect = light.green
                },
                [light.yellow] = {
                    reflect = light.yellow
                },
                [light.cyan] = {
                    refract = light.blue,
                    reflect = light.green
                },
                [light.magenta] = {
                    refract = light.blue,
                    reflect = light.red
                }
            }
        },
        { -- yellow
            tint = {1, 1, 0},
            thickness = 0.1,
            texture = textures.glass,
            material = material.glass,
            split = {
                [light.white] = {
                    refract = light.yellow,
                    reflect = light.blue
                },
                [light.red] = {
                    refract = light.red
                },
                [light.green] = {
                    refract = light.green
                },
                [light.blue] = {
                    reflect = light.blue
                },
                [light.yellow] = {
                    refract = light.yellow
                },
                [light.cyan] = {
                    refract = light.green,
                    reflect = light.blue
                },
                [light.magenta] = {
                    refract = light.red,
                    reflect = light.blue
                }
            }
        },
        { -- cyan
            tint = {0, 1, 1},
            thickness = 0.1,
            texture = textures.glass,
            material = material.glass,
            split = {
                [light.white] = {
                    refract = light.cyan,
                    reflect = light.red
                },
                [light.red] = {
                    reflect = light.red
                },
                [light.green] = {
                    refract = light.green
                },
                [light.blue] = {
                    refract = light.blue
                },
                [light.yellow] = {
                    refract = light.green,
                    reflect = light.red
                },
                [light.cyan] = {
                    refract = light.cyan
                },
                [light.magenta] = {
                    refract = light.blue,
                    reflect = light.red
                }
            }
        },
        { -- magenta
            tint = {1, 0, 1},
            thickness = 0.1,
            texture = textures.glass,
            material = material.glass,
            split = {
                [light.white] = {
                    refract = light.magenta,
                    reflect = light.green
                },
                [light.red] = {
                    refract = light.red
                },
                [light.green] = {
                    reflect = light.green
                },
                [light.blue] = {
                    refract = light.blue
                },
                [light.yellow] = {
                    refract = light.red,
                    reflect = light.green
                },
                [light.cyan] = {
                    refract = light.blue,
                    reflect = light.green
                },
                [light.magenta] = {
                    refract = light.magenta
                }
            }
        }
    }
    for i, wall in ipairs(wallTypes) do
        wall.mask = i + 1
    end

    -- global graphics setup
    groundTexture = textures.floor
    backgroundTexture = love.graphics.newImage("background.png")
    backgroundScale = 0.02
    
    -- bolts
    previewRange = 10
    boltSpeed = 20
    boltLength = 1
    bolts = {} -- { ray, distance }

    -- particles
    particleLifetime = 1
    particleEaseOut = 4
    particleStartOpacity = 1
    particleEndOpacity = 0
    particleStartRadius = 0.02
    particleEndRadius = 0.2
    particles = {} -- { position, color, lifetime }

    -- player
    position = vec.polar(love.math.random() * 2 * math.pi, 11)
    currentCell = nil
    radius = 0.25
    moveSpeed = 5
    pointerSens = 0.002
    viewSize = previewRange + 2
    viewOffset = previewRange/3
    direction = -position:normal()
    lightToggles = {true, true, true}
    lightTypeMap = {
        [true] = {
            [true] = {
                [true] = light.white,
                [false] = light.yellow
            },
            [false] = {
                [true] = light.magenta,
                [false] = light.red
            }
        },
        [false] = {
            [true] = {
                [true] = light.cyan,
                [false] = light.green
            },
            [false] = {
                [true] = light.blue
            }
        }
    }
    currentLight = light.white
    currentRay = nil -- cell, origin, direction, length, light, power, hit { point, normal, edge, cell }, reflect, refract

    -- map generator settings
    seed = os.time()
    love.math.setRandomSeed(seed)
    boundaryWall = wallTypes[1]
    minRoomCount, maxRoomCount = 6, 12
    minRoomSize = 10
    roomWall = wallTypes[1]

    -- map
    cells = {byPosition = {}} -- { position, anchor, vertices[ index -> point ], edges[ index -> edge, neighbor -> edge ], neighbors[ edge -> neighbor ] } [ index -> cell ] byPosition[ position -> cell ]
    edges = {} -- { pointA, pointB, length, wall } [ pointA -> pointB -> edge]
    boundary = {cells = {}, edges = {}} -- cells[ index -> cell, edge -> cell ], edges[ cell -> array<edge>]
    rooms = {} -- { cells[ index -> cell ], edges[ index -> edge, room -> array<edge> ], neighbors[ index -> room, edge -> room ] }

    -- generate polygons
    for x = -mapSize, mapSize do
        for y = -mapSize, mapSize do
            if x^2 + y^2 <= mapSize^2 * 1.1 then
                local cell = generateVoronoiCell(seed, x, y)
                table.insert(cells, cell)
                cells.byPosition[cell.position] = cell
                if insidePolygon(position, cell.vertices) then
                    currentCell = cell
                end
                for i, v in ipairs(cell.vertices) do
                    edges[v] = {}
                end
            end
        end
    end

    -- link neighbors
    for _, cell in ipairs(cells) do
        boundary.edges[cell] = {}
        for i, edge in ipairs(cell.edges) do
            local v1, v2 = unpack(edge)
            if v2.x < v1.x or (v2.x == v1.x and v2.y < v1.y) then v1, v2 = v2, v1 end
            local e = edges[v1][v2]
            if not e then
                e = {
                    v1, v2, length = (v1 - v2).len
                }
                table.insert(edges, e)
                edges[v1][v2], edges[v2][v1] = e, e
            end
            cell.edges[i] = e
            local n = cells.byPosition[cell.neighbors[edge]]
            cell.neighbors[edge] = nil
            if n then
                cell.neighbors[e] = n
                cell.edges[n] = e
            else
                table.insert(boundary.cells, cell)
                boundary.cells[e] = cell
                table.insert(boundary.edges[cell], e)
                e.wall = boundaryWall
            end
        end
    end

    -- initialize rooms
    local queue = {}
    for i = 1, love.math.random(minRoomCount, maxRoomCount) do
        local cell, isValid
        local iterations = 0
        repeat
            cell = cells[love.math.random(#cells)]
            isValid = true
            for j, room in ipairs(rooms) do
                if (room.cells[1].anchor - cell.anchor).len < minRoomSize/2 then
                    isValid = false
                    break
                end
            end
            iterations = iterations + 1
        until isValid == true or iterations > 20
        if isValid then
            local room = {cells = {cell}, edges = {}, neighbors = {}}
            cell.room = room
            table.insert(rooms, room)
            table.insert(queue, cell)
        end
    end

    -- flood fill
    while #queue > 0 do
        for i = #queue, 1, -1 do
            local cell = table.remove(queue, i)
            cell.queued = nil
            if not cell.room then
                local room, weight = nil, 0
                for r, w in pairs(cell.roomWeights) do
                    if w > weight then
                        room, weight = r, w
                    end
                end
                cell.room = room
                table.insert(room.cells, cell)
            end
            local room = cell.room
            for edge, neighbor in pairs(cell.neighbors) do
                local other = neighbor.room
                if not other then
                    if not neighbor.queued then
                        neighbor.queued = true
                        neighbor.roomWeights = {}
                        table.insert(queue, neighbor)
                    end
                    neighbor.roomWeights[room] = (neighbor.roomWeights[room] or 0) + edge.length
                elseif other ~= room then
                    if not room.edges[other] then
                        room.edges[other] = {}
                        table.insert(room.neighbors, other)
                    end
                    if not other.edges[room] then
                        other.edges[room] = {}
                        table.insert(other.neighbors, room)
                    end
                    if not room.neighbors[edge] then
                        table.insert(room.edges, edge)
                        table.insert(room.edges[other], edge)
                        room.neighbors[edge] = other
                    end
                    if not other.neighbors[edge] then
                        table.insert(other.edges, edge)
                        table.insert(other.edges[room], edge)
                        other.neighbors[edge] = room
                    end
                    edge.wall = roomWall
                end
            end
        end
    end

    -- create doors
    for i, room in ipairs(rooms) do
        for j, other in ipairs(room.neighbors) do
            local door = nil
            for k, edge in ipairs(room.edges[other]) do
                if not door or edge.length > door.length then
                    door = edge
                end
            end
            if door then
                door.wall = nil
            end
        end
    end
end

function traceRay(cell, origin, direction, range, light, power)
    if not (cell and origin and direction and range) then return end
    direction = direction:normal()
    power = power or 1
    local r = {
        cell = cell,
        origin = origin,
        direction = direction,
        length = range,
        light = light,
        power = power,
        hit = nil,
    }
    for _, edge in ipairs(cell.edges) do
        local v1, v2 = unpack(edge)
        if (v1 - cell.anchor):det(v2 - cell.anchor) < 0 then v1, v2 = v2, v1 end
        local normal = (v2 - v1):normal()
        normal = vec(-normal.y, normal.x)
        local p = intersect("vector ray", origin, direction, "segment", v1, v2)
        if p and direction:dot(normal) < 0 then
            local d = (p - origin).len
            if not range or d < range  then
                r.length = d
                local neighbor = cell.neighbors[edge]
                if not edge.wall and not neighbor.wall then
                    r = traceRay(neighbor, origin, direction, range, light, power) or r
                    r.cell = cell
                    return r
                end
                r.hit = {
                    point = p,
                    normal = normal,
                    edge = edge,
                    cell = neighbor
                }
                local wall = cell.wall ~= edge.wall and edge.wall or neighbor and neighbor.wall
                local n1 = cell.wall and cell.wall.material.density or 1
                local n2 = wall and wall.material.density or 1
                local alpha = (-normal):signedAngle(direction)
                local refl  = normal:rotate(-alpha)
                local sin_beta = math.sin(alpha) * n1/n2
                if math.abs(sin_beta) < 1 then
                    local refr = (-normal):rotate(math.asin(sin_beta))
                    if light and wall.split and wall.split[light] then
                        if wall.split[light].refract and neighbor then
                            r.refract = traceRay(neighbor, p, refr, range - d, wall.split[light].refract, power/2)
                        end
                        if wall.split[light].reflect then
                            r.reflect = traceRay(cell,     p, refl, range - d, wall.split[light].reflect, power/2)
                        end
                    elseif wall.material.refract and neighbor then
                        r.refract = traceRay(neighbor, p, refr, range - d, light, power)
                    elseif wall.material.reflect then
                        r.reflect = traceRay(cell,     p, refl, range - d, light, power)
                    end
                else
                    r.reflect = traceRay(cell, p, refl, range - d, light, power)
                end
                return r
            end
        end
    end
    return r
end

local maxRayLength = 30
function drawRay(ray, width, from, to, opacity, overrideColor)
    opacity = opacity or 1
    from, to = from or 0, to or maxRayLength
    local len = math.min(ray.length, maxRayLength)
    if to > len then
        if ray.reflect then
            drawRay(ray.reflect, width, from - len, to - len, opacity, overrideColor)
        end
        if ray.refract then
            drawRay(ray.refract, width, from - len, to - len, opacity, overrideColor)
        end
    end
    if from < len and to > 0 and (overrideColor or ray.light) then
        from, to = math.max(math.min(from, len), 0), math.max(math.min(to, len), 0)
        local p1, p2 = ray.origin + ray.direction:setLen(from), ray.origin + ray.direction:setLen(to)
        love.graphics.push("all")
        local r, g, b = unpack(overrideColor or ray.light.color)
        love.graphics.setColor(r, g, b, opacity)
        love.graphics.circle("fill", p1.x, p1.y, width/2)
        love.graphics.circle("fill", p2.x, p2.y, width/2)
        love.graphics.setLineWidth(width)
        love.graphics.line(p1.x, p1.y, p2.x, p2.y)
        love.graphics.pop()
    end
end

function love.update(dt)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    -- player movement
    local move_inp = vec(
        (love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0),
        (love.keyboard.isDown("s") and 1 or 0) - (love.keyboard.isDown("w") and 1 or 0)
    ):rotate(direction.atan2 + math.pi/2)
    local delta = move_inp:setLen(moveSpeed * dt)
    -- player collision
    --[[
    for _, edge in ipairs(currentCell.edges) do
        if edge.wall then
            local v1, v2 = unpack(edge)
            if (v1 - currentCell.anchor):det(v2 - currentCell.anchor) < 0 then v1, v2 = v2, v1 end
            local e = (v2 - v1):normal()
            local normal = vec(-e.y, e.x)
            if normal:dot(delta) < 0 then
                local t = radius + edge.wall.thickness/2
                local p = intersect("vector segment", position, delta, "segment", v1 + normal * t, v2 + normal * t)
                if p then
                    delta = delta:project(e) + (p - position):project(normal) * 0.99
                end
            end
        end
    end
    for _, point in ipairs(currentCell.vertices) do
        local r = 0
        for _, edge in pairs(edges[point]) do
            if edge.wall and edge.wall.thickness/2 > r then
                r = edge.wall.thickness/2
            end
        end
        if r > 0 then
            local p = intersectCircle("vector segment", position, delta, point, r + radius)
            if p then
                local normal = (p - point):normal()
                local tangent = vec(-normal.y, normal.x)
                delta = delta:project(tangent) + (p - position):project(normal)
            end
        end
    end
    position = position + delta
    ]]--
    local newPosition = position + delta
    for _, edge in ipairs(currentCell.edges) do
        if edge.wall then
            local v1, v2 = unpack(edge)
            if (v1 - currentCell.anchor):det(v2 - currentCell.anchor) < 0 then v1, v2 = v2, v1 end
            local e = (v2 - v1):normal()
            local normal = vec(-e.y, e.x)
            if normal:dot(position - v1) > 0 then
                local t = radius + edge.wall.thickness/2
                local p = nearestPoint(position, "segment", v1, v2)
                local d = newPosition - p
                if d.len < t then
                    newPosition = p + d:setLen(t)
                end
            end
        end
    end
    for _, neighbor in pairs(currentCell.neighbors) do
        for _, edge in ipairs(neighbor.edges) do
            if edge.wall then
                local v1, v2 = unpack(edge)
                if (v1 - currentCell.anchor):det(v2 - currentCell.anchor) < 0 then v1, v2 = v2, v1 end
                local e = (v2 - v1):normal()
                local normal = vec(-e.y, e.x)
                if normal:dot(position - v1) > 0 then
                    local t = radius + edge.wall.thickness/2
                    local p = nearestPoint(position, "segment", v1, v2)
                    local d = newPosition - p
                    if d.len < t then
                        newPosition = p + d:setLen(t)
                    end
                end
            end
        end
    end
    position = newPosition
    -- update player region
    if not insidePolygon(position, currentCell.vertices) then
        for _, neighbor in pairs(currentCell.neighbors) do
            if insidePolygon(position, neighbor.vertices) then
                currentCell = neighbor
                break
            end
        end
    end

    -- preview bolt trajectory
    currentRay = traceRay(currentCell, position, direction, previewRange, currentLight)

    -- update bolts
    local inc = boltSpeed * dt
    for i = #bolts, 1, -1 do
        local bolt = bolts[i]
        bolt.distance = bolt.distance + inc
        if bolt.ray.hit and not bolt.impacted and bolt.distance > bolt.ray.length then
            local c = (bolt.ray.reflect and bolt.ray.reflect.light and bolt.ray.reflect.light.color) or (not bolt.ray.refract and bolt.ray.light and bolt.ray.light.color)
            if c then
                table.insert(particles, {
                    position = bolt.ray.hit.point,
                    color = c,
                    lifetime = 0
                })
            end
            bolt.impacted = true
        end
        if bolt.distance > bolt.ray.length + boltLength then
            table.remove(bolts, i)
            if bolt.ray.refract then
                table.insert(bolts, {
                    distance = bolt.distance - bolt.ray.length,
                    ray = traceRay(bolt.ray.refract.cell, bolt.ray.refract.origin, bolt.ray.refract.direction, previewRange, bolt.ray.refract.light, bolt.ray.refract.power)
                })
            end
            if bolt.ray.reflect then
                table.insert(bolts, {
                    distance = bolt.distance - bolt.ray.length,
                    ray = traceRay(bolt.ray.reflect.cell, bolt.ray.reflect.origin, bolt.ray.reflect.direction, previewRange, bolt.ray.reflect.light, bolt.ray.reflect.power)
                })
            end
        end
    end

    -- update particles
    for i = #particles, 1, -1 do
        local particle = particles[i]
        particle.lifetime = particle.lifetime + dt
        if particle.lifetime > particleLifetime then
            table.remove(particles, i)
        end
    end
end

function applyCameraTransform(x, y, z, r)
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    love.graphics.scale(z or 1)
    love.graphics.rotate(-(r or 0))
    love.graphics.translate(-x, -y)
end

function love.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.push("all")
    applyCameraTransform(position.x + direction.x * viewOffset, position.y + direction.y * viewOffset, h / viewSize, direction.atan2 + math.pi/2)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(backgroundTexture, 0, 0, 0, backgroundScale, backgroundScale, backgroundTexture:getWidth()/2, backgroundTexture:getHeight()/2)

    -- draw ground
    love.graphics.stencil(function()
        for _, cell in ipairs(cells) do
            love.graphics.polygon("fill", vec.flattenArray(cell.vertices))
        end
    end)
    love.graphics.setStencilTest("equal", 1)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.draw(groundTexture, 0, 0, 0, 2, 2)
    -- draw particles
    for _, particle in ipairs(particles) do
        local t = 1 - (-(particle.lifetime/particleLifetime - 1)) ^ particleEaseOut
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particleStartOpacity + (particleEndOpacity - particleStartOpacity) * t)
        love.graphics.circle("fill", particle.position.x, particle.position.y, particleStartRadius + (particleEndRadius - particleStartRadius) * t)
    end
    -- draw aim preview
    for d = 0, previewRange, 0.5 do
        drawRay(currentRay, 0.01, d + 0.25, d + 0.5)
    end
    -- draw light bolts
    for _, bolt in ipairs(bolts) do
        drawRay(bolt.ray, 0.09, bolt.distance - boltLength, bolt.distance, 1)
        drawRay(bolt.ray, 0.03, bolt.distance - boltLength, bolt.distance, 1, {1, 1, 1})
    end
    -- draw player
    love.graphics.setLineWidth(0.025)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", position.x, position.y, radius)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", position.x, position.y, radius)
    -- draw walls
    for _, cell in pairs(cells) do
        if cell.wall then
            love.graphics.stencil(function()
                love.graphics.polygon(vec.flattenArray(cell.vertices))
            end, "replace", cell.wall.mask, true)
        end
    end
    for _, edge in ipairs(edges) do
        if edge.wall then
            love.graphics.stencil(function()
                love.graphics.setLineWidth(edge.wall.thickness)
                love.graphics.line(vec.flattenArray(edge))
                love.graphics.circle("fill", edge[1].x, edge[1].y, edge.wall.thickness/2)
                love.graphics.circle("fill", edge[2].x, edge[2].y, edge.wall.thickness/2)
            end, "replace", edge.wall.mask, true)
        end
    end
    for i, w in ipairs(wallTypes) do
        love.graphics.setStencilTest("equal", w.mask)
        love.graphics.setColor(w.tint)
        love.graphics.draw(w.texture)
    end


    -- room borders
    love.graphics.setStencilTest()
    love.graphics.setLineWidth(0.02)
    if currentCell and currentCell.room then
        local colors = {
            {1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 1, 0}, {1, 0, 1}, {0, 1, 1}
        }
        for i, other in ipairs(currentCell.room.neighbors) do
            love.graphics.setColor(colors[(i - 1) % #colors + 1])
            for j, edge in ipairs(currentCell.room.edges[other]) do
                if edge.wall then
                    love.graphics.line(vec.flattenArray(edge))
                else
                    local o, d = edge[1], edge[2] - edge[1]
                    for i = 0, 10 do
                        local p = o + i/10 * d
                        love.graphics.circle("fill", p.x, p.y, 0.01)
                    end
                end
            end
        end
    end
    
    -- UI
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(("%d FPS\n%s - %s"):format(love.timer.getFPS(), tostring(position), tostring(currentCell.position)))
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "return" then
        love.load()
    elseif key == "z" then
        lightToggles[1] = not lightToggles[1]
        currentLight = lightTypeMap[lightToggles[1]][lightToggles[2]][lightToggles[3]]
    elseif key == "x" then
        lightToggles[2] = not lightToggles[2]
        currentLight = lightTypeMap[lightToggles[1]][lightToggles[2]][lightToggles[3]]
    elseif key == "c" then
        lightToggles[3] = not lightToggles[3]
        currentLight = lightTypeMap[lightToggles[1]][lightToggles[2]][lightToggles[3]]
    end
end

function love.mousepressed(x, y, b)
    if b == 1 then
        table.insert(bolts, {ray = traceRay(currentCell, position, direction, previewRange, currentLight), distance = 0})
    end
end

function love.mousemoved(x, y, dx, dy)
    direction = direction:rotate(dx * pointerSens)
end