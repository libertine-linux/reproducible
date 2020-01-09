# Reproducible: A reproducible build environment to bootstrap from-scratch builds

Reproducible uses the absolute minimum of tools, on either Linux or Mac OS, to create an as isolated-as-possible minimimal build environment that is reproducible and allows for reproducible builds.

It's main usage is to build [Libertine Linux](https:://github.com/libertine-linux) from other Linux and Mac OS distributions. See the [Libertine](https:://github.com/libertine-linux/libertine) subproject's `tools` folder for an example of usage. It's primary host platform is Linux (where its dependencies are not much more than a copy of Busybox).

On Linux, it uses a chroot; on Mac OS, it uses QEMU (and compiles its own copy to work on older machines).

A long term goal is for Reproducible to switch from using a stable copy of Alpine Linux's binaries to one produced by Libertine Linux.

Reprducible tries hard to avoid the need to connect to the internet except for initial bootstrapping, allowing one to capture binary dependencies and keep them in version control.


## Mac OS

On Mac OS, Reproducible also manages a local (not per user) reproducible (also thus versioned) MacPorts installation suitable for checking in to git.


## Configuration

Configuration is stored using line delimited, tab-separated test files in a folder, typically `configuration`. A working example is in the `sample-configuration`.
If configuration files are changed that Reproducible destroys and then downloads, unpacks or installs as necessary, but tries hard to use cached data where possible.


## License

The license for this project is MIT.
