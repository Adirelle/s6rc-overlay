s6rc-overlay
============

s6rc-overlay is a collection of statically-compiled binairies and scripts aimed at easing the building of containers with complex setup.

It is heavily inspired by [s6-overlay](https://github.com/just-containers/s6-overlay/) but uses [skarnet's s6-rc](http://www.skarnet.org/software/s6-rc/) for controlling setup and service dependencies.

Installation
------------

Coming soon™...

Usage
-----

Coming soon™...

Documenation
------------

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
