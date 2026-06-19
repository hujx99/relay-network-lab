# 第 5 章：Tailscale 实验

本章学习 Tailscale 的基本模型，以及 Exit Node 和 Subnet Router 的区别。

## 1. 这是什么

Tailscale 是基于 WireGuard 的组网工具。它把设备加入同一个 tailnet，并通过身份、ACL、路由发布和管理台审批来管理访问。

常见概念：

| 概念 | 含义 |
| --- | --- |
| Tailnet | 一个 Tailscale 私有网络 |
| Node / Machine | 加入 tailnet 的设备 |
| MagicDNS | Tailscale 提供的内部 DNS 名称 |
| Exit Node | 让其他设备通过它访问公网 |
| Subnet Router | 让 tailnet 访问某个私有网段 |
| ACL / Grants | 控制谁能访问什么 |

## 2. 为什么需要

手写 WireGuard 很适合学习底层原理，但设备多了以后，密钥分发、路由审批、访问控制、设备下线都会变复杂。

Tailscale 适合学习：

- 身份驱动的私有网络
- 不同设备之间的点对点连接
- 出口节点和子网路由
- 管理台审批流程
- ACL 对网络访问的影响

## 3. 它解决什么问题

Tailscale 可以解决：

- 多设备安全互联
- 不暴露公网端口访问私有服务
- 给授权设备提供受控 exit node
- 通过 subnet router 访问没有安装 Tailscale 的内网设备
- 用管理台查看设备、路由和访问策略

Exit Node 和 Subnet Router 的区别：

- Exit Node：改变设备访问公网时的出口。
- Subnet Router：让 tailnet 访问某个私有网段，不改变公网默认出口。

Tailscale 官方文档也明确：exit node 使用默认路由语义，subnet router 则发布特定子网路由。

## 4. 它不能解决什么问题

Tailscale 不能自动解决：

- 目标服务的账号、设备、浏览器指纹识别
- 未授权共享 exit node 带来的责任问题
- 终端被入侵后的数据泄露
- 错误 ACL 导致的横向访问风险
- 出口节点自身的日志和合规要求

它降低组网复杂度，但不替代 threat model 和最小权限设计。

## 5. 实验步骤

本章对应实验：`labs/lab-04-tailscale-exit-node.md`。

### 5.1 安装

Tailscale 官方 Linux 下载页提供一行安装方式：

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

生产或企业环境建议先阅读脚本内容和发行版包管理方式。

### 5.2 登录 tailnet

```bash
sudo tailscale up
tailscale status
tailscale ip
```

### 5.3 发布 exit node

在准备作为出口的设备上：

```bash
sudo tailscale up --advertise-exit-node
```

然后到 Tailscale 管理台批准该设备作为 exit node。

### 5.4 使用 exit node

在客户端上：

```bash
tailscale status
sudo tailscale up --exit-node=EXIT_NODE_NAME
```

如果需要继续访问本地局域网：

```bash
sudo tailscale up --exit-node=EXIT_NODE_NAME --exit-node-allow-lan-access
```

### 5.5 发布 subnet route

在作为网关的 Linux 设备上，先开启转发：

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

发布私有网段：

```bash
sudo tailscale set --advertise-routes=192.168.10.0/24
```

然后到管理台批准该 subnet route，并用 ACL 限制访问范围。

## 6. 常见坑

- 设备发布了 exit node，但管理台没有批准。
- 客户端没有显式选择 exit node。
- 启用 exit node 后无法访问本地局域网，需要考虑 `--exit-node-allow-lan-access`。
- Subnet Router 开了 IP forwarding，但防火墙默认转发策略太宽。
- 发布了过大的网段，例如整个 `10.0.0.0/8`，导致路由冲突或权限过大。
- ACL 允许了比预期更大的访问范围。

## 7. 安全提醒

- Exit Node 只给明确授权的用户和设备使用。
- Subnet Router 只发布必要网段，不发布无关内网。
- 管理台审批不是访问控制的全部，还要检查 ACL。
- 对服务器类节点考虑关闭 key expiry 或使用 tag，但要配合更严格的 ACL。
- 不要把 Tailscale 当作规避第三方平台控制的工具。

## 8. 英文关键词

- Tailscale
- Tailnet
- MagicDNS
- Exit node
- Subnet router
- Advertise routes
- ACL
- Grants
- Route approval
- Local network access

