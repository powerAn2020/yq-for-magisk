#!/bin/sh

zip -r -o -X -ll JQ-FOR-MAGISK-$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'build.sh' -x '.github/*'