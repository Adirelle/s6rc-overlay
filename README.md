s6rc-overlay
============

[![Build Status](https://travis-ci.org/Adirelle/s6rc-overlay.svg?branch=master)](https://travis-ci.org/Adirelle/s6rc-overlay)

s6rc-overlay is a collection of statically-compiled binairies and scripts aimed
at easing the building of containers with complex setup.

It is heavily inspired by
[s6-overlay](https://github.com/just-containers/s6-overlay/) but uses
[skarnet's s6-rc](http://www.skarnet.org/software/s6-rc/) for controlling setup
and service dependencies.

The reading of [s6](http://skarnet.org/software/s6) and
[s6-rc](http://skarnet.org/software/s6-rc) overview dans documentation is
highly advised.

Usage
-----

### With Docker

You can use one of the [docker images](https://hub.docker.com/r/adirelle/s6rc-overlay/).

Or include it in your Dockerfile, like this:

```Dockerfile
ENV S6RC_VERSION 0.0.1
ADD https://github.com/Adirelle/s6rc-overlay/releases/download/v${S6RC_VERSION}/s6rc-overlay-v${S6RC_VERSION}-amd64.tar.bz2 /tmp/s6rc-overlay.tar.bz2
RUN tar xfa /tmp/s6rc-overlay.tar.bz2 -C / \
&&  rm /tmp/s6rc-overlay.tar.bz2
ENTRYPOINT ["/sbin/container-init"]
```

Running process
---------------

1. When starting, s6rc-overlay entrypoint extracts its configuration variables
from the environment, backup the other variables, as well as the current user
and working directory, then clear all variables and gain root privileges.

2. It removes everything in both `/tmp` and `/run` and installs its working
directory in `/run/s6-rc`.

3. If there is no precompiled service database, it compiles one from
`/etc/services.d`.

4. It tries to bring up the target
service, which should depends on the actual services to start.

5. Once all the services are started:

    1. If command line has been given, it restores the initial environment
(user, working directory, variables) and executes it.

    2. Else it waits forever until some signal is received.

6. s6rc-overlay regains the control as root, then tries to bring down the
services.

7. It sends a SIGTERM signal to all remaining processes and waits 2 seconds.

8.  Finally it returns the exit code of the commmand, or 0 if they was none.

Environments
------------

When the starting user is not root, s6rc-overlay creates a safe environment for
root: it clears all environment variables, redefines PATH and imports the
configuration variables from the starting environment.

Said otherwise, root default environment does not contains that environment
variables passed at launch, and the starting user does not have access to
configuration variables.

All services are run in the root environment, i.e. as root with almost no
variables. If they need variables from the starting environment, you
can use the `with-contenv` helper (see below).

Services
--------

### Service database

You can provide a precompiled service database in `/etc/s6-rc/compiled` or let
s6rc-overlay compile it from service definitions in `/etc/services.d`.  See the
[s6-rc-compile documentation](http://skarnet.org/software/s6-rc/s6-rc-compile.html) about
the format of service definitions.

### Default services

s6rc-overlay comes with the following default services. They are defined in the
`/etc/services.d` directory and can be configured using environment variables. 

**Note:** in case you provided precompiled service database, these services
would not be available.

#### `remove-paths`

Recursively removes all files and directories matching `REMOVE_PATHS`. Does
nothing if `REMOVE_PATHS` is undefined.

#### `writable-paths`

Recursively gives write permissions to `WRITABLE_USER` on all files and
directories matching `WRITABLE_PATHS`, using `setfacl`. Does nothing if any of
these variables is undefined.

It depends on `remove-paths`.

#### `init`

A simple bundle that references `writable-paths`. It can be used as a
synchronisation point before launching longruns. You can add other services to
wait to with a single command:

```
echo my_other_service >> /etc/s6-rc/source/init/contents
```

#### `services`

This service is dynamically added by s6rc-overlay on compilation. It is a
simple bundle that lists every services in `/etc/services.d` to ensure they are
all started.

Helper commands
---------------

### s6-notice

    s6-notice message prog...

Prints `message` in green and executes into `prog`.

### s6-logcmd

    s6-logcmd prog...

Prints `prog` in yellow and executes it. Standard and error outputs are colored
in white and red, respectively. The final status is shown as 'Success' in green
if it is 0, or as 'Failed (actual value)' in red in case of failure.

All outputs are prefixed with `NN>` where NN is a sequential number. This helps
identifying entangled outputs from parallel tasks.

### with-contenv (root only)

    with-contenv [ -a | [-c] [-e] [-w] [-u] ] prog...

Executes `prog` with all or parts of the starting environment, depending on the
options.

* `-a` is an alias for `-cewu`.

* `-c` clears the environment. It is intended to be used with `-e`.

* `-e` imports all variables from the starting environment.

* `-w` changes the working directory to the starting one.

* `-u` runs progs as the starting user.

Configuration
-------------

He is a list of environment variables that alters s6rc-overlay behavior:

* `S6_VERBOSITY`: the verbosity of various s6-rc commands. Defaults to 1.

* `S6_TARGET`: the service to bring up at startup. Defaults to `services`.

* `S6_INIT_TIMEOUT`: the initialisation timeout (see s6-rc-init), in
milliseconds. Defauts to 500ms.

* `S6_START_TIMEOUT`: the service start timeout, in milliseconds. Defauts to 2
minutes.

* `S6_STOP_TIMEOUT`: the service stop timeout, in milliseconds. Defauts to 5s.

* `S6_CONF_DIR`: the path to the initial configuration of s6rc-overlay. Defaults
to `/etc/s6-rc`.

* `S6_RUN_DIR`: the path to the working directory of s6rc-overlay. Defaults to
`/run/s6-rc`.

Security concerns
-----------------

s6rc-overlay uses `gosu` : it is required for privilege escalation in the
container during startup, but it can also be exploited by malicious code.

Components
----------

 * skarnet's tools, as statically-linked binaries from [just-containers/skaware](https://github.com/just-containers/skaware/):
   * scripting language: [execline](http://www.skarnet.org/software/execline/)
   * POSIX-compliant tools, well-suited for execline scripts: [s6-portable-utils](http://www.skarnet.org/software/s6-portable-utils/),
   * supervision suite: [s6](http://www.skarnet.org/software/s6/),
   * service manager: [s6-rc](http://www.skarnet.org/software/s6-rc/),
 * [gosu](https://github.com/tianon/gosu).

License
-------

s6rc-overlay scripts are released under the [MIT license](LICENSE.md).
