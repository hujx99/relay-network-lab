# 第 3 章：SSH Tunnel 与 SOCKS5

本章学习 SSH 动态端口转发。它适合做小范围、临时、可控的应用层隧道实验。

## 1. 这是什么

SSH Tunnel 是把本地端口上的连接放进 SSH 加密连接里，再由远程 SSH 服务器发起对目标的连接。

常见类型：

| 类型 | 参数 | 用途 |
| --- | --- | --- |
| 本地端口转发 | `-L` | 把本地端口转到远程目标 |
| 远程端口转发 | `-R` | 把远程端口转回本地目标 |
| 动态端口转发 | `-D` | 在本地启动 SOCKS4/5 代理 |

本项目重点使用 `-D 127.0.0.1:1080`。OpenSSH 手册说明，`-D` 会在本地监听端口，并让 `ssh` 充当 SOCKS 服务器。

## 2. 为什么需要

SSH SOCKS5 很适合入门，因为它：

- 不需要在服务器上额外安装 VPN 软件
- 默认只需要 SSH 访问权限
- 容易启动和停止
- 可以按应用配置，不必改系统默认路由
- 便于观察“应用走隧道”和“系统默认路由不变”的区别

## 3. 它解决什么问题

SSH SOCKS5 可以解决：

- 临时让某个支持 SOCKS 的应用从远程服务器出口访问网络
- 加密本机到 SSH 服务器之间的流量
- 在不修改系统路由的情况下做出口 IP 对比
- 学习 DNS 是否随代理一起走的问题

推荐测试命令：

```bash
ssh -N -T -D 127.0.0.1:1080 user@server
curl --socks5-hostname 127.0.0.1:1080 https://ifconfig.me
```

`--socks5-hostname` 表示让域名解析也交给 SOCKS 连接另一端处理。`--socks5` 则可能在本地先解析域名。

## 4. 它不能解决什么问题

SSH SOCKS5 不能解决：

- 全系统流量自动进入隧道
- UDP 流量的通用转发
- 所有应用都正确使用代理
- 浏览器指纹、账号关联、Cookie 关联
- 远程 SSH 服务器本身的可见性和日志问题
- 对公共用户提供稳定代理服务

它是应用层代理，不是完整 VPN。

## 5. 实验步骤

本章对应实验：`labs/lab-02-ssh-socks5.md`。

### 5.1 准备两台机器

- 本地机器：发起 SSH 连接，运行 SOCKS5 本地端口
- 远程服务器：你拥有或被授权使用的 SSH 服务器

### 5.2 启动本地 SOCKS5

```bash
ssh -N -T -o ExitOnForwardFailure=yes -D 127.0.0.1:1080 user@SERVER_PUBLIC_IP
```

参数含义：

- `-N`：不执行远程命令，只做转发
- `-T`：不分配 TTY
- `-D 127.0.0.1:1080`：只在本机回环地址监听 SOCKS5
- `ExitOnForwardFailure=yes`：端口转发失败时直接退出

### 5.3 检查监听地址

另开一个终端：

```bash
ss -tulpen | grep 1080
```

期望看到 `127.0.0.1:1080`，而不是 `0.0.0.0:1080`。

### 5.4 对比出口 IP

不走 SOCKS5：

```bash
curl -4 https://ifconfig.me
```

走 SOCKS5：

```bash
curl --socks5-hostname 127.0.0.1:1080 https://ifconfig.me
```

如果两者不同，说明该 `curl` 请求从 SSH 服务器出口发出。

### 5.5 测试 DNS 行为

本地解析：

```bash
dig +short example.com
```

通过 SOCKS5 访问域名：

```bash
curl -v --socks5-hostname 127.0.0.1:1080 https://example.com
```

注意：`dig` 不会自动使用 SOCKS5。它测试的是本机 DNS 配置。

## 6. 常见坑

- 把 SOCKS5 监听到 `0.0.0.0`，导致局域网或公网其他主机可连。
- 使用 `curl --socks5` 而不是 `--socks5-hostname`，导致 DNS 仍在本地解析。
- 浏览器配置了 HTTP 代理但没有配置 SOCKS 代理。
- SSH 断开后，应用仍然以为代理存在。
- 远程服务器防火墙或云安全组只影响入站 SSH，不影响它作为客户端访问外部目标。

## 7. 安全提醒

- 不要使用 `-g`，不要监听 `0.0.0.0`。
- 不要把 SOCKS5 当作公共代理提供给他人。
- 使用专用低权限 SSH 用户更容易审计。
- 关闭 SSH agent forwarding，除非你明确需要并理解风险。
- 远程服务器能看到它自己发起连接的目标 IP、时间和连接元数据。

## 8. 英文关键词

- SSH tunnel
- Dynamic forwarding
- SOCKS5
- Local bind address
- Loopback
- ExitOnForwardFailure
- Proxy DNS
- Application proxy
- Agent forwarding

