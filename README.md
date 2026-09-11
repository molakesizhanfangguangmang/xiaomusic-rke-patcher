# xiaomusic-rke-patcher

给 `hanxi/xiaomusic:v0.6.1` 打的运行时补丁，连带把几处用法记在这儿。跑它的是台 aarch64 小盒子——OneThingCloud OEC（Rockchip RK3566）上的 fnOS，Docker 里跑官方镜像。

改的只是容器里 `/app/xiaomusic/device_player.py` 这一个文件。仓库里只有源码级的改动，本机数据一律不进来：cookie、登录态、tag_cache、音乐文件都不在。

## 补了什么

三处，都在 yt-dlp 那一行附近。

**给请求补上完整的头。** 默认那条 yt-dlp 命令不带 `--user-agent`，请求头是不全的，B 站见到这种脚本请求就回 HTTP 412。显式给一个浏览器 UA，命中就少了。

**限定音频格式** `-f "ba[abr<=320]/ba"`。只取 320kbps 以下的分档，省掉选中高码率 DASH 源之后还要再转码的那一步。

**让 cookie 生效。** `yt-dlp-cookie.txt` 走容器 conf 挂载，设置里把 `enable_yt_dlp_cookies` 打开。要用的话，把 Netscape 格式的 cookie 写进容器的 `conf/yt-dlp-cookie.txt`。这不是必须的一步，412 跟登录态基本无关，补头才是主要那一下。

## 412 是怎么回事

间歇性的，跟登录态、机器码都没关系。同一台机器、同一条命令，前一分钟能过，后一分钟就 412；连着发几次请求会把它诱发出来，停一会儿又自己好。所以拿它反复试只会越试越糟。

UA 和 cookie 只是把命中概率压低，躲不干净。

## 为什么把它放仓库里

补丁是对容器内一个 python 文件的手工修改。`docker restart` 不丢，但 `docker rm` 或者镜像重建之后就没了。放仓库里，是为了被冲掉之后能一键重打。

## 用法

在能执行 docker 的宿主机（fnOS）上跑，容器名默认 `xiaomusic`：

```bash
./apply.sh                 # 默认容器名
./apply.sh my-container    # 或者指定
```

它把仓库里的 `device_player.py` 拷回容器里对应路径，再 `docker restart`。重复执行只重写同一个文件再重启，跑几次都一样。

## 目录

`device_player.py` 是打完补丁的完整文件，基线是 v0.6.1 镜像里那个同名文件。

`apply.sh` 是拷贝加重启的脚本。

## 许可

`device_player.py` 改自 [hanxi/xiaomusic](https://github.com/hanxi/xiaomusic) v0.6.1，原项目是 MIT（Copyright (c) 2023 涵曦）。这里沿用同一个许可，全文见 `LICENSE`。

## 顺便记一笔，跟补丁无关

下载过程中 `tag_cache` 会短暂记住「下载中段」的时长，有时会让播放器提前切歌。这是运行时数据，重建镜像不解决也不跟着镜像走；遇到了自己改一下对应条目再重启。
