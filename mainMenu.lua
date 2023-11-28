-- mainMenu.lua
local mainMenu = {}

function mainMenu.load()
    -- Inicializa o menu
    mainMenu.title = "Meu Jogo"
    mainMenu.playButton = {
        x = 100,
        y = 200,
        width = 200,
        height = 50,
        text = "Jogar",
    }
end

function mainMenu.update(dt)
    -- Atualiza lógica do menu (se necessário)
end

function mainMenu.draw()
    -- Desenha o menu
    love.graphics.setColor(1, 1, 1) -- Cor branca
    love.graphics.print(mainMenu.title, 300, 100, 0, 2, 2) -- Título

    -- Botão Jogar
    love.graphics.setColor(0.5, 0.5, 0.5) -- Cor cinza para o botão
    love.graphics.rectangle("fill", mainMenu.playButton.x, mainMenu.playButton.y, mainMenu.playButton.width, mainMenu.playButton.height)
    
    love.graphics.setColor(1, 1, 1) -- Restaura a cor branca
    love.graphics.print(mainMenu.playButton.text, mainMenu.playButton.x + 30, mainMenu.playButton.y + 15)
end

return mainMenu
