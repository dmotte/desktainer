# desktainer

![icon](icon-128.png)

[![GitHub main workflow](https://img.shields.io/github/actions/workflow/status/dmotte/desktainer/main.yml?branch=main&logo=github&label=main&style=flat-square)](https://github.com/dmotte/desktainer/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/dmotte/desktainer?logo=docker&style=flat-square)](https://hub.docker.com/r/dmotte/desktainer)

:computer: Remote **desk**top in a con**tainer**.

> :package: This image is also on **Docker Hub** as [`dmotte/desktainer`](https://hub.docker.com/r/dmotte/desktainer) and runs on **several architectures** (e.g. amd64, arm64, ...). To see the full list of supported platforms, please refer to the [`.github/workflows/main.yml`](.github/workflows/main.yml) file. If you need an architecture that is currently unsupported, feel free to open an issue.

Thanks to [fcwu/docker-ubuntu-vnc-desktop](https://github.com/fcwu/docker-ubuntu-vnc-desktop) and [soffchen/tiny-remote-desktop](https://github.com/soffchen/tiny-remote-desktop) for the inspiration.

## Simple usage

The simplest way to try this image is:

```bash
docker run -it --rm -p6900:6900 -eUSERNGO_{NAME=myuser,PSW=myuser} dmotte/desktainer
```

> **Note**: since some GUI applications may have issues with Docker's default _seccomp_ profile, you may need to use `--security-opt seccomp=unconfined`

Then head over to http://localhost:6900/ to access the remote desktop.

![Screenshot](screen-01.png)

> **Note**: this Docker image runs [userngo](https://github.com/dmotte/misc/tree/main/scripts/userngo) at startup to handle user creation and setup. See https://github.com/dmotte/misc/tree/main/scripts/userngo#examples for documentation and usage examples.

## Standard usage

The [`docker-compose.yml`](docker-compose.yml) file contains a complete usage example for this image. Feel free to simplify it and adapt it to your needs. Unless you want to build the image from scratch, comment out the `build: build` line to use the pre-built one from _Docker Hub_ instead.

To start the Docker-Compose stack in daemon (detached) mode:

```bash
docker-compose up -d
```

Then you can view the logs using this command:

```bash
docker-compose logs -ft
```

## Tips

:bulb: If you need to run things on desktop **startup**, you can create **launcher files** in the `/etc/xdg/autostart` or the `~/.config/autostart` directory.

:bulb: To make **GTK-based applications** use a **dark theme**:

```bash
sudo apt update && sudo apt install -y dconf-cli

dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
```

:bulb: To set a **custom display resolution** (and optionally **refresh rate**):

```bash
sudo apt update && sudo apt install -y wlr-randr

wlr-randr --output=HEADLESS-1 --custom-mode=1920x1080@5Hz
```

## Development

If you want to contribute to this project, you can use the following one-liner to **rebuild the image** and bring up the **Docker-Compose stack** every time you make a change to the code:

```bash
docker-compose down && docker-compose up --build
```

> **Note**: I know that this Docker image has many **layers**, but this shouldn't be a problem in most cases. If you want to reduce its number of layers, there are several techniques out there, e.g. see [this](https://stackoverflow.com/questions/39695031/how-make-docker-layer-to-single-layer)

## TODO

Known issue: the **Task Manager** panel **doesn't show any window**. But LXQt's Wayland support is still experimental in Debian 13 (trixie), and hopefully it will be more robust in Debian 14 (forky). For now, we can use `Alt+Tab` to cycle through open windows.

Warning: when running **wayvnc** as `root`, the `enable_pam=true` config line makes it **accept any existing user** as a valid login! This can be an issue if you create more users in the container and set passwords for them. It is therefore **highly discouraged** to run it as `root`.
