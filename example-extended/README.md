# example-extended

This directory contains an example of **how to extend** the `dmotte/desktainer` Docker image to easily adapt to your needs.

TODO ssh host keys mount from outside

```bash
mkdir -p ssh-host-keys/etc/ssh
ssh-keygen -A -f ssh-host-keys
mv ssh-host-keys/etc/ssh/* ssh-host-keys
rm -r ssh-host-keys/etc
```

TODO fixed custom user debian
