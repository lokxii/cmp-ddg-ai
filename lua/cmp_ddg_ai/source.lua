local api = vim.api
local cmp = require('cmp')
local session = require('cmp_ddg_ai.session')
local job = require('plenary.job')

local source = {}
function source:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function source:get_debug_name()
    return 'AI'
end

function source:complete(ctx, callback)
    local max_lines = 1000
    local cursor = ctx.context.cursor
    local cur_line = ctx.context.cursor_line

    local cur_line_before = vim.fn.strpart(cur_line, 0, math.max(cursor.col - 1, 0), true)
    local cur_line_after = vim.fn.strpart(cur_line, math.max(cursor.col - 1, 0), vim.fn.strdisplaywidth(cur_line), true) -- include current character

    local lines_before = api.nvim_buf_get_lines(0, math.max(0, cursor.line - max_lines), cursor.line, false)
    table.insert(lines_before, cur_line_before)
    local before = table.concat(lines_before, '\n')

    local lines_after = api.nvim_buf_get_lines(0, cursor.line + 1, cursor.line + max_lines, false)
    table.insert(lines_after, 1, cur_line_after)
    local after = table.concat(lines_after, '\n')

    local short_name = vim.filetype.match({ buf = 0 }) or ''
    source:_fetch_response(before, after, vim.o.filetype, function(answer)
        local item = {
            label = answer,
            textEdit = {
                newText = answer,
                range = {
                    start = {
                        line = ctx.context.cursor.row - 1,
                        character = 0,
                    },
                    ['end'] = {
                        line = ctx.context.cursor.row - 1,
                        character = ctx.context.cursor.col - 1,
                    }
                }
            },
            documentation = {
                kind = cmp.lsp.MarkupKind.Markdown,
                value = '```' .. short_name .. '\n' .. answer .. '\n```',
            }
        }
        callback({
            items = { item },
            isIncomplete = true,
        })
    end)
end

local function filter_inplace(arr, func)
    local new_index = 1
    local size_orig = #arr
    for old_index, v in ipairs(arr) do
        if func(v, old_index) then
            arr[new_index] = v
            new_index = new_index + 1
        end
    end
    for i = new_index, size_orig do arr[i] = nil end
end

function source:_fetch_response(before, after, filetype, callback)
    if session:get_vqd() == nil then
        return
    end

    local message = table.concat({
        'Given the following ' .. filetype .. ' code, complete the code at <COMPLETE_CODE_HERE> for me.',
        'DO NOT USE MARKDOWN. Write only valid code.',
        'Make sure to follow indentation style.',
        before .. '<COMPLETE_CODE_HERE>' .. after,
    }, '\n')

    local body = vim.json.encode({
        -- model = 'gpt-3.5-turbo-0125', -- gpt-3.5 sucks at following instructions
        model = "claude-instant-1.2",
        messages = {
            {
                role = 'user',
                content = message,
            }
        }
    })

    job
        :new({
            command = "curl",
            args = {
                'https://duckduckgo.com/duckchat/v1/chat',
                '-X', 'POST',
                '-H', 'Content-Type: application/json',
                '-H', 'Accept: text/event-stream',
                '-H', 'x-vqd-4: ' .. session:get_vqd(),
                '--data-binary', body,
            },
            on_exit = function(out, _)
                local lines = out:result()
                filter_inplace(lines, function(line)
                    return #line > 0 and line ~= 'data: [DONE]'
                end)
                local tokens = {}
                for _, line in ipairs(lines) do
                    local object = line:match('data: (.+)')
                    if object ~= nil then
                        table.insert(tokens, vim.json.decode(object).message)
                    end
                end
                local s = table.concat(tokens, ''):gsub('<end_code_middle>', ''):sub(2)
                callback(s)
            end
        })
        :start()
end

return source
