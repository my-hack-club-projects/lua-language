local oo = require 'libs.oo'

local expressions = require 'expressions'

local parser = oo.class()

function parser:init(tokens)
    assert(tokens, "Tokens must be provided.")

    self.expressions = {}

    local i = 0

    local function next_token()
        i = i + 1
        local token = tokens[i]
        return token
    end

    local function skip_token()
        i = i + 1
    end

    local function peek_token(offset)
        if not offset then
            offset = 0
        end

        if i + offset > #tokens or i + offset < 1 then
            return nil
        end

        return tokens[i + offset]
    end

    -- Parse the tokens.

    while i <= #tokens do
        local token = next_token()
        local prev_token = peek_token(-1)

        if not token then
            break
        end

        -- Variable declaration.
        if (prev_token == nil or prev_token == ";") and peek_token(2) == "=" then
            local type = token
            local name = next_token()
            assert(next_token() == "=", "Expected '='.")
            local expression_tokens = {}
            while next_token() ~= ";" and peek_token() ~= nil do
                table.insert(expression_tokens, peek_token())
            end
            local value_expression = self:parse_expression(expression_tokens)
            local variable_expression = expressions.declare_variable(type, name, value_expression)
            table.insert(self.expressions, variable_expression)

            -- Variable assignment.
        elseif prev_token == ";" and peek_token(1) == "=" then
            local name = token
            assert(next_token() == "=", "Expected '='.")
            local expression_tokens = {}
            while next_token() ~= ";" do
                table.insert(expression_tokens, peek_token())
            end
            local value_expression = self:parse_expression(expression_tokens)
            local variable_expression = expressions.assign_variable(name, value_expression)
            table.insert(self.expressions, variable_expression)

            -- Function call. Any expression that is not a variable declaration or assignment, followed by parantheses is considered a function call.
            -- Steps:
            -- 1. Parse the function name.
            -- -- That can either be a single word or a dot-separated list of words
            -- 2. Parse the arguments.
            -- 3. Create a function call expression.
        elseif token:match("^%a+$") and peek_token(1) == "." or peek_token(1) == "[" or peek_token(1) == "(" then
            -- get the whole path. the current token is the first word.

            local path = { token }
            while next_token() == "." do
                local _next = next_token()
                assert(_next:match("^%a+$"), "Expected an identifier.")
                table.insert(path, _next)
            end

            local function_name = table.concat(path, ".")

            -- skip the function name and the opening parantheses
            assert(peek_token() == "(")

            local arguments = {}

            while peek_token() ~= ")" do
                local expression_tokens = {}
                while next_token() ~= "," and peek_token() ~= ")" do
                    table.insert(expression_tokens, peek_token())
                end
                for i = 1, #expression_tokens do
                    print("Expression token: " .. expression_tokens[i])
                end
                local argument_expression = self:parse_expression(expression_tokens)
                table.insert(arguments, argument_expression)
            end

            assert(peek_token() == ")", "Expected ')'.")
            assert(next_token() == ";", "Expected ';'.")

            local function_call_expression = expressions.function_call(function_name, arguments)
            table.insert(self.expressions, function_call_expression)
        else
            error("Unexpected token: " .. token)
        end
    end
end

function parser:parse_expression(expression_tokens)
    local i = 1

    local function next_token()
        local token = expression_tokens[i]
        i = i + 1
        return token
    end

    local function skip_token()
        i = i + 1
    end

    local function peek_token(offset)
        if not offset then
            offset = 0
        end

        if i + offset > #expression_tokens or i + offset < 1 then
            return nil
        end

        return expression_tokens[i + offset]
    end

    local function parse_expression()
        local token = next_token()

        if token == "(" then
            local expression = parse_expression()
            assert(next_token() == ")", "Expected ')'.")
            return expression
        elseif token:match("^%d+$") then
            return expressions.number(tonumber(token))
        elseif token == "not" then
            local expression = parse_expression()
            return expressions.not_op(expression)
        elseif token:match("^%a+$") then
            if token == "true" then
                return expressions.boolean(true)
            elseif token == "false" then
                return expressions.boolean(false)
            elseif token == "none" then
                return expressions.none()
            else
                return expressions.variable(token)
            end
        elseif token:match('"(.-)"') then
            return expressions.string(token:match('"(.-)"'))
        else
            error("Unexpected token: " .. token)
        end
    end

    local function parse_expression_with_precedence(precedence)
        local expression = parse_expression()

        while true do
            local operator = peek_token()

            if operator == nil then
                break
            end

            local operator_precedence = 0

            if operator == "or" then
                operator_precedence = 1
            elseif operator == "and" then
                operator_precedence = 2
            elseif operator == "<" or operator == ">" or operator == "<=" or operator == ">=" or operator == "==" or operator == "!=" then
                operator_precedence = 3
            elseif operator == "+" or operator == "-" then
                operator_precedence = 4
            elseif operator == "*" or operator == "/" or operator == "%" then
                operator_precedence = 5
            elseif operator == "^" then
                operator_precedence = 6
            end

            if operator_precedence <= precedence then
                break
            end

            skip_token()

            local right_expression = parse_expression_with_precedence(operator_precedence)

            if operator == "or" then
                expression = expressions.or_op(expression, right_expression)
            elseif operator == "and" then
                expression = expressions.and_op(expression, right_expression)
            elseif operator == "<" then
                expression = expressions.less_than(expression, right_expression)
            elseif operator == ">" then
                expression = expressions.greater_than(expression, right_expression)
            elseif operator == "<=" then
                expression = expressions.less_than_or_equal(expression, right_expression)
            elseif operator == ">=" then
                expression = expressions.greater_than_or_equal(expression, right_expression)
            elseif operator == "==" then
                expression = expressions.equal(expression, right_expression)
            elseif operator == "!=" then
                expression = expressions.not_equal(expression, right_expression)
            elseif operator == "+" then
                expression = expressions.add(expression, right_expression)
            elseif operator == "-" then
                expression = expressions.subtract(expression, right_expression)
            elseif operator == "*" then
                expression = expressions.multiply(expression, right_expression)
            elseif operator == "/" then
                expression = expressions.divide(expression, right_expression)
            elseif operator == "%" then
                expression = expressions.modulo(expression, right_expression)
            elseif operator == "^" then
                expression = expressions.power(expression, right_expression)
            end
        end

        return expression
    end

    return parse_expression_with_precedence(0)
end

return parser
