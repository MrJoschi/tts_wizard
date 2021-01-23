local Constants = require "constants"

local UIManager = {
    init = function(self)
        UI.setAttribute("TurnScreen", "active", "true")
        UI.setAttribute("Scoreboard", "active", "true")
    end,
}

return UIManager