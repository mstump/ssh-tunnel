ssh-tunnel
==========

Script to establish a VPN like tunnel over SSH and setup bi-direction routing.

## Setup
1. The script requires permissions for the tunnel interface, this typically means root on both the target and source machine.
1. The script assumes that the SSH keys required for authentication are already present and configured on the target machine.
1. The two directives below must be present and un-commented in ```sshd_config``` on the target host. Make sure to restart ```sshd``` after making any changes to the configuration file.

```
PermitTunnel yes
PermitRootLogin yes
```

## Usage

```
initiate.sh target_host local_network remote_network tunnel_device_number
```

## Example

```
initiate.sh 54.193.39.196 192.168.51.0/24 192.168.16.0/24 2
```
