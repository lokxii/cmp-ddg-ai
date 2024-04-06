local utils = {}

function utils.find_overlap(a, b)
    if a == '' or b == '' then
        return ''
    end

    -- Deal with cases where the strings differ in length
    local start_a = 1
    local end_b = #b
    if #a > #b then
        start_a = #a - #b + 1
    elseif #a < #b then
        end_b = #a
    end

    -- Create a back-reference for each index
    -- that should be followed in case of a mismatch.
    -- We only need B to make these references:
    local backref_map = {}
    for i = 1, end_b do
        backref_map[i] = 0
    end
    local k = 0 -- Index that lags behind j
    backref_map[1] = 0
    for j = 2, end_b do
        if b:sub(j, j) == b:sub(k + 1, k + 1) then
            backref_map[j] = backref_map[k + 1] -- skip over the same character (optional optimisation)
        else
            backref_map[j] = k + 1
        end
        while k > 0 and b:sub(j, j) ~= b:sub(k + 1, k + 1) do
            k = backref_map[k + 1] - 1
        end
        if b:sub(j, j) == b:sub(k + 1, k + 1) then
            k = k + 1
        end
    end

    -- Phase 2: use these references while iterating over A
    k = 0
    for i = start_a, #a do
        while k > 0 and a:sub(i, i) ~= b:sub(k + 1, k + 1) do
            k = backref_map[k + 1] - 1
        end
        if a:sub(i, i) == b:sub(k + 1, k + 1) then
            k = k + 1
        end
    end

    if k == 0 then
        return ''
    end
    return a:sub(-k)
end

function utils.split(inputstr, sep)
    sep = sep or "%s"

    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

return utils
