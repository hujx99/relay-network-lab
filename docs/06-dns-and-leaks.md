# 第 6 章：DNS 与泄露检查

本章学习 DNS 请求如何发生，以及为什么“出口 IP 变了”不等于“DNS 也走了预期路径”。

## 1. 这是什么

DNS 泄露通常指：你希望某个应用或系统的流量走隧道，但域名解析仍然发给了本地网络、运营商、云厂商默认 resolver 或其他非预期 resolver。

DNS 可能发生在多个位置：

- 操作系统 resolver
- systemd-resolved
- 浏览器内置 DNS-over-HTTPS
- 应用自己的 DNS 客户端
- 代理协议的远端解析
- VPN 或 Tailscale 下发的 DNS 配置

## 2. 为什么需要

DNS 查询本身会暴露你访问的域名。即使 HTTPS 加密了网页内容，DNS 查询仍可能让 resolver 看到目标域名和查询时间。

在中继网络实验中，你必须分别检查：

- HTTP/HTTPS 请求从哪里出
- DNS 查询由谁处理
- IPv4 和 IPv6 是否一致
- 应用是否绕过系统 DNS

## 3. 它解决什么问题

DNS 泄露检查能帮助你：

- 确认系统 resolver
- 发现浏览器和命令行行为差异
- 比较 SOCKS5 本地解析和远端解析
- 判断 VPN 是否接管 DNS
- 检查 IPv6 是否绕过预期出口

## 4. 它不能解决什么问题

DNS 泄露检查不能解决：

- SNI、HTTP Host、账号、Cookie 等应用层标识
- 目标服务自己的日志
- 恶意或不可信 resolver 的记录行为
- 浏览器指纹和设备关联
- 终端上其他应用的独立网络行为

DNS 只是隐私模型中的一层。

## 5. 实验步骤

### 5.1 查看系统 DNS

```bash
cat /etc/resolv.conf
resolvectl status
```

### 5.2 直接查询域名

```bash
dig example.com
dig +short example.com
dig +trace example.com
```

`dig +trace` 会显示从根域开始的解析路径，适合学习 DNS 层级，不适合频繁大量运行。

### 5.3 对比 SOCKS5 DNS

本地 DNS：

```bash
curl --socks5 127.0.0.1:1080 https://example.com
```

远端 DNS：

```bash
curl --socks5-hostname 127.0.0.1:1080 https://example.com
```

一般情况下，做 SSH SOCKS5 实验时优先用 `--socks5-hostname`。

### 5.4 观察 DNS 包

在授权测试机上观察本机是否向外发送 53 端口 DNS：

```bash
sudo tcpdump -ni any port 53
```

然后另开终端执行：

```bash
dig example.com
curl https://example.com
```

如果浏览器启用了 DNS-over-HTTPS，传统 53 端口抓包可能看不到浏览器 DNS。

### 5.5 检查 IPv6

```bash
curl -4 https://ifconfig.me
curl -6 https://ifconfig.me
dig A example.com
dig AAAA example.com
```

如果 IPv4 走隧道而 IPv6 没走，可能出现路径不一致。

## 6. 常见坑

- 只检查出口 IP，没有检查 DNS。
- 用了 SOCKS5，但应用本地解析域名。
- 浏览器启用 DoH，绕过系统 DNS 设置。
- systemd-resolved 显示 `127.0.0.53`，误以为上游 DNS 是本机。
- IPv6 默认路由仍然直连。
- 容器内 DNS 和宿主机 DNS 不一致。

## 7. 安全提醒

- 不要把完整 DNS 查询日志公开。
- 不要用未知来源的公共 DNS 作为“隐私解决方案”。
- 对团队环境，应明确 resolver、日志保留和访问权限。
- 如果业务要求固定 DNS 出口，应通过防火墙和路由强制约束，而不是只靠应用配置。
- 检查 DNS 时避免访问敏感域名，用 `example.com` 这类测试域名即可。

## 8. 英文关键词

- DNS leak
- Resolver
- Stub resolver
- Upstream DNS
- DNS-over-HTTPS
- DNS-over-TLS
- A record
- AAAA record
- SOCKS remote DNS
- IPv6 leak

