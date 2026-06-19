# relay-network-lab

中文名：中继网络实验室

这是一个从零学习中继节点、加密隧道、受控出口和网络隐私保护的中文教程项目。项目重点是理解网络基础、搭建可控实验环境、观察流量路径，并建立清晰的 threat model。

## 项目边界

本项目用于学习：

- secure networking
- traffic isolation
- controlled egress
- DNS 与路由可观测性
- 个人或团队内部授权环境中的网络实验

本项目不用于：

- 绕过平台风控、封禁或访问控制
- 搭建公共代理服务
- 未授权访问第三方网络或系统
- 任何违法、滥用或隐藏攻击来源的用途

如果某个实验会改变服务器出口、转发规则或防火墙策略，请只在你拥有或被授权管理的机器上进行。

## 学习目标

完成本项目后，你应该能够：

- 解释 IP、端口、DNS、路由、网关、防火墙的基本作用
- 区分 SSH Tunnel、SOCKS5、WireGuard、Tailscale、Exit Node、Subnet Router
- 检查当前出口 IP、DNS 解析路径、路由路径和监听端口
- 设计一个最小权限、可审计、可回滚的中继网络实验环境
- 说明本机、云厂商、运营商、目标服务、中继节点分别可能看到什么
- 把实验过程整理成适合 GitHub 发布的中文教程

## 推荐读者

- 熟悉 Linux 命令行基础，但对网络还不系统的人
- 想理解 VPN、隧道、出口节点、DNS 泄露的人
- 想为个人实验室或团队内部环境设计受控出口的人

## 前置条件

- 一台 Linux 测试机，推荐 Ubuntu 或 Debian
- 具备 `sudo` 权限
- 能通过 SSH 登录测试机
- 不在生产环境机器上直接实验防火墙、路由和出口策略

## 目录结构

```text
relay-network-lab/
├── README.md
├── docs/
│   ├── 01-network-basics.md
│   ├── 02-linux-networking.md
│   ├── 03-ssh-tunnel.md
│   ├── 04-wireguard-basics.md
│   ├── 05-tailscale-lab.md
│   ├── 06-dns-and-leaks.md
│   ├── 07-firewall-killswitch.md
│   ├── 08-threat-model.md
│   └── 09-visualize-network-flow.md
├── labs/
│   ├── lab-01-check-ip-route.md
│   ├── lab-02-ssh-socks5.md
│   ├── lab-03-wireguard-peer.md
│   ├── lab-04-tailscale-exit-node.md
│   └── lab-05-visualize-flow.md
├── diagrams/
├── scripts/
└── LICENSE
```

当前已完成：

- [x] README 第一版
- [x] 第 1 章：网络基础
- [x] 实验 1：检查出口 IP、DNS 与路由
- [x] 第 2 章：Linux 网络工具
- [x] 第 3 章：SSH Tunnel 与 SOCKS5
- [x] 第 4 章：WireGuard 基础
- [x] 第 5 章：Tailscale 实验
- [x] 第 6 章：DNS 与泄露检查
- [x] 第 7 章：防火墙与 kill switch
- [x] 第 8 章：Threat model
- [x] 第 9 章：可视化网络流
- [x] 实验 2：SSH SOCKS5 本地隧道
- [x] 实验 3：WireGuard 双节点互联
- [x] 实验 4：Tailscale Exit Node
- [x] 实验 5：可视化访问某个网址或服务的网络流

## 章节索引

- [第 1 章：网络基础](docs/01-network-basics.md)
- [第 2 章：Linux 网络工具](docs/02-linux-networking.md)
- [第 3 章：SSH Tunnel 与 SOCKS5](docs/03-ssh-tunnel.md)
- [第 4 章：WireGuard 基础](docs/04-wireguard-basics.md)
- [第 5 章：Tailscale 实验](docs/05-tailscale-lab.md)
- [第 6 章：DNS 与泄露检查](docs/06-dns-and-leaks.md)
- [第 7 章：防火墙与 kill switch](docs/07-firewall-killswitch.md)
- [第 8 章：Threat model](docs/08-threat-model.md)
- [第 9 章：可视化网络流](docs/09-visualize-network-flow.md)

## 实验索引

- [实验 1：检查出口 IP、DNS 与路由](labs/lab-01-check-ip-route.md)
- [实验 2：SSH SOCKS5 本地隧道](labs/lab-02-ssh-socks5.md)
- [实验 3：WireGuard 双节点互联](labs/lab-03-wireguard-peer.md)
- [实验 4：Tailscale Exit Node](labs/lab-04-tailscale-exit-node.md)
- [实验 5：可视化访问某个网址或服务的网络流](labs/lab-05-visualize-flow.md)

## 学习路线

1. 先做 `labs/lab-01-check-ip-route.md`，记录当前机器的出口 IP、DNS、默认路由和路径。
2. 阅读 `docs/01-network-basics.md`，把实验输出和概念对应起来。
3. 再进入 Linux 网络工具、SSH 隧道、WireGuard 和 Tailscale。
4. 每做一个隧道或出口实验，都重复检查出口 IP、DNS 和路由路径。
5. 最后整理 threat model，明确每一层观察者能看到什么、看不到什么。

## 建议实验环境

建议至少准备：

- 本地电脑：用于 SSH 登录和发起测试
- Linux 测试服务器 A：普通网络观察实验
- Linux 测试服务器 B：后续作为中继节点或出口节点

不要一开始就在重要业务服务器上改防火墙和默认路由。网络实验很容易因为一条错误规则导致 SSH 断连。

## 记录模板

每次实验建议记录：

```text
实验日期：
机器角色：
系统版本：
公网 IPv4：
公网 IPv6：
DNS 服务器：
默认网关：
关键命令：
观察结果：
风险与回滚：
```

## License

MIT License. See `LICENSE`.
