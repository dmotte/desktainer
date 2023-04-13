# example

This is an example of how to extend the [dmotte/desktainer](https://github.com/dmotte/desktainer) Docker image. You can use this for inspiration.

On top of the base image, we have:

- installed some **additional packages** (`nano`, `curl`, `zip`, `tmux`, etc.)
- installed the **Firefox** web browser
- installed the **OpenSSH server**
  - configured it in _supervisor_ as a service
  - running on **port 22**
  - missing OpenSSH server **host keys** are **generated automatically** at container startup
- installed **Shell In A Box**
  - configured it in _supervisor_ as a service
  - running on **port 4200**
- already created a custom user named `mainuser` and made some customizations to it
- declared a persistent `/data` volume
- installed a **screen recording** service
  - always running in background
  - configured it in _supervisor_ as a service

See [`build/Dockerfile`](build/Dockerfile) for further details.

## Usage

The [`docker-compose.yml`](docker-compose.yml) file should be pretty self-explanatory. The commands are similar to those of the parent project.

If you want to use **persistent host keys** for the OpenSSH server (recommended for production) you can generate them with the following commands before running the container:

```bash
mkdir -p hostkeys/etc/ssh
ssh-keygen -Af hostkeys
mv hostkeys/etc/ssh/* hostkeys
rm -r hostkeys/etc
```

Then remember to uncomment the related lines inside the [`docker-compose.yml`](docker-compose.yml) file.
