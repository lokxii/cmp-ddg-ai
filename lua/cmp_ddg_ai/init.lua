local cmp = require('cmp')
local source = require('cmp_ddg_ai.source')
local session = require('cmp_ddg_ai.session')

local M = {}

M.setup = function()
    M.ai_source = source:new()
    cmp.register_source('cmp_ddg_ai', M.ai_source)
end

-- session:get_vqd()

return M
