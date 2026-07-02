# sing-box-yg-ultra 速用文档

VPS 上使用 `sing-box-yg-ultra` 的最短操作说明：安装、更新、生成节点、多人用户、Argo、TUIC 警告处理。

## 1. 安装

```bash
sudo -i
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

菜单选择：

```text
1. 一键安装 Sing-box
```

以后进入管理菜单：

```bash
sb
```

## 2. 更新

更新 `sb`：

```bash
curl -L -o /usr/bin/sb https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh
chmod +x /usr/bin/sb
```

更新 `sbuser`：

```bash
cd /root/sing-box-yg-ultra
git pull
bash install-sbuser.sh
```

首次安装 `sbuser`：

```bash
cd /root
git clone https://github.com/heartreeW/sing-box-yg-ultra.git
cd sing-box-yg-ultra
bash install-sbuser.sh
```

## 3. sb 常用菜单

```bash
sb
```

常用入口：

```text
3   变更配置
4   更改端口
6   重启/关闭 Sing-box
7   更新脚本
8   更新/切换内核
9   刷新并查看节点
10  查看日志
```

刷新节点：

```text
sb -> 9 -> 1
```

意思是：运行 `sb`，输入 `9` 回车，再输入 `1` 回车。

## 4. 查看节点

默认使用自签证书首次安装时，脚本会自动申请 Argo 临时隧道，并在安装结束时输出 Argo 节点。

刷新并显示节点：

```text
sb -> 9 -> 1
```

查看 Mihomo / Sing-box 配置和订阅：

```text
sb -> 9 -> 2
```

常用输出文件：

```text
/etc/s-box/tuic5.txt
/etc/s-box/hy2.txt
/etc/s-box/vl_reality.txt
/etc/s-box/vm_ws.txt
/etc/s-box/vm_ws_tls.txt
/etc/s-box/vm_ws_argols.txt
/etc/s-box/vm_ws_argogd.txt
/etc/s-box/clmi.yaml
/etc/s-box/sbox.json
/etc/s-box/jhsub.txt
```

## 5. 多人用户

添加用户：

```bash
sbuser add alice
```

添加多个：

```bash
sbuser add alice bob charlie
```

查看用户：

```bash
sbuser list
```

查看用户链接：

```bash
sbuser links alice
```

删除用户：

```bash
sbuser remove alice
```

用户链接：

```text
/etc/s-box/users/alice.txt
```

如果已配置 Argo 且 vmess-ws 关闭 TLS，`sbuser add alice` 会自动生成：

```text
/etc/s-box/vm_argo_user_alice.txt
```

## 6. Argo

默认自签证书安装会自动生成 Argo 临时节点。

Argo 需要 vmess-ws 关闭 TLS；如果你安装时选择了 Acme 域名证书并开启 TLS，需要先关闭 TLS。

关闭/切换 TLS：

```text
sb -> 3 -> 1
```

设置 Argo 临时或固定隧道：

```text
sb -> 3 -> 3
```

单独新增 vm-argo 用户：

```text
sb -> 3 -> 10
```

推荐：优先用 `sbuser add alice`。如果 Argo 条件满足，会同时生成普通多协议节点和 vm-argo 链接。

## 7. TUIC 警告

如果电脑客户端提示 Xray 将禁用 `allowInsecure`，说明你导入了旧 TUIC 链接。

旧链接问题字段：

```text
insecure=1
allowInsecure=1
allow_insecure=1
```

处理方法：

```bash
curl -L -o /usr/bin/sb https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh
chmod +x /usr/bin/sb
sb
```

然后：

```text
9 -> 1
```

新 TUIC 链接应包含：

```text
pinnedPeerCertSha256=...
```

并且不应再包含：

```text
allowInsecure=1
```

导入新链接前，先删除客户端里的旧 TUIC 节点。

## 8. 订阅和推送

本地 IP 订阅：

```text
sb -> 3 -> 8
sb -> 9 -> 2
```

Telegram 推送：

```text
sb -> 3 -> 5
sb -> 9 -> 3
```

## 9. 排错

状态：

```bash
systemctl status sing-box
```

重启：

```bash
systemctl restart sing-box
```

检查配置：

```bash
/etc/s-box/sing-box check -c /etc/s-box/sb.json
```

日志：

```bash
journalctl -u sing-box -e --no-pager
```

`sb` 不存在时修复：

```bash
curl -L -o /usr/bin/sb https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh
chmod +x /usr/bin/sb
sb
```

## 10. 重要文件

```text
/etc/s-box/sb.json              主配置
/etc/s-box/users/               sbuser 用户链接
/etc/s-box/multi-users.tsv      sbuser 用户记录
/etc/s-box/vm_argo_user_*.txt   vm-argo 用户链接
/etc/s-box/tuic5.txt            TUIC 链接
/etc/s-box/clmi.yaml            Mihomo 配置
/etc/s-box/sbox.json            Sing-box 客户端配置
/etc/s-box/jhsub.txt            聚合订阅
```

建议权限：

```bash
chmod 600 /etc/s-box/sb.json
chmod 600 /etc/s-box/multi-users.tsv 2>/dev/null || true
chmod 700 /etc/s-box/users 2>/dev/null || true
chmod 600 /etc/s-box/vm_argo_user_*.txt 2>/dev/null || true
```

## 11. 卸载

```bash
sb
```

选择：

```text
2. 删除卸载 Sing-box
```

删除 `sbuser`：

```bash
rm -f /usr/local/bin/sbuser
```
