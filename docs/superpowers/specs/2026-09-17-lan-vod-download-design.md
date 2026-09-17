# 局域网成片下载

日期：2026-09-17

## 问题

局域网首页可以列出并播放已录成片，但浏览器无法把 MP4 存到本机。现场 MJPEG 不在范围内。

## 决策

- 列表点成片名字：仍在共用播放器里播 `/vod/<id>`（Range 不变）。
- 每条旁边单独「下载」：请求 `GET /vod/<id>?download=1`。
- 带 `download=1` 时返回整文件 `200`，`Content-Type: video/mp4`，`Content-Disposition: attachment`，文件名用库里的显示名。
- 不新增 `/download/` 路由；不把 attachment 加到普通播放请求上，避免 `<video>` 被浏览器改成下载。
- `download=1` 忽略 `Range`，避免分段保存出残片。
- 现场预览、推流、无密码局域网策略都不改。

## 文件名

显示名去掉 `/` `\` 和 `\0`，去掉首尾空白与点。若结果为空或没有 `.mp4` 后缀，则补上 `.mp4`。HTTP 头同时给 ASCII 回退名 `recording.mp4` 和 RFC 5987 的 `filename*`（UTF-8），以便中文标题在桌面浏览器里可用。

## 页面

现有列表行改成：名字可点播放；右侧保留大小；再加「下载」链接（`download` 属性 + `?download=1`）。点下载不得触发播放、不得关掉当前正在播的成片。五语增加 `lan_download`。

## 不改

- `/live.mjpeg` 与实时预览开关
- `/api/recordings` 字段
- 播放路径的 Range / 206
- 鉴权、HTTPS、zip 打包多条

## 验收

- 点名字仍播放；点下载得到完整 MP4，文件名接近成片标题。
- 不带 `download=1` 的 `/vod/<id>` 行为与现在一致。
- 已删除的成片下载返回 404。
- 插件单测覆盖：识别 `download=1`、Content-Disposition 编码、非法标题回落到 `recording.mp4`。
