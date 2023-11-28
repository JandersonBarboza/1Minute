local gameplay = require("gameplay")
local fullscreen = false

function love.load()
    love.window.setTitle("1 Minute")
    love.window.setMode(400, 400, { resizable = true })
    love.window.setFullscreen(fullscreen)

    gameplay.initialize()
end

function love.update(dt)
    gameplay.update(dt)
    if love.keyboard.isDown("f") then
        -- fullscreen == false ? true : false

        fullscreen = false and false or true

        love.window.setFullscreen(fullscreen)
    end
end

function love.draw()
    gameplay.draw()
end

function love.keypressed(key, scancode)
    gameplay.keypressed(key, scancode)
end
