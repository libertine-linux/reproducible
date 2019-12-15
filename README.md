# Reproducible: A reproducible build environment to bootstrap from-scratch builds

Reproducible uses the absolute minimum of tools, on either Linux or Mac OS, to create an as isolated-as-possible minimimal build environment that is reproducible and allows for reproducible builds.

It's main usage is to build [Libertine Linux](https:://github.com/libertine-linux) from other Linux and Mac OS distributions. See the [Libertine](https:://github.com/libertine-linux/libertine) subproject's `tools` folder for an example of usage. It's primary host platform is Linux (where its dependencies are not much more than a copy of Busybox).

On Linux, it uses a chroot; on Mac OS, it uses QEMU (and compiles its own copy to work on older machines).

A long term goal is for Reproducible to switch from using a stable copy of Alpine Linux's binaries to one produced by Libertine Linux.


## License

The license for this project is MIT.
