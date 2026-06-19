# 实验 3：WireGuard 双节点互联

本实验用两台授权 Linux 机器建立一个最小 WireGuard peer-to-peer 网络。目标是让两台机器通过 `10.66.0.0/24` 隧道地址互相 ping 通。

## 1. 这是什么

这是一个 split tunnel 实验。

拓扑：

```text
Server A
  公网：A_PUBLIC_IP
  wg0：10.66.0.1/24
  UDP：51820

Server B
  公网：B_PUBLIC_IP 或 NAT 后
  wg0：10.66.0.2/24
```

本实验只让 WireGuard 内网地址互通，不接管默认路由。

## 2. 为什么需要

WireGuard 的很多问题都来自 `AllowedIPs` 和路由理解不清。本实验先从最小互联开始，避免一开始就做 full tunnel 和 NAT。

## 3. 它解决什么问题

本实验能帮助你：

- 生成 WireGuard 密钥
- 配置两个 peer
- 放行 WireGuard UDP 端口
- 启动和停止 `wg0`
- 观察握手、路由和隧道地址

## 4. 它不能解决什么问题

本实验不做：

- 默认出口切换
- NAT 出口
- DNS 下发
- 多用户权限管理
- 公共 VPN 服务

## 5. 实验步骤

### 5.1 安装 WireGuard

两台机器都执行：

```bash
sudo apt update
sudo apt install -y wireguard
```

### 5.2 生成密钥

两台机器都执行：

```bash
mkdir -p ~/wg-lab
cd ~/wg-lab
umask 077
wg genkey | tee privatekey | wg pubkey > publickey
cat publickey
```

记录：

```text
A_PUBLIC_KEY：
B_PUBLIC_KEY：
```

不要复制或公开 `privatekey` 内容。

### 5.3 配置 Server A

在 Server A 上创建 `~/wg-lab/wg0.conf`：

```ini
[Interface]
Address = 10.66.0.1/24
ListenPort = 51820
PrivateKey = A_PRIVATE_KEY

[Peer]
PublicKey = B_PUBLIC_KEY
AllowedIPs = 10.66.0.2/32
```

把 `A_PRIVATE_KEY` 替换为 Server A 的私钥内容，把 `B_PUBLIC_KEY` 替换为 Server B 的公钥内容。

### 5.4 配置 Server B

在 Server B 上创建 `~/wg-lab/wg0.conf`：

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

如果 Server B 有固定公网 IP，也可以在 Server A 的 peer 里添加 `Endpoint = B_PUBLIC_IP:51820`，但最小实验不要求。

### 5.5 放行 Server A UDP 端口

在 Server A 的云安全组和本机防火墙中允许 UDP `51820`。

UFW 示例：

```bash
sudo ufw allow 51820/udp
sudo ufw status verbose
```

如果你没有启用 UFW，不要为了本实验临时开启 UFW，除非你已经确认 SSH 管理入口不会被阻断。

### 5.6 启动 WireGuard

两台机器都在 `~/wg-lab` 目录执行：

```bash
sudo wg-quick up ./wg0.conf
```

查看状态：

```bash
sudo wg show
ip addr show wg0
ip route
```

### 5.7 测试互通

Server A：

```bash
ping -c 4 10.66.0.2
```

Server B：

```bash
ping -c 4 10.66.0.1
```

检查握手：

```bash
sudo wg show
```

关注：

- `latest handshake`
- `transfer`
- `allowed ips`

### 5.8 停止实验

两台机器都执行：

```bash
sudo wg-quick down ./wg0.conf
```

确认接口消失：

```bash
ip addr show wg0 || echo "wg0 down"
```

### 5.9 记录模板

```text
实验名称：lab-03-wireguard-peer
实验日期：

Server A 公网 IP：
Server A wg0 IP：
Server A 公钥：

Server B 公网 IP：
Server B wg0 IP：
Server B 公钥：

A ping B 结果：
B ping A 结果：
latest handshake：
transfer：

云安全组：
本机防火墙：
异常现象：
```

## 6. 常见坑

- Server A 云安全组没有放行 UDP `51820`。
- `AllowedIPs` 写成了对端公网 IP，而不是隧道 IP。
- 两端系统时间差太大，导致排查握手困难。
- 用了相同的私钥。
- 配置文件权限过宽。
- `wg-quick up` 后忘记 `wg-quick down`，重复启动报错。

## 7. 安全提醒

- `privatekey` 不要提交 GitHub。
- `wg0.conf` 包含私钥，不要公开。
- 每台机器独立密钥。
- 不要把 full tunnel、NAT、开放转发混在第一个实验里。
- 实验结束后关闭不再需要的 UDP 端口。

## 8. 英文关键词

- WireGuard peer
- wg-quick
- PublicKey
- PrivateKey
- AllowedIPs
- Endpoint
- Handshake
- UDP port
- Split tunnel

