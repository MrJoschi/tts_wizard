local Board = require "modules.board.board"
local ScoreTable = require "modules.score.scoretable"
local ScoreBoard = require "modules.score.scoreboard"
local CounterManager = require "modules.counter.countermanager"
local PlayerManager = require "modules.player.playermanager"

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

    instance:init()

    return instance
end

function Game:init()
    CounterManager:init()
end

function Game:start()
    if PlayerManager:setPlayerNumber() then
        self.round = 0
        
        self:setStartPlayer()
        self:clearPoints()

        self.scoreTable:reset()
        self.scoreBoard:reset()

        CounterManager:destroyUnusedCounters()
        
        UI.setAttribute("TurnScreen", "active", "true")
        UI.setAttribute("Scoreboard", "active", "true")
        -- startRound()
    end

    return false
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
            trump = item.getName()
        end
    end

    interpretTrump()
end

function Game:setStartPlayer()
    self.startPlayer = PlayerManager:getRandomPlayer()
    broadcastToAll(Player[self.startPlayer].steam_name.." is randomly chosen as starting player", self.startPlayer)
end

return Game