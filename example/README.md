# example

This is an example of how to extend the [dmotte/desktainer](https://github.com/dmotte/desktainer) Docker image. You can use this for inspiration.

In short, on top of the base image, we have:

- installed some **additional packages** (e.g. `nano`, `curl`, `zip`, `tmux`, etc.)
- installed the **Firefox** web browser
- installed the **OpenSSH server**
  - configured it in _supervisor_ as a service
  - running on **port 22**
  - missing OpenSSH server **host keys** are **generated automatically** at container startup, and also copied to `/etc/ssh/host-keys`
- installed **Shell In A Box**
  - configured it in _supervisor_ as a service
  - running on **port 4200**
- already created a custom user named `mainuser` and made some customizations to it
- declared a persistent `/data` volume
- installed a **screen recording** service
  - always running in background
  - configured it in _supervisor_ as a service

TODO complete the list of additions
TODOEND see differences and test them

TODO: Purposes of the users:

- `mainuser`:
  - access to the desktop
  - run services locally
  - use `supervisorctl` (with `sudo`)
  - connect with SSH (even _VSCode Remote-SSH_ should work)
- `alice`:
  - access to local TCP ports (via SSH tunnel)
  - expose TCP ports `8001-8005` locally (via SSH tunnel)

## Usage

The first thing to do is to replace all the `(put-...-here)` placeholders in all the files with your actual values. Also, make sure that all the dummy values (e.g. `myuser`, `myserver`, etc.) are properly replaced.

The [`docker-compose.yml`](docker-compose.yml) file should be pretty self-explanatory. The commands are similar to those of the parent project.
