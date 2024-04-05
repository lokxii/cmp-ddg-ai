local async = require('plenary.async')
local job = require('plenary.job')

local session = {}

function split(inputstr, sep)
    sep = sep or "%s"

    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function session:get_vqd()
    if self.vqd ~= nil then
        return self.vqd
    end

    local stdout, _ = job
        :new({
            command = "curl",
            args = {
                'https://duckduckgo.com/duckchat/v1/status',
                '-D', '-',
                '-H', 'x-vqd-accept: 1',
                '-H', 'cache-control: no-store',
            },
        })
        :sync()
    for _, line in ipairs(stdout) do
        local entry = split(line, ' ')
        if entry[1] == 'x-vqd-4:' then
            self.vqd = entry[2]
        end
    end
    return self.vqd
end

return session
