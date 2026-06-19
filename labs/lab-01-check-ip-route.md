# 实验 1：检查出口 IP、DNS 与路由

本实验用于建立基线：在配置 SSH Tunnel、WireGuard、Tailscale Exit Node 之前，先记录一台 Linux 机器当前的网络状态。

## 1. 这是什么

这是一个只读观察实验。你会查看：

- 本机网卡和 IP
- 默认路由
- 访问目标 IP 时的路由选择
- 公网出口 IP
- DNS 配置
- 网络路径
- 本机监听端口

本实验不会修改系统配置。

## 2. 为什么需要

后续任何隧道或出口节点实验，都需要和这个基线对比。

如果你不知道配置前的状态，就很难判断配置后是否真的改变了出口、DNS 或路由。

## 3. 它解决什么问题

本实验能帮助你回答：

- 当前机器的公网出口 IPv4 是什么？
- 当前机器是否有可用 IPv6？
- 默认路由走哪个网卡和网关？
- DNS 服务器是谁？
- 访问常见目标时路由是否一致？
- 本机有没有意外暴露的监听端口？

## 4. 它不能解决什么问题

本实验不能证明：

- 你已经匿名
- 目标服务无法识别你
- DNS 一定没有泄露
- 后续隧道配置一定安全
- 云厂商、运营商或目标服务没有日志

它只建立当前状态的观察记录。

## 5. 实验步骤

### 5.1 准备工具

Debian 或 Ubuntu：

```bash
sudo apt update
sudo apt install -y curl dnsutils iproute2 iputils-ping traceroute
```

RHEL、CentOS、Rocky Linux 或 AlmaLinux：

```bash
sudo dnf install -y curl bind-utils iproute iputils traceroute
```

如果你的系统没有 `dnf`，可尝试：

```bash
sudo yum install -y curl bind-utils iproute iputils traceroute
```

### 5.2 记录系统信息

```bash
date -Is
hostnamectl
uname -a
```

### 5.3 查看网卡和地址

```bash
ip addr
```

记录：

```text
主要网卡：
IPv4 地址：
IPv6 地址：
是否存在隧道接口：
```

### 5.4 查看默认路由

```bash
ip route
ip -6 route
```

记录：

```text
IPv4 默认路由：
IPv6 默认路由：
默认网关：
默认出口网卡：
```

### 5.5 查看具体目标的路由选择

```bash
ip route get 1.1.1.1
ip route get 8.8.8.8
ip route get 9.9.9.9
```

记录每条输出里的：

- `dev`
- `src`
- `via`

### 5.6 检查公网出口 IP

```bash
curl -4 https://ifconfig.me
printf '\n'
curl -4 https://api.ipify.org
printf '\n'
```

如果机器支持 IPv6：

```bash
curl -6 https://ifconfig.me
printf '\n'
curl -6 https://api64.ipify.org
printf '\n'
```

记录：

```text
公网 IPv4：
公网 IPv6：
查询服务是否一致：
```

### 5.7 检查 DNS 配置

```bash
cat /etc/resolv.conf
```

如果系统支持 systemd-resolved：

```bash
resolvectl status
```

再用 DNS 查询出口 IP：

```bash
dig +short myip.opendns.com @resolver1.opendns.com
```

记录：

```text
resolv.conf nameserver：
systemd-resolved DNS：
DNS 查询得到的出口 IP：
```

### 5.8 检查路由路径

```bash
tracepath 1.1.1.1
tracepath 8.8.8.8
```

如果有 `traceroute`：

```bash
traceroute 1.1.1.1
```

记录：

```text
第一跳：
是否出现云厂商内网网关：
是否出现运营商网络：
路径是否完整：
```

### 5.9 查看监听端口

```bash
ss -tulpen
```

重点记录非本地监听：

```text
监听地址不是 127.0.0.1 的服务：
监听地址不是 ::1 的服务：
不认识的进程：
```

### 5.10 保存实验记录

建议复制下面模板到自己的笔记中：

```text
实验名称：lab-01-check-ip-route
实验日期：
机器角色：
云厂商或网络环境：
系统版本：

主要网卡：
本机 IPv4：
本机 IPv6：

公网 IPv4：
公网 IPv6：

DNS 配置：
DNS 出口检查：

IPv4 默认路由：
IPv6 默认路由：
默认网关：

ip route get 1.1.1.1：
ip route get 8.8.8.8：
ip route get 9.9.9.9：

tracepath 1.1.1.1 摘要：
监听端口摘要：

异常现象：
下一步计划：
```

## 6. 常见坑

- `curl -4` 成功但 `curl -6` 失败，不一定是错误，可能只是没有 IPv6。
- `resolv.conf` 里看到 `127.0.0.53`，通常表示 systemd-resolved 本地 stub resolver，不代表真正上游 DNS 是本机。
- `tracepath` 或 `traceroute` 中间出现 `no reply`，不代表网络不可达。
- 云服务器的公网 IP 不一定直接配置在 `ip addr` 里，可能由云厂商 NAT 或弹性公网 IP 映射。
- 如果 `ss -tulpen` 看不到进程名，可能需要加 `sudo`。

## 7. 安全提醒

- 本实验只读，不需要修改防火墙和路由。
- 不要把完整实验输出直接公开到 GitHub，里面可能包含公网 IP、内网 IP、主机名、进程名和网络拓扑。
- 如果发现陌生公网监听端口，先确认服务来源，再决定是否关闭或限制访问。
- 不要在不理解含义的情况下执行网上复制来的 `iptables`、`nft` 或 `ip route` 修改命令。

## 8. 英文关键词

- Baseline
- Public IP
- Egress IP
- DNS resolver
- Default route
- Network interface
- Gateway
- Tracepath
- Traceroute
- Listening port
- Local address
- Remote address

