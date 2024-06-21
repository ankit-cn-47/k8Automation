sudo hostnamectl set-hostname new-node-name
# edit host name file
sudo vim /etc/hosts
# reboot
sudo reboot

#to join cluster
kubeadm token create --print-join-command


master.kubernetes.cluster
worker1.kubernetes.cluster
