#!/bin/bash
# b8_yang@163.com
# modify by: aaa103439@hotmail.com


if [[ "$(whoami)" != "root" ]]; then
        echo "please run this script as root ." >&2
        exit 1
fi


echo -e "\033[31m 这个是centos7系统初始化脚本，获取更多工具及脚本请关注公众号： 波哥的IT人生  Please continue to enter or ctrl+C to cancel \033[0m"
sleep 5
#yum update
yum_update(){
        yum update -y
}
#configure yum source
yum_config(){
  yum install wget epel-release -y
  cd /etc/yum.repos.d/ && mkdir bak && mv -f *.repo bak/
  wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
  yum clean all && yum makecache
  yum -y install iotop iftop net-tools lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel bash-completion
}
#firewalld
# 关闭 firewalld, 并安装 iptables，但清空 iptables 规则
iptables_config(){
  systemctl stop firewalld.service
  systemctl disable firewalld.service
  yum install iptables-services -y
  systemctl enable iptables
  systemctl start iptables
  iptables -F
  service iptables save
}
#system config
# 关闭 selinux
# 上海时区
# 安装 chrony 时间同步服务
system_config(){
  sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
  timedatectl set-local-rtc 1 && timedatectl set-timezone Asia/Shanghai
  yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service
}

# 设定文件描述符
ulimit_config(){
  echo "ulimit -SHn 102400" >> /etc/rc.local
  cat >> /etc/security/limits.conf << EOF
  *           soft   nofile       102400
  *           hard   nofile       102400
  *           soft   nproc        102400
  *           hard   nproc        102400
  *           soft  memlock      unlimited
  *           hard  memlock      unlimited
EOF

}

#set sysctl
# 调整内核参数
sysctl_config(){
  cp /etc/sysctl.conf /etc/sysctl.conf.bak
  pgsize=`getconf PAGESIZE`
  cat > /etc/sysctl.conf << EOF
  ### kernel
  # 关闭内核组合快捷键
  kernel.sysrq = 0
  # 内核消息队列
  kernel.msgmnb = 65536
  kernel.msgmax = 65536
  # 定义 core 文件名
  kernel.core_uses_pid = 1
  # 定义 core 文件存放路径
  kernel.core_pattern = /corefile/core-%e-%p-%t"
  # 系统级别上限， 即整个系统所有进程单位时间可打开的文件描述符数量
  fs.file-max = 6553500
  ### tcp/ip
  # 开启转发
  net.ipv4.ip_forward = 1
  # 保持反向路由回溯是关闭的，默认也是关闭
  net.ipv4.conf.default.rp_filter = 0
  net.ipv4.conf.default.accept_source_route = 0
  #
  net.ipv4.tcp_window_scaling = 1
  # 针对外网访问, 开启有选择应答，便于客户端仅发送丢失报文，从而提高网络接收性能，但会增加CPU消耗
  net.ipv4.tcp_sack = 1
  # 三次握手请求频次
  net.ipv4.tcp_syn_retries = 5
  # 放弃回应一个TCP请求之前，需要尝试多少次
  net.ipv4.tcp_retries1 = 3
  # 三次握手应答频次
  net.ipv4.tcp_synack_retries = 2
  # 三次握手完毕， 没有数据沟通的情况下， 空连接存活时间
  net.ipv4.tcp_keepalive_time = 60
  # 探测消息发送次数
  net.ipv4.tcp_keepalive_probes = 3
  # 探测消息发送间隔时间
  net.ipv4.tcp_keepalive_intvl = 15
  net.ipv4.tcp_retries2 = 5
  net.ipv4.tcp_fin_timeout = 5
  # 尽量缓存syn，然而服务器压力过大的时候，并没有啥软用
  net.ipv4.tcp_syncookies = 1
  # 在每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目.放大10倍
  net.core.netdev_max_backlog = 10240
  # 对于还未获得对方确认的连接请求，可保存在队列中的最大数目.放大20倍
  net.ipv4.tcp_max_syn_backlog = 10240
  # 定义了系统中每一个端口最大的监听队列的长度.放大20倍
  net.core.somaxconn=10240
  # 开启时间戳
  net.ipv4.tcp_timestamps=1
  # 仅当服务器作为客户端的时候有效，必须在开启时间戳的前提下
  net.ipv4.tcp_tw_reuse = 1
  #最大timewait数
  net.ipv4.tcp_max_tw_buckets = 20000
  net.ipv4.ip_local_port_range = 1024 65500
  # 系统处理不属于任何进程的TCP链接
  net.ipv4.tcp_orphan_retries = 3
  net.ipv4.tcp_max_orphans = 327680
  # 开启 iptables 后，链路追踪上限和超时时间, 若没有使用 iptables，则无效
  net.netfilter.nf_conntrack_max = 6553500
  net.netfilter.nf_conntrack_tcp_timeout_established = 150
  # 下列参数如果设置不当，有可能导致系统进不去
  #net.ipv4.tcp_mem = 94500000 915000000 927000000
  #net.ipv4.tcp_rmem = 4096 87380 4194304
  #net.ipv4.tcp_wmem = 4096 16384 4194304
  #net.core.wmem_default = 8388608
  #net.core.rmem_default = 8388608
  #net.core.rmem_max = 16777216
  #net.core.wmem_max = 16777216
  #kernel.shmmax = 68719476736
  #kernel.shmall = 4294967296
EOF
  /sbin/sysctl -p
  echo "sysctl set OK!!"
}
#install docker
install_docker() {
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum-config-manager --enable docker-ce-edge
    yum-config-manager --enable docker-ce-test
    yum-config-manager --disable docker-ce-edge
    yum install docker-ce -y
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["http://hub-mirror.c.163.com"],
  "data-root": "/export/docker-data-root"
}
EOF
        systemctl enable docker
        echo "docker install succeed!!"
}
#install_docker_compace
install_docker_compace() {
#curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#mv ./docker-compose /usr/local/bin/
#chmod +x /usr/local/bin/docker-compose
    yum install python3-pip -y
    pip3 install --upgrade pip
    pip3 install docker-compose
    docker-compose --version
    echo "docker-compose install succeed!!"
}

main(){
  yum_update
  yum_config
  iptables_config
  system_config
  ulimit_config
  sysctl_config
  install_docker
  install_docker_compace
}
main
