#!/bin/sh

curl 'https://duckduckgo.com/duckchat/v1/status' \
    -D - \
    -H 'x-vqd-accept: 1' \
    -H 'cache-control: no-store' \
    2>/dev/null |
grep x-vqd-4 |
awk '{ print $2 }'
