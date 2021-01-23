local Constants = require "constants"
local Table = {}

function Table:new()
    local instance = {}
    self.__index = self
    setmetatable(instance, self)

    instance.deckZone = getObjectFromGUID(Constants.Guid.Table.DeckZone)
    instance.deck = getObjectFromGUID(Constants.Guid.Table.Deck)
    instance.playZone = getObjectFromGUID(Constants.Guid.Table.DeckZone)

    instance:init()

    return instance
end

function Table:init()
    self.deck.interactable = false
end

return Table