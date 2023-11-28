local gameplay = {}

function gameplay.initialize()
    -- DEBUG
    showInfoScreen = false
    -- Variáveis
    player = { x = 200, y = 200, speed = 200, size = 20, level = 1, exp = 0, upgrades = 0, lastLevel = 0 }
    pauseGame = false
    currentUpgrades = {}
    selectedKeptUpgrade = 1
    bullets = {}
    enemies = {}
    items = {}
    gameOver = false
    menuSelection = 1
    camera = { x = 0, y = 0 }
    timer = 60
    bulletTypes = {
        { damage = 20, speed = 300 }, -- Tipo 1
        { damage = 30, speed = 400 }, -- Tipo 2
        { damage = 40, speed = 500 }  -- Tipo 3
    }
    currentBulletType = 1
    damageTexts = {}
    upgradesList = {
        "+5% de Dano",
        "Aumento de Frequência de Tiro",
        "Dobrar Tiro",
        "Habilidade Passiva para Ganho de XP Extra",
        "+10% de Velocidade para a Nave"
    }
    availableUpgrades = {
        {
            description = "+10% de Dano",
            effect = function() bulletTypes[currentBulletType].damage = bulletTypes[currentBulletType].damage + 0.1 * bulletTypes[currentBulletType].damage end
        },
        {
            description = "Aumento de Frequência de Tiro",
            effect = function() fireRate = fireRate + 0.1 * fireRate end
        },
        {
            description = "Dobrar Tiro",
            effect = function() numBulletsToShoot = numBulletsToShoot * 2 end
        },
        {
            description = "Habilidade Passiva para Ganho de XP Extra",
            effect = function() extraExp = extraExp + 5 end
        },
        {
            description = "+10% de Velocidade para a Nave",
            effect = function() player.speed = player.speed + 0.1 * player.speed end
        },
        -- Adicione mais upgrades conforme necessário
    }
    selectedUpgrade = 1
    levelUp = false
    timeSinceLastShot = 0
    fireRate = 1  -- Altere este valor para ajustar a frequência de tiro (disparos por segundo)
    numBulletsToShoot = 1 -- Defina o número desejado de balas externamente
    extraExp = 50
    enemyRate = 0.01

    -- Controle de Tutorial
    tutorialActive = true
    tutorial = 1
    tutorialText = {
        "Operações: Comandante, temos menos \n1 minuto para o fim... Colete os materiais.",
        "Operações: Investigamos os materiais coletados. \nAlcançe Nível 2 para fazer nossa primeira melhoria",
        "Operações: Estamos indo bem, continue coletando!",
        "Operações: Comandante, já temos o suficiente \npara o nossa próxima melhoria. O que gostaria de melhorar?",
    }

    function gameplay.getRandomUpgrades()
        local randomUpgrades = {}
        local availableIndices = {}

        for i = 1, #availableUpgrades do
            table.insert(availableIndices, i)
        end

        for i = 1, 3 do
            -- Verifica se ainda há índices disponíveis
            if #availableIndices > 0 then
                local randomIndex = table.remove(availableIndices, love.math.random(1, #availableIndices))
                table.insert(randomUpgrades, availableUpgrades[randomIndex])
            else
                -- Se não houver mais índices disponíveis, encerre o loop
                break
            end
        end

        return randomUpgrades
    end

    -- Inicializa a lista de opções de upgrade
    upgradeOptions = gameplay.getRandomUpgrades()

    function gameplay.applyUpgrade(upgradeIndex)
        local upgrade = upgradeOptions[upgradeIndex]
        upgrade.effect()

        -- Adiciona a melhoria atual à tabela currentUpgrades
        table.insert(currentUpgrades, upgrade)

        -- Remove a melhoria escolhida da lista de opções
        gameplay.removeUpgradeOption(upgradeIndex)
    
        enemyRate = enemyRate + 0.01
        timer = timer + 30
        extraExp = extraExp - player.level
    end

    -- Função para reiniciar o jogo
    function gameplay.restartGame()
        if levelUp and selectedUpgrade > 0 and selectedUpgrade <= #upgradeOptions then
            local keptUpgrade = upgradeOptions[selectedUpgrade]
            keptUpgrade.effect()

            -- Limpe a tabela de melhorias atuais, exceto a mantida
            currentUpgrades = { keptUpgrade }

            -- Reinicie outras configurações do jogo
            player.level = 1
            player.exp = 0
            player.upgrades = 0
            bullets = {}
            enemies = {}
            items = {}
            gameOver = false
            timer = 60
            levelUp = false
            extraExp = 8
            enemyRate = 0.01

            -- Desfaça o efeito de todas as melhorias anteriores
            for _, upgrade in ipairs(currentUpgrades) do
                upgrade.effect = function() end -- Efeito vazio para desfazer as alterações
                upgrade.effect()
            end

            -- Criar novas opções de upgrade quando o jogo for reiniciado
            upgradeOptions = gameplay.getRandomUpgrades()
        else
            -- Reinicie o jogo normalmente
            player = { x = 200, y = 200, speed = 200, size = 20, level = 1, exp = 0, upgrades = 0, lastLevel = 0 }
            bullets = {}
            enemies = {}
            items = {}
            gameOver = false
            timer = 60
            levelUp = false
            extraExp = 8
            enemyRate = 0.01

            -- Desfaça o efeito de todas as melhorias anteriores
            for _, upgrade in ipairs(currentUpgrades) do
                upgrade.effect = function() end -- Efeito vazio para desfazer as alterações
                upgrade.effect()
            end

            -- Criar novas opções de upgrade quando o jogo for reiniciado
            upgradeOptions = gameplay.getRandomUpgrades()
        end
    end

    -- Função de atualização
    function gameplay.update(dt)
        if not gameOver then
            if love.keyboard.isDown("f1") and not pauseGame then
                levelUp = true
            end

            if levelUp then
                return
            end

            if pauseGame then
                return
            end

            timer = timer - dt

            local dx, dy = 0, 0

            if love.keyboard.isDown("up") then
                dy = -1
            elseif love.keyboard.isDown("down") then
                dy = 1
            end

            if love.keyboard.isDown("left") then
                dx = -1
            elseif love.keyboard.isDown("right") then
                dx = 1
            end


            player.x = player.x + dx * player.speed * dt
            player.y = player.y + dy * player.speed * dt

            camera.x = player.x - love.graphics.getWidth() / 2
            camera.y = player.y - love.graphics.getHeight() / 2

            -- Atualizar o tempo desde o último disparo
            timeSinceLastShot = timeSinceLastShot + dt

            -- Atirar se o tempo desde o último disparo for maior que o inverso da taxa de disparo
            if timeSinceLastShot > 1 / fireRate then
                for i = 1, numBulletsToShoot do
                    local angle = i * (2 * math.pi / numBulletsToShoot)
                    local bullet = {
                        x = player.x + player.size / 2,
                        y = player.y + player.size / 2,
                        dx = math.cos(angle),
                        dy = math.sin(angle),
                        type = currentBulletType
                    }
                    table.insert(bullets, bullet)
                end

                -- Resetar o tempo desde o último disparo
                timeSinceLastShot = 0
            end

            for i, bullet in ipairs(bullets) do
                bullet.x = bullet.x + bullet.dx * bulletTypes[bullet.type].speed * dt
                bullet.y = bullet.y + bullet.dy * bulletTypes[bullet.type].speed * dt

                if bullet.x < camera.x or bullet.x > camera.x + love.graphics.getWidth() or
                    bullet.y < camera.y or bullet.y > camera.y + love.graphics.getHeight() then
                    table.remove(bullets, i)
                end
            end

            for i, enemy in ipairs(enemies) do
                for j, bullet in ipairs(bullets) do
                    if bullet.x < enemy.x + enemy.size and
                        bullet.x + 2 > enemy.x and
                        bullet.y < enemy.y + enemy.size and
                        bullet.y + 5 > enemy.y then
                        table.remove(bullets, j)
                        enemy.hp = enemy.hp - bulletTypes[bullet.type].damage

                        local damageText = {
                            x = enemy.x,
                            y = enemy.y - 10,
                            text = "-" .. bulletTypes[bullet.type].damage,
                            color = {255, 255, 255, 0.8},
                            timer = 1
                        }
                        table.insert(damageTexts, damageText)

                        if enemy.hp <= 0 then
                            local item = { x = enemy.x, y = enemy.y, size = 10 }
                            table.insert(items, item)

                            table.remove(enemies, i)
                        end
                    end
                end
            end

            for i, damageText in ipairs(damageTexts) do
                damageText.timer = damageText.timer - dt
                damageText.y = damageText.y - 10 * dt

                if damageText.timer <= 0 then
                    table.remove(damageTexts, i)
                end
            end

            -- Adicionar inimigos
            if math.random() < enemyRate then
                local side = math.random(1, 4)
                local enemy = {}

                if side == 1 then
                    enemy.x = math.random(love.graphics.getWidth())
                    enemy.y = -20
                elseif side == 2 then
                    enemy.x = math.random(love.graphics.getWidth())
                    enemy.y = love.graphics.getHeight() + 20
                elseif side == 3 then
                    enemy.x = -20
                    enemy.y = math.random(love.graphics.getHeight())
                elseif side == 4 then
                    enemy.x = love.graphics.getWidth() + 20
                    enemy.y = math.random(love.graphics.getHeight())
                end

                if math.abs(player.x - enemy.x) > 50 and math.abs(player.y - enemy.y) > 50 then
                    enemy.size = 20
                    enemy.hp = 50 + player.level * 10
                    table.insert(enemies, enemy)
                end
            end

            if math.random() < 0.005 then
                local item = { x = math.random(love.graphics.getWidth()), y = math.random(love.graphics.getHeight()), size = 10 }
                table.insert(items, item)
            end

            -- Atualizar a lista de opções de upgrade quando houver um novo nível
            if player.level > player.lastLevel then
                upgradeOptions = gameplay.getRandomUpgrades()
                player.lastLevel = player.level
            end

            for _, enemy in ipairs(enemies) do
                local angle = math.atan2(player.y - enemy.y, player.x - enemy.x)
                local speed = 50 + player.level * 5
                enemy.x = enemy.x + math.cos(angle) * speed * dt
                enemy.y = enemy.y + math.sin(angle) * speed * dt
            end

            for _, enemy in ipairs(enemies) do
                if player.x < enemy.x + enemy.size and
                    player.x + player.size > enemy.x and
                    player.y < enemy.y + enemy.size and
                    player.y + player.size > enemy.y then
                    gameOver = true
                end
            end

            for i, item in ipairs(items) do
                if player.x < item.x + item.size and
                    player.x + player.size > item.x and
                    player.y < item.y + item.size and
                    player.y + player.size > item.y then
                    table.remove(items, i)

                    player.exp = player.exp + extraExp

                    -- Level Up!
                    if player.exp >= 100 then
                        player.level = player.level + 1
                        player.exp = 0
                        levelUp = true
                    end
                end
            end

            if timer <= 0 then
                gameOver = true
            end
        else
            tutorialActive = false
        end

    end

    -- Função de desenho
    function gameplay.draw()
        love.graphics.clear(0, 0, 0)
        -- Desenha a tela de informações se showInfoScreen for verdadeiro
        if showInfoScreen then
            drawInfoScreen()
        end

        for _, bullet in ipairs(bullets) do
            love.graphics.rectangle("fill", bullet.x - camera.x, bullet.y - camera.y, 2, 5)
        end

        for _, enemy in ipairs(enemies) do
            love.graphics.rectangle("fill", enemy.x - camera.x, enemy.y - camera.y, enemy.size, enemy.size)
            -- love.graphics.print("HP: " .. enemy.hp, enemy.x - camera.x - 10, enemy.y - camera.y - 20)
        end

        for _, item in ipairs(items) do
            love.graphics.rectangle("fill", item.x - camera.x, item.y - camera.y, item.size, item.size)
        end

        love.graphics.circle("fill", player.x - camera.x + player.size / 2, player.y - camera.y + player.size / 2, player.size / 2)

        love.graphics.print("Nível: " .. player.level, 10, 10)
        love.graphics.print("EXP: " .. player.exp, 120, 28)
        love.graphics.rectangle("line", 10, 30, 100, 10)
        love.graphics.rectangle("fill", 10, 30, player.exp, 10)

        love.graphics.print("Timer: " .. math.ceil(timer), love.graphics.getWidth() - 80, love.graphics.getHeight() - 20)

        -- if gameOver then
        --     love.graphics.print("Melhorias Feitas:", love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 - 70)
        
        --     for i, upgrade in ipairs(currentUpgrades) do
        --         love.graphics.print(upgrade.description, love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2 - 50 + i * 20)
        --     end
        
        --     love.graphics.print("Pressione 'Esc' para sair.", love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2 + 50)
        -- end

        for _, damageText in ipairs(damageTexts) do
            love.graphics.setColor(damageText.color)
            love.graphics.print(damageText.text, damageText.x - camera.x, damageText.y - camera.y)
            love.graphics.setColor(255, 255, 255)
        end

        -- Desenho da tela de Upgrade
        if levelUp then
            love.graphics.print("Escolha:", love.graphics.getWidth() / 2 - 150, love.graphics.getHeight() / 2 - 50)
        
            for i, upgradeOption in ipairs(upgradeOptions) do
                love.graphics.print(upgradeOption.description, love.graphics.getWidth() / 2 - 120, love.graphics.getHeight() / 2 + i * 20)
        
                -- Verifica se a opção atual está selecionada
                if i == selectedUpgrade then
                    love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 150, love.graphics.getHeight() / 2 + i * 20, 300, 16)
                end
            end
        end

        -- Desenho da tela de "Melhorias feitas:"
        if gameOver and not levelUp then
            tutorialActive = false
            love.graphics.print("Melhorias feitas:", love.graphics.getWidth() / 2 - 150, love.graphics.getHeight() / 2 - 50)

            for i, keptUpgrade in ipairs(currentUpgrades) do
                love.graphics.print(keptUpgrade.description, love.graphics.getWidth() / 2 - 120, love.graphics.getHeight() / 2 + i * 20)

                -- Verifica se a melhoria atual está selecionada
                if i == selectedKeptUpgrade then
                    love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 150, love.graphics.getHeight() / 2 + i * 20, 300, 16)

                    -- Adiciona um destaque à melhoria selecionada
                    love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 150, love.graphics.getHeight() / 2 + i * 20, 300, 16)
                end
            end
        end

        local function textX(x) return love.graphics.getWidth() / 2 - x end
        local function textY(y) return love.graphics.getHeight() / 2 + y end
        
        -- Desenhar Pause Game
        if pauseGame then
            love.graphics.rectangle("line", 
            love.graphics.getWidth() / 2 - 15, love.graphics.getHeight() / 2 - 50,
            50, 15
            )
            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("fill", 
            love.graphics.getWidth() / 2 - 15, love.graphics.getHeight() / 2 - 49,
            49, 14
            )
            love.graphics.setColor(1,1,1)
            love.graphics.print("Pause!", love.graphics.getWidth() / 2 - 10, love.graphics.getHeight() / 2 - 50)
        end
        
        if not gameOver then

            -- Desenhar Caixa de Dialogo
            if tutorialActive then
                love.graphics.rectangle("line", textX(170), textY(50), 340, 50)
                love.graphics.polygon("fill",
                
                    textX(0), textY(40),
                    textX(10), textY(50),
                    textX(0), textY(50)
                )
                love.graphics.setColor(0,0,0)
                love.graphics.polygon("fill",
                textX(0.5), textY(41.5),
                textX(9.5), textY(51.5),
                textX(0.5), textY(51.5)
                )
                love.graphics.setColor(1,1,1)
            end

            -- Tutorial Controller
            if tutorial == 1 and player.exp > 0 and player.exp < 10 then
                tutorialActive = false
            end
            if tutorial == 1 and player.exp >= 10 and player.exp < 20 then
                tutorialActive = true
                tutorial = 2
            end
            if tutorial == 2 and player.exp >= 20 and player.exp < 30 then
                tutorialActive = false
            end
            if tutorial == 2 and player.exp >= 50 and player.exp < 60 then
                tutorialActive = true
                tutorial = 3
            end
            if tutorial == 3 and player.exp >= 80 and player.exp < 100 then
                tutorialActive = false
            end
            if tutorial == 3 and player.level == 2 and player.exp == 0 then
                tutorialActive = true
                tutorial = 4
            end
            if tutorial == 4 and player.level == 2 and not levelUp then
                tutorialActive = false
            end
                -- Tutorial Lvl 1
                if tutorial == 1 and tutorialActive then
                    love.graphics.print(tutorialText[tutorial], textX(140), textY(60))
                end
                
                -- Tutorial Lvl 2
                if tutorial == 2 and tutorialActive then
                    love.graphics.print(tutorialText[tutorial], textX(140), textY(60))
                end

                -- Tutorial Lvl 3
                if tutorial == 3 and tutorialActive then
                    love.graphics.print(tutorialText[tutorial], textX(140), textY(60))
                end

                -- Tutorial Lvl 4
                if tutorial == 4 and tutorialActive then
                    love.graphics.print(tutorialText[tutorial], textX(140), textY(60))
                end
            -- Tutorial Controller
        else
            love.graphics.rectangle("line", textX(170), textY(50), 340, 50)
            love.graphics.polygon("fill",
            
                textX(0), textY(40),
                textX(10), textY(50),
                textX(0), textY(50)
            )
            love.graphics.setColor(0,0,0)
            love.graphics.polygon("fill",
            textX(0.5), textY(41.5),
            textX(9.5), textY(51.5),
            textX(0.5), textY(51.5)
            )
            love.graphics.setColor(1,1,1)
            if timer == 0 then
                love.graphics.print("Operação: Nosso tempo acabou! \nUtilizaremos todo que temos para voltar no tempo.", textX(140), textY(60))
            else
                love.graphics.print("Operação: Fomos atingidos! \nVamos ter que utilizar o que temos para o reparo.", textX(140), textY(60))
            end
            -- DEBUG
            if love.keyboard.isDown("z") then
                if not levelUp then
                    love.graphics.print("teste", 200, 10)
                end
            end
        end
    end

    -- Função para disparo
    function gameplay.keypressed(key, scancode)
        -- DEBUG MODE
        if key == "f2" then
            showInfoScreen = not showInfoScreen
        end
        -- DEBUG MODE

        if not gameOver and not levelUp then
            if scancode == "p" then
                if pauseGame then
                    pauseGame = false
                else
                    pauseGame = true
                end
            end
        end
        if gameOver then
            if key == "up" and selectedKeptUpgrade > 1 then
                selectedKeptUpgrade = selectedKeptUpgrade - 1
            elseif key == "down" and selectedKeptUpgrade < #currentUpgrades then
                selectedKeptUpgrade = selectedKeptUpgrade + 1
            elseif key == "return" then
                if selectedKeptUpgrade > 0 and selectedKeptUpgrade <= #currentUpgrades then
                    gameplay.chooseKeptUpgrade(selectedKeptUpgrade)
                else
                    gameplay.restartGame()
                end
            end
        end
        if levelUp then
            if key == "up" and selectedUpgrade > 1 then
                selectedUpgrade = selectedUpgrade - 1
            elseif key == "down" and selectedUpgrade < #upgradeOptions then
                selectedUpgrade = selectedUpgrade + 1
            elseif key == "return" then
                gameplay.applyUpgrade(selectedUpgrade)
                levelUp = false
                player.upgrades = player.upgrades - 1
        
                if player.upgrades == 0 then
                    levelUp = false
                    gameOver = love.filesystem.areSymlinksEnabled()
                end
            end
        end
        if key == "escape" then
            love.event.quit()
        end
    end

    function gameplay.chooseKeptUpgrade(selectedUpgrade)
        if #currentUpgrades > 0 then
            local selectedUpgrade = currentUpgrades[selectedUpgrade]
            if selectedUpgrade then
                selectedUpgrade.effect()
    
                -- Limpe a tabela de melhorias atuais
                currentUpgrades = {}
    
                -- Reinicie o jogo ou execute outras ações necessárias após escolher a melhoria
                gameplay.restartGame()
            end
        end
    end

    function gameplay.removeUpgradeOption(index)
        table.remove(upgradeOptions, index)
    end

    -- DEBUG MODE
    function drawInfoScreen()
        love.graphics.setBackgroundColor(0, 0, 0, 0.8) -- Define o fundo como preto com alguma transparência
        love.graphics.setColor(1, 1, 1) -- Define a cor do texto como branco
    
        local y = 10 -- Posição inicial y para imprimir informações
        local lineHeight = 20 -- Altura de cada linha
    
        -- Função auxiliar para imprimir variável e valor
        local function printVariable(name, value)
            love.graphics.print(name .. ": " .. tostring(value), 10, y)
            y = y + lineHeight
        end
    
        -- Imprime variáveis do jogador
        for key, value in pairs(player) do
            printVariable("player." .. key, value)
        end
    
        -- Imprime outras variáveis do jogo
        printVariable("pauseGame", pauseGame)
        printVariable("currentUpgrades", currentUpgrades)
        printVariable("selectedKeptUpgrade", selectedKeptUpgrade)
        printVariable("bullets", bullets)
        printVariable("enemies", enemies)
        printVariable("items", items)
        printVariable("gameOver", gameOver)
        printVariable("menuSelection", menuSelection)
        printVariable("camera", camera)
        printVariable("timer", timer)
        printVariable("bulletTypes", bulletTypes)
        printVariable("currentBulletType", currentBulletType)
        printVariable("damageTexts", damageTexts)
        printVariable("upgradesList", upgradesList)
        printVariable("availableUpgrades", availableUpgrades)
        printVariable("selectedUpgrade", selectedUpgrade)
        printVariable("levelUp", levelUp)
        printVariable("timeSinceLastShot", timeSinceLastShot)
        printVariable("fireRate", fireRate)
        printVariable("numBulletsToShoot", numBulletsToShoot)
        printVariable("extraExp", extraExp)
        printVariable("enemyRate", enemyRate)
    
        -- Adicione outras variáveis conforme necessário
    end
    -- DEBUG MODE
end

return gameplay