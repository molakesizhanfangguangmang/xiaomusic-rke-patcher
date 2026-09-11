# xiaomusic-rke-patcher

给 `hanxi/xiaomusic:v0.6.1` 打的运行时补丁。跑它的是台 aarch64 小盒子——OneThingCloud OEC（Rockchip RK3566）上的 fnOS，Docker 里跑官方镜像。

改的只是容器里 `/app/xiaomusic/device_player.py` 这一个文件。仓库里只有源码级的改动，本机数据一律不进来：cookie、登录态、tag_cache、音乐文件都不在。

## 补了什么

yt-dlp 下载时注入 `--user-agent`。B 站对「没登录态、也没有 UA」的脚本请求会回 HTTP 412，加上之后命中少了。

音频格式限定 `-f "ba[abr<=320]/ba"`。只取 320kbps 以下的分档，省掉选中高码率 DASH 源之后还要再转码的那一步。

让 `yt-dlp-cookie.txt` 通过容器 conf 挂载生效，设置里要把 `enable_yt_dlp_cookies` 打开。要用的话，把 Netscape 格式的 cookie 写进容器的 `conf/yt-dlp-cookie.txt`。

412 是间歇性风控，跟登录态、机器码都没关系。UA 和 cookie 只是把命中概率压低，躲不干净。

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

## 顺便记一笔，跟补丁无关

下载过程中 `tag_cache` 会短暂记住「下载中段」的时长，有时会让播放器提前切歌。这是运行时数据，重建镜像不解决也不跟着镜像走；遇到了自己改一下对应条目再重启。
