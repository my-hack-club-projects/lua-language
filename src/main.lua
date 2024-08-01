local tablef = require 'libs.tablef'

local lexer = require 'lexer'
local parser = require 'parser'

local input = [[
    number x = 10;
    x = x + 1

    any y = 20
    y = y * x / 2

    boolean z = x > 10 or y < 10
    z = not z
    z = z and true

    any test = none
    none test2 = none

    number a = 10
    a = x

    a c = 20
    c = a

    string d = "hello"
]]

local lex = lexer(input)

tablef.print(lex.tokens)
print(("-"):rep(50))
local parse = parser(lex.tokens)

for _, expression in ipairs(parse.expressions) do
    print(expression:compile())
end
