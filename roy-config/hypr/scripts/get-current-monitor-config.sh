#!/bin/sh

dir=$1
config=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.name),transform,'$dir'"')

echo $config

hyprctl keyword monitor $config
