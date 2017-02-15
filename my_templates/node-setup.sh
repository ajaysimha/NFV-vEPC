#!/bin/bash

# Install some packages
yum install tcpdump wget strace screen ftp mlocate -y

# Update the locate database
updatedb

# Permit root login over SSH
sed -i 's/.*ssh-rsa/ssh-rsa/' /root/.ssh/authorized_keys
sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config

systemctl restart sshd

# Update the root password to something we know
echo redhat | sudo passwd root --stdin

# Configure a system identifier httpd virtual host
yum install httpd -y
mkdir -p /var/www/ident/

cat << FOE > /etc/httpd/conf.d/ident.conf
Listen 8088
NameVirtualHost *:8088

<VirtualHost *:8088>
DocumentRoot /var/www/ident/
</VirtualHost>
FOE

restorecon /etc/httpd/conf.d/ident.conf

cat << FOE > /var/www/ident/index.html
Hello from $(hostname) :-)
FOE

restorecon -R /var/www/ident/
chown -R apache:apache /var/www/ident/

iptables -A INPUT -p tcp -m tcp --dport 8088 -j ACCEPT
semanage port -a -t http_port_t -p tcp 8088
systemctl start httpd
systemctl reload httpd
systemctl enable httpd
