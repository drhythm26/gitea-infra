# 踩坑记录
## 1 创建VM时镜像找不到
```powershell
错误信息：
ERROR: (gcloud.compute.instances.create) Could not fetch resource:
 - The resource 'projects/ubuntu-os-cloud/zones/asia-east1-b/imageFamilyViews/ubuntu-2404-lts' was not found

原因：
ubunu-2404-lts不是正确的镜像名 ubuntu-2404-lts-amd64才是正确的镜像名，之前的命令里写错了
```
解决方法：
```bash
gcloud compute images list --project=ubuntu-os-cloud | awk '/ubuntu-2404-lts/ || NR==1'
NAME                              PROJECT            FAMILY                  DEPRECATED  STATUS
ubuntu-2404-lts-amd64-v20260422   ubuntu-os-cloud    ubuntu-2404-lts-amd64   READY
ubuntu-2404-lts-arm64-v20260422   ubuntu-os-cloud    ubuntu-2404-lts-arm64   READY
```

## 2 从堡垒机ssh到内网机器失败
```powershell
错误信息：
lan@bastion:~$ ssh 10.0.2.10
The authenticity of host '10.0.2.10 (10.0.2.10)' can't be established.
ED25519 key fingerprint is SHA256:/o0jVnobF6fp3SL2O95B6x7RMHTSZk53tR7QjXE+qFM.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.0.2.10' (ED25519) to the list of known hosts.
lan@10.0.2.10: Permission denied (publickey).

原因：
SSH密钥（私钥）只在本地电脑上，堡垒机上没有。
从堡垒机连内网机器时，需要用私钥做认证，
但堡垒机找不到私钥，所以连接失败。

解决方法是SSH Agent Forwarding：
把本地的ssh-agent通过SSH连接转发到堡垒机，
让堡垒机临时借用本地的私钥来连接内网机器，
私钥本身不会被复制到堡垒机上。
```
解决方法：
```
eval $(ssh-agent -s)
ssh-add ~/.ssh/google_compute_engine
gcloud compute ssh bastion --ssh-flag="-A"
```
