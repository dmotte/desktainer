# desktainer

![](icon-128.png)

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/dmotte/desktainer/release?logo=github&style=flat-square)](https://github.com/dmotte/desktainer/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/dmotte/desktainer?logo=docker&style=flat-square)](https://hub.docker.com/r/dmotte/desktainer)

:computer: Remote **desk**top in a cont**ainer**.

> :package: This image is also on **Docker Hub** as [`dmotte/desktainer`](https://hub.docker.com/r/dmotte/desktainer) and runs on **several architectures** (e.g. amd64, arm64, ...). To see the full list of supported platforms, please refer to the `.github/workflows/release.yml` file. If you need an architecture which is currently unsupported, feel free to open an issue.

> :calendar: The build process of this Docker image is **triggered automatically every month** (thanks, [GitHub Actions](https://github.com/features/actions)! :smile:) to ensure that you get it with all the latest updated packages. See the [workflow file](.github/workflows/release.yml) for further information.

Thanks to [fcwu/docker-ubuntu-vnc-desktop](https://github.com/fcwu/docker-ubuntu-vnc-desktop) and [soffchen/tiny-remote-desktop](https://github.com/soffchen/tiny-remote-desktop) for the inspiration.

:eight_spoked_asterisk: For an **extended version** of this Docker image, see [dmotte/desktainer-plus](https://github.com/dmotte/desktainer-plus).

## Usage

The simplest way to try this image is:

```bash
docker run -it --rm -p 6901:6901 dmotte/desktainer
```

Then head over to http://localhost:6901/ to access the remote desktop.

![screen01](screen01.png)

> :bulb: **Tip**: If you want to **change the resolution** while the container is running, you can use the `xrandr --fb 1024x768` command. The new resolution cannot be larger than the one specified in the `RESOLUTION` environment variable though.

For a more complex example, refer to the `docker-compose.yml` file.

> **Note**: this image is not meant to be run with the `--user` Docker option, because the `startup.sh` script needs to run as root in the initial phase. Moreover, the custom user created via the `USER` environment variable (see below) will be a **sudoer**, so running the container as root is useful in any case.

> :bulb: **Tip**: If you need to, you can extend this project by making your own `Dockerfile` starting from this image (i.e. `FROM dmotte/desktainer`) and/or mount custom _supervisor_ configuration files. See the [dmotte/desktainer-plus](https://github.com/dmotte/desktainer-plus) Docker image for an example of how to do it.

### Environment variables

List of supported **environment variables**:

| Variable       | Required               | Description                                                                                              |
| -------------- | ---------------------- | -------------------------------------------------------------------------------------------------------- |
| `RESOLUTION`   | No (default: 1280x720) | Screen resolution                                                                                        |
| `USER`         | No (default: debian)   | Name of the custom user. If set to `root`, no custom user will be created and the main user will be root |
| `PASSWORD`     | No (default: `debian`) | Password of the custom user (if `USER != root`)                                                          |
| `VNC_PASSWORD` | No (default: `debian`) | Password for the VNC server                                                                              |
| `VNC_PORT`     | No (default: 5901)     | TCP port of the VNC server                                                                               |
| `NOVNC_PORT`   | No (default: 6901)     | TCP port of the noVNC webserver                                                                          |

## Development

If you want to contribute to this project, the first thing you have to do is to **clone this repository** on your local machine:

```bash
git clone https://github.com/dmotte/desktainer.git
```

Then you just have to run this command:

```bash
docker-compose down && docker-compose up --build
```

This will automatically **build the Docker image** using the `docker-build` directory as build context and then the **Docker-Compose stack** will be started.

If you prefer to run the stack in daemon (detached) mode:

```bash
docker-compose up -d
```

In this case, you can view the logs using the `docker-compose logs` command:

```bash
docker-compose logs -ft
```
