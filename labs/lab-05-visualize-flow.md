# 实验 5：可视化访问某个网址或服务的网络流

本实验把访问一个 URL 的过程整理成 Markdown 报告和 Mermaid 流程图。它适合在直连、SSH SOCKS5、WireGuard、Tailscale Exit Node 前后做对比。

## 1. 这是什么

这是一个只读可视化实验。输入一个 URL 或主机名，输出：

- 目标 host
- DNS A / AAAA 记录
- 本机 DNS 配置
- 当前公网出口 IPv4 / IPv6
- `ip route get` 路由选择
- `tracepath` 路径摘要
- Mermaid 网络流图

## 2. 为什么需要

很多网络问题不是“通不通”，而是“从哪里通”。

可视化报告能帮助你快速看出：

- 目标域名解析到了哪里
- 本机从哪个接口访问目标
- 默认网关或隧道接口是否符合预期
- 公网出口是否变化
- DNS 和出口是否一致

## 3. 它解决什么问题

本实验能帮助你：

- 给 GitHub 教程生成图
- 给每次网络实验留下可读记录
- 对比启用隧道前后的路径
- 发现 DNS 泄露和 IPv6 路径差异
- 解释“应用、DNS、路由、出口、目标”的关系

## 4. 它不能解决什么问题

本实验不能：

- 证明完整互联网路径
- 抓取应用内部所有连接
- 判断浏览器指纹或账号关联
- 替代抓包和日志审计
- 替代云厂商或防火墙规则检查

## 5. 实验步骤

### 5.1 准备工具

Debian 或 Ubuntu：

```bash
sudo apt update
sudo apt install -y curl dnsutils iproute2 iputils-ping iputils-tracepath traceroute
```

RHEL 系发行版：

```bash
sudo dnf install -y curl bind-utils iproute iputils traceroute
```

### 5.2 检查脚本

在项目根目录：

```bash
cd /root/relay-network-lab
bash -n scripts/flow-map.sh
```

### 5.3 生成 example.com 报告

```bash
mkdir -p notes
./scripts/flow-map.sh https://example.com > notes/example-flow.local.md
```

查看报告：

```bash
sed -n '1,180p' notes/example-flow.local.md
```

### 5.4 生成服务端口报告

如果你想观察某个服务，例如 SSH：

```bash
./scripts/flow-map.sh github.com:22 > notes/github-ssh-flow.local.md
```

如果你想观察 HTTPS：

```bash
./scripts/flow-map.sh https://github.com > notes/github-https-flow.local.md
```

### 5.5 复制 Mermaid 图

报告里会包含：

```text
```mermaid
flowchart LR
...
```
```

这段可以放进 GitHub Markdown。

### 5.6 对比隧道前后

直连状态：

```bash
./scripts/flow-map.sh https://example.com > notes/flow-direct.local.md
```

启用 Tailscale Exit Node 后：

```bash
./scripts/flow-map.sh https://example.com > notes/flow-exit-node.local.md
```

对比：

```bash
diff -u notes/flow-direct.local.md notes/flow-exit-node.local.md || true
```

重点看：

- Public IPv4
- DNS servers
- Route lookup
- Trace summary
- Mermaid 图中的 gateway / egress 节点

### 5.7 记录模板

```text
实验名称：lab-05-visualize-flow
实验日期：
目标 URL 或服务：
网络状态：直连 / SSH SOCKS5 / WireGuard / Tailscale Exit Node

目标 A 记录：
目标 AAAA 记录：
公网 IPv4：
公网 IPv6：
本机 DNS：
路由接口：
源地址：
下一跳：
路径摘要：

观察结论：
异常现象：
```

## 6. 常见坑

- CDN 域名解析结果变化很正常。
- `tracepath` 的 hop 不完整很正常。
- 服务端口不会改变 DNS 解析，但可能影响后续 TCP 连接结果。
- 脚本显示的是命令行视角，不代表浏览器全部行为。
- SOCKS5 场景下，普通 `ip route get` 仍显示本机到 SSH 服务器或目标的系统路由，不代表应用最终出口。

## 7. 安全提醒

- `notes/*.local.md` 不要提交到 GitHub。
- 不要对第三方目标做高频探测。
- 不要把真实内网网段和公网 IP 放进公开教程图。
- 可公开示例优先使用 `example.com` 或脱敏地址。
- 本脚本只做观察，不修改网络配置。

## 8. 英文关键词

- Flow map
- Network path
- Mermaid diagram
- DNS record
- Route lookup
- Source address
- Gateway
- Egress IP
- Trace summary
- Before and after comparison
