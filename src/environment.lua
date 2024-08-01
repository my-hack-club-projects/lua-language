local oo = require 'libs.oo'

local number = oo.class()

function number:init(value)
    self.value = value
end

function number:__eq(other)
    return self.value == other.value
end

function number:__tostring()
    return tostring(self.value)
end

function number:__add(other)
    return number(self.value + other.value)
end

function number:__sub(other)
    return number(self.value - other.value)
end

function number:__mul(other)
    return number(self.value * other.value)
end

function number:__div(other)
    return number(self.value / other.value)
end

function number:__mod(other)
    return number(self.value % other.value)
end

function number:__pow(other)
    return number(self.value ^ other.value)
end

function number:__unm()
    return number(-self.value)
end

function number:__lt(other)
    return self.value < other.value
end

function number:__le(other)
    return self.value <= other.value
end

function number:__gt(other)
    return self.value > other.value
end

function number:__ge(other)
    return self.value >= other.value
end

function number:__concat(other)
    return number(self.value .. other.value)
end

return {
    number = number,

    print = function(...)
        local args = { ... }
        for i = 1, #args do
            io.write(tostring(args[i]))
            if i < #args then
                io.write("\t")
            end
        end
        io.write("\n")
    end,
}
