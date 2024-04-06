local api = vim.api
local cmp = require('cmp')
local job = require('plenary.job')
local session = require('cmp_ddg_ai.session')
local utils = require('cmp_ddg_ai.utils')

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

local function esc(str)
    return str:gsub("([^%w])", "%%%1")
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
        local prefix = ctx.context.cursor_before_line:sub(ctx.offset)
        local lines = utils.split(answer, '\n')
        local trimmed = lines[1]:gsub('^\\s+', '')
        local overlap = utils.find_overlap(ctx.context.cursor_before_line, trimmed)

        lines[1] = trimmed:gsub(esc(overlap), '', 1)
        local edit = table.concat(lines, '\n')

        local item = {
            label = prefix .. edit,
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
        'You are a coding companion.',
        ' You need to suggest code completions for the language ',
        filetype,
        '. Given some code prefix and suffix for context, output code which should follow the prefix code.',
        ' You should only output valid code in ',
        filetype,
        '. To clearly define a code block, including white space, we will wrap the code block with tags.',
        ' Make sure to respect the white space and indentation rules of the language.',
        ' OUTPUT ONLY CODE AND DO NOT WRAP YOUR ANSWER IN MARKDOWN, make sure you only use the relevant programming language verbatim.',
        ' Follow the instructions appearing next.',
        ' Now for the users request: ',
        ' For example, consider the following request:',
        ' <begin_code_prefix>def print_hello():<end_code_prefix><begin_code_suffix>\n    return<end_code_suffix><begin_code_middle>',
        ' Your answer should be:',
        [=[    print('Hello')<end_code_middle>]=],
        '<begin_code_prefix>',
        before,
        '<end_code_prefix> <begin_code_suffix>',
        after,
        '<end_code_suffix><begin_code_middle>',
    }, '\n')

    local body = vim.json.encode({
        model = 'gpt-3.5-turbo-0125', -- gpt-3.5 sucks at following instructions
        -- model = "claude-instant-1.2",
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
                '-H', 'user-agent: ' .. session:get_user_agent(),
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
                local s = table.concat(tokens, ''):gsub('<end_code_middle>', '')
                if s:find('```') then
                    s = s:match('```[^\n]*\n(.*)```')
                end
                callback(s)
            end
        })
        :start()
end

return source
