math.sign = function(x) return x > 0 and 1 or x < 0 and -1 or 0 end
vec = require "vec"
require "gen"

function love.load(args)
    love.graphics.setDefaultFilter("linear")
    local crosshair = love.mouse.newCursor("crosshair.png", 8, 8)
    love.mouse.setCursor(crosshair)

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

    material = {
        glass = {
            density = 2,
            refract = true,
            reflect = true
        },
        tintedGlass = {
            density = 2,
            refract = false,
            reflect = true,
        }
    }

    textures = {
        glass = love.graphics.newImage("glass.png"),
        grass = love.graphics.newImage("grass.png")
    }

    mapSize = 12
    outerThickness = 2
    innerMapSize = mapSize - outerThickness

    -- transform into tiled meshes
    meshSize = 2 * mapSize + 10
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

    -- global graphics setup
    groundTexture = textures.grass
    outerTint = {0.75, 0.75, 0.75}
    borderColor = {0.3, 0.6, 0.3}
    backgroundColor = {0.6, 0.6, 1}

    -- wall types
    walls = {
        { -- white
            color = {
                fill = {1, 1, 1},
                outline = {1, 1, 1}
            },
            texture = textures.glass,
            material = material.glass,
            split = {
                --[light] => {refract, reflect}
            }
        },
        { -- red
            color = {
                fill = {1, 0, 0},
                outline = {1, 0, 0}
            },
            texture = textures.glass,
            material = material.tintedGlass,
            split = {
                [light.white] = {
                    light.red, light.cyan
                },
                [light.red] = {
                    light.red, nil
                },
                [light.yellow] = {
                    light.red, light.green
                },
                [light.magenta] = {
                    light.red, light.blue
                }
            }
        },
        { -- green
            color = {
                fill = {0, 1, 0},
                outline = {0, 1, 0}
            },
            texture = textures.glass,
            material = material.tintedGlass,
            split = {
                [light.white] = {
                    light.green, light.magenta
                },
                [light.green] = {
                    light.green, nil
                },
                [light.yellow] = {
                    light.green, light.red
                },
                [light.cyan] = {
                    light.green, light.blue
                }
            }
        },
        { -- blue
            color = {
                fill = {0, 0, 1},
                outline = {0, 0, 1}
            },
            texture = textures.glass,
            material = material.tintedGlass,
            split = {
                [light.white] = {
                    light.blue, light.yellow
                },
                [light.blue] = {
                    light.blue, nil
                },
                [light.cyan] = {
                    light.blue, light.green
                },
                [light.magenta] = {
                    light.blue, light.red
                }
            }
        },
        { -- yellow
            color = {
                fill = {1, 1, 0},
                outline = {1, 1, 0}
            },
            texture = textures.glass,
            material = material.tintedGlass,
            split = {
                [light.white] = {
                    light.yellow, light.blue
                },
                [light.red] = {
                    light.red, nil
                },
                [light.green] = {
                    light.green, nil
                },
                [light.yellow] = {
                    light.yellow, nil
                },
                [light.cyan] = {
                    light.green, light.blue
                },
                [light.magenta] = {
                    light.red, light.blue
                }
            }
        },
        { -- cyan
            color = {
                fill = {0, 1, 1},
                outline = {0, 1, 1}
            },
            texture = textures.glass,
            material = material.tintedGlass,
            split = {
                [light.white] = {
                    light.cyan, light.red
                },
                [light.green] = {
                    light.green, nil
                },
                [light.blue] = {
                    light.blue, nil
                },
                [light.yellow] = {
                    light.green, light.red
                },
                [light.cyan] = {
                    light.cyan, nil
                },
                [light.magenta] = {
                    light.blue, light.red
                }
            }
        },
        { -- magenta
            color = {
                fill = {1, 0, 1},
                outline = {1, 0, 1}
            },
            texture = textures.glass,
            material = material.tintedGlass,
            split = {
                [light.white] = {
                    light.magenta, light.green
                },
                [light.red] = {
                    light.red, nil
                },
                [light.blue] = {
                    light.blue, nil
                },
                [light.yellow] = {
                    light.red, light.green
                },
                [light.cyan] = {
                    light.blue, light.green
                },
                [light.magenta] = {
                    light.magenta, nil
                }
            }
        }
    }
    for i, wall in ipairs(walls) do
        wall.index = i
    end

    position = vec.polar(love.math.random() * 2 * math.pi) * 11
    radius = 0.25
    moveSpeed = 5
    direction = vec(0, 0)
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
    currentRay = nil
    
    boltRange = 10
    boltSpeed = 20
    boltLength = 1
    bolts = {} -- {ray, distance}

    regions = {}
    borders = {}
    currentRegion = nil

    seed = os.time()
    love.math.setRandomSeed(seed)

    -- generate polygons
    for x = -mapSize, mapSize do
        for y = -mapSize, mapSize do
            if x^2 + y^2 <= mapSize^2 * 1.1 then
                local region = generateVoronoiCell(seed, x, y)
                regions[vec(x, y).str] = region
                if insidePolygon(position, region.vertices) then
                    currentRegion = region
                end
            end
        end
    end

    -- link neighbors
    for _, region in pairs(regions) do
        region.isEdge = false
        for i, edge in ipairs(region.edges) do
            region.neighbors[edge] = regions[region.neighbors[edge].str]
            if not region.neighbors[edge] then
                table.insert(borders, edge)
                borders[edge] = region
                region.isEdge = true
            end
        end
    end

    -- generate walls
    for pos, region in pairs(regions) do
        region.isOuter = vec.fromString(pos).sqrLen > innerMapSize^2 * 1.1
    end

    -- weighted random neighbor
    local initialSpawnRate = 0.07
    local earlyTerminationChance = 0.1
    local directionNormalizationDegree = 2

    local patches, direction = {}, {}
    for _, region in pairs(regions) do
        local rand = love.math.random()
        if not region.isOuter and rand > 1 - initialSpawnRate then
            region.wall = walls[love.math.random(1, #walls)]
            table.insert(patches, region)
            table.insert(direction, -region.anchor.norm)
        end
    end
    while #patches > 0 do
        for i = #patches, 1, -1 do
            if love.math.random() > earlyTerminationChance then
                local region = patches[i]
                local deltaAngle = (love.math.random() * 2 - 1) ^ (2 * directionNormalizationDegree + 1) * math.pi
                direction[i] = direction[i]:rotate(deltaAngle)
                for _, edge in ipairs(region.edges) do
                    local p = intersect("vector ray", region.anchor, direction[i], "segment", edge[1], edge[2])
                    if p then
                        local neighbor = region.neighbors[edge]
                        local valid = neighbor ~= nil and not neighbor.isOuter and not neighbor.wall
                        if valid then
                            neighbor.wall = region.wall
                            patches[i] = neighbor
                        else
                            table.remove(patches, i)
                            table.remove(direction, i)
                        end
                        break
                    end
                end
            else
                table.remove(patches, i)
                table.remove(direction, i)
            end
        end
    end
end

function traceRay(region, origin, direction, light, range, power)
    direction = direction.norm
    power = power or 1
    local r = {
        region = region,
        origin = origin,
        direction = direction,
        length = range,
        light = light,
        split = {},
        power = power,
    }
    if light and region and region.wall then
        if region.wall.split[light] then
            light = region.wall.split[light][1]
        elseif not region.wall.material.refract then
            light = nil
        end
    end
    if not region then
        return r
    end
    for _, edge in ipairs(region.edges) do
        local p = intersect("vector ray", origin, direction, "segment", edge[1], edge[2])
        local normal = (edge[2] - edge[1]).norm
        normal = vec(normal.y, -normal.x)
        if p and direction:dot(normal) > 0 then
            local d = (p - origin).len
            if not range or d < range  then
                r.length = d
                local neighbor = region.neighbors[edge]
                if (neighbor and neighbor.wall) == region.wall then
                    r = traceRay(neighbor, origin, direction, light, range, power)
                    r.region = region
                    return r
                end
                local n1 = region.wall and region.wall.material.density or 1
                local n2 = neighbor and neighbor.wall and neighbor.wall.material.density or 1
                local alpha = normal:angleTo(direction)
                local refl = -normal:rotate(-alpha)
                local sin_beta = n1/n2 * math.sin(alpha)
                if math.abs(sin_beta) < 1 then
                    local refr = normal:rotate(math.asin(sin_beta))
                    if neighbor and neighbor.wall and neighbor.wall.split[light] then
                        local refr_type, refl_type = unpack(neighbor.wall.split[light])
                        r.split = {
                            traceRay(neighbor, p, refr, refr_type, (range and (range - d)) or nil, power/2),
                            traceRay(region,   p, refl, refl_type, (range and (range - d)) or nil, power/2)
                        }
                    elseif not neighbor or not neighbor.wall or neighbor.wall.material.refract then
                        r.split = {traceRay(neighbor, p, refr, light, (range and (range - d)) or nil, power)}
                    elseif neighbor and neighbor.wall and neighbor.wall.material.reflect then
                        r.split = {traceRay(region, p, refl, light, (range and (range - d)) or nil, power)}
                    end
                else
                    r.split = {traceRay(region, p, refl, light, (range and (range - d)) or nil, power)}
                end
                return r
            end
        end
    end
    return r
end

local infiniteRayLength = 100
function drawRay(ray, width, from, to, overrideColor)
    from, to = from or 0, to or infiniteRayLength
    for _, r in ipairs(ray.split) do
        local l = ray.length or (r.origin - ray.origin).len
        if to > l then
            drawRay(r, width, from - l, to - l, overrideColor)
        end
    end
    local len = ray.length or infiniteRayLength
    if from < len and to > 0 and ray.light then
        from, to = math.max(math.min(from, len), 0), math.max(math.min(to, len), 0)
        local p1, p2 = ray.origin + ray.direction:setLen(from), ray.origin + ray.direction:setLen(to)
        love.graphics.push("all")
        love.graphics.setColor(overrideColor or ray.light.color)
        love.graphics.circle("fill", p1.x, p1.y, width/2)
        love.graphics.circle("fill", p2.x, p2.y, width/2)
        love.graphics.setLineWidth(width)
        love.graphics.line(p1.x, p1.y, p2.x, p2.y)
        love.graphics.pop()
    end
end

function love.update(dt)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    local move_inp = vec(
        (love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0),
        (love.keyboard.isDown("s") and 1 or 0) - (love.keyboard.isDown("w") and 1 or 0)
    )
    local delta = move_inp:setLen(moveSpeed * dt)
    for _, edge in ipairs(currentRegion.edges) do
        local neighbor = currentRegion.neighbors[edge]
        if (not neighbor or neighbor.wall ~= currentRegion.wall) and intersectCircle("line", edge[1], edge[2], position + delta, radius) then
            local e = (edge[2] - edge[1]).norm
            local normal = vec(e.y, -e.x)
            delta = delta:project(e) + (math.abs((position - edge[1]):det(e)) - radius) * normal
        end
    end
    position = position + delta
    if not insidePolygon(position, currentRegion.vertices) then
        for _, neighbor in pairs(currentRegion.neighbors) do
            if insidePolygon(position, neighbor.vertices) then
                currentRegion = neighbor
                break
            end
        end
    end
    direction = (vec(love.mouse.getPosition()) - vec(w/2, h/2)).norm

    currentRay = traceRay(currentRegion, position, direction, currentLight, boltRange)

    local inc = boltSpeed * dt
    for i = #bolts, 1, -1 do
        local bolt = bolts[i]
        bolt.distance = bolt.distance + inc
        if bolt.distance > bolt.ray.length + boltLength then
            table.remove(bolts, i)
            for _, r in ipairs(bolt.ray.split) do
                table.insert(bolts, {distance = bolt.distance - bolt.ray.length, ray = traceRay(r.region, r.origin, r.direction, r.light, boltRange, r.power)})
            end
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
    applyCameraTransform(position.x, position.y, w/2 / (boltRange + 1), 0)
    
    love.graphics.setBackgroundColor(backgroundColor)

    love.graphics.setLineWidth(0.025)
    -- set stencil values (1 for normal ground, 2 for outer layer, 2 + n for each wall type)
    for _, r in pairs(regions) do
        love.graphics.stencil(function()
            love.graphics.polygon("fill", vec.convertArray(r.vertices))
        end, "replace", (r.wall and r.wall.index + 2) or (r.isOuter and 2) or 1, true)
    end
    -- draw normal ground
    love.graphics.setColor(1, 1, 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.draw(groundTexture)
    -- draw outer layer
    love.graphics.setColor(borderColor)
    love.graphics.setStencilTest("equal", 2)
    love.graphics.draw(groundTexture)
    -- draw map edges
    love.graphics.setStencilTest()
    for _, edge in ipairs(borders) do
        local d = edge[2] - edge[1]
        d = vec(-d.norm.y, d.norm.x)
        love.graphics.line(vec.convertArray{
            edge[1] + love.graphics.getLineWidth()/2 * d,
            edge[2] + love.graphics.getLineWidth()/2 * d
        })
    end
    -- draw aim preview
    for d = 0, boltRange, 0.5 do
        drawRay(currentRay, 0.01, d + 0.25, d + 0.5)
    end
    -- draw light bolts
    for _, bolt in ipairs(bolts) do
        drawRay(bolt.ray, 0.09, bolt.distance - boltLength, bolt.distance)
        drawRay(bolt.ray, 0.03, bolt.distance - boltLength, bolt.distance, {1, 1, 1})
    end
    -- draw player
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", position.x, position.y, radius)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", position.x, position.y, radius)
    -- draw walls
    for i, w in ipairs(walls) do
        love.graphics.setColor(w.color.fill)
        love.graphics.setStencilTest("equal", i + 2)
        love.graphics.draw(w.texture)
    end
    -- draw wall edges
    love.graphics.setStencilTest()
    for _, r in pairs(regions) do
        if r.wall then
            love.graphics.setColor(r.wall.color.outline)
            for edge, n in pairs(r.neighbors) do
                if n.wall ~= r.wall then
                    local d = edge[2] - edge[1]
                    d = vec(-d.norm.y, d.norm.x)
                    love.graphics.line(vec.convertArray{
                        edge[1] + love.graphics.getLineWidth()/2 * d,
                        edge[2] + love.graphics.getLineWidth()/2 * d
                    })
                end
            end
        end
    end
    
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(("%d FPS\n%s"):format(love.timer.getFPS(), currentRegion.position.str))
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
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
        table.insert(bolts, {ray = currentRay, distance = 0})
    end
end