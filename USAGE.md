# sing-box-yg-ultra 操作文档

本文档适用于使用 VPS 搭建 sing-box 代理服务，并通过 `sbuser` 创建多人独立账号。

## 适用场景

适合：

- 有一台 VPS。
- 想一键安装 sing-box 多协议节点。
- 想给多人分别创建独立 UUID/密码。
- 想单独删除某个用户，而不影响其他人。

不适合：

- 需要单人流量统计。
- 需要单人限速。
- 需要用户到期时间。
- 需要设备数量限制。
- 需要完整网页面板。

如果需要这些面板功能，建议使用 3x-ui、s-ui、Marzban 等项目。

## 准备条件

你需要一台 VPS，推荐系统：

- Ubuntu 22.04 / 24.04
- Debian 11 / 12

建议使用 `root` 用户操作。如果不是 root，请先切换：

```bash
sudo -i
```

检查当前用户：

```bash
whoami
```

显示 `root` 即可。

## 一、安装 sing-box

在 VPS 上执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

进入菜单后，选择：

```text
1. 一键安装 Sing-box
```

安装过程中按提示选择即可。新手通常可以直接回车使用默认值。

安装完成后，脚本会自动创建快捷命令：

```bash
sb
```

以后管理 sing-box 节点，可以直接执行：

```bash
sb
```

## 二、确认安装是否成功

检查 sing-box 配置文件：

```bash
ls -l /etc/s-box/sb.json
```

检查快捷命令：

```bash
which sb
ls -l /usr/bin/sb
```

正常情况下会看到：

```text
/usr/bin/sb
```

检查 sing-box 服务状态：

```bash
systemctl status sing-box
```

如果是 Alpine 系统，可以使用：

```bash
rc-service sing-box status
```

## 三、如果找不到 sb 命令

如果执行：

```bash
sb
```

提示：

```text
command not found
```

先检查是否已经完成安装：

```bash
ls -l /etc/s-box/sb.json
```

如果 `/etc/s-box/sb.json` 不存在，说明 sing-box 还没有安装成功。重新执行安装命令，并在菜单里选择 `1`：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

如果 `/etc/s-box/sb.json` 存在，但 `/usr/bin/sb` 不存在，可以手动修复快捷命令：

```bash
curl -L -o /usr/bin/sb https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh
chmod +x /usr/bin/sb
sb
```

## 四、安装多人管理命令 sbuser

先克隆仓库：

```bash
cd /root
git clone https://github.com/heartreeW/sing-box-yg-ultra.git
cd sing-box-yg-ultra
```

安装 `sbuser` 命令：

```bash
bash install-sbuser.sh
```

安装完成后检查：

```bash
which sbuser
```

正常会显示：

```text
/usr/local/bin/sbuser
```

## 五、创建多人用户

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
- 备份旧配置。
- 检查配置是否正确。
- 尝试重启 sing-box。
- 输出每个人的节点链接。

## 六、查看已有用户

```bash
sbuser list
```

会显示类似：

```text
Registered users:
  alice  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  bob    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

还会显示各协议当前用户数量。

## 七、查看某个用户的节点链接

```bash
sbuser links alice
```

节点链接也会保存到：

```text
/etc/s-box/users/alice.txt
```

查看文件：

```bash
cat /etc/s-box/users/alice.txt
```

把 `alice.txt` 里的内容发给 Alice 即可。

多人使用时，建议每个人只发自己的文件，不要把整个 `/etc/s-box/users/` 目录公开。

## 八、删除某个用户

删除 Alice：

```bash
sbuser remove alice
```

删除后：

- Alice 的 UUID/密码会从配置中移除。
- Alice 的旧链接会失效。
- 其他用户不受影响。
- sing-box 会自动重启。

也可以用 UUID 删除：

```bash
sbuser remove xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## 九、配置文件位置

sing-box 主配置：

```text
/etc/s-box/sb.json
```

脚本模板配置：

```text
/etc/s-box/sb10.json
/etc/s-box/sb11.json
```

多人用户登记表：

```text
/etc/s-box/multi-users.tsv
```

每个用户的节点链接：

```text
/etc/s-box/users/<用户名>.txt
```

配置备份目录：

```text
/etc/s-box/backups/
```

## 十、建议权限设置

建议执行：

```bash
chmod 600 /etc/s-box/sb.json
chmod 600 /etc/s-box/multi-users.tsv
chmod 700 /etc/s-box/users
```

这些文件包含用户 UUID/密码，不要公开。

## 十一、常用命令汇总

安装 sing-box：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

打开 sing-box 管理菜单：

```bash
sb
```

安装多人管理命令：

```bash
cd /root
git clone https://github.com/heartreeW/sing-box-yg-ultra.git
cd sing-box-yg-ultra
bash install-sbuser.sh
```

添加用户：

```bash
sbuser add alice bob
```

查看用户：

```bash
sbuser list
```

查看节点：

```bash
sbuser links alice
```

删除用户：

```bash
sbuser remove alice
```

重启 sing-box：

```bash
systemctl restart sing-box
```

查看 sing-box 状态：

```bash
systemctl status sing-box
```

## 十二、推荐完整流程

从零开始，推荐按这个顺序执行：

```bash
sudo -i
```

```bash
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

在菜单中选择：

```text
1. 一键安装 Sing-box
```

安装完成后：

```bash
cd /root
git clone https://github.com/heartreeW/sing-box-yg-ultra.git
cd sing-box-yg-ultra
bash install-sbuser.sh
```

创建用户：

```bash
sbuser add alice bob charlie
```

查看 Alice 的节点：

```bash
sbuser links alice
```

把输出内容发给 Alice。

## 十三、更新脚本

进入仓库目录：

```bash
cd /root/sing-box-yg-ultra
git pull
```

重新安装 `sbuser`：

```bash
bash install-sbuser.sh
```

更新 `sb` 快捷脚本：

```bash
curl -L -o /usr/bin/sb https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh
chmod +x /usr/bin/sb
```

## 十四、卸载

如果要卸载 sing-box，可以运行：

```bash
sb
```

在菜单里选择卸载相关选项。

也可以手动删除多人命令：

```bash
rm -f /usr/local/bin/sbuser
```

如需完全清理配置，请谨慎操作：

```bash
rm -rf /etc/s-box
```

注意：这会删除所有节点配置、用户信息和备份。

## 十五、常见问题

### 1. 执行 sbuser 提示 command not found

说明还没有安装 `sbuser`。执行：

```bash
cd /root/sing-box-yg-ultra
bash install-sbuser.sh
```

### 2. 添加用户时提示缺少 jq

安装 `jq`：

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

### 3. 添加用户后无法连接

先检查配置：

```bash
/etc/s-box/sing-box check -c /etc/s-box/sb.json
```

重启服务：

```bash
systemctl restart sing-box
```

查看状态：

```bash
systemctl status sing-box
```

再确认 VPS 防火墙、安全组是否开放对应端口。

### 4. 删除用户后对方还能用

先确认删除成功：

```bash
sbuser list
```

然后重启 sing-box：

```bash
systemctl restart sing-box
```

如果对方还在使用，可能是客户端缓存或正在维持旧连接。断开重连后应失效。

### 5. 原脚本重装后用户不见了

如果你使用 `sb` 脚本重装或重置配置，手动添加的多人用户可能被覆盖。

建议提前备份：

```bash
cp -a /etc/s-box/multi-users.tsv /root/multi-users.tsv.bak
cp -a /etc/s-box/users /root/sbox-users-bak
```

## 十六、安全建议

- 不要公开用户链接。
- 不要公开 `/etc/s-box/users/`。
- 不要公开 `/etc/s-box/multi-users.tsv`。
- 不要把 VPS root 密码发给别人。
- 只开放 sing-box 需要的端口。
- 不认识的人离开后，及时执行 `sbuser remove 用户名`。

## 十七、最短使用版

如果你已经熟悉流程，只需要记住下面几条：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/heartreeW/sing-box-yg-ultra/main/sb.sh)
```

菜单选：

```text
1. 一键安装 Sing-box
```

然后：

```bash
cd /root
git clone https://github.com/heartreeW/sing-box-yg-ultra.git
cd sing-box-yg-ultra
bash install-sbuser.sh
sbuser add alice bob
sbuser links alice
```
