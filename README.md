# sing-box-yg-ultra

一个精简 VPS 版 sing-box-yg 分支：保留 VPS 一键安装，并额外加入多人用户管理命令。

## 保留内容

- `sb.sh`: VPS 一键安装 sing-box 多协议节点。
- `sb-multi-user.sh`: 多人账号管理脚本。
- `install-sbuser.sh`: 将多人脚本安装为 `sbuser` 命令。

完整操作文档见：[USAGE.md](USAGE.md)

## 已移除内容

本分支不包含 Serv00、GitHub Actions 保活、网页保活、Cloudflare Worker 等功能文件。  
如果你只是用 VPS 搭建代理并给多人使用，这些功能不是必需项。

## VPS 一键安装

在 VPS 上运行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

安装完成后，原脚本会创建快捷命令：

```bash
sb
```

## 安装多人命令

在 VPS 上拉取本仓库后运行：

```bash
git clone https://github.com/heartreeW/sing-box-yg-ultra.git
cd sing-box-yg-ultra
bash install-sbuser.sh
```

之后可以直接使用：

```bash
sbuser add alice bob
sbuser list
sbuser links alice
sbuser remove alice
```

## 多人脚本说明

`sbuser add` 会为每个用户生成独立 UUID/密码，并同步写入：

```text
/etc/s-box/sb.json
/etc/s-box/sb10.json
/etc/s-box/sb11.json
```

生成的用户信息会保存到：

```text
/etc/s-box/multi-users.tsv
/etc/s-box/users/<name>.txt
```

如果已经通过 `sb` 配置好 Argo 隧道，并且 vmess-ws 关闭 TLS，`sbuser add` 和 `sbuser links` 会自动额外生成该用户的 vm-argo 链接，并保存到：

```text
/etc/s-box/vm_argo_user_<name>.txt
```

每个用户可以单独删除：

```bash
sbuser remove alice
```

## 注意事项

- 本脚本适合 VPS 使用，不是流量统计/限速面板。
- 删除用户可以让该用户的 UUID/密码失效，但不提供单人限速、流量统计、到期时间或设备数限制。
- 如果需要完整用户面板，建议使用 3x-ui、s-ui、Marzban 等项目。
- 不要公开 `/etc/s-box/users/` 和 `/etc/s-box/multi-users.tsv`。

建议设置权限：

```bash
chmod 600 /etc/s-box/sb.json
chmod 600 /etc/s-box/multi-users.tsv
chmod 700 /etc/s-box/users
```

## 来源

本项目基于 `yonggekkk/sing-box-yg` 精简并增加多人用户管理脚本。
