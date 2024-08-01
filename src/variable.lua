local oo = require 'libs.oo'

local variable = oo.class()

function variable:init(type, name, value)
    self.type = type
    self.name = name
    self.value = value
end

return variable
