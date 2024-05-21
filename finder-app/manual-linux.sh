#!/bin/sh
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
PATCH_COMMIT=e33a814e772cdc36436c8c188d8c42d019fda639

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

echo "Building Linux kernel ..."

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd ${OUTDIR}/linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here

    #Apply patch to scripts/dtc/dtc-lexer.l
    git fetch origin ${PATCH_COMMIT}
    git cherry-pick ${PATCH_COMMIT}

    echo "Applied patch to scripts/dtc/dtc-lexer.l"

    # “deep clean” the kernel build tree - removing the .config file with any existing configurations
    make -j 16 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

    # Configure for our “virt” arm dev board we will simulate in QEMU
    make -j 16 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

    # Build a kernel image for booting with QEMU
    make -j 16 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all

    # Build any kernel modules
    # make -j 16 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules

    # Build the devicetree
    make -j 16 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
else
    echo "Found ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image"
fi

echo "Adding the Image in outdir"
cp -r ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"

mkdir -p bin \
            dev \
            etc \
            home \
            lib \
            lib64 \
            proc \
            sbin \
            sys \
            tmp \
            usr \
            usr/bin \
            usr/lib \
            usr/sbin \
            var \
            var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd ${OUTDIR}/busybox
    git checkout ${BUSYBOX_VERSION}

    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd ${OUTDIR}/busybox
fi

# TODO: Make and install busybox

make -j 16 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make -j 16 CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"

cd ${OUTDIR}/rootfs

echo "Checking for program interpreter in busybox binary:"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"

echo "Checking for shared libraries in busybox binary:"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

echo "Adding library dependencies to rootfs ..."

cp ${SYSROOT}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
cp ${SYSROOT}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp ${SYSROOT}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/
cp ${SYSROOT}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/

# TODO: Make device nodes

echo "Making device nodes ..."

cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1

# TODO: Clean and build the writer utility

echo "Cleaning writer app ..."

cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE} 

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

echo "Copying finder app ..."

cp writer "${OUTDIR}/rootfs/home"
cp finder.sh "${OUTDIR}/rootfs/home"
cp finder-test.sh "${OUTDIR}/rootfs/home"
cp autorun-qemu.sh "${OUTDIR}/rootfs/home"
cp -r '../conf' "${OUTDIR}/rootfs/home"

# TODO: Chown the root directory

echo "Chown the root directory ..."

cd ${OUTDIR}/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz

echo "Creating initramfs.cpio.gz ..."

find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"
gzip -f ${OUTDIR}/initramfs.cpio
