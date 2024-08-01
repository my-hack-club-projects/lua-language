local tablef = require 'libs.tablef'

local lexer = require 'lexer'
local parser = require 'parser'
local environment = require 'environment'

local input = [[
    print("Hello, world!")
    print("Hello, world!"
]]

-- local input = [[
--     print("h")
-- ]]

local lex = lexer(input)

tablef.print(lex.tokens)
print(("-"):rep(50))
local parse = parser(lex.tokens)
local compiled = ""

for _, expression in ipairs(parse.expressions) do
    compiled = compiled .. expression:compile() .. "\n"
end

print(compiled)

print(("-"):rep(50))

-- Execute the code (test: compile first, then exec)
local code = load(compiled, "code", "t", environment)

code()
