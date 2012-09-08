KERNCONF=RPI-B
FREEBSD_SRC=${TOPDIR}/freebsd-rpi
UBOOT_SRC=${TOPDIR}/u-boot-pi
RPI_BOOTFILES_SRC=${TOPDIR}/rpi

check_prerequisites ( ) {
    freebsd_src_test \
	${KERNCONF} \
 	" $ git clone git://github.com/gonzoua/freebsd-pi.git $FREEBSD_SRC"

    uboot_test \
	"$UBOOT_SRC/board/raspberrypi/rpi_b/Makefile" \
	"git clone -b rpi_b git://github.com/gonzoua/u-boot-pi.git ${UBOOT_SRC}"

    if [ ! -f "${RPI_BOOTFILES_SRC}/boot/start.elf" ]; then
	echo "Need Rasberry Pi closed-source boot files."
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone git://github.com/raspberrypi/firmware ${RPI_BOOTFILES_SRC}"
	echo
	echo "Run this script again after you have the files."
	exit 1
    fi
}

build_bootloader ( ) {
    # Closed-source firmware is already built.
    # Build U-Boot
    # uboot_patch ${BOARDDIR}/files/uboot_*.patch
    uboot_configure rpi_b_config
    uboot_build
    # Build ubldr.
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
}

construct_boot_partition ( ) {
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_format
    disk_fat_mount ${FAT_MOUNT}

    echo "Setting up boot partition"
    cd ${RPI_BOOTFILES_SRC}/boot
    cp bootcode.bin loader.bin start.elf ${FAT_MOUNT}
    cp ${UBOOT_SRC}/u-boot.img ${FAT_MOUNT}
    cp ${BOARDDIR}/files/uEnv.txt ${FAT_MOUNT}

    freebsd_ubldr_copy ${FAT_MOUNT}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
