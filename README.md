# xiaomusic-rke-patcher

针对 `hanxi/xiaomusic:v0.6.1`（小爱音箱 / aarch64, RK3568 盒子）的运行时补丁，
解决本机实测的两类问题。仓库只含源码级改动，不含任何本机数据（cookie / 登录态 /
tag_cache / 音乐文件一律不在此仓）。

## 补丁内容（相对 v0.6.1 官方镜像内 `/app/xiaomusic/device_player.py`）

| 改动 | 作用 | 定位 |
|---|---|---|
| yt-dlp 下载注入 `--user-agent` | 缓解 B 站搜索/下载对无登录态 + 无 UA 脚本的 HTTP 412 风控 | 见下方说明 |
| 音频格式上限 `-f "ba[abr<=320]/ba"` | 只取 ≤320kbps 分档，避免选中高码 DASH 源后再转码的浪费 | 320 上限档 |
| `enable_yt_dlp_cookies` 支持 | 使 `yt-dlp-cookie.txt` 通过容器 conf 挂载生效 | 需在设置开启 |

> 412 是间歇性风控，不是登录态或机器码问题；UA 与（可选）cookie 只是降低命中概率，
> 不能保证完全免疫。
>
> 配置侧如需 cookie：把 Netscape 格式 cookie 写入容器的 `conf/yt-dlp-cookie.txt`，
> 并开启 `enable_yt_dlp_cookies=True`（设置项名称见上表）。

## 为什么要有这个仓

该容器跑在 fnOS（Docker）。补丁是对容器内一个 python 文件的手工修改；
`docker restart` 不丢，但 **`docker rm` / 重建（recreate）镜像后改动会丢**——
本仓用于改动被冲掉后一键重打。

## 用法

```bash
# 在能执行 docker 的宿主机（fnOS）上，运行容器的名字默认 xiaomusic：
./apply.sh                 # 用默认容器名 xiaomusic
./apply.sh my-container    # 或指定容器名
```

`apply.sh` 会把本仓里的 `device_player.py` 拷回容器内对应路径并 `docker restart`。
幂等：重复执行只重写同一文件后重启。

## 目录

- `device_player.py` — 已打补丁的完整文件（基线 = v0.6.1 镜像内置同名文件）。
- `apply.sh` — 拷贝 + 重启的一键脚本。

## 非源码类的小修（供参考，不入仓）

下载过程中的 `tag_cache` 会短暂缓存「下载中段」时长，可能触发播放器提前切歌，
属运行时数据，重建不解决也不随镜像；遇到可自行修正对应条目后重启即可。
