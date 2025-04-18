# Main needed
sudo apt install vncviewer qemu-system qemu-utils qemu-kvm libvirt-daemon-system libvirt-clients

# d for isos, c for disks
mkdir d
mkdir c

# Info
lsmod | grep kvm
egrep -c '(vmx|svm)' /proc/cpuinfo
