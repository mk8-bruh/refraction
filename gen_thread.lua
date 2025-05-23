require "gen"
require "love.math"

inch, outch, seed = ...

seed = seed or os.time()

while inch:peek() ~= "QUIT" do
    local inp = inch:pop()
    if type(inp) == "table" and type(inp.x) == "number" and type(inp.y) == "number" then
        outch:push(generateVoronoiCell(seed, inp.x, inp.y))
    end
end