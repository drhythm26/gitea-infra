# GCP 基础设施命令记录
## 创建vpc

```bash
gcloud compute networks create gitea-vpc \
    --subnet-mode=custom
```
说明：
- custom模式表示子网由我们自己手动创建，不让GCP自动分配
- 不指定GCP会自动创建子网    

## 创建子网
```bash
# 公共子网（放堡垒机）
gcloud compute networks subnets create public-subnet \
  --network=gitea-vpc \
  --region=asia-east1 \
  --range=10.0.1.0/24 \
  --description="堡垒机子网"

# 应用子网（放Gitea服务器）
gcloud compute networks subnets create app-subnet \
  --network=gitea-vpc \
  --region=asia-east1 \
  --range=10.0.2.0/24 \
  --description="Gitea应用子网"

# 数据子网（放MySQL）
gcloud compute networks subnets create data-subnet \
  --network=gitea-vpc \
  --region=asia-east1 \
  --range=10.0.3.0/24 \
  --description="数据库子网"

# 监控子网（放Prometheus+Grafana）
gcloud compute networks subnets create monitor-subnet \
  --network=gitea-vpc \
  --region=asia-east1 \
  --range=10.0.4.0/24 \
  --description="监控子网"
```
说明：
- --network=gitea-vpc 把子网挂在gitea-vpc VPC网络下
- --region=asia-east1 绑定到asia-east1 台湾区域
- --range 是这个子网的ip范围

## 创建Cloud Router 和 NAT网关
```bash
# 先创建Cloud Router（NAT网关依赖它）
gcloud compute routers create gitea-router \
  --network=gitea-vpc \
  --region=asia-east1

# 创建NAT网关
gcloud compute routers nats create gitea-nat \
  --router=gitea-router \
  --region=asia-east1 \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips
```
说明：Cloud Router是GCP的路由组件，NAT网关需要挂在它上面
--nat-all-subnet-ip-ranges 选项让VPC里面所有的子网都可以通过NAT出去
--auto-allocate-nat-external-ips 选项自动分配一个公网IP给NAT网关

## 创建防火墙规则
```bash
# 规则1：允许外网SSH到堡垒机（只开22端口）
gcloud compute firewall-rules create allow-ssh-bastion \
  --network=gitea-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=bastion \
  --description="允许外网SSH到堡垒机"

# 规则2：允许堡垒机SSH到所有内网机器
gcloud compute firewall-rules create allow-ssh-internal \
  --network=gitea-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-tags=bastion \
  --target-tags=internal \
  --description="堡垒机SSH到内网机器"

# 规则3：允许外网访问Gitea的HTTP/HTTPS
gcloud compute firewall-rules create allow-web \
  --network=gitea-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:80,tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=gitea-server \
  --description="允许外网访问Gitea"

# 规则4：允许Gitea访问MySQL
gcloud compute firewall-rules create allow-mysql \
  --network=gitea-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:3306 \
  --source-tags=gitea-server \
  --target-tags=mysql-server \
  --description="Gitea访问MySQL"

# 规则5：允许监控服务器采集所有机器的指标
gcloud compute firewall-rules create allow-monitoring \
  --network=gitea-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:9100 \
  --source-tags=monitor \
  --target-tags=internal \
  --description="Prometheus采集node_exporter指标"
```
说明：
- --network=gitea-vpc 把防火墙规则挂到VPC网络gitea-vpc下
- --direction=INGRESS 入口流量
- --action=ALLOW 允许
- --rules=tcp:9100 放行tcp：9100端口
- --source-tags=monitor 来源标签
- --source-ranges=0.0.0.0/0 来源ip 0.0.0.0/0 表示所有ip
- --target-tags=internal 目标标签

## 创建Compute engine
```bash
# 堡垒机（有公网IP，打bastion标签）
gcloud compute instances create bastion \
  --zone=asia-east1-b \
  --machine-type=e2-micro \
  --subnet=public-subnet \
  --private-network-ip=10.0.1.10 \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --tags=bastion \
  --description="堡垒机"

# Gitea服务器（无公网IP，打gitea-server和internal标签）
gcloud compute instances create gitea-server \
  --zone=asia-east1-b \
  --machine-type=e2-medium \
  --subnet=app-subnet \
  --private-network-ip=10.0.2.10 \
  --no-address \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --tags=gitea-server,internal \
  --description="Gitea应用服务器"

# MySQL服务器（无公网IP）
gcloud compute instances create mysql-server \
  --zone=asia-east1-b \
  --machine-type=e2-medium \
  --subnet=data-subnet \
  --private-network-ip=10.0.3.10 \
  --no-address \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --tags=mysql-server,internal \
  --description="MySQL数据库服务器"

# 监控服务器（无公网IP）
gcloud compute instances create monitor \
  --zone=asia-east1-b \
  --machine-type=e2-small \
  --subnet=monitor-subnet \
  --private-network-ip=10.0.4.10 \
  --no-address \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --tags=monitor,internal \
  --description="监控服务器"
```
说明：
- --zone=asia-east1-b 绑定到asia-east1-b这个可用区
- --machine-type=e2-small 机器类型
- --subnet=monitor-subnet 子网
- --private-network-ip=10.0.4.10 私有IP
- --no-address 无公网IP
- --image-family=ubuntu-2404-lts-amd64 镜像系列
- --image-project=ubuntu-os-cloud 镜像项目
- --tags=monitor,internal 标签

## 验证命令
# 查看所有VM
gcloud compute instances list

# 查看防火墙规则
gcloud compute firewall-rules list \
  --filter="network=gitea-vpc"

# 查看子网
gcloud compute networks subnets list \
  --network=gitea-vpc \
  --regions=asia-east1

# SSH进堡垒机（带Agent Forwarding）
eval $(ssh-agent -s)
ssh-add ~/.ssh/google_compute_engine
gcloud compute ssh bastion \
  --zone=asia-east1-b \
  --ssh-flag="-A"

# 从堡垒机跳转到内网机器
ssh 10.0.2.10   # gitea-server
ssh 10.0.3.10   # mysql-server
ssh 10.0.4.10   # monitor
```
