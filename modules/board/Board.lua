local Constants = require "constants"
local Board = {}

function Board:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.deckZone = getObjectFromGUID(Constants.Guid.Board.DeckZone)
    instance.deck = getObjectFromGUID(Constants.Guid.Board.Deck)
    instance.playZone = getObjectFromGUID(Constants.Guid.Board.DeckZone)

    instance:init()

    return instance
end

function Board:init()
    self.deck.interactable = false
end

return Board