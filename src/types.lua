local oo = require 'libs.oo'
local tablef = require 'libs.tablef'

local types = {}

local Type = setmetatable(oo.class(), {
    __eq = function(t1, t2)
        return t1.name == t2.name
    end,
})

function Type:init(name_str)
    self.name = name_str
end

function Type:eq(other)
    if type(other) == "string" then
        return self.name == other
    end

    return self.name == other.name
end

function Type.__tostring(self)
    return "<type " .. self.name .. ">"
end

types.string = oo.class(Type)

function types.string:init()
    Type.init(self, "string")
end

types.number = oo.class(Type)

function types.number:init()
    Type.init(self, "number")
end

types.boolean = oo.class(Type)

function types.boolean:init()
    Type.init(self, "boolean")
end

types.any = oo.class(Type)

function types.any:init()
    Type.init(self, "any")
end

types.none = oo.class(Type)

function types.none:init()
    Type.init(self, "none")
end

types.table = oo.class(Type)

function types.table:init(t)
    Type.init(self, "table")
    self.t = t
end

function types.table:__eq(other)
    if type(other) == "string" then
        return self.name == other
    end

    return self.name == other.name and tablef.every(self.t, function(k, v)
        return other.t[k] == v
    end)
end

return types
