#! /bin/bash

echo -e "\nInstalling MySQL server.."
sudo apt-get install -y mysql-server
echo -e "\nMySQL server installation complete.."
sleep 5

sudo sed -i "s|^\(log_error.*\)|#\1|g" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl stop mysql.service
sleep 5

echo -e "\nCreating /var/run/mysqld directory.."
sudo mkdir -p /var/run/mysqld && sudo chown -R mysql:mysql /var/run/mysqld
sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.mysqld

echo -e "\nCreating /var/run/mysql-data directory.."
sudo mkdir -p /var/run/mysql-data

echo -e "\nInitializing MySQL database"
sleep 5
mysqld --initialize-insecure --datadir=/var/run/mysql-data

sudo grep -qxF '* soft nofile 65535' /etc/security/limits.conf || sudo echo '* soft nofile 65535' >> /etc/security/limits.conf
sudo grep -qxF '* hard nofile 65535' /etc/security/limits.conf || sudo echo '* hard nofile 65535' >> /etc/security/limits.conf

sudo sysctl net.ipv4.tcp_max_syn_backlog=65535
sudo sysctl net.core.somaxconn=65535

echo -e "\nStarting MySQL server.."
sleep 5
mysqld --datadir=/var/run/mysql-data --skip-log-bin &

sleep 5

echo -e "\nInstalling sysbench.."
sudo apt-get install -y sysbench
