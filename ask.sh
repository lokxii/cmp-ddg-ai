#!/bin/sh

curl 'https://duckduckgo.com/duckchat/v1/chat' \
    -X 'POST' \
    -H 'Content-Type: application/json' \
    -H 'Accept: text/event-stream' \
    -H "x-vqd-4: $1" \
    --data-binary '{"model":"claude-instant-1.2","messages":[{"role":"user","content":"what am I doing"}]}' 2>/dev/null |
grep -v '^$'
