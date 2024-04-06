local async = require('plenary.async')
local job = require('plenary.job')
local utils = require('cmp_ddg_ai.utils')

local session = {}

session.user_agent_num = 1

function session:get_vqd(tries)
    tries = tries or 0
    if tries >= 3 then -- Probably have some very serious problem. Give up
        return self.vqd
    end

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
                '-H', 'user-agent: ' .. self:get_user_agent()
            },
        })
        :sync()
    for _, line in ipairs(stdout) do
        local entry = utils.split(line, ' ')
        if entry[1] == 'x-vqd-4:' then
            self.vqd = entry[2]
        end
    end

    if self.vqd ~= nil then
        return self.vqd
    end

    self.user_agent_num = self.user_agent_num + 1 -- Rate limit over. Try another user agent
    return self:get_vqd(tries + 1)
end

function session:get_user_agent()
    return 'curl/' .. self.user_agent_num
end

return session
