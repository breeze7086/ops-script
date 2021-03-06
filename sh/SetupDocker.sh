#!/bin/sh

# --author:may--
# --time:20170511--

DOCKER_VERSION="docker-ce-17.03.1.ce"
DOCKER_UBUNTU1604_VERSION="docker-ce=17.03.1~ce-0~ubuntu-xenial"
DOCKER_DISK="/dev/sdb"
DOCKER_VGNAME="vgdocker"
DOCKER_LVNAME="thinpool"

install_docker(){
    echo -e '\033[33m"Begin to install docker,version:'$1' ......"\033[0m'
    # need command 'which'
    which yum-config-manager > /dev/null 2>&1
    if [ $? -ne 0 ];then
        yum install -y yum-utils
    fi
    if [ ! -s "/etc/yum.repos.d/docker-ce.repo" ];then
        echo -e '\033[33m"Add docker-ce repo ......"\033[0m'
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    fi
    # now to install docker
    if [ -f "/usr/bin/docker" ];then
        return 0
    else
        yum install -y $1
    fi
    if [ -f "/usr/bin/docker" ];then
        return 0
    fi
    return 1
}

install_docker_ubuntu(){
    echo -e '\033[33m"Begin to install docker,version:'$1' ......"\033[0m'
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    echo -e '\033[33m"Repo installed success,now update the package index......"\033[0m'
    sudo apt-get update
    if [ -f "/usr/bin/docker" ];then
        return 0
    else
        sudo apt-get install -y --allow-unauthenticated $1
    fi

    if [ -f "/etc/docker/daemon.json" ];then
        return 0
    else
        # use overlay2 replace default aufs storage driver
        cat > /etc/docker/daemon.json << EOF
{
  "storage-driver": "overlay2"
}
EOF
    fi

    if [ -f "/usr/bin/docker" ];then
        return 0
    fi
    return 1
}

convert_disk(){
    # if has /dev/vgdocker/thinpool,then consider all steps done
    if [ -f "/dev/$2/$3" ];then
        #echo "Find /dev/$2/$3 exist,installation may be ready..."
        echo -e '\033[33m"Find /dev/'$2'/'$3' exist,installation may be ready..."\033[0m'
        #echo "All steps done!"
        echo -e '\033[33m"All steps done!"\033[0m'
        exit
    else
        # if no /dev/vdb exist,exit
        fdisk -l | grep $1 > /dev/null 2>&1
        if [ $? -ne 0 ];then
            #echo "Can't find disk $1,please check disk...88"
            echo -e '\033[31m"Can not find disk '$1',please check disk...88"\033[0m'
            exit
        fi
        # check if already has /dev/vdb1
        fdisk -l | grep $1"1" > /dev/null 2>&1
        if [ $? -ne 0 ];then
            fdisk $1 <<EOF
n
p



t
8e
w
EOF
        fi
        fdisk -l | grep $1"1" > /dev/null 2>&1
        if [ $? -ne 0 ];then
            #echo "Convert disk "$1" failed,check the reason and try again...88"
            echo -e '\033[31m"Convert disk '$1' failed,check the reason and try again...88"\033[0m'
            exit
        fi
        return 0
    fi
    return 1
}

create_lvm(){
    if [ ! -f "/usr/sbin/pvcreate" ];then
        #echo "Can't find lvm utils on this server,now install..."
        echo -e '\033[33m"Can not find lvm utils on this server,now install..."\033[0m'
        yum install -y lvm2
    fi
    if [ $? -ne 0 ];then
        #echo "Install lvm2 package fail,check the reason and try again...88"
        echo -e '\033[31m"Install lvm2 package fail,check the reason and try again...88"\033[0m'
        exit
    fi
    vgdisplay  | grep $2 > /dev/null 2>&1 && lvdisplay | grep $3 > /dev/null 2>&1
    if [ $? -eq 0 ];then
        #echo "Already has "$2" and "$2"-"$3
        echo -e '\033[33m"Already has '$2' and '$2'-'$3'"\033[0m'
        return 0
    fi
    pvcreate $1"1" > /dev/null 2>&1
    vgcreate $2 $1"1" > /dev/null 2>&1
    lvcreate --wipesignatures y -n $3 -l 95%VG $2 > /dev/null 2>&1
    lvcreate --wipesignatures y -n thinpoolmeta -l 1%VG $2 > /dev/null 2>&1
    lvscan > /dev/null 2>&1
    lvconvert -y --zero n -c 512K --thinpool $2/$3 --poolmetadata $2/thinpoolmeta > /dev/null 2>&1
    cat > /etc/lvm/profile/docker-thinpool.profile << EOF
activation {
    thin_pool_autoextend_threshold=80
    thin_pool_autoextend_percent=20
}
EOF
    lvchange --metadataprofile docker-thinpool $2/$3 > /dev/null 2>&1
    vgdisplay  | grep $2 && lvdisplay | grep $3 > /dev/null 2>&1
    if [ $? -eq 0 ];then
        #echo "Create lvm ok..."
        echo -e '\033[33m"Create lvm ok..."\033[0m'
        return 0
    fi
    return 1
}

create_lvm_ubuntu(){
    if [ ! -f "/sbin/pvcreate" ];then
        #echo "Can't find lvm utils on this server,now install..."
        echo -e '\033[33m"Can not find lvm utils on this server,now install..."\033[0m'
        sudo apt-get install -y lvm2
    fi
    if [ $? -ne 0 ];then
        #echo "Install lvm2 package fail,check the reason and try again...88"
        echo -e '\033[31m"Install lvm2 package fail,check the reason and try again...88"\033[0m'
        exit
    fi
    vgdisplay | grep $2 > /dev/null 2>&1 && lvdisplay | grep $3 > /dev/null 2>&1
    if [ $? -eq 0 ];then
        #echo "Already has "$2" and "$2"-"$3
        echo -e '\033[33m"Already has '$2' and '$2'-'$3'"\033[0m'
        return 0
    fi
    pvcreate $1"1" > /dev/null 2>&1
    vgcreate $2 $1"1" > /dev/null 2>&1
    lvcreate -n $3 -l 100%VG $2 > /dev/null 2>&1

    vgdisplay  | grep $2 && lvdisplay | grep $3 > /dev/null 2>&1
    if [ $? -eq 0 ];then
        #echo "Create lvm ok..."
        echo -e '\033[33m"Create lvm ok..."\033[0m'
        return 0
    fi
    return 1
}

#echo 'This script will install '"$DOCKER_VERSION"' on this server.'
echo -e '\033[33m"This script will install '$DOCKER_VERSION' on this server."\033[0m'
confirm=''
while [ -z $confirm ];do
    #echo -n "If you want to continue,enter [y/Y]:"
    echo -ne '\033[33m"If you want to continue,enter [y/Y]:"\033[0m'
    read confirm
done

if [ $confirm = 'y' ] || [ $confirm = 'Y' ];then
    isubuntu=false
    cat /etc/issue | grep "Ubuntu"
    if [ $? -eq 0 ];then
        isubuntu=true
    fi

    if [ $isubuntu = false ];then    
        setenforce 0
    fi

    convert_disk $DOCKER_DISK $DOCKER_VGNAME $DOCKER_LVNAME
    if [ $? -ne 0 ];then
        echo -e '\033[31m"Function convert_disk fail,check the reason and try again..88"\033[0m'
        exit
    fi

    if [ $isubuntu = true ]; then
        create_lvm_ubuntu $DOCKER_DISK $DOCKER_VGNAME $DOCKER_LVNAME
    else
        create_lvm $DOCKER_DISK $DOCKER_VGNAME $DOCKER_LVNAME
    fi
    if [ $? -ne 0 ];then
        echo -e '\033[31m"Function create_lvm fail,check the reason and try again..88"\033[0m'
        exit
    fi

    if [ $isubuntu = true ]; then
        install_docker_ubuntu $DOCKER_UBUNTU1604_VERSION
    else
        install_docker $DOCKER_VERSION
    fi

    if [ $? -eq 0 ];then
        # modify docker startup configuration
        #echo "Begin to modiy docker configuration ......"
        echo -e '\033[33m"Begin to modiy docker configuration ......"\033[0m'
        if [ ! -d "/etc/systemd/system/docker.service.d" ];then
            #echo "Create docker.service.d directory ......"
            echo -e '\033[33m"Create docker.service.d directory ......"\033[0m'
            mkdir -p /etc/systemd/system/docker.service.d
        fi
        if [ $isubuntu = true ]; then
            cat > /etc/systemd/system/docker.service.d/daemon.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock --registry-mirror=https://xlzccif5.mirror.aliyuncs.com
EOF
        else
            cat > /etc/systemd/system/docker.service.d/daemon.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock --registry-mirror=https://xlzccif5.mirror.aliyuncs.com --storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/$DOCKER_VGNAME-$DOCKER_LVNAME --storage-opt dm.use_deferred_removal=true
EOF
        fi

        systemctl daemon-reload
        if [ $? -ne 0 ];then
            #echo "Reload docker daemon failed,check the reason and try again...88"
            echo -e '\033[31m"Reload docker daemon failed,check the reason and try again...88"\033[0m'
            exit
        fi
        systemctl restart docker
        #echo "***************************************************************"
        echo -e '\033[33m"***************************************************************"\033[0m'
        #echo "All steps has done! Let's docker."
        echo -e '\033[33m"All steps has done! Let us docker."\033[0m'
    else
        #echo "Install docker failed,check the reason and try again...88"
        echo -e '\033[31m"Install docker failed,check the reason and try again...88"\033[0m'
        exit
    fi
else
    #echo "cancel install...88"
    echo -e '\033[31m"cancel install...88"\033[0m'
    exit
fi
