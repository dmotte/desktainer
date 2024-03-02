# example

This is an example of how to extend the [dmotte/desktainer](https://github.com/dmotte/desktainer) Docker image. You can use this for inspiration.

## Usage

The first thing to do is to replace all the `(put-...-here)` **placeholders** in all the files with your actual values. Also, make sure that all the **dummy values** (e.g. `myuser`, `myserver`, etc.) are properly replaced.

Then, place the missing **required files** (e.g. the authorized keys files) inside the `remote` folder. You can take a look to `.gitignore` and `main.sh` to figure out exactly what's missing.

To start the _docker-compose_ stack:

```bash
docker-compose up -d
```

Then we can leverage the [`remote-dir-run.sh`](https://github.com/dmotte/misc/blob/main/scripts/remote-dir-run.sh) script to provision the container using the content of the `remote` directory:

```bash
time remote-dir-run.sh remote docker-compose exec -T dt01 bash -c ++ \
    env SUPERVISOR_RELOAD=true bash main.sh; echo $?
```
