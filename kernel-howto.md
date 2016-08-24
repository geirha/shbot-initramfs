## How to make a tiny kernel for shbot

This document describes the steps used to create the kernel for shbot. It will hopefully be useful for tweaking shbot's kernel, or for creating a tiny kernel for other/similar purposes.

These steps are based on linux 4.8-rc2, which is the latest version from
the linux-stable repository at the time of this writing.

The steps use a separate directory for building, to avoid messing with the source tree.

Start by grabbing the sources from http://kernel.org or via git:

```bash
~$ git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
Cloning into 'linux-stable'...
<This takes a while and you will see some progress output here while it's doing
its thing>
~$ cd linux-stable
~/linux-stable$ git describe
v4.8-rc2
```

The remainder of this guide assumes the working directory is the linux source
tree (`~/linux-stable` in the above example).

The default kernel configuration has a ton of features enabled by default. Most
of which are unecessary for shbot, so we instead start of with as little
features as possible. To do that we can use the tinyconfig make target:

```
make tinyconfig O=../linux-build
```

This will create a `.config` file under `../linux-build` (which is where
we'll be building the kernel) where almost all features are disabled.

Note that as we enable new features from this point, new options may
appear, and some of those will be enabled by default. For instance, if
we enable `64-bit kernel`, a new option `Enable vsyscall emulation` will
appear under `Processor type and features`. You can track these down and
disable them if you like, but it shouldn't matter much. Also note that
some options actually make the kernel smaller when enabled, so you
should read the help-texts before deciding on whether to disable or not.

Usually, the new options appear right below the option that caused them
to appear. `64-bit kernel` is more of a special case.

To enable and disable features, we use one of the interactive config
options, like menuconfig. There are several to choose from. Run this to
see a list:

```
make help | less
```

If you settle on menuconfig, the command to run is:

```
make menuconfig O=../linux-build
```

You can exit the menuconfig at any time and build the kernel with the
following command:

```
make -C ../linux-build
```

The resuling kernel image you find at
`../linux-build/arch/x86/boot/bzImage`:

```
~/linux-stable$ make -C ../linux-build/
... lots of make output ...
Setup is 15500 bytes (padded to 15872 bytes).
System is 369 kB
CRC 3440e975
Kernel: arch/x86/boot/bzImage is ready  (#1)
make: Leaving directory `/home/geirha/linux-build'
~/linux-stable$ ls -lh ../linux-build/arch/x86/boot/bzImage
-rw-rw-r-- 1 geirha geirha 384K Aug 24 12:08 ../linux-build/arch/x86/boot/bzImage
```

### 64-bit

Let's start by enabling 64-bit kernel

```
    [*] 64-bit kernel
```

As noted above, this will make new options visible, some of which will
be enabled by default. Whether you bother tracking them down or not is
up to you.

### Debugging output - printk

In order to test the kernel underway, it's useful to enable debugging messages, which you can disable later when you're done adding features.

```
> General setup > Configure standard kernel features (expert users)
    [*]   Enable support for printk
```

### Serial Console
 
The simplest way of communicating with the guest is using a serial console.
There's no need for any graphics drivers, no virtual consoles.

First off we have to enable TTY:

```
> Device Drivers > Character devices
    [*] Enable TTY
```

Several new selections will be available (like Virtual terminal and
Unix98 PTY support), some of them pre-enabled, they are not needed; I'll
only list the ones actually needed.

Now move down to Serial drivers to enable Console on 8250/16550 and
compatible serial port:

```
> Device Drivers > Character devices > Serial drivers
    [*] 8250/16550 and compatible serial support
    [ ]   Support 8250_core.* kernel options (DEPRECATED)
    [ ]   Support for Fintek F81216A LPC to 4 UART RS485 API
    [*]   Console on 8250/16550 and compatible serial port
```

At this point you can actually try booting the kernel with qemu. You
won't get a usable system, but you can see the kernel boot up. Yea!

```
~/linux-stable$ make -C ../linux-build/
... lots of make output ...
Setup is 15260 bytes (padded to 15360 bytes).
System is 471 kB
CRC ca1ac0a9
Kernel: arch/x86/boot/bzImage is ready  (#4)
make: Leaving directory `/home/geirha/linux-build'
~/linux-stable$ qemu-system-x86_64 -kernel ../linux-build/arch/x86/boot/bzImage -m 32 -nographic
... lots of kernel output ...
---[ end Kernel panic - not syncing: No working init found.  Try passing init= option to kernel. See Linux Documentation/init.txt for guidance.
```

Since the kernel has no power management features at this point, it
cannot tell qemu that it wants to shut the system down, so to shut down
qemu at this point, switch to the monitor with `^Ac` (meaning hit
**Ctrl** + **a** followed by **c**).  Then type `quit`.

```
...
---[ end Kernel panic - not syncing: No working init found.  Try passing init= option to kernel. See Linux Documentation/init.txt for guidance.
QEMU 2.0.0 monitor - type 'help' for more information
(qemu) quit
~/linux-stable$ 
```

### Executables and Initramfs

No init, it said. Let's add support for running ELF-binaries and scripts, and enable support for initramfs.

```
> Executable file formats / Emulations
    [*] Kernel support for ELF binaries
    [*] Kernel support for scripts starting with #!
```

```
> General setup
    [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
    ()    Initramfs source file(s) (NEW)
    [*]   Support initial ramdisks compressed using gzip (NEW)
```

We can actually boot a small system with a shell now. You can find a
prebuilt initramfs file at
https://github.com/geirha/shbot-initramfs/releases

```
~/linux-stable$ make -C ../linux-build
... lots of make output ...
Setup is 15260 bytes (padded to 15360 bytes).
System is 481 kB
CRC cca78fa5
Kernel: arch/x86/boot/bzImage is ready  (#5)
make: Leaving directory `/home/geirha/linux-build'
~/linux-stable$ qemu-system-x86_64 -kernel ../linux-build/arch/x86/boot/bzImage -initrd ../shbot-0.1.cpio.gz -m 64 -nographic
... lots of kernel output ...
Unpacking initramfs...
Freeing initrd memory: 14532K (ffff8800031af000 - ffff880003fe0000)
platform rtc_cmos: registered platform RTC device (no PNP device found)
Serial: 8250/16550 driver, 4 ports, IRQ sharing disabled
serial8250: ttyS0 at I/O 0x3f8 (irq = 4, base_baud = 115200) is a 16550A
Freeing unused kernel memory: 416K (ffffffff81103000 - ffffffff8116b000)
mount: none has wrong device number or fs type proc not supported
/init: line 29: /proc/cmdline: No such file or directory
cat: /proc/cmdline: No such file or directory
bash-4.3# ls -a
.  ..  .bashrc  .mkshrc
bash-4.3# printf '%s\n' "$BASH_VERSION"
4.3.46(1)-release
bash-4.3# ls /
bin  dev  etc  init  lib  lib64  mnt  proc  root  tmp  usr  var
bash-4.3# logout
(shell exited with 0)
Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000000

Kernel Offset: disabled
---[ end Kernel panic - not syncing: Attempted to kill init!  exitcode=0x00000000

QEMU 2.5.50 monitor - type 'help' for more information
(qemu) quit
```
(Remember, **Ctrl+a c** to switch to the qemu monitor)

### /proc/sysrq-trigger and ACPI

With /proc/sysrq-trigger we can make the machine shut down by writing `o` to
it. (`printf o >/proc/sysrq-trigger`)

```
> File systems > Pseudo filesystems
    [*] /proc file system support
```

```
> Kernel hacking
    [*] Magic SysRq key
```

In order for the kernel to be able to tell qemu to shut down, ACPI have to be enabled. This in turn requires PCI support.

```
> Bus options (PCI etc.)
    [*] PCI support
```

```
> Power management and ACPI options
    [*] ACPI (Advanced Configuration and Power Interface) Support (NEW)  --->
```

Now we can shut down qemu from within the guest!

```
~/linux-build$ make -C ../linux-build/
...
Setup is 15452 bytes (padded to 15872 bytes).
System is 690 kB
CRC a1b22d74
Kernel: arch/x86/boot/bzImage is ready  (#6)
make: Leaving directory `/home/geirha/linux-build'
~/linux-stable$ qemu-system-x86_64 -kernel ../linux-build/arch/x86/boot/bzImage -initrd ../shbot-0.1.cpio.gz -m 64 -nographic
...
bash-4.3# printf o >/proc/sysrq-trigger
sysrq: SysRq : Power Off
ACPI: Preparing to enter system sleep state S5
reboot: Power down
~/linux-stable$ 
```

### Unix domain sockets

If you want to use pipes in ksh93, they require Unix domain sockets:

```
[*] Networking support  --->

> Networking support > Networking options
[*] Unix domain sockets
```

### Removing printk

We don't need all the printk messages any more.

```
> General setup > Configure standard kernel features (expert users)
    [ ]   Enable support for printk
```
