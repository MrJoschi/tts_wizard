local Table = require "modules.table.table"
local ScoreTable = require "modules.score.scoretable"
local ScoreBoard = require "modules.score.scoreboard"
local CounterManager = require "modules.counter.countermanager"
local PlayerManager = require "modules.player.playermanager"
local Constants = require "constants"
local UIManager = require "modules.ui.uimanager"

local Game = {}

function Game:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.table = Table:new()
    instance.scoreTable = ScoreTable:new()
    instance.scoreBoard = ScoreBoard:new()

    -- Startspieler der aktuellen Runde
    instance.startPlayer = nil
    -- Startspieler des aktuellen Stiches
    instance.startPlayerTrick = nil
    -- Spieler am Zug
    instance.activePlayer = nil
    -- Anzahl der gespielten Runden
    instance.round = 0
    -- Punkte der Spieler
    instance.points = {}
    -- Gebote der Spieler
    self.bids = {}

    instance.tricks = {}
    instance.tricksTotal = 0

    instance.currentState = Constants.State.Pregame

    instance:init()

    return instance
end

function Game:init()
    CounterManager:init()
end

function Game:start()
    if PlayerManager:setPlayerNumber() then
        self.round = 0
        self.startPlayer = nil
        self.trump = nil
        self.bids = {}
        self:setStartPlayer()
        self:clearPoints()

        self.scoreTable:reset()
        self.scoreBoard:reset(self)

        CounterManager:destroyUnusedCounters()

        UIManager:init()

        self:startRound()
    end

    return false
end

function Game:startRound()
    self:initVariables()
    local deck = getObjectFromGUID(Constants.Guid.Table.Deck)
    -- Deck wird gemischt und die erste Karte wird ausgeteilt
    deck.randomize()
    deck.deal(self.round)
    -- Die oberste Karte wird umgedreht und als Trumpf in Global definiert
    local deckPos = deck.getPosition()

    deck.takeObject({flip = true, position = deckPos, callback_function = function(flippedCard) 
        self:callbackFlippedCard(flippedCard)
    end
    })
end

function Game:callbackFlippedCard(flippedCard)
    flippedCard.interactable = false

    self:setTrump()
    
    self.currentState = Constants.State.Bid
end

function Game:initVariables()
    self.activePlayer = self.startPlayer
    self.startPlayerTrick = self.activePlayer
    self:printTurn(self.activePlayer)
    self:setTricksToZero()
    self.round = self.round + 1

    self:getNextPlayer()
end


function Game:bid(counterParams)
    if self.currentState ~= Constants.State.Bid then
        broadcastToColor("It's not time to bid for tricks!", counterParams.counterPlayer, "Red")
    else
        if self.currentState == Constants.State.TrumpSelection then
            local previousPlayerNumber = startPlayerNumber - 1
            if previousPlayerNumber == 0 then
               previousPlayerNumber = PlayerManager:getNumberOfPlayers()
            end
            broadcastToColor(Player[playerList[previousPlayerNumber]].steam_name.." has to determine trump.", counterParams.counterPlayer, "Red")
            return
        end
        if self.activePlayer == counterParams.counterPlayer then
            if counterParams.counterValue < 0 then
                broadcastToColor("Negative bids are not allowed!", counterParams.counterPlayer, "Red")
                CounterManager:clearForPlayer(counterParams.counterPlayer)
            elseif counterParams.counterValue > self.round then
                broadcastToColor("You don't have that many cards!", counterParams.counterPlayer, "Red")
                CounterManager:clearForPlayer(counterParams.counterPlayer)
            else
                self.bids[self.activePlayer] = counterParams.counterValue
                if lastPlayer == true then
                    local bidsTotal = 0
                    for player in pairs(PlayerManager:getPlayers()) do
                        bidsTotal = bidsTotal + self.bids[player]
                    end
                    if bidsTotal == self.round then
                        broadcastToColor("The total tricks must not equal the number of cards handed out this round. Please change your bid!", counterParams.counterPlayer, "Red")
                        return
                    end
                end

                --Todo auslagern
                self.scoreTable.textBids[self.activePlayer][self.round].setValue(tostring(self.bids[self.activePlayer]))
                self:nextActivePlayer()
            end
        end
    end
end


function Game:setTricksToZero()
    for player in pairs(PlayerManager:getPlayers()) do
        self.tricks[player] = 0
    end
    self.tricksTotal = 0
end

function Game:clearPoints()
    self.points = {}

    for player in pairs(PlayerManager:getPlayers()) do
        self.points[player] = 0
    end
end

function Game:endTrick()
    self.table:moveTrickToWinner()

    startPlayerTrick = bestCardPlayer
    activePlayer = bestCardPlayer
    activePlayerNumber = bestCardPlayerNumber
    self:countTricks()
end

function Game:countTricks()
    self.tricks[bestCardPlayerNumber] = self.tricks[bestCardPlayerNumber] + 1
    self.tricksTotal = self.tricksTotal + 1
    if self.tricksTotal == self.round then
        Wait.time(endRound, 1)
    else
        self:printTurn(self.activePlayer)
    end
end

function Game:resetDeck()
    if self.round == 60 / PlayerManager.getNumberOfPlayers() then
        self:endGame()
    else
        self.table:resetDeck()
        self:startRound()
    end
end

function Game:endRound()
    self:countPoints()
    self.scoreTable:writePoints(self.round)
    self.startPlayer = PlayerManager:getNextPlayer(self.startPlayer)

    Wait.time(function()
        self.table:collectCards(function()
            self:resetDeck()
        end)
    end, 2)
end

function Game:countPoints()
  for player in pairs(PlayerManager:getPlayers()) do
      if self.bids[player] == self.tricks[player] then
        self.points[player] = 20 + 10 * self.tricks[player] + self.points[player]
      else
        self.points[player] = math.abs(self.bids[player] - self.tricks[player]) * -10 + self.points[player]
      end
  end
end

function Game:endGame()
    local bestPlayer = {}
    local highestPoints = math.max(self.points)
    for player in pairs(PlayerManager:getPlayers()) do
        if points[player] == highestPoints then
            table.insert(bestPlayer, player)
        end
    end
    if #bestPlayer == 1 then
        UIManager:printEndScreen(bestPlayer[1])
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

---Trump
function Game:setTrump()
    local deckZoneObjects = self.table.deckZone.getObjects()

    for _, item in ipairs(deckZoneObjects) do
        if item.tag == "Card" then
            self.trump = item.getName()
        end
    end

    self:interpretTrump()
end

function Game:interpretTrump()
    if self.trump == nil then
        logToAllOrHost("Fehler bei Ermittlung Trumpf", "Red")
    elseif self.trump == "N" then
        self.trump = "null"
    elseif self.trump == "Z" then
        self.currentState = Constants.State.TrumpSelection
        self:selectTrump()
    end
end

function Game:selectTrump()
    local previousPlayer = self:getPreviousPlayer()
    broadcastToAll("Spieler "..PlayerManager:getName(previousPlayer).." darf bestimmen, welche Farbe diese Runde Trumpf ist", "Red")
end

---Player
function Game:nextActivePlayer()
    self.activePlayer = self:getNextPlayer()
    self:printTurn(self.activePlayer)

    if self:isLastPlayer() then
        self:printTurn(self.activePlayer)
    else
        if self.activePlayer == self.startPlayerTrick then
            if self.currentState == Constants.State.Bid then
                self.currentState = Constants.State.PlayCards
                self:printTurn(self.activePlayer)
            else
                self:endTrick()
            end
        else
            self:printTurn(self.activePlayer)
        end
    end
end

function Game:setStartPlayer()
    self.startPlayer = PlayerManager:getRandomPlayer()
    broadcastToAll(PlayerManager:getName(self.startPlayer).." is randomly chosen as starting player", self.startPlayer)
end

function Game:getNextPlayer(player)
    if player == nil then
        player = self.activePlayer
    end

    return PlayerManager:getNextPlayer(self.activePlayer)
end

function Game:getPreviousPlayer()
    return PlayerManager:getPreviousPlayer(self.activePlayer)
end

function Game:isLastPlayer(player)
    if player == nil then
        player = self.activePlayer
    end

    return PlayerManager:getNextPlayer(player) == self.startPlayerTrick
end

---Misc
function Game:printTurn(player)
    UI.setAttributes("TurnText", {text = PlayerManager:getName(player).."'s Turn", color = player})
    printToAll("<--------------------- "..PlayerManager:getName(player).."'s Turn --------------------->", player)
end

return Game