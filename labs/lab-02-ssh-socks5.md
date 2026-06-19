# 实验 2：SSH SOCKS5 本地隧道

本实验学习如何用 OpenSSH 在本机启动一个只监听 `127.0.0.1` 的 SOCKS5 端口，并验证单个命令是否通过远程 SSH 服务器出口访问网络。

## 1. 这是什么

这是一个应用层代理实验。

实验拓扑：

```text
本地机器 curl
  -> 127.0.0.1:1080 SOCKS5
  -> SSH 加密连接
  -> 远程 SSH 服务器
  -> 目标网站
```

本实验不会修改系统默认路由，不会让所有应用自动走隧道。

## 2. 为什么需要

SSH SOCKS5 是学习隧道的低风险入口：

- 启停简单
- 不需要改防火墙转发链
- 不需要改默认路由
- 能直观看到“同一台机器，不同应用配置，出口不同”

## 3. 它解决什么问题

本实验能帮助你：

- 创建一个本机 SOCKS5 端口
- 对比直连出口 IP 和隧道出口 IP
- 理解 `--socks5` 与 `--socks5-hostname` 的差异
- 确认代理端口没有暴露到公网

## 4. 它不能解决什么问题

本实验不能：

- 让所有系统流量自动进入隧道
- 转发任意 UDP 应用
- 消除浏览器指纹或账号关联
- 证明匿名
- 作为公共代理服务

## 5. 实验步骤

### 5.1 准备变量

把下面变量替换成你的远程服务器信息：

```bash
export SSH_USER="your_user"
export SSH_HOST="your_server_ip_or_domain"
export SOCKS_PORT="1080"
```

### 5.2 记录直连出口

```bash
curl -4 https://ifconfig.me
printf '\n'
curl -4 https://api.ipify.org
printf '\n'
```

记录：

```text
直连公网 IPv4：
```

### 5.3 启动 SOCKS5

```bash
ssh -N -T \
  -o ExitOnForwardFailure=yes \
  -D 127.0.0.1:${SOCKS_PORT} \
  ${SSH_USER}@${SSH_HOST}
```

保持这个终端不要关闭。

### 5.4 检查监听端口

另开一个终端：

```bash
ss -tulpen | grep ":${SOCKS_PORT}"
```

期望看到：

```text
127.0.0.1:1080
```

如果看到 `0.0.0.0:1080` 或 `[::]:1080`，停止实验并检查命令。

### 5.5 通过 SOCKS5 检查出口

```bash
curl --socks5-hostname 127.0.0.1:${SOCKS_PORT} https://ifconfig.me
printf '\n'
curl --socks5-hostname 127.0.0.1:${SOCKS_PORT} https://api.ipify.org
printf '\n'
```

记录：

```text
SOCKS5 后公网 IPv4：
是否等于远程服务器公网 IP：
```

### 5.6 对比 DNS 行为

本地解析：

```bash
dig +short example.com
```

SOCKS5 远端解析方式访问：

```bash
curl -v --socks5-hostname 127.0.0.1:${SOCKS_PORT} https://example.com
```

SOCKS5 本地解析方式访问：

```bash
curl -v --socks5 127.0.0.1:${SOCKS_PORT} https://example.com
```

观察 `curl -v` 输出中是否先解析了域名，以及请求是否成功。

### 5.7 停止实验

回到运行 `ssh -N -T` 的终端，按：

```text
Ctrl+C
```

确认端口关闭：

```bash
ss -tulpen | grep ":${SOCKS_PORT}" || echo "SOCKS5 stopped"
```

### 5.8 记录模板

```text
实验名称：lab-02-ssh-socks5
实验日期：
本地机器：
远程 SSH 服务器：

直连公网 IPv4：
SOCKS5 公网 IPv4：

SOCKS5 监听地址：
是否仅监听 127.0.0.1：

curl --socks5-hostname 结果：
curl --socks5 结果：

异常现象：
安全检查：
```

## 6. 常见坑

- `ssh` 连接成功，但 `-D` 端口被占用，导致代理没有启动。
- 忘记使用 `127.0.0.1` 绑定地址。
- 浏览器配置了代理，但命令行 `curl` 没有配置。
- 使用 `dig` 以为能测试 SOCKS5 DNS，实际上 `dig` 不会自动走 SOCKS5。
- 远程服务器访问目标失败，不代表本地 SOCKS5 启动失败。

## 7. 安全提醒

- 不要加 `-g`。
- 不要监听 `0.0.0.0`。
- 不要把这个 SOCKS5 分享给其他人使用。
- 不要把远程 SSH 服务器用于绕过平台风控或访问控制。
- 实验记录公开前要删除真实 IP、用户名和主机名。

## 8. 英文关键词

- SSH dynamic forwarding
- SOCKS5
- Localhost
- Bind address
- Remote DNS
- Application proxy
- Egress IP
- Exit server

