local Game = require 'modules.game.Game'
local Table = require 'modules.board.Board'

deckGUID = "a92a97"
deckZoneGUID = "a09ba8"
playZoneGUID = "aa5aa2"

counterGUID = {
    White = "75b7a7",
    Red = "2dcca8",
    Orange = "046790",
    Yellow = "c635b3",
    Green = "f6d657",
    Blue = "c44d44",
    Purple = "65b4d9",
    Pink = "80d397"
  }

textPlayerGUID = {}

textPlayerGUID[1] = "f009aa"
textPlayerGUID[2] = "8c7d09"
textPlayerGUID[3] = "16778e"
textPlayerGUID[4] = "1d529f"
textPlayerGUID[5] = "2cb93a"
textPlayerGUID[6] = "6c27f2"

textPointsGUID = "65e97f"

pointblockGUID = "2d4bf2"

logToAll = true
minPlayerNumber = 1
tricks = {}
points = {}
bids = {}
bidRound = false
textPlayer = {}
lastPlayer = false

trump = nil

--function onLoad()

-- <button
--     onClick="bid"
--     position="0 22 -24"
--     width="50"
--     height="20"
--     fontSize="17">
--     Bid
-- </button>
--
--     params = {
--         click_function = "bidButtonReturn",
--         --function_owner = self,
--         label          = "Bid",
--         position       = {0, 22, -24},
--         --rotation       = {0, 180, 0},
--         width          = 50,
--         height         = 20,
--         font_size      = 17,
--         --color          = {0.5, 0.5, 0.5},
--         --font_color     = {1, 1, 1},
--         tooltip        = "This text appears on mouseover.",
--     }
--     buttonObject.createButton(params)
-- end
local game = nil
function onLoad()
    game = Game:new()

    game:start()

    deckZone = getObjectFromGUID(deckZoneGUID)
    deck = getObjectFromGUID(deckGUID)
    deck.interactable = false
    playZone = getObjectFromGUID(playZoneGUID)
    for i = 1, 6, 1 do
        textPlayer[i] = getObjectFromGUID(textPlayerGUID[i])
    end
    textPointsOrigin = getObjectFromGUID(textPointsGUID)
    getObjectFromGUID(pointblockGUID).interactable = false
    for player, GUID in pairs(counterGUID) do
      getObjectFromGUID(GUID).interactable = false
    end
end

function selectTrump()
    local previousPlayerNumber = startPlayerNumber - 1
    if previousPlayerNumber == 0 then
       previousPlayerNumber = numberOfPlayers
    end
    broadcastToAll(Player[playerList[previousPlayerNumber]].steam_name.." can decide which suit is trump this round!", "Red")
end

function interpretTrump()
    if trump == nil then
        logToAllOrHost("Fehler bei Ermittlung Trumpf", "Red")
    elseif trump == "N" then
        trump = "null"
    elseif trump == "Z" then
            waitForSelectTrump = true
            selectTrump()
    end
end

-- function setTrump()
--     local deckZoneObjects = deckZone.getObjects()
--     for _, item in ipairs(deckZoneObjects) do
--         if item.tag == "Card" then
--             trump = item.getName()
--         end
--     end
--     interpretTrump()
-- end

function setTricksToZero()
    for i = 1, numberOfPlayers, 1 do
        tricks[i] = 0
    end
    tricksTotal = 0
end

function setPlayerNumber()
    playerList = getSeatedPlayers()
    numberOfPlayers = #playerList
    if numberOfPlayers < minPlayerNumber or numberOfPlayers > 6 then
        broadcastToAll("Dieses Spiel ist nur für 3-6 Spieler!", "Red")
        return false
    end
    broadcastToAll("You are playing with "..numberOfPlayers.." players", "Green")
    return true
end

function randomStartPlayer()
    startPlayerNumber = math.random(1, numberOfPlayers)
    startPlayerRound = playerList[startPlayerNumber]
    broadcastToAll(Player[startPlayerRound].steam_name.." is randomly chosen as starting player", startPlayerRound)
end

function setStartRoundVar()
    activePlayerNumber = startPlayerNumber
    activePlayer = startPlayerRound
    startPlayerTrick = startPlayerRound
    printTurn(activePlayer)
    setTricksToZero()
    round = round + 1
end

function tableContains(table, element)
    for _, item in ipairs(table) do
        if item == element then
          return true
        end
    end
    return false
end

function convertCounterToColor(counterObject)
    for player, GUID in pairs(counterGUID) do
        local objectFromCounterGUID = getObjectFromGUID(GUID)
        if objectFromCounterGUID == counterObject then
            return player
        end
    end
    return nil
end

function bid(counterParameters)
    local counterColor = convertCounterToColor(counterParameters.counterObject)
    if counterParameters.counterPlayer ~= counterColor then
        broadcastToColor("Hands off from "..Player[counterColor].steam_name.."'s Bid-Button!", counterParameters.counterPlayer, "Red")
    else   
        if bidRound == false then
            broadcastToColor("It's not time to bid for tricks!", counterParameters.counterPlayer, "Red")
        else
            if waitForSelectTrump == true then
                local previousPlayerNumber = startPlayerNumber - 1
                if previousPlayerNumber == 0 then
                previousPlayerNumber = numberOfPlayers
                end
                broadcastToColor(Player[playerList[previousPlayerNumber]].steam_name.." has to determine trump.", counterParameters.counterPlayer, "Red")
                return
            end
            if activePlayer == counterParameters.counterPlayer then
                if counterParameters.counterValue < 0 then
                    broadcastToColor("Negative bids are not allowed!", counterParameters.counterPlayer, "Red")
                    counterParameters.counterObject.Counter.clear()
                elseif counterParameters.counterValue > round then
                    broadcastToColor("You don't have that many cards!", counterParameters.counterPlayer, "Red")
                    counterParameters.counterObject.Counter.clear()
                else
                    bids[activePlayerNumber] = counterParameters.counterValue
                    if lastPlayer == true then
                        local bidsTotal = 0
                        for i = 1, numberOfPlayers, 1 do
                            bidsTotal = bidsTotal + bids[i]
                        end
                        if bidsTotal == round then
                            broadcastToColor("The total tricks must not equal the number of cards handed out this round. Please change your bid!", counterParameters.counterPlayer, "Red")
                            return
                        end
                    end
                    textBids[activePlayerNumber][round].setValue(tostring(bids[activePlayerNumber]))
                    nextActivePlayer()
                end
            end
        end
    end
end

function prepareCounters()
    for player, GUID in pairs(counterGUID) do
          if tableContains(playerList, player) == false then
            destroyObject(getObjectFromGUID(GUID))
          else 
            getObjectFromGUID(GUID).UI.setAttribute("bidButton", "interactable", true)
            getObjectFromGUID(GUID).UI.setAttribute("bidButton", "textColor", "#FFFFFF")
            getObjectFromGUID(GUID).Counter.clear()
          end
    end
end

function writePoints()
    for i = 1, numberOfPlayers, 1 do
        textPoints[i][round].setValue(tostring(points[i]))
        UI.setAttribute("ScoreboardPlayer"..i, "text", Player[playerList[i]].steam_name..": "..points[i])
    end
end

function writePointblockHeadlines()
    if numberOfPlayers < 6 then
        for i = 6, numberOfPlayers + 1, -1 do
            textPlayer[i].destruct()
        end
    end
    for i = 1, numberOfPlayers, 1 do
        --textPlayer[i].setValue(Player[playerList[startPlayerNumber % numberOfPlayers + i]].steam_name)
        textPlayer[i].setValue(Player[playerList[i]].steam_name)
    end

end

function setTextPoints()
  textPoints = {}   -- create the matrix
  for i = 1, numberOfPlayers do
      textPoints[i] = {}     -- create a new row
      for j = 1, 60 / numberOfPlayers do
      -- for j = 1, 20 do
          textPoints[i][j] = textPointsOrigin.clone({
            position     = {x = -20.84 + 2.34 * i, y = -4.1, z = 8.24 - 0.903 * j} --y-Koordinate ist ein Bug
          })
      end
  end
end

function setTextBids()
  textBids = {}   -- create the matrix
  for i = 1, numberOfPlayers do
  -- for i = 1, 6 do
      textBids[i] = {}     -- create a new row
      for j = 1, 60 / numberOfPlayers do
      -- for j = 1, 20 do
          textBids[i][j] = textPointsOrigin.clone({
            position     = {x = -19.68 + 2.34 * i, y = -4.1, z = 8.24 - 0.903 * j} --y-Koordinate ist ein Bug
          })
      end
  end
end

function turnOnScoreboard()
  UI.setAttribute("Scoreboard", "active", "true")
end

function writeScoreboard()
    for i = 1, numberOfPlayers, 1 do
        UI.setAttributes("ScoreboardPlayer"..i, {color = playerList[i], text = Player[playerList[i]].steam_name})
        UI.setAttributes("ScoreboardPoints"..i, {color = playerList[i], text = points[i]})
    end
end

function setupTheGame()
    prepareCounters()
    randomStartPlayer()
    writePointblockHeadlines()
    round = 0
    setPointsToZero()
    setTextPoints()
    setTextBids()
    turnOnTurnScreen()
    turnOnScoreboard()
    writeScoreboard()
    startRound()
end

function callbackFlippedCard(flippedCard)
    flippedCard.interactable = false
    
    game:setTrump()
    
    bidRound = true
end

function startRound()
    setStartRoundVar()
    local deck = getObjectFromGUID(deckGUID)
    -- Deck wird gemischt und die erste Karte wird ausgeteilt
    deck.randomize()
    deck.deal(round)
    -- Die oberste Karte wird umgedreht und als Trumpf in Global definiert
    local deckPos = deck.getPosition()

    deck.takeObject({flip = true, position = deckPos, callback_function = callbackFlippedCard} )
end

function setPointsToZero()
    for i = 1, numberOfPlayers, 1 do
        points[i] = 0
    end
end

function countPoints()
  for i = 1, numberOfPlayers, 1 do
      if bids[i] == tricks[i] then
          points[i] = 20 + 10 * tricks[i] + points[i]
      else
          points[i] = math.abs(bids[i] - tricks[i]) * -10 + points[i]
      end
  end
end

function collectCards()
    local allObjects = getAllObjects()
    local allCards = {}
    for _, item in ipairs(allObjects) do
        if item.tag == "Card" or item.tag == "Deck" then
            table.insert(allCards, item)
        end
    end
    local allCardsDeck = group(allCards)
    Wait.time(resetDeck, 3)
end

function printEndScreen(player)
    UI.setAttributes("PermanentTextTop", {text = "GAME OVER\nThe winner is: "..Player[player].steam_name, color = player})
end

function endGame()
    local bestPlayer = {}
    local highestPoints = math.max(points)
    for i = 1, numberOfPlayers, 1 do
        if points[i] == highestPoints then
            table.insert(bestPlayer, playerList[i])
        end
    end
    if #bestPlayer == 1 then
        printEndScreen(bestPlayer[1])
    else
        broadcastToAll("GAME OVER\nThe winners are:", "Red")
        for i = 1, #bestPlayer, 1 do
            broadcastToAll(bestPlayer[i], bestPlayer[i])
            if i ~= #bestPlayer then
                broadcastToAll("and", "Red")
            end
        end
    end
end

function resetDeck()
    if round == 60 / numberOfPlayers then
        endGame()
    else
        deck.setPositionSmooth({x=0,y=1,z=0}, false, false)
        startRound()
    end
end

function endRound()
    countPoints()
    writePoints()
    startPlayerNumber = startPlayerNumber % numberOfPlayers + 1
    startPlayerRound = playerList[startPlayerNumber]
    Wait.time(collectCards, 2)
end

function countTricks()
    tricks[bestCardPlayerNumber] = tricks[bestCardPlayerNumber] + 1
    tricksTotal = tricksTotal + 1
    if tricksTotal == round then
        Wait.time(endRound, 1)
    else
        printTurn(activePlayer)
    end
end

function endTrick()
    local groupedTrick = group(playZone.getObjects())
    Wait.time(function()
        local playZoneObjects = playZone.getObjects()
        for _, item in ipairs(playZoneObjects) do
            if item.tag == "Deck" then
                for i = 1, numberOfPlayers, 1 do
                    item.dealToColorWithOffset({-5+3*tricks[bestCardPlayerNumber], 0, 5}, true, bestCardPlayer)
                end
            end
        end
    end, 1)
    startPlayerTrick = bestCardPlayer
    activePlayer = bestCardPlayer
    activePlayerNumber = bestCardPlayerNumber
    countTricks()
end

function nextActivePlayer()
    activePlayerNumber = activePlayerNumber % numberOfPlayers + 1
    activePlayer = playerList[activePlayerNumber]
    if playerList[activePlayerNumber % numberOfPlayers + 1] == startPlayerTrick then
        lastPlayer = true
        printTurn(activePlayer)
    else
        lastPlayer = false
        if activePlayer == startPlayerTrick then
            if bidRound == true then
                bidRound = false
                printTurn(activePlayer)
            else
                endTrick()
            end
        else
            printTurn(activePlayer)
        end
    end
end

function detectBestCardPlayerNumber()
  for i = 1, numberOfPlayers, 1 do
      if bestCardPlayer == playerList[i] then
          bestCardPlayerNumber = i
          return
      end
  end
end

function setBest(droppingPlayer, droppedCard)
    bestCardPlayer = droppingPlayer
    detectBestCardPlayerNumber()
    bestCard = droppedCard
    bestCardValue = tonumber(bestCard.getDescription())
end


--Checked Handkarten nach zu bedienender Farbe (true: kann bedienen)
function checkHandcardsForSuitToFollow(droppingPlayer, droppedCard)

    local handCards = Player[droppingPlayer].getHandObjects()

    for _, item in ipairs(handCards) do
        --Wenn es Handkarten zum Bedienen gibt
        if item.getName() == suitToFollow then
            broadcastToColor("You need to follow the suit!", droppingPlayer, "Red")
            droppedCard.deal(1, droppingPlayer)
            return true
        end
    end
    return false
end

function betterValue(droppedCard)
  droppedCardValue = tonumber(droppedCard.getDescription())
    --Wenn ausgespielte Karte besser ist
  if droppedCardValue > bestCardValue then
      return true
  else return false
  end
end

function lockPlayedCard(droppedCard)
    droppedCard.setLock(true)
    local position = droppedCard.getPosition()
    droppedCard.setPositionSmooth({position.x, 1, position.z}, true, false)
end

function onObjectDrop(droppingPlayer, droppedCard)

    local playZoneObjects = playZone.getObjects()

    for _, item in ipairs(playZoneObjects) do
        --Wenn Karte in die playZone gelegt wird
        if item == droppedCard then

            --Wenn noch die Stiche geboten werden müssen
            if bidRound == true then
                broadcastToAll("You need to bid how many tricks you try to get!", "Red")
                droppedCard.deal(1, droppingPlayer)

            --Wenn schon geboten wurde
            else

                --cardPlayed(droppingPlayer, droppedCard)
                local suit = droppedCard.getName()

                --Ausspielen von Spieler der nicht am Zug ist
                if droppingPlayer ~= activePlayer then
                    broadcastToColor("It is not your turn! It is "..activePlayer.."'s turn.", droppingPlayer, "Red")
                    droppedCard.deal(1, droppingPlayer)

                --Spieler ist am Zug
                else
                    --Ausspielen der ersten Karte im Stich
                    if activePlayer == startPlayerTrick then
                        suitToFollow = suit
                        setBest(droppingPlayer, droppedCard)
                        nextActivePlayer()
                        lockPlayedCard(droppedCard)

                    --Wenn bereits eine Karte ausgespielt wurde (nicht Startspieler)
                    else
                        --Wenn bisher nur Narren gespielt wurden
                        if suitToFollow == "N" then
                          --Wenn darauf kein Narr gespielt wird
                          if suit ~= "N" then
                            suitToFollow = suit
                            setBest(droppingPlayer, droppedCard)
                          end
                          nextActivePlayer()
                          lockPlayedCard(droppedCard)

                        --Wenn schon Zauberer gespielt wurde
                        elseif suitToFollow == "Z" then
                          nextActivePlayer()
                          lockPlayedCard(droppedCard)

                        --Wenn erste Karte weder Zauberer noch Narr war
                        else
                            --Wenn bedient wird
                            if suit == suitToFollow then
                                lockPlayedCard(droppedCard)
                                if bestCard.getName() ~= trump and betterValue(droppedCard) == true then
                                    setBest(droppingPlayer, droppedCard)
                                end
                                nextActivePlayer()
                            --Wenn Narr gespielt wird
                            elseif suit == "N" then
                                lockPlayedCard(droppedCard)
                                nextActivePlayer()
                            --Wenn Zauberer gespielt wird
                            elseif suit == "Z" then
                                setBest(droppingPlayer, droppedCard)
                                lockPlayedCard(droppedCard)
                                suitToFollow = "Z"
                                nextActivePlayer()
                            --Wenn nicht bedient wird
                            elseif checkHandcardsForSuitToFollow(droppingPlayer, droppedCard) == false then
                                lockPlayedCard(droppedCard)
                                --Wenn gestochen wird
                                if suit == trump then
                                    --Wenn zuvor schon gestochen wurde
                                    if bestCard.getName() == trump then
                                       if betterValue(droppedCard) then
                                         setBest(droppingPlayer, droppedCard)
                                       end
                                    else
                                        setBest(droppingPlayer, droppedCard)
                                    end
                                end
                                nextActivePlayer()
                            else
                                return
                            end
                        end
                    end
                end
                return
            end
        end
    end
    --hier kann noch was hin, für alle gedroppten Objekte, welche nicht in die playZone gedroppt wurden
end

--[[function cardPlayed(playedCard)

end--]]

function logToAllOrHost(text, color)
    if logToAll == true then
        printToAll(text, color)
    else
        print(text)
    end
end

function turnOnTurnScreen()
    UI.setAttribute("TurnScreen", "active", "true")
end

function printTurn(player)
    UI.setAttributes("TurnText", {text = Player[player].steam_name.."'s Turn", color = player})
    printToAll("<--------------------- "..Player[player].steam_name.."'s Turn --------------------->", player)
end

function onChat(message, player)
    if waitForSelectTrump == true then
        local previousPlayerNumber = startPlayerNumber - 1
        if previousPlayerNumber == 0 then
           previousPlayerNumber = numberOfPlayers
        end
        if player.color == playerList[previousPlayerNumber] then
            if message == "h" or message == "p" or message == "k" or message == "c" then
                trump = message
                broadcastToAll(trump.." is defined as trump", "Red")
                waitForSelectTrump = false
            end
        end
    end
end