# 第 4 章：WireGuard 基础

本章学习 WireGuard 的核心概念：接口、密钥、peer、AllowedIPs、Endpoint 和 Keepalive。

## 1. 这是什么

WireGuard 是一种基于密钥的轻量级 VPN 协议和工具。它在 Linux 上通常表现为一个网络接口，例如 `wg0`。

最小模型：

```text
Peer A wg0 10.66.0.1/24 <==== UDP/WireGuard ====> Peer B wg0 10.66.0.2/24
```

每个 peer 都有：

- 私钥：只保存在本机
- 公钥：告诉对端
- WireGuard 内网地址：例如 `10.66.0.1/24`
- `AllowedIPs`：这个 peer 负责哪些目标地址
- `Endpoint`：对端公网 IP 和 UDP 端口，可选

## 2. 为什么需要

WireGuard 适合学习受控网络连接，因为它把身份和路由绑定得很清楚：

- 谁是对端：由公钥决定
- 允许发往哪里：由 `AllowedIPs` 决定
- 通过哪个接口走：由路由决定
- 是否有握手：由 `wg show` 观察

相比 SSH SOCKS5，WireGuard 更接近系统层 VPN，能承载更多协议，不局限于支持 SOCKS 的应用。

## 3. 它解决什么问题

WireGuard 可以解决：

- 两台或多台授权主机之间的加密互联
- 私有服务只通过隧道访问
- 小型实验网络的受控路由
- 指定网段或默认路由经过某个 peer
- 观察 full tunnel 与 split tunnel 的区别

`AllowedIPs` 是理解 WireGuard 的关键：

- `10.66.0.2/32`：只把某个 peer 的隧道地址指向它
- `10.66.0.0/24`：把整个 WireGuard 网段指向它
- `0.0.0.0/0, ::/0`：把默认流量指向它，也就是 full tunnel

## 4. 它不能解决什么问题

WireGuard 不能自动解决：

- DNS 泄露
- 出口节点上的 NAT 和防火墙策略
- 多用户权限管理
- 设备丢失后的密钥轮换
- 目标服务的账号、设备、行为识别
- 合规审计和流量日志策略

WireGuard 提供安全的隧道，但安全架构还包括路由、DNS、防火墙、密钥管理和审计。

## 5. 实验步骤

本章对应实验：`labs/lab-03-wireguard-peer.md`。

### 5.1 安装 WireGuard

Debian 或 Ubuntu：

```bash
sudo apt update
sudo apt install -y wireguard
```

### 5.2 生成密钥

在每台机器上执行：

```bash
umask 077
wg genkey | tee privatekey | wg pubkey > publickey
```

`privatekey` 不要提交到 GitHub，不要通过聊天发送。

### 5.3 最小双 peer 配置

服务器 A：`10.66.0.1`

```ini
[Interface]
Address = 10.66.0.1/24
ListenPort = 51820
PrivateKey = A_PRIVATE_KEY

[Peer]
PublicKey = B_PUBLIC_KEY
AllowedIPs = 10.66.0.2/32
```

服务器 B：`10.66.0.2`

```ini
[Interface]
Address = 10.66.0.2/24
PrivateKey = B_PRIVATE_KEY

[Peer]
PublicKey = A_PUBLIC_KEY
Endpoint = A_PUBLIC_IP:51820
AllowedIPs = 10.66.0.1/32
PersistentKeepalive = 25
```

### 5.4 启动和观察

```bash
sudo wg-quick up ./wg0.conf
sudo wg show
ip addr show wg0
ip route
```

测试：

```bash
ping 10.66.0.1
ping 10.66.0.2
```

关闭：

```bash
sudo wg-quick down ./wg0.conf
```

### 5.5 后续 full tunnel 实验

只有当你已经理解 split tunnel 后，才考虑 full tunnel：

```ini
AllowedIPs = 0.0.0.0/0, ::/0
```

full tunnel 通常还需要出口节点启用 IP forwarding、NAT 和防火墙策略。本项目后续会单独讨论。

## 6. 常见坑

- 两端 `AllowedIPs` 写错，握手有了但 ping 不通。
- 云安全组没有放行 UDP `51820`。
- 本机防火墙拦截了 WireGuard UDP 端口。
- NAT 后面的 peer 没有设置 `PersistentKeepalive`，长时间静默后无法收到入站包。
- 把私钥误写入公开仓库。
- full tunnel 后 DNS 仍然走本地网络。

## 7. 安全提醒

- 私钥只保存在对应机器上。
- 为每台设备生成独立 key，不要共用。
- 不要把 `0.0.0.0/0` 当作默认配置；先从单 peer、单网段开始。
- WireGuard UDP 端口只开放给需要访问的来源更好。
- 移除设备时，要从所有相关 peer 配置中删除它的公钥和 `AllowedIPs`。

## 8. 英文关键词

- WireGuard
- Peer
- Interface
- Private key
- Public key
- AllowedIPs
- Endpoint
- PersistentKeepalive
- Split tunnel
- Full tunnel
- NAT traversal

