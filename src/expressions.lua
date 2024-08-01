local oo = require 'libs.oo'
local tablef = require 'libs.tablef'
local uuid = require 'libs.uuid'
local checkType = type

local variable = require 'variable'

local ScopeTree = {
    any = {
        type = "any",
        name = "any",
        value = nil,
    },
    none = {
        type = "none",
        name = "none",
        value = nil,
    },
    number = {
        type = "number",
        name = "number",
        value = nil,
    },
    string = {
        type = "string",
        name = "string",
        value = nil,
    },
    boolean = {
        type = "boolean",
        name = "boolean",
        value = nil,
    },
}

local function getScope(scope)
    --scope: index path, for example: {2, 1}. If nil, then global scope.

    if not scope then scope = {} end

    local function getVariables(t)
        local vars = {}
        for k, v in pairs(t) do
            if v.type then
                vars[k] = v
            end
        end
        return vars
    end

    local current = ScopeTree
    local allVariables = getVariables(current)

    for _, index in ipairs(scope) do
        current = current[index]
        local newVariables = getVariables(current)

        for k, v in pairs(newVariables) do
            allVariables[k] = v
        end
    end

    return allVariables
end

local function addVariable(variable, scope)
    --scope: index path, for example: {2, 1}. If nil, then global scope.

    if not scope then scope = {} end

    local current = ScopeTree

    for _, index in ipairs(scope) do
        if not current[index] then
            current[index] = {}
        end
        current = current[index]
    end

    current[variable.name] = variable
end

local exps = {}

exps.Expression = oo.class()

function exps.Expression:init()
    self.type = "NotImplemented"
end

function exps.Expression:compile()
    -- Compile into native Lua code
    error("Not implemented.")
end

---

exps.declare_variable = oo.class(exps.Expression)

function exps.declare_variable:init(type, name, expression, scopePath)
    assert(checkType(type) == "string", "Type must be a string.")
    assert(checkType(name) == "string", "Name must be a string.")
    assert(checkType(expression) == "table", "Expression must be an expression.")

    local scope = getScope(scopePath)
    local typeInstanceIndex = tablef.findfn(
        scope,
        function(v)
            return v.name == type
        end
    )
    local typeInstance = scope[typeInstanceIndex]
    assert(typeInstance ~= nil, "Type not declared.")
    assert(not scope[name], "Variable already declared.")

    self.type = typeInstance.type
    self.name = name
    self.expression = expression

    self.variable = variable(self.type, name, expression)

    addVariable(self.variable, scopePath)
end

function exps.declare_variable:compile()
    return string.format("%s %s = %s; --type:%s", "local", self.name, self.expression:compile(), self.type)
end

exps.assign_variable = oo.class(exps.Expression)

function exps.assign_variable:init(name, expression, scope_path)
    assert(checkType(name) == "string", "Name must be a string.")
    assert(checkType(expression) == "table", "Expression must be an expression.")

    local scope = getScope(scope_path)

    assert(scope[name], "Variable not declared.")

    -- Check if the expression is of the same type as the variable

    assert(scope[name].type == expression.type or scope[name].type == "any",
        "Type mismatch. Expected " .. scope[name].type .. ", got " .. expression.type)

    self.name = name
    self.expression = expression
end

function exps.assign_variable:compile()
    return string.format("%s = %s;", self.name, self.expression:compile())
end

---

exps.number = oo.class(exps.Expression)

function exps.number:init(value)
    assert(type(value) == "number", "Value must be a number.")
    self.value = value
    self.type = "number"
end

function exps.number:compile()
    return tostring(self.value)
end

exps.boolean = oo.class(exps.Expression)

function exps.boolean:init(value)
    assert(type(value) == "boolean", "Value must be a boolean.")
    self.value = value
    self.type = "boolean"
end

function exps.boolean:compile()
    return tostring(self.value)
end

exps.none = oo.class(exps.Expression)

function exps.none:init()
    self.type = "none"
end

function exps.none:compile()
    return "nil"
end

---

exps.variable = oo.class(exps.Expression)

function exps.variable:init(name, scope_path)
    assert(type(name) == "string", "Name must be a string.")
    self.name = name
    self.scope_path = scope_path

    local scope = getScope(scope_path)

    assert(scope[name], "Variable '" .. name .. "' not declared.")

    self.type = scope[name].type
end

function exps.variable:compile()
    return self.name
end

---

exps.MathOperation = oo.class(exps.Expression)

function exps.MathOperation:init(op, left, right)
    assert(type(op) == "string", "Operator must be a string.")
    assert(type(left) == "table", "Left must be an expression.")
    assert(type(right) == "table", "Right must be an expression.")
    assert(left.type == "number" or left.type == "any", "Invalid type for operand. Got " .. left.type)
    assert(right.type == "number" or right.type == "any", "Invalid type for operand. Got " .. right.type)

    self.op = op
    self.left = left
    self.right = right
    self.type = "number"
end

function exps.MathOperation:compile()
    return "(" .. self.left:compile() .. " " .. self.op .. " " .. self.right:compile() .. ")"
end

exps.add = oo.class(exps.MathOperation)

function exps.add:init(left, right)
    exps.MathOperation.init(self, "+", left, right)
end

exps.subtract = oo.class(exps.MathOperation)

function exps.subtract:init(left, right)
    exps.MathOperation.init(self, "-", left, right)
end

exps.multiply = oo.class(exps.MathOperation)

function exps.multiply:init(left, right)
    exps.MathOperation.init(self, "*", left, right)
end

exps.divide = oo.class(exps.MathOperation)

function exps.divide:init(left, right)
    exps.MathOperation.init(self, "/", left, right)
end

exps.modulo = oo.class(exps.MathOperation)

function exps.modulo:init(left, right)
    exps.MathOperation.init(self, "%", left, right)
end

exps.power = oo.class(exps.MathOperation)

function exps.power:init(left, right)
    exps.MathOperation.init(self, "^", left, right)
end

---

exps.BooleanOperation = oo.class(exps.Expression)

function exps.BooleanOperation:init(op, left, right)
    assert(type(op) == "string", "Operator must be a string.")
    assert(type(left) == "table", "Left must be an expression.")
    assert(type(right) == "table", "Right must be an expression.")
    self.op = op
    self.left = left
    self.right = right
    self.type = "boolean"
end

function exps.BooleanOperation:compile()
    return "(" .. self.left:compile() .. " " .. self.op .. " " .. self.right:compile() .. ")"
end

exps.and_op = oo.class(exps.BooleanOperation)

function exps.and_op:init(left, right)
    exps.BooleanOperation.init(self, "and", left, right)
end

exps.or_op = oo.class(exps.BooleanOperation)

function exps.or_op:init(left, right)
    exps.BooleanOperation.init(self, "or", left, right)
end

exps.not_op = oo.class(exps.Expression)

function exps.not_op:init(expression)
    assert(type(expression) == "table", "Expression must be an expression.")
    self.expression = expression
    self.type = "boolean"
end

function exps.not_op:compile()
    return "(not " .. self.expression:compile() .. ")"
end

---

exps.ComparisonOperation = oo.class(exps.Expression)

function exps.ComparisonOperation:init(op, left, right)
    assert(type(op) == "string", "Operator must be a string.")
    assert(type(left) == "table", "Left must be an expression.")
    assert(type(right) == "table", "Right must be an expression.")
    self.op = op
    self.left = left
    self.right = right
    self.type = "boolean"
end

function exps.ComparisonOperation:compile()
    return "(" .. self.left:compile() .. " " .. self.op .. " " .. self.right:compile() .. ")"
end

exps.equal = oo.class(exps.ComparisonOperation)

function exps.equal:init(left, right)
    exps.ComparisonOperation.init(self, "==", left, right)
end

exps.not_equal = oo.class(exps.ComparisonOperation)

function exps.not_equal:init(left, right)
    exps.ComparisonOperation.init(self, "~=", left, right)
end

exps.less_than = oo.class(exps.ComparisonOperation)

function exps.less_than:init(left, right)
    exps.ComparisonOperation.init(self, "<", left, right)
end

exps.less_than_or_equal = oo.class(exps.ComparisonOperation)

function exps.less_than_or_equal:init(left, right)
    exps.ComparisonOperation.init(self, "<=", left, right)
end

exps.greater_than = oo.class(exps.ComparisonOperation)

function exps.greater_than:init(left, right)
    exps.ComparisonOperation.init(self, ">", left, right)
end

exps.greater_than_or_equal = oo.class(exps.ComparisonOperation)

function exps.greater_than_or_equal:init(left, right)
    exps.ComparisonOperation.init(self, ">=", left, right)
end

return exps
