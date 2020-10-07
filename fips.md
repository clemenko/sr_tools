# Enable FIPS

## Rhel/Centos

This can require a reboot.

```bash
sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="fips=1 /g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
reboot
```

## FIPS in Docker

Simply add a systmed file.

```bash
echo -e "[Service]\n  Environment=\"DOCKER_FIPS=1\"" > /etc/systemd/system/docker.service.d/fips-module.conf; systemctl daemon-reload; systemctl restart docker
```
