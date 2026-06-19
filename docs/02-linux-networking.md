# 第 2 章：Linux 网络工具

本章目标是掌握 Linux 上最常用的网络观察工具。后续做 SSH Tunnel、WireGuard、Tailscale 和防火墙实验时，所有判断都要回到这些工具。

## 1. 这是什么

Linux 网络工具是一组用来查看和诊断网络状态的命令。

本项目优先使用：

| 工具 | 用途 |
| --- | --- |
| `ip` | 查看地址、路由、接口状态 |
| `ss` | 查看监听端口和连接 |
| `curl` | 测试 HTTP/HTTPS 请求和出口 IP |
| `dig` | 测试 DNS 解析 |
| `resolvectl` | 查看 systemd-resolved DNS 状态 |
| `tracepath` / `traceroute` | 探测路径 |
| `ping` | 基础连通性测试 |
| `nft` / `iptables` | 查看或配置防火墙规则 |
| `sysctl` | 查看内核网络参数 |

## 2. 为什么需要

网络实验不能只看软件提示“已连接”。你需要知道内核实际如何转发包、DNS 由谁处理、端口暴露在哪里。

例如：

- `tailscale status` 显示在线，但默认路由可能没有使用 exit node。
- `wg show` 显示有 peer，但 `AllowedIPs` 可能没有覆盖目标网段。
- SSH SOCKS5 隧道已经启动，但应用可能没有使用它。
- 防火墙允许了入站端口，但云厂商安全组仍然阻断。

## 3. 它解决什么问题

这些工具可以帮助你：

- 识别当前网络接口和地址
- 查看默认路由、策略路由和具体目标路由
- 确认端口是否只监听本机
- 检查 DNS 配置和解析结果
- 判断 IPv4 与 IPv6 是否走不同路径
- 观察隧道接口是否出现
- 发现误开的公网服务

## 4. 它不能解决什么问题

Linux 网络工具不能直接判断：

- 目标服务如何识别账号或设备
- 云厂商和运营商保存了哪些日志
- 浏览器是否泄露指纹
- 应用是否使用内置 DNS-over-HTTPS
- 加密隧道里的上层应用是否安全

工具只能告诉你系统层面的可观察事实。

## 5. 实验步骤

### 5.1 安装基础工具

Debian 或 Ubuntu：

```bash
sudo apt update
sudo apt install -y curl dnsutils iproute2 iputils-ping iputils-tracepath traceroute
```

RHEL 系发行版：

```bash
sudo dnf install -y curl bind-utils iproute iputils traceroute
```

### 5.2 查看接口

```bash
ip link
ip addr
```

常见接口：

- `lo`：本机回环接口
- `eth0` / `ens*`：云服务器或虚拟机网卡
- `wg0`：常见 WireGuard 接口名
- `tailscale0`：Tailscale 接口
- `tun0`：常见 TUN 隧道接口名

### 5.3 查看路由

```bash
ip route
ip -6 route
ip route get 1.1.1.1
```

`ip route get` 很重要，它能告诉你访问某个目标时内核会选择哪个网卡、源地址和下一跳。

### 5.4 查看连接和监听

```bash
ss -tulpen
ss -tnp
```

重点区分：

- `127.0.0.1:1080`：只允许本机访问
- `0.0.0.0:1080`：所有 IPv4 接口都可访问
- `[::]:1080`：所有 IPv6 接口都可访问

### 5.5 查看 DNS

```bash
cat /etc/resolv.conf
resolvectl status
dig example.com
dig +short example.com
```

如果 `/etc/resolv.conf` 指向 `127.0.0.53`，通常表示系统使用 systemd-resolved 的本地 stub resolver，需要继续看 `resolvectl status`。

### 5.6 查看内核转发参数

```bash
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding
```

普通客户端通常不需要开启转发。作为 exit node、subnet router 或 WireGuard 网关时，才可能需要开启。

### 5.7 查看防火墙状态

Ubuntu 常见：

```bash
sudo ufw status verbose
```

nftables：

```bash
sudo nft list ruleset
```

iptables：

```bash
sudo iptables -S
sudo iptables -t nat -S
```

不要在没有控制台或回滚方案的远程 SSH 会话里直接清空防火墙规则。

## 6. 常见坑

- `ping` 失败不等于 TCP 不通，目标或中间设备可能屏蔽 ICMP。
- `curl` 能访问不代表 DNS 没问题，可能命中了缓存或直接访问 IP。
- `ip addr` 看到的是接口地址，不一定是公网出口地址。
- `ss` 看到监听在 `::` 时，可能同时接受 IPv4 和 IPv6，取决于系统配置。
- Docker、Kubernetes、Tailscale、WireGuard 都可能添加路由和防火墙规则。

## 7. 安全提醒

- 先观察，再修改。
- 每次修改网络配置前，保存 `ip route`、`ss -tulpen`、防火墙规则和云安全组截图。
- 暴露公网端口前，先确认认证、访问来源和日志策略。
- 对中继和出口节点，默认拒绝未知入站和未知转发流量。
- 不要公开发布包含真实 IP、主机名、内网网段、密钥路径的完整输出。

## 8. 英文关键词

- Interface
- Loopback
- Routing table
- Default route
- Source address
- Socket
- Listening port
- Resolver
- Packet forwarding
- Firewall ruleset
- NAT table
- Conntrack
