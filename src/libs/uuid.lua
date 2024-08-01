local existing = {}

return function()
    -- Generate a UUID. Must start with a letter, no spaces, no special characters.

    local uuid = ""

    repeat
        uuid = ""

        for i = 1, 32 do
            local char = string.char(math.random(97, 122))
            uuid = uuid .. char
        end
    until not existing[uuid]

    existing[uuid] = true

    return uuid
end
