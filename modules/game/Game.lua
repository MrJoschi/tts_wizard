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
    instance.playerManager = PlayerManager:new()
    instance.counterManager = CounterManager:new(instance.playerManager)

    instance.startPlayer = nil

    instance:init()

    return instance
end

function Game:init()
end

function Game:start()
    if self.playerManager:setPlayerNumber() then
        self.counterManager:destroyUnusedCounters()
        self:setStartPlayer()
        -- writePointblockHeadlines()
        -- round = 0
        -- setPointsToZero()
        -- setTextPoints()
        -- setTextBids()
        -- turnOnTurnScreen()
        -- turnOnScoreboard()
        -- writeScoreboard()
        -- startRound()
    end

    return false
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
    self.startPlayer = self.playerManager:getRandomPlayer()
    broadcastToAll(Player[self.startPlayer].steam_name.." is randomly chosen as starting player", self.startPlayer)
end

return Game