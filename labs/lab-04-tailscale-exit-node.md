# 实验 4：Tailscale Exit Node

本实验学习如何让一台授权设备发布为 Tailscale Exit Node，并让另一台设备显式选择它作为公网出口。

## 1. 这是什么

Exit Node 是 tailnet 中的一台设备。其他设备选择它后，公网流量会通过该设备出口。

实验拓扑：

```text
Client
  -> tailscale0
  -> Exit Node
  -> Internet
```

Tailscale 官方文档说明，使用 exit node 相当于把非 Tailscale 的公网流量通过默认路由语义发往该节点。

## 2. 为什么需要

Exit Node 是学习 controlled egress 的好实验：

- 它有明确的管理台审批流程
- 客户端必须显式选择
- 可以与基线出口 IP 对比
- 可以观察 DNS、路由和本地网络访问变化

## 3. 它解决什么问题

本实验能帮助你：

- 安装并登录 Tailscale
- 发布 exit node
- 在管理台批准 exit node
- 客户端选择 exit node
- 验证出口 IP 是否变化
- 停止使用 exit node

## 4. 它不能解决什么问题

本实验不能：

- 绕过第三方平台规则
- 提供匿名访问
- 自动保护浏览器指纹和账号状态
- 替代 ACL 设计
- 替代出口节点日志和合规策略

## 5. 实验步骤

### 5.1 准备两台设备

- Exit Node：你拥有或被授权管理的 Linux 服务器
- Client：同一 tailnet 中的另一台设备

两台设备都需要能登录同一个 Tailscale tailnet。

### 5.2 安装 Tailscale

两台 Linux 设备都执行：

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

登录：

```bash
sudo tailscale up
tailscale status
tailscale ip
```

### 5.3 记录 Client 基线出口

在 Client 上：

```bash
curl -4 https://ifconfig.me
printf '\n'
curl -4 https://api.ipify.org
printf '\n'
ip route
```

记录：

```text
Client 直连公网 IPv4：
```

### 5.4 在 Exit Node 上发布

在 Exit Node 上：

```bash
sudo tailscale up --advertise-exit-node
tailscale status
```

然后打开 Tailscale 管理台，在该设备的 route settings 中启用 `Use as exit node`。

如果你使用严格 ACL，确认允许目标用户使用 exit node。

### 5.5 在 Client 上选择 exit node

先查看可用设备名：

```bash
tailscale status
```

选择 exit node：

```bash
sudo tailscale up --exit-node=EXIT_NODE_NAME
```

如果需要继续访问本地局域网：

```bash
sudo tailscale up --exit-node=EXIT_NODE_NAME --exit-node-allow-lan-access
```

### 5.6 验证出口变化

在 Client 上：

```bash
curl -4 https://ifconfig.me
printf '\n'
curl -4 https://api.ipify.org
printf '\n'
ip route
tailscale status
```

记录：

```text
Client 使用 exit node 后公网 IPv4：
是否等于 Exit Node 公网 IPv4：
```

### 5.7 检查 DNS

在 Client 上：

```bash
cat /etc/resolv.conf
resolvectl status || true
dig +short example.com
```

记录 DNS 是否和预期一致。注意：浏览器可能使用自己的 DNS-over-HTTPS 设置。

### 5.8 停止使用 exit node

在 Client 上：

```bash
sudo tailscale up --exit-node=
```

再次检查出口：

```bash
curl -4 https://ifconfig.me
printf '\n'
```

如果需要让 Exit Node 停止发布：

```bash
sudo tailscale up --advertise-exit-node=false
```

然后在管理台确认 route settings。

### 5.9 记录模板

```text
实验名称：lab-04-tailscale-exit-node
实验日期：

Tailnet：
Exit Node 名称：
Exit Node 公网 IPv4：
Client 名称：

Client 直连公网 IPv4：
Client 使用 exit node 后公网 IPv4：
停止 exit node 后公网 IPv4：

是否批准 Use as exit node：
是否允许 local LAN access：
DNS 观察：
异常现象：
```

## 6. 常见坑

- Exit Node 已发布但没有在管理台批准。
- Client 没有显式选择 exit node。
- 设备名称写错。
- ACL 不允许用户使用 exit node。
- 使用 exit node 后访问不了本地局域网。
- 只检查 IP，没有检查 DNS。

## 7. 安全提醒

- 只给可信用户和设备使用 exit node。
- 不要把 exit node 当公共代理。
- 出口节点负责人应清楚它可能承载哪些流量。
- 定期审计 tailnet 设备、route settings 和 ACL。
- 实验结束后撤销不需要的 exit node 发布。

## 8. 英文关键词

- Tailscale exit node
- Tailnet
- Route settings
- Use as exit node
- Exit node allow LAN access
- Public IP
- Controlled egress
- ACL

