sudo hostnamectl set-hostname new-node-name
# edit host name file
sudo vim /etc/hosts
# reboot
sudo reboot

#to join cluster
kubeadm token create --print-join-command


master.kubernetes.cluster
worker1.kubernetes.cluster

#update calico yaml CALICO_IPV4POOL_CIDR value identical to --pod-network-cidr value while initializing the control plane

#update all the hostnames for the other nodes in /etc/hosts file
192.168.56.12 master.kubernetes.cluster
192.168.56.13 worker1.kubernetes.cluster
192.168.56.14 worker2.kubernetes.cluster
192.168.56.15 worker3.kubernetes.cluster


# sudo kubeadm join master.kubernetes.cluster:6443 --token d8ea8u.v7w3yjecapqourab --discovery-token-ca-cert-hash sha256:ddeba72812f613a683ba9ade1ff5e94d069f0b92a05bf6244e50ffe50cd7b670

# kubectl delete pod coredns-76f75df574-5m9xb coredns-76f75df574-lcbvb --grace-period=0 --force --namespace kube-system