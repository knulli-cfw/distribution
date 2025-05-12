#!/bin/bash

name='Master'

value=$(amixer sget "$name" | sed -n "s/  Front Left: \([0-9]*\) .*/\1/p")

if [[ "$1" == "up" ]]; then
        let value=value+10
        if [[ $value -gt 255 ]]; then value=255; fi
else
        let value=value-10
        if [[ $value -lt 0 ]]; then value=0; fi
fi

amixer sset "$name" $value

