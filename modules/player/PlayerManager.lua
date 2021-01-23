local Constants = require "constants"
local Helpers = require "helpers"

local playersArray = {}
local players = {}
local numberOfPlayers = 0

local PlayerManager = {
    setPlayerNumber = function()
        playersArray = getSeatedPlayers()
        players = {}

        for id, player in pairs(playersArray) do
            players[player] = player
        end

        numberOfPlayers = Helpers.getSize(players)

        if numberOfPlayers < Constants.Config.countPlayerMin or numberOfPlayers > Constants.Config.countPlayerMax then
            broadcastToAll("Dieses Spiel ist nur für "..Constants.Config.countPlayerMin.."-"..Constants.Config.countPlayerMax.." Spieler!", "Red")
            return false
        end

        broadcastToAll("You are playing with "..numberOfPlayers.." player(s)", "Green")
        return true
    end,
    getPlayers = function()
        return players
    end,
    getPlayersArray = function()
        return playersArray
    end,
    hasPlayer = function(self, player)
        return players[player] ~= nil
    end,
    getNumberOfPlayers = function()
        return numberOfPlayers
    end,
    getRandomPlayer = function()
        local randomNumber = math.random(1, numberOfPlayers)
        return playersArray[randomNumber]
    end,
    getName = function(player)
        return Player[player].steam_name
    end,
    getNextPlayer = function(self, currentPlayer)
        local index = self.getIndexOfPlayer(currentPlayer)
        local indexNextPlayer = index + 1

        if indexNextPlayer > numberOfPlayers then
            indexNextPlayer = 1
        end

        return playersArray[indexNextPlayer]
    end,
    getPreviousPlayer = function(self, currentPlayer)
        local index = self.getIndexOfPlayer(currentPlayer)

        local indexNextPlayer = index - 1

        if indexNextPlayer == 0 then
            indexNextPlayer = numberOfPlayers
        end

        return playersArray[indexNextPlayer]
    end,
    getIndexOfPlayer = function(playerPassed)
        for index, player in pairs(playersArray) do
            if (playerPassed == player) then
                return index
            end
        end
    end,
}

return PlayerManager