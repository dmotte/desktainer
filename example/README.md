# example

This is an example of how to extend the [dmotte/desktainer](https://github.com/dmotte/desktainer) Docker image. You can use this for inspiration.

In short, on top of the base image, we have:

- declared a persistent `/data` volume
- installed some **additional packages** (e.g. `nano`, `curl`, `zip`, `tmux`, etc.)
- installed the **Firefox** web browser
- configured some **additional services**
  - refer to the [`build/setup/main.sh`](build/setup/main.sh) file for further details
  - note that some of them are actually commented
- already created a **custom user** named `mainuser`
  - can access the desktop
  - can use `supervisorctl` (with `sudo`)
  - full access via SSH (even _Visual Studio Code Remote-SSH_ should work)
- created an **additional user** named `alice`
  - limited access via SSH - **port forwarding** only
    - access to local TCP ports
    - expose TCP ports `8001-8005` locally

## Usage

The first thing to do is to replace all the `(put-...-here)` placeholders in all the files with your actual values. Also, make sure that all the dummy values (e.g. `myuser`, `myserver`, etc.) are properly replaced.

The [`docker-compose.yml`](docker-compose.yml) file should be pretty self-explanatory. The commands are similar to those of the parent project.

If you want to **build the image faster** (useful for testing), you can optionally trick your local Docker instance by **pre-installing some packages** and tag the resulting image as `docker.io/dmotte/desktainer:latest` itself:

```bash
docker build -t docker.io/dmotte/desktainer:latest -f- << 'EOF'
FROM docker.io/dmotte/desktainer:latest
RUN apt-get update && \
    apt-get install -y ... && \
    rm -rf /var/lib/apt/lists/*
EOF
```

> **Note**: this is not recommended because it will also affect other stuff that rely on the `docker.io/dmotte/desktainer:latest` image on your computer. Only do this if you know what you're doing.
