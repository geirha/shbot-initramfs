Shbot is an IRC bot that runs shell code. It is a fork of evalbot
(http://www.vidarholen.net/contents/evalbot/).

If you just want shbot up and running, go grab a prebuilt initramfs and kernel from [releases](https://github.com/geirha/shbot-initramfs/releases).

If you want to make changes, you can either mess with the sources and build everything from scratch, or modify the prebuilt initramfs archive by doing the following:

```bash
mkdir shbot-root
cd shbot-root

# using pax, the standard archiver
gzip -cd ../shbot-0.1.cpio.gz | pax -rv
# or using GNU cpio
gzip -cd ../shbot-0.1.cpio.gz | cpio -iv

# make the changes you want in this directory tree, then put it back into a gziped cpio archive:

# using pax
pax -x sv4cpio -wv . | gzip -9 > ../shbot-custom.cpio.gz
# or using GNU cpio and find
find . -print0 | cpio -o0v -H newc | gzip -9 > ../shbot-custom.cpio.gz
```

### Building from scratch

To build, you'll need

- Typical build tools: A C compiler, make, yacc, lex patch
- Header files of libraries needed to build bash, awk, mksh etc.

For Ubuntu/Debian

```
sudo apt-get install build-essential ncompress qemu-system libicu-dev
sudo apt-get build-dep bash gawk mawk ksh mksh
```

For Fedora/CentOS

```
sudo yum install patch ncompress flex byacc bison
sudo yum-builddep bash gawk mawk ksh mksh
```

Should get most, if not all, build requirements down.

Run 
```
make
```

[kernel-howto.md](kernel-howto.md) explains how to configure and build the kernel
