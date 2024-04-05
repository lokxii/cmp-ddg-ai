# cmp-ddg-ai

duckduckgo chat (claude-instant-1.2) made available as nvim-cmp

nvim-cmp source name: `cmp_ddg_ai`

It is recommended to use a dedicated key to trigger the completion to prevent
reaching api usage limit

```lua
cmp.setup({
  ...
  mapping = {
    ...
    ['<C-x>'] = cmp.mapping(
      cmp.mapping.complete({
        config = {
          sources = cmp.config.sources({
            { name = 'cmp_ddg_ai' },
          }),
        },
      }),
      { 'i' }
    ),
  },
})
```

## To-do list

[ ] config: ignore file types
[ ] option to choose gpt-3.5-turbo
[ ] proper indentation
[ ] proper logging
[ ] proper error reporting
