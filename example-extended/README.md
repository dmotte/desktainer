# example-extended

This directory contains an example of **how to extend** the `dmotte/desktainer` Docker image to easily adapt it to your needs.

On top of the base image, we have:

- installed some **additional packages** (`nano`, `curl`, `zip`, `tmux`, etc.)
- installed the **Firefox** web browser
- installed the **OpenSSH server**
  - configured it in *supervisor* as a service
  - running on **port 22**
- installed **Shell In A Box**
  - configured it in *supervisor* as a service
  - running on **port 4200**
- already created a custom user named `debian` and made some customizations to it

See the `docker-build/Dockerfile` file for further details.

:warning: **Note**: for this image to work, it is mandatory to **generate the host keys** for the *OpenSSH server* before starting the container. You can do this with the following commands:

```bash
mkdir -p ssh-host-keys/etc/ssh
ssh-keygen -A -f ssh-host-keys
mv ssh-host-keys/etc/ssh/* ssh-host-keys
rm -r ssh-host-keys/etc
```

The host keys files must then be mounted inside the container; see the `docker-compose.yml` file for example.
