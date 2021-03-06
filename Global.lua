local Game = require 'modules.game.Game'
--local Table = require 'modules.board.Board'

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
startRoundAt = 1 --muss kleiner als maxRounds sein
maxRounds = 10   --60 / numberOfPlayers
minPlayerNumber = 1
tricks = {}
points = {}
bids = {}
bidRound = false
textPlayer = {}
lastPlayer = false

trump = nil

handZoneObjects = {}

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

function trumpSelected(player, selectedTrump)
    trump = selectedTrump
    hideTrumpSelectButtons()
    --broadcastToAll(trump.." is defined as trump", "Red")
    interpretTrump()
    waitForSelectTrump = false
end

function hideTrumpSelectButtons()
    for i = 1, 4, 1 do
        UI.setAttribute("trumpSelectButton"..i, "visibility", "nil")
    end 
end

function showTrumpSelectButtons(previousPlayerNumber)
    for i = 1, 4, 1 do
        UI.setAttributes("trumpSelectButton"..i, {visibility = playerList[previousPlayerNumber], textColor = "#FFFFFF"})
    end 
end

function selectTrump()
    local previousPlayerNumber = startPlayerNumber - 1
    if previousPlayerNumber == 0 then
       previousPlayerNumber = numberOfPlayers
    end
    broadcastToAll(Player[playerList[previousPlayerNumber]].steam_name.." can decide which suit is trump this round!", "Red")
    showTrumpSelectButtons(previousPlayerNumber)  
end

function writeTrump(trumpText)
    local pointblock = getObjectFromGUID(pointblockGUID)
    pointblock.UI.setAttribute("TrumpText", "text", trumpText)
end

function clearTrumpText()
    local pointblock = getObjectFromGUID(pointblockGUID)
    pointblock.UI.setAttribute("TrumpText", "text", "")
end

function interpretTrump()
    local trumpText = nil
    if trump == nil then
        logToAllOrHost("Trump determination failed", "Red")
        trumpText = "Error"
    elseif trump == "N" then
        trump = "null"
        trumpText = "No Trump"
    elseif trump == "Z" then
        waitForSelectTrump = true
        trumpText = "Selecting..."
        selectTrump()
    elseif trump =="c" then
        trumpText = "Diamonds"
    elseif trump =="k" then
        trumpText = "Clubs"
    elseif trump =="h" then
        trumpText = "Hearts"
    elseif trump =="p" then
        trumpText = "Spades"
    end 
    writeTrump(trumpText)
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
                    UI.setAttributes("ScoreboardBids"..activePlayerNumber, {color = playerList[activePlayerNumber], text = bids[activePlayerNumber]})
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
        UI.setAttribute("ScoreboardPoints"..i, "text", points[i])
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

function turnOnTrumpText()
    local pointblock = getObjectFromGUID(pointblockGUID)
    pointblock.UI.setAttribute("TrumpTable", "active", true)
end

function turnOnScoreboard()
    UI.setAttribute("Scoreboard", "active", "true")
end

function writeScoreboard()
    for i = 6, numberOfPlayers, -1 do
        UI.setAttribute("ScorboardRow"..i, "active", false)
    end
    UI.setAttribute("Scoreboard", "Height", 40 * numberOfPlayers)
    for i = 1, numberOfPlayers, 1 do
        UI.setAttributes("ScoreboardPlayer"..i, {color = playerList[i], text = Player[playerList[i]].steam_name})
        UI.setAttributes("ScoreboardPoints"..i, {color = playerList[i], text = points[i]})
    end
end

function setupTheGame()
    prepareCounters()
    randomStartPlayer()
    writePointblockHeadlines()
    round = startRoundAt - 1
    setPointsToZero()
    setTextPoints()
    setTextBids()
    turnOnTurnScreen()
    turnOnScoreboard()
    turnOnTrumpText()
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
    deck.randomize()
    deck.deal(round)
    local deckPos = deck.getPosition()
    deck.takeObject({flip = true, position = deckPos, callback_function = callbackFlippedCard})
    Wait.frames(function ()
        for _, player in ipairs(playerList) do
            handZoneObjects[player] = Player[player].getHandObjects()
        end
    end, 20)
    
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

function clearScoreboardBids()
    for i = 1, numberOfPlayers, 1 do
        UI.setAttribute("ScoreboardBids"..i, "text", "")
    end
end

function collectCards()
    clearTrumpText()
    clearScoreboardBids()
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
    if round == maxRounds then
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
                Wait.time(endTrick, 2)
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

function getCardOwner(card)
    for _, player in ipairs(playerList) do
        for _, item in ipairs(handZoneObjects[player]) do
            if item == card then
                return player
            end
        end
    end
end

function onObjectPickUp(playerPickedUp, pickedUpObject)
    local cardOwner = getCardOwner(pickedUpObject)
    if playerPickedUp ~= cardOwner then
        pickedUpObject.deal(1,cardOwner)
        broadcastToColor("Hands off from other handcards!", playerPickedUp, "Red")
    end
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
                                --Wenn Trumpf bedient wird
                                if suit == trump and betterValue(droppedCard) == true then
                                    setBest(droppingPlayer, droppedCard)
                                --Wenn zwischendurch nicht gestochen wurde
                                elseif bestCard.getName() ~= trump and betterValue(droppedCard) == true then
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
    --selectTrump()
end