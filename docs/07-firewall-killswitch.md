# 第 7 章：防火墙与 kill switch

本章学习如何用防火墙限制流量路径。重点不是复制规则，而是建立“默认拒绝、显式允许、可回滚”的思维。

## 1. 这是什么

防火墙控制流量是否允许进入、离开或转发。Kill switch 是一种保护策略：当预期隧道不可用时，阻止流量自动回落到普通网络出口。

三类流量要分开看：

- 入站：外部访问本机
- 出站：本机访问外部
- 转发：本机把其他机器的流量转发出去

## 2. 为什么需要

隧道和出口节点常见风险是“失败后静默回落”。

例如：

- WireGuard 掉线后，系统改走默认网关。
- Tailscale exit node 不可用后，应用重新直连。
- DNS 查询绕过隧道。
- 出口节点意外转发了非授权来源流量。

Kill switch 的目标是把失败变成可见的断网，而不是不可见的路径变化。

## 3. 它解决什么问题

防火墙和 kill switch 可以帮助：

- 限制 SOCKS5 只监听本机
- 限制 WireGuard 只允许指定 UDP 端口
- 限制出口节点只转发授权网段
- 阻止非隧道接口直接访问公网
- 阻止 DNS 从非预期接口泄露
- 在隧道不可用时 fail closed

## 4. 它不能解决什么问题

它不能解决：

- 应用层账号关联
- 目标服务日志
- 出口节点自身被入侵
- 错误 threat model
- 管理员误操作
- 云安全组和本机防火墙配置不一致

防火墙只是一层控制，不能替代密钥管理、日志审计和最小权限。

## 5. 实验步骤

以下是设计流程，不建议直接复制到远程生产机执行。

### 5.1 先保存当前状态

```bash
ip addr
ip route
ss -tulpen
sudo nft list ruleset
sudo iptables -S
sudo iptables -t nat -S
```

### 5.2 确认管理入口

记录你的 SSH 来源 IP：

```bash
echo "MY_ADMIN_IP=你的固定管理公网IP"
```

如果你没有固定管理 IP，不要在远程服务器上贸然设置严格入站规则。

### 5.3 设计允许列表

最小允许项通常包括：

- 已建立连接：允许返回流量
- SSH 管理入口：只允许你的管理 IP
- WireGuard UDP 端口：只允许需要的来源
- Tailscale 接口流量：按实际策略允许
- DNS：只允许指定 resolver 或只允许通过隧道

### 5.4 使用 UFW 的入门策略

仅示例，先替换管理 IP：

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from MY_ADMIN_IP to any port 22 proto tcp
sudo ufw allow 51820/udp
sudo ufw enable
sudo ufw status verbose
```

如果你要做出口节点，不能只看 UFW 入站策略，还要检查转发策略和 NAT。

### 5.5 kill switch 思路

客户端 full tunnel 的 kill switch 原则：

```text
允许访问 VPN 服务器的公网 IP 和端口
允许隧道接口流量
拒绝其他普通公网出站
保留本地回环和必要局域网访问
```

出口节点的转发原则：

```text
只允许授权来源网段进入转发链
只允许从隧道接口转发到公网接口
明确 NAT 出口
拒绝其他转发
```

### 5.6 回滚准备

远程实验前可以准备一个延迟回滚任务，例如 2 分钟后关闭 UFW：

```bash
echo "sudo ufw disable" | at now + 2 minutes
```

确认规则无误后，再取消回滚任务：

```bash
atq
atrm JOB_ID
```

如果系统没有 `at`，就不要在没有控制台的远程机器上做高风险防火墙实验。

## 6. 常见坑

- 忘记允许 SSH 管理来源，把自己锁在服务器外。
- 只配置云安全组，不配置本机防火墙。
- 只配置本机防火墙，忘记云安全组仍然开放。
- 只限制 IPv4，IPv6 仍然可达。
- 默认允许转发，导致出口节点被非预期网段使用。
- Docker 或其他软件改写了防火墙规则。

## 7. 安全提醒

- 防火墙实验优先在临时测试机做。
- 修改远程防火墙前，确认有云控制台或串口控制台。
- 不要搭建开放代理或开放转发。
- 不要把 kill switch 写成无法审计的一长串命令。
- 规则变更要记录：时间、目的、命令、验证结果、回滚方式。

## 8. 英文关键词

- Firewall
- Kill switch
- Fail closed
- Inbound
- Outbound
- Forwarding
- Default deny
- Allowlist
- UFW
- nftables
- iptables
- NAT

