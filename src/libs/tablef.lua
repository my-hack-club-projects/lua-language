local tablef = setmetatable({}, { __index = table })

function tablef.print(t, _indent)
    -- recursive function to print a table with proper indentation

    local indent = _indent or 0
    local indent_str = string.rep(" ", indent)

    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent_str .. k .. ":")
            tablef.print(v, indent + 4)
        else
            print(indent_str .. k .. ": " .. tostring(v))
        end
    end
end

function tablef.every(t, f)
    for k, v in pairs(t) do
        if not f(k, v) then
            return false
        end
    end
    return true
end

function tablef.find(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
    return nil
end

function tablef.findfn(t, f)
    for k, v in pairs(t) do
        if f(v) then
            return k
        end
    end
    return nil
end

function tablef.keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

function tablef.values(t)
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

function tablef.map(t, f)
    local new_t = {}
    for k, v in pairs(t) do
        new_t[k] = f(v)
    end
    return new_t
end

function tablef.filter(t, f)
    local new_t = {}
    for k, v in pairs(t) do
        if f(v) then
            new_t[k] = v
        end
    end
    return new_t
end

function tablef.reduce(t, f, initial)
    local acc = initial
    for _, v in pairs(t) do
        acc = f(acc, v)
    end
    return acc
end

function tablef.merge(t1, t2)
    local new_t = {}
    for k, v in pairs(t1) do
        new_t[k] = v
    end
    for k, v in pairs(t2) do
        new_t[k] = v
    end
    return new_t
end

function tablef.copy(t)
    return tablef.merge(t, {})
end

function tablef.reverse(t)
    local new_t = {}
    for i = #t, 1, -1 do
        table.insert(new_t, t[i])
    end
    return new_t
end

function tablef.slice(t, start, stop)
    local new_t = {}
    for i = start, stop do
        table.insert(new_t, t[i])
    end
    return new_t
end

function tablef.contains(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

function tablef.unique(t)
    local new_t = {}
    for _, v in pairs(t) do
        if not tablef.contains(new_t, v) then
            table.insert(new_t, v)
        end
    end
    return new_t
end

function tablef.is_empty(t)
    return next(t) == nil
end

return tablef
