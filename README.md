frr-docker
===

Building FRR Docker Image
---

```sh
docker build -t frr:dev .
```


Running FRR Container
---

```sh
PATH_TO_SOURCE=/home/user/sources

mkdir -pv $PATH_TO_SOURCE
cd $PATH_TO_SOURCE
git clone https://github.com/FRRouting/frr.git

# After these two commands a shell inside the FRR instance will be opened
# with tmux and you can use as a regular FRR router.
FRR_HOSTNAME='frr-1'

docker run --interactive --tty --privileged --init \
  --volume "$PATH_TO_SOURCE:/usr/src" \
  --hostname $FRR_HOSTNAME --name $FRR_HOSTNAME \
  frr:dev

# On a different terminal
FRR_HOSTNAME='frr-2'

docker run --interactive --tty --privileged --init \
  --volume "$PATH_TO_SOURCE:/usr/src" \
  --hostname $FRR_HOSTNAME --name $FRR_HOSTNAME \
  frr:dev

# On a different terminal
docker network create frr-net1
docker network connect frr-net1 frr-1
docker network connect frr-net1 frr-2

# Now you can configure routing protocols between `frr-1` and `frr-2`
#
# Interface `eth0` will always be connected to the internet and `ethX`
# will be the interfaces configured with
# `docker network connect frr-netX frr-X`.
```


(Re)building FRR
---

If you changed the source code you'll want to run `frr-build.sh`. The build
script builds and installs FRR using the sources found on `/usr/src/frr`.

Run `frr-build.sh --help` for more information.


Docker Image Details
---

The default 'init' (initialization) script is `frr-start.sh`. It is called
once on startup to setup the container environment (see `container-init.sh`)
and start tmux as the main process (if it dies the container goes away with
all process).

Here are some of the default `tmux` bindings for quick-start:
* `CTRL-b c` - Create new window and switch to it
* `CTRL-b n` - Change screen to next window
* `CTRL-b p` - Change screen to previous window
* `CTRL-b d` - Detatch from tmux (effectively kills all processes and exit)


Troubleshooting
---

1. FRR is using too much virtual memory or it is too slow to stop with
   `/usr/lib/frr/watchfrr.sh stop`.

This is probably releated with the container default file descriptors limit.

You can check your current container limit with: `ulimit -n`. If the value is
too high it means FRR will try to allocate a lot of memory
(Linux won't actually allocate until you use it) and when you shutdown the
`libfrr` will iterate over all allocated entries to attempt to `close()` file
descriptors and reset the value.

You can configure this value in `/etc/frr/daemons` by editing the variable
(or uncommenting) `MAX_FDS` or by passing the command line argument
`--limit-fds` to individual daemon.


2. FRR startup fails with "fork: not enough memory".

See item (1) above.


3. FRR is behaving unexpectedly or is crashing.

FRR will try to use syslog for logging, but no syslog daemons are
configured by default. If you want to save the FRR daemons log you
can change `/etc/frr/daemons` and append the command line options
`--log file:/var/log/frr/<daemon>.log --log-level debug` to get them
saved in `/var/log/frr/<daemon>.log`.

In case of crashes you may check `/var/log/frr/<daemon>-<pid>` files
since the container is configured to save them there by default.

`frr-build.sh` by default uses dev builds which means the binaries will
have all symbols. This means you can debug FRR daemons with `gdb`.

* Checking a core dump:
  `gdb --core=/var/log/frr/<daemon>-<pid> /usr/lib/frr/<daemon>`.

* Attaching `gdb` to a running daemon:
  `gdb --pid=$(pgrep <daemon>) /usr/lib/frr/<daemon>`

  or

  `gdb --pid=$(cat /var/run/frr/<daemon>.pid) /usr/lib/frr/<daemon>`
