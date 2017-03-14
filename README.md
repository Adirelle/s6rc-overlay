s6rc-overlay
============

[![Build Status](https://travis-ci.org/Adirelle/s6rc-overlay.svg?branch=master)](https://travis-ci.org/Adirelle/s6rc-overlay)

s6rc-overlay is a collection of statically-compiled binairies and scripts aimed at easing the building of containers with complex setup.

It is heavily inspired by [s6-overlay](https://github.com/just-containers/s6-overlay/) but uses [skarnet's s6-rc](http://www.skarnet.org/software/s6-rc/) for controlling setup and service dependencies.

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

Documentation
-------------

Coming soon™...

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
