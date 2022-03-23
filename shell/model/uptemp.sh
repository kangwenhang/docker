#!/usr/bin/env bash

if [ -e "/push/shell/push.sh" ]; then
    rm -rf /push/shell/push.sh
fi
if [ -e "/push/shell/submit.sh" ]; then
    rm -rf /push/shell/submit.sh
fi
