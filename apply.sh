#!/usr/bin/env bash
# 重打补丁 —— 一键把补丁版 device_player.py 拷回容器并重启
# 必在能执行 docker 的宿主机（fnOS）上运行，容器默认名 xiaomusic。
set -euo pipefail

CT="${1:-xiaomusic}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/device_player.py"

if ! docker ps --format '{{.Names}}' | grep -qx "$CT"; then
  echo "找不到运行中的容器: $CT" >&2
  exit 1
fi

docker cp "$SRC" "$CT:/app/xiaomusic/device_player.py"
docker restart "$CT"
echo "已重打补丁并重启容器 $CT"
