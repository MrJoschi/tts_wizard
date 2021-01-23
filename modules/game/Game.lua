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

    instance.startPlayer = nil
    instance.round = 0
    instance.points = {}

    instance.tricks = {}
    instance.tricksTotal = 0

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
    
    bidRound = true
end

function Game:initVariables()
    activePlayer = self.startPlayer
    startPlayerTrick = activePlayer
    self:printTurn(activePlayer)
    self:setTricksToZero()
    self.round = self.round + 1

    self:getNextPlayer()
end


function Game:bid(counterParams)
    if bidRound == false then
        broadcastToColor("It's not time to bid for tricks!", counterParams.counterPlayer, "Red")
    else
        if waitForSelectTrump == true then
            local previousPlayerNumber = startPlayerNumber - 1
            if previousPlayerNumber == 0 then
               previousPlayerNumber = PlayerManager.getNumberOfPlayers()
            end
            broadcastToColor(Player[playerList[previousPlayerNumber]].steam_name.." has to determine trump.", counterParams.counterPlayer, "Red")
            return
        end
        if activePlayer == counterParams.counterPlayer then
            if counterParams.counterValue < 0 then
                broadcastToColor("Negative bids are not allowed!", counterParams.counterPlayer, "Red")
                clearCounter(counterParams.counterPlayer)
            elseif counterParams.counterValue > self.round then
                broadcastToColor("You don't have that many cards!", counterParams.counterPlayer, "Red")
                clearCounter(counterParams.counterPlayer)
            else
                self.bids[activePlayer] = counterParams.counterValue
                if lastPlayer == true then
                    local bidsTotal = 0
                    for i = 1, PlayerManager.getNumberOfPlayers(), 1 do
                        bidsTotal = bidsTotal + self.bids[i]
                    end
                    if bidsTotal == self.round then
                        broadcastToColor("The total tricks must not equal the number of cards handed out this round. Please change your bid!", counterParams.counterPlayer, "Red")
                        return
                    end
                end

                --Todo auslagern
                self.scoreTable.textBids[activePlayer][self.round].setValue(tostring(self.bids[activePlayer]))
                self:nextActivePlayer()
            end
        end
    end
end


function Game:setTricksToZero()
    for i = 1, PlayerManager.getNumberOfPlayers(), 1 do
        self.tricks[i] = 0
    end
    self.tricksTotal = 0
end

function Game:clearPoints()
    self.points = {}

    for player in pairs(PlayerManager.getPlayers()) do
        self.points[player] = 0
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
            waitForSelectTrump = true
            self:selectTrump()
    end
end

function Game:selectTrump()
    local previousPlayer = self:getPreviousPlayer()
    broadcastToAll("Spieler "..PlayerManager.getName(previousPlayer).." darf bestimmen, welche Farbe diese Runde Trumpf ist", "Red")
end

---Player
function Game:nextActivePlayer()
    activePlayer = self:getNextPlayer()

    if activePlayer == startPlayerTrick then
        lastPlayer = true
        self:printTurn(activePlayer)
    else
        lastPlayer = false
        if activePlayer == startPlayerTrick then
            if bidRound == true then
                bidRound = false
                self:printTurn(activePlayer)
            else
                endTrick()
            end
        else
            self:printTurn(activePlayer)
        end
    end
end

function Game:setStartPlayer()
    self.startPlayer = PlayerManager:getRandomPlayer()
    broadcastToAll(PlayerManager.getName(self.startPlayer).." is randomly chosen as starting player", self.startPlayer)
end

function Game:getNextPlayer()
    return PlayerManager:getNextPlayer(activePlayer)
end

function Game:getPreviousPlayer()
    return PlayerManager:getPreviousPlayer(activePlayer)
end

---Misc
function Game:printTurn(player)
    UI.setAttributes("TurnText", {text = Player[player].steam_name.."'s Turn", color = player})
    printToAll("<--------------------- "..Player[player].steam_name.."'s Turn --------------------->", player)
end

return Game