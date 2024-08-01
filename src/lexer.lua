-- lexer.lua: The lexer for our custom language.
local oo = require 'libs.oo'
local tablef = require 'libs.tablef'
local lexer = oo.class()

lexer.separators = {
    "(", ")", "{", "}", "[", "]",
    "+", "-", "*", "/", "%", "^",
    ",", ".", ";", ":", "=", "<", ">", "!", "?",
}

function lexer:init(input)
    assert(input, "Input must be provided.")

    self.input = input
    self.tokens = {}

    local current_token, i = "", 1
    local literalStringOpen = false
    local paranthesesOpen = 0

    while i <= #input do
        local c = input:sub(i, i)

        if c:match(" ") and not literalStringOpen then -- Space
            if current_token ~= "" then
                table.insert(self.tokens, current_token)
                current_token = ""
            end
            i = i + 1
        elseif c:match("\n") and not literalStringOpen then -- Newline, automatically insert a semicolon if its not there already
            if current_token ~= "" then
                table.insert(self.tokens, current_token)
                current_token = ""
            end
            if self.tokens[#self.tokens] ~= ";" and paranthesesOpen == 0 then
                table.insert(self.tokens, ";")
            end
            i = i + 1
        elseif c:match("[%w_]") or literalStringOpen and c ~= '"' then -- Alphanumeric or underscore
            current_token = current_token .. c
            i = i + 1
        elseif c:match('"') then -- String literal
            if literalStringOpen then
                table.insert(self.tokens, current_token .. c)
                current_token = ""
                literalStringOpen = false
            else
                literalStringOpen = true
                current_token = current_token .. c
            end
            i = i + 1
        elseif tablef.contains(self.separators, c) then -- Separator
            if c == "(" or c == "{" or c == "[" then
                paranthesesOpen = paranthesesOpen + 1
            elseif c == ")" or c == "}" or c == "]" then
                paranthesesOpen = paranthesesOpen - 1
            end

            if current_token ~= "" then
                table.insert(self.tokens, current_token)
                current_token = ""
            end
            table.insert(self.tokens, c)
            i = i + 1
        else
            error("Unexpected character: " .. c)
        end
    end

    if current_token ~= "" then
        table.insert(self.tokens, current_token)
    end
end

return lexer
