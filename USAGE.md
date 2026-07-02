# sing-box-yg-ultra 使用文档

本文档适用于在 VPS 上使用 `sing-box-yg-ultra` 搭建 sing-box 多协议节点，并按需生成多人独立账号、Argo 节点、本地订阅和推送信息。

## 项目定位

`sing-box-yg-ultra` 是基于 `sing-box-yg` 精简后的 VPS 使用版本，保留 VPS 一键安装和常用管理能力，并额外提供多人账号管理脚本。

适合：

- 一台 VPS 搭建 sing-box 多协议节点。
- 使用 `sb` 菜单管理节点、端口、证书、Argo、订阅和推送。
- 给多人生成独立 UUID/密码。
- 给 Argo 节点新增独立 UUID 用户，共用同一条 Argo 隧道。
- 单独删除某个 `sbuser` 用户，不影响其他人。

不适合：

- 需要单用户流量统计。
- 需要单用户限速。
- 需要到期时间、设备数量限制。
- 需要完整网页面板。

如果需要这些面板功能，建议使用 3x-ui、s-ui、Marzban 等项目。

## 准备条件

推荐系统：

- Ubuntu 22.04 / 24.04
- Debian 11 / 12
- Alpine Linux

建议使用 `root` 用户操作：

```bash
sudo -i
```

确认当前用户：

```bash
whoami
```

显示 `root` 即可。

## 一、安装 Sing-box

在 VPS 上执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

进入菜单后选择：

```text
1. 一键安装 Sing-box
```

安装过程中按提示选择端口、证书和协议参数。新手通常可以直接回车使用默认值。

安装完成后，脚本会创建快捷命令：

```bash
sb
```

以后管理节点直接执行：

```bash
sb
```

## 二、确认安装状态

检查配置文件：

```bash
ls -l /etc/s-box/sb.json
```

检查快捷命令：

```bash
which sb
ls -l /usr/bin/sb
```

检查 sing-box 服务：

```bash
systemctl status sing-box
```

Alpine 系统使用：

```bash
rc-service sing-box status
```

如果 `sb` 提示 `command not found`，但 `/etc/s-box/sb.json` 已存在，可以手动修复快捷命令：

```bash
curl -L -o /usr/bin/sb https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh
chmod +x /usr/bin/sb
sb
```

## 三、sb 主菜单说明

执行 `sb` 后会进入主菜单，常用选项如下：

```text
1. 一键安装 Sing-box
2. 删除卸载 Sing-box
3. 变更配置
4. 更改主端口/添加多端口跳跃复用
5. 三通道域名分流
6. 关闭/重启 Sing-box
7. 更新 Sing-box-yg 脚本
8. 更新/切换/指定 Sing-box 内核版本
9. 刷新并查看节点/订阅链接/推送 TG 通知
10. 查看 Sing-box 运行日志
11. 一键原版 BBR+FQ 加速
12. 管理 Acme 申请域名证书
13. 管理 Warp 查看 Netflix/ChatGPT 解锁情况
14. 添加 WARP-plus-Socks5 代理模式
15. 更换 IP 刷新本地 IP、调整 IPV4/IPV6 配置输出
16. Sing-box-yg 脚本使用说明书
0. 退出脚本
```

日常最常用的是：

- `3`：变更配置。
- `4`：修改协议端口。
- `6`：重启或关闭 sing-box。
- `7`：更新脚本。
- `8`：更新或切换 sing-box 内核。
- `9`：刷新并查看节点链接、订阅配置、Telegram 推送。
- `10`：查看运行日志排错。

## 四、配置变更菜单说明

主菜单选择 `3` 后进入配置变更菜单：

```text
1. 更换 Reality 域名伪装地址、切换自签证书与 Acme 域名证书、开关 TLS
2. 更换全协议 UUID(密码)、Vmess-Path 路径
3. 设置 Argo 临时隧道、固定隧道
4. 切换 IPV4 或 IPV6 的代理优先级
5. 设置 Telegram 推送节点通知
6. 更换 Warp-wireguard 出站账户
7. 设置 Gitlab 订阅分享链接
8. 设置本地 IP 订阅分享链接
9. 设置所有 Vmess 节点的 CDN 优选地址
10. 新增 vm-argo 用户，独立 UUID，共用同一条隧道
0. 返回上层
```

其中新增的 `10` 是本版本重点功能：可以在已经配置好的 Argo 隧道上，为新用户生成独立的 vmess UUID 和独立分享链接。

## 五、刷新并查看节点

安装完成后，建议先执行：

```bash
sb
```

选择：

```text
9. 刷新并查看节点
```

子菜单说明：

```text
1. 刷新并查看节点信息
2. 刷新并查看 Mihomo、Sing-box 客户端配置、Gitlab 私有订阅链接
3. 推送最新节点配置信息到 Telegram
0. 返回上层
```

常见客户端对应：

- v2rayN、v2rayNG、NekoBox、Shadowrocket：使用脚本输出的分享链接。
- Mihomo / Clash Meta：使用 `/etc/s-box/clmi.yaml`。
- SFA / SFI / SFW：使用 `/etc/s-box/sbox.json`。
- 聚合链接：使用 `/etc/s-box/jhsub.txt`。

## 六、配置 Argo 隧道

Argo 功能依赖 `vmess-ws` 关闭 TLS。进入：

```text
sb -> 3 -> 3
```

可选择：

```text
1. 添加或者删除 Argo 临时隧道
2. 添加或者删除 Argo 固定隧道
0. 返回上层
```

注意：

- 如果 vmess-ws 当前开启 TLS，脚本会提示 Argo 不可用。
- 如需使用 Argo，可先进入 `sb -> 3 -> 1`，关闭 vmess-ws TLS。
- 临时隧道域名来自 Cloudflare TryCloudflare，可能变化。
- 固定隧道需要提前准备 Cloudflare Tunnel Token 和固定域名。

Argo 相关文件：

```text
/etc/s-box/argo.log
/etc/s-box/sbargoym.log
/etc/s-box/sbargotoken.log
/etc/s-box/vm_ws_argols.txt
/etc/s-box/vm_ws_argogd.txt
```

## 七、新增 vm-argo 独立用户

这是新版 `sb.sh` 新增功能。

用途：

- 给 vmess-ws + Argo 节点新增一个独立 UUID。
- 新用户与原 Argo 节点共用同一条临时或固定 Argo 隧道。
- 适合给手机、家人、朋友或不同设备单独生成一个 Argo 链接。

前置条件：

- 已安装 Sing-box。
- `/etc/s-box/sb.json` 存在。
- vmess-ws 已关闭 TLS。
- 已经通过 `sb -> 3 -> 3` 配置过 Argo 临时隧道或固定隧道。

操作路径：

```text
sb -> 3 -> 10
```

脚本会提示：

```text
输入新用户UUID（留空自动生成新的）：
输入新用户备注名（如 phone2，留空默认user）：
```

建议：

- UUID 留空，让脚本自动生成。
- 备注名使用英文、数字或简单短横线，例如 `phone2`、`alice`、`ipad`。

执行后脚本会：

- 把新 UUID 写入 `/etc/s-box/sb.json` 的 vmess-ws 用户列表。
- 自动重启 Sing-box 生效。
- 读取当前 Argo 临时域名或固定域名。
- 生成新的 `vmess://` 分享链接。
- 显示二维码。
- 保存链接到：

```text
/etc/s-box/vm_argo_user_<备注名>.txt
```

例如备注名是 `phone2`，文件为：

```text
/etc/s-box/vm_argo_user_phone2.txt
```

查看链接：

```bash
cat /etc/s-box/vm_argo_user_phone2.txt
```

如果脚本提示未检测到 Argo 隧道，请先执行：

```text
sb -> 3 -> 3
```

如果脚本提示 vmess-ws 已开启 TLS，请先执行：

```text
sb -> 3 -> 1
```

关闭 TLS 后再新增 vm-argo 用户。

## 八、安装多人管理命令 sbuser

`sbuser` 是本仓库提供的独立多人管理命令，适合给每个人生成完整多协议独立 UUID/密码。

如果当前已经配置好 Argo 隧道，并且 vmess-ws 处于关闭 TLS 状态，`sbuser add` 和 `sbuser links` 会自动额外生成该用户的 `vm-argo` 链接。

先克隆仓库：

```bash
cd /root
git clone https://github.com/heartreeW/sing-box-yg-ultra.git
cd sing-box-yg-ultra
```

安装 `sbuser`：

```bash
bash install-sbuser.sh
```

检查：

```bash
which sbuser
```

正常显示：

```text
/usr/local/bin/sbuser
```

## 九、使用 sbuser 创建多人用户

创建一个用户：

```bash
sbuser add alice
```

一次创建多个用户：

```bash
sbuser add alice bob charlie
```

脚本会自动：

- 给每个人生成独立 UUID/密码。
- 写入 sing-box 服务端配置。
- 同步更新存在的 `/etc/s-box/sb10.json`、`/etc/s-box/sb11.json`。
- 备份旧配置。
- 检查配置是否正确。
- 尝试重启 sing-box。
- 输出每个人的节点链接。
- 如果 Argo 可用，额外输出 `vm-argo` 链接。

查看已有用户：

```bash
sbuser list
```

查看某个用户的节点链接：

```bash
sbuser links alice
```

用户链接保存到：

```text
/etc/s-box/users/alice.txt
```

如果 Argo 可用，Alice 的 vm-argo 独立链接也会单独保存到：

```text
/etc/s-box/vm_argo_user_alice.txt
```

删除用户：

```bash
sbuser remove alice
```

也可以用 UUID 删除：

```bash
sbuser remove xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

删除后，该用户的 UUID/密码会从配置中移除，旧链接失效，其他用户不受影响。

检查配置：

```bash
sbuser check
```

## 十、两种多人方式怎么选

`sbuser add`：

- 适合给用户完整多协议节点。
- 会把同一个 UUID/密码加入 vless、vmess、hy2、tuic、anytls 等协议配置。
- 如果 Argo 已配置且 vmess-ws TLS 已关闭，会自动生成 vm-argo 链接。
- 支持 `list`、`links`、`remove`、`check`。
- 用户信息记录在 `/etc/s-box/multi-users.tsv`。

`sb -> 3 -> 10`：

- 只新增 vmess-ws + Argo 用户，不生成完整多协议用户。
- 每个用户有独立 UUID 和独立 Argo 分享链接。
- 共用同一条 Argo 临时或固定隧道。
- 链接保存到 `/etc/s-box/vm_argo_user_<备注名>.txt`。
- 更适合已经有用户 UUID，或只想临时补一个 Argo 节点的场景。

现在推荐优先使用 `sbuser add alice`。它会生成完整多协议节点；当 Argo 条件满足时，也会同时给 Alice 生成可直接使用的 `vm-argo` 链接。

## 十一、订阅链接

### Gitlab 私有订阅

进入：

```text
sb -> 3 -> 7
```

按提示填写：

- Gitlab 登录邮箱。
- Gitlab 访问令牌。
- Gitlab 用户名。
- 项目名。
- 分支名。

设置完成后，执行：

```text
sb -> 9 -> 2
```

可以刷新并查看 Gitlab 私有订阅链接。

### 本地 IP 订阅

进入：

```text
sb -> 3 -> 8
```

可选择：

```text
1. 重置安装本地 IP 订阅链接
2. 更换订阅链接路径密码
3. 更换订阅链接端口
4. 卸载本地 IP 订阅链接
0. 返回上层
```

启用后，主菜单会显示类似：

```text
Clash/Mihomo本地IP订阅地址：http://IP:端口/路径/clmi.yaml
Sing-box本地IP订阅地址：http://IP:端口/路径/sbox.json
聚合协议本地IP订阅地址：http://IP:端口/路径/jhsub.txt
```

注意开放对应端口。

## 十二、CDN 优选地址

进入：

```text
sb -> 3 -> 9
```

可选择：

```text
1. 自定义 Vmess-ws(tls) 主协议节点的 CDN 优选地址
2. 重置客户端 host/sni 域名
3. 自定义 Vmess-ws(tls)-Argo 节点的 CDN 优选地址
0. 返回上层
```

Argo 节点默认优选地址为：

```text
cloudflare-ech.com
```

自定义 Argo 优选地址后会写入：

```text
/etc/s-box/cfvmadd_argo.txt
```

设置完成后建议执行：

```text
sb -> 9
```

刷新节点信息。

## 十三、Telegram 推送

进入：

```text
sb -> 3 -> 5
```

填写：

- Telegram Bot Token。
- Telegram 用户 ID。

之后可以执行：

```text
sb -> 9 -> 3
```

把最新节点、订阅和配置推送到 Telegram。

## 十四、常用文件位置

主配置：

```text
/etc/s-box/sb.json
```

可选配置：

```text
/etc/s-box/sb10.json
/etc/s-box/sb11.json
```

多人用户登记表：

```text
/etc/s-box/multi-users.tsv
```

`sbuser` 用户链接：

```text
/etc/s-box/users/<用户名>.txt
```

vm-argo 独立用户链接：

```text
/etc/s-box/vm_argo_user_<备注名>.txt
```

配置备份目录：

```text
/etc/s-box/backups/
```

客户端配置：

```text
/etc/s-box/clmi.yaml
/etc/s-box/sbox.json
/etc/s-box/jhsub.txt
```

本地订阅配置：

```text
/etc/s-box/subtoken.log
/etc/s-box/subport.log
```

Argo 配置：

```text
/etc/s-box/argo.log
/etc/s-box/sbargoym.log
/etc/s-box/sbargotoken.log
/etc/s-box/cfvmadd_argo.txt
```

## 十五、建议权限设置

这些文件包含 UUID、密码、订阅路径或节点信息，不要公开。

建议执行：

```bash
chmod 600 /etc/s-box/sb.json
chmod 600 /etc/s-box/multi-users.tsv
chmod 700 /etc/s-box/users
```

如果生成了 vm-argo 用户链接，也可以限制权限：

```bash
chmod 600 /etc/s-box/vm_argo_user_*.txt
```

## 十六、更新脚本

如果已经安装 `sb` 快捷命令，可直接进入：

```text
sb -> 7
```

也可以手动更新：

```bash
curl -L -o /usr/bin/sb https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh
chmod +x /usr/bin/sb
```

如果本地克隆了仓库：

```bash
cd /root/sing-box-yg-ultra
git pull
bash install-sbuser.sh
```

## 十七、卸载

进入：

```bash
sb
```

选择：

```text
2. 删除卸载 Sing-box
```

如需删除 `sbuser` 命令：

```bash
rm -f /usr/local/bin/sbuser
```

如需完全清理配置，请谨慎执行：

```bash
rm -rf /etc/s-box
```

这会删除所有节点配置、用户信息、订阅信息和备份。

## 十八、推荐完整流程

从零开始推荐按以下顺序：

```bash
sudo -i
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

菜单选择：

```text
1. 一键安装 Sing-box
```

安装完成后刷新节点：

```text
sb -> 9 -> 1
```

如需完整多人账号：

```bash
cd /root
git clone https://github.com/heartreeW/sing-box-yg-ultra.git
cd sing-box-yg-ultra
bash install-sbuser.sh
sbuser add alice bob
sbuser links alice
```

如需 Argo 节点：

```text
sb -> 3 -> 1  关闭 vmess-ws TLS
sb -> 3 -> 3  设置 Argo 临时或固定隧道
sb -> 9 -> 1  刷新查看 Argo 节点
```

如需给 Argo 新增独立用户：

```text
sb -> 3 -> 10
```

如果已经提前配置好 Argo，执行 `sbuser add alice` 时会自动生成 Alice 的 vm-argo 链接；`sb -> 3 -> 10` 主要用于只想单独补一个 Argo 用户的情况。

## 十九、常见问题

### 1. sb 命令不存在

重新下载快捷脚本：

```bash
curl -L -o /usr/bin/sb https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh
chmod +x /usr/bin/sb
sb
```

### 2. sbuser 提示 command not found

重新安装：

```bash
cd /root/sing-box-yg-ultra
bash install-sbuser.sh
```

### 3. 添加用户时提示缺少 jq

Debian / Ubuntu：

```bash
apt update && apt install -y jq
```

Alpine：

```bash
apk add jq
```

CentOS / Rocky / AlmaLinux：

```bash
yum install -y jq
```

### 4. Argo 菜单提示 vmess-ws TLS 已开启

Argo 需要 vmess-ws 关闭 TLS。进入：

```text
sb -> 3 -> 1
```

按提示关闭 TLS 后，再进入：

```text
sb -> 3 -> 3
```

设置 Argo 隧道。

### 5. 新增 vm-argo 用户提示没有 Argo 隧道

先进入：

```text
sb -> 3 -> 3
```

添加 Argo 临时隧道或固定隧道，然后再执行：

```text
sb -> 3 -> 10
```

### 6. 新增 vm-argo 用户后无法连接

依次检查：

```bash
/etc/s-box/sing-box check -c /etc/s-box/sb.json
systemctl restart sing-box
systemctl status sing-box
```

然后执行：

```text
sb -> 9 -> 1
```

确认 Argo 域名存在，且客户端使用的是最新生成的链接。

### 7. sbuser 删除用户后对方还能用

确认用户已删除：

```bash
sbuser list
```

重启服务：

```bash
systemctl restart sing-box
```

如果对方客户端仍然显示连接，可能是旧连接尚未断开或客户端缓存。断开重连后应失效。

### 8. 原脚本重装后用户不见了

如果使用 `sb` 重装或重置配置，手动添加的多人用户可能被覆盖。建议提前备份：

```bash
cp -a /etc/s-box/multi-users.tsv /root/multi-users.tsv.bak
cp -a /etc/s-box/users /root/sbox-users-bak
cp -a /etc/s-box/vm_argo_user_*.txt /root/ 2>/dev/null || true
```

### 9. 本地订阅无法访问

检查：

- VPS 防火墙是否开放订阅端口。
- 云厂商安全组是否开放订阅端口。
- `/etc/s-box/subport.log` 中的端口是否正确。
- `busybox httpd` 是否仍在运行。

查看端口：

```bash
cat /etc/s-box/subport.log
```

### 10. 查看运行日志

进入：

```text
sb -> 10
```

也可以手动查看：

```bash
journalctl -u sing-box -e --no-pager
```

Alpine：

```bash
rc-service sing-box status
```

### 11. 电脑端使用 TUIC 提示 allowInsecure 警告

如果客户端提示：

```text
Xray 将在 2026.8.1 禁用跳过证书验证 allowInsecure
```

说明旧 TUIC 链接使用了跳过证书校验。新版脚本会在自签证书场景下自动给 TUIC 分享链接加入 `pinnedPeerCertSha256` 证书固定指纹，并且不再写入 `allowInsecure`。

更新脚本后重新刷新节点：

```text
sb -> 9 -> 1
```

然后把新的 `Tuic-v5` 链接重新导入电脑客户端即可。
