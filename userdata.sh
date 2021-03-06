#!/bin/bash
#
# Set hostname, ensure it remains
#
hostnamectl set-hostname ${appliedhostname}.${domain_name}
#
#  Create initial hostname entry to remove: 
#  'unable to resolve host ubuntu' error
#
echo $(hostname -I | cut -d\  -f1) $(hostname) | sudo tee -a /etc/hosts
#
# Install Java 1.8.0_181
#
/usr/bin/apt-get update && /usr/bin/apt-get install unattended-upgrades -y
unattended-upgrade -d -v
add-apt-repository ppa:webupd8team/java -y
apt-get update -y
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections # Allows for auto-install of Java
apt-get install oracle-java8-installer -y
#
# Create EFS mount folder & mount
#
/usr/bin/apt-get install nfs-common -y
mkdir /efsmnt
mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dnsname}:/ /efsmnt
echo '${efs_dnsname}:/ /efsmnt nfs defaults,_netdev 0 0' >> /etc/fstab
#
# Install Jenkins
#
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
/usr/bin/apt-get update -y 
/usr/bin/apt-get install jenkins -y
#
# Ensure we are running the latest WAR
#
service jenkins stop
chown jenkins:jenkins /efsmnt
apt-get install --only-upgrade jenkins -y
#
# Mount JENKINS_HOME -> EFS
#
sed -i '/JENKINS_HOME/c\JENKINS_HOME=/efsmnt' /etc/default/jenkins
# Lets ensure state: 
#   * EFS mounted
#   * Mounts are all working
#   * Jenkins user and group own /efsmnt
#
service jenkins stop
chown jenkins:jenkins /efsmnt
mount -a
service jenkins start
