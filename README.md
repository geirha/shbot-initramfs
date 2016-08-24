Shbot is an IRC bot that runs shell code. It is a fork of evalbot
(http://www.vidarholen.net/contents/evalbot/).

To build, you'll need

- Typical build tools: A C compiler, make, yacc, lex patch
- Header files of libraries needed to build bash, awk, mksh etc.

For Ubuntu/Debian

```
sudo apt-get install build-essential ncompress
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
