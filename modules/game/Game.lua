local Board = require "modules.board.board"
local ScoreTable = require "modules.score.scoretable"
local ScoreBoard = require "modules.score.scoreboard"
local CounterManager = require "modules.counter.countermanager"
local PlayerManager = require "modules.player.playermanager"
local Constants = require "constants"

local Game = {}

function Game:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.board = Board:new()
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

        self:setStartPlayer()
        self:clearPoints()

        self.scoreTable:reset()
        self.scoreBoard:reset(self)

        CounterManager:destroyUnusedCounters()

        UI.setAttribute("TurnScreen", "active", "true")
        UI.setAttribute("Scoreboard", "active", "true")

        self:startRound()
    end

    return false
end

function Game:startRound()
    self:initVariables()
    local deck = getObjectFromGUID(Constants.Guid.Board.Deck)
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
    -- startPlayerTrick = startPlayerRound
    self:printTurn(activePlayer)
    self:setTricksToZero()
    self.round = self.round + 1
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

function Game:setTrump()
    local deckZoneObjects = self.board.deckZone.getObjects()

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
            selectTrump()
    end
end

function Game:selectTrump()
    local previousPlayerNumber = startPlayerNumber - 1
    if previousPlayerNumber == 0 then
       previousPlayerNumber = numberOfPlayers
    end
    broadcastToAll("Spieler "..playerList[previousPlayerNumber].." darf bestimmen, welche Farbe diese Runde Trumpf ist", "Red")
end

function Game:setStartPlayer()
    self.startPlayer = PlayerManager:getRandomPlayer()
    broadcastToAll(Player[self.startPlayer].steam_name.." is randomly chosen as starting player", self.startPlayer)
end

function Game:printTurn(player)
    UI.setAttributes("TurnText", {text = Player[player].steam_name.."'s Turn", color = player})
    printToAll("<--------------------- "..Player[player].steam_name.."'s Turn --------------------->", player)
end

return Game