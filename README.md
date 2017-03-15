s6rc-overlay
============

[![Build Status](https://travis-ci.org/Adirelle/s6rc-overlay.svg?branch=master)](https://travis-ci.org/Adirelle/s6rc-overlay)

s6rc-overlay is a collection of statically-compiled binairies and scripts aimed at easing the building of containers with complex setup.

It is heavily inspired by [s6-overlay](https://github.com/just-containers/s6-overlay/) but uses [skarnet's s6-rc](http://www.skarnet.org/software/s6-rc/) for controlling setup and service dependencies.

The reading of [s6](http://skarnet.org/software/s6) and [s6-rc](http://skarnet.org/software/s6-rc) overview dans documentation is highly advised.

Usage
------------

### With Docker

You can use on of the (yet to come) [public images](https://hub.docker.com/r/adirelle/s6rc-overlay/).

Or include it in your Dockerfile, like this:

```Dockerfile
ENV S6RC_VERSION 0.0.1
ADD https://github.com/Adirelle/s6rc-overlay/releases/download/v${S6RC_VERSION}/s6rc-overlay-v${S6RC_VERSION}-amd64.tar.bz2 /tmp/s6rc-overlay.tar.bz2
RUN tar xfa /tmp/s6rc-overlay.tar.bz2 -C / 
&&  rm /tmp/s6rc-overlay.tar.bz2
ENTRYPOINT ["/sbin/container-init"]
```

Running process
---------------

1. When starting, s6rc-overlay entrypoint extracts its configuration variables from the environment, backup the other variables, as well as the current user and working directory, then gain root privileges to continue.
2. It removes everything in both `/tmp` and `/run` and installs its working directory in `/run/s6-rc`.
3. If there is no precompiled service database, it creates one from `/etc/services.d`.
4. It tries to bring up the main service, which should depends on all the actual services to start.
5. Once all the services are started:
    1. If command line has been given, it restores the initial environment (user, working directory, variables) and runs it.
    2. Else it waits forever until some signal is received.
6. s6rc-overlay regains the control as root, then tries to bring down the services.
7. It sends a SIGTERM signal to all remaining processes and waits 2 seconds.
8. Finally it returns the exit code of the commmand, or 0 if they was none.

Services
--------

### Service database

You can provide a precompiled service database in /etc/s6-rc/compiled or let s6rc-overlay compile it from service definitions in /etc/services.d.

### Default services

s6rc-overlay comes with the following default services. They are defined in the /etc/services.d directory and are configured through environment variables.

#### `remove-paths`

Recursively removes all files and directories matching `REMOVE_PATHS`. Does nothing if `REMOVE_PATHS` is undefined.

#### `writable-paths`

Recursively gives write permissions to `WRITABLE_USER` on all files and directories matching `WRITABLE_PATHS`. It does nothing if any of these variables is undefined.

It depends on `remove-paths`.

#### `init`

A simple bundle that references `writable-paths`. It can be used at synchronisation point before launching longruns. You can add other services to wait to with a single command:

```
echo my_other_service >> /etc/services.d/init/contents
```

#### `services`

This service is dynamically added by s6rc-overlay on compilation. This is a simple bundle that lists every services in /etc/services.d to ensure they are all started.

Configuration
-------------

He is a list of environment variables that can be used to alter s6rc-overlay behavior:

`S6_VERBOSITY`: the verbosity of various s6-rc commands. Defaults to 1.

`S6_TARGET`: the service to bring up at startup. Defaults to `services`.

`S6_INIT_TIMEOUT`: the initialisation timeout (see s6-rc-init), in milliseconds. Defauts to 500ms.

`S6_START_TIMEOUT`: the service start timeout, in milliseconds. Defauts to 2 minutes.

`S6_STOP_TIMEOUT`: the service stop timeout, in milliseconds. Defauts to 5s.

`S6_CONF_DIR`: the path to the initial configuration of s6rc-overlay. Defaults to `/etc/s6-rc`.

`S6_RUN_DIR`: the path to the working directory of s6rc-overlay. Defaults to `/run/s6-rc`.

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
