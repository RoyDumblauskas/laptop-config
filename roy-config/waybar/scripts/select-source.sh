sink=$(
  pw-dump |
    jq -r '
      .[]
      | select(.type == "PipeWire:Interface:Node")
      | select(.info.props["media.class"] == "Audio/Source")
      | "\(.id)\t\(.info.props["node.description"] // .info.props["node.name"])"
    ' |
    wofi --dmenu |
    cut -f1
)

[ -n "$sink" ] && wpctl set-default "$sink"
