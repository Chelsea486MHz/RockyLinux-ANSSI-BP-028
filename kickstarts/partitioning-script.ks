#!/usr/bin/env python3
#  -*- coding: utf-8 -*-


__intname__ = "kickstart.partition_script.RHEL9"
__author__ = "Orsiris de Jong"
__copyright__ = "Copyright (C) 2022-2025 Orsiris de Jong - NetInvent SASU"
__licence__ = "BSD 3-Clause"
__build__ = "2025031501"

### This is a pre-script for kickstart files in RHEL 9
### Allows specific partition schemes with one or more data partitions
# Standard partitioning scheme is
# | (efi) | boot | root | data 1 | data part n | swap
# LVM partitioning scheme is
# | (efi) | boot | lv [data 1| data part n | swap]

## Possible partitioning targets
# generic: One big root partition
# web: Generic web server setup
# anssi: ANSSI-BP028 high profile compatible partitioning scheme
# hv: Standard KVM hypervisor
# hv-stateless: Stateless KVM hypervisor, /!\: NOT LVM compatible
# stateless: Generic machine with a 50% sized partition for statefulness (readonly-ro), /!\: NOT LVM compatible
TARGET = "anssi"

DISK_PATH = "%TARGET_BLOCK_DEVICE%"

# Reserve 5% of disk space on physical machines, useful for SSD disks
# Set to 0 to disable
REDUCE_PHYSICAL_DISK_SPACE = 0

# Enable LVM partitioning (if using stateless partition profiles, this will be automatically disabled)
LVM_ENABLED = True
# LVM volume group name
VG_NAME = "vg00"
# LVM Physical extent size
PE_SIZE = 4096
# Please note that the following arguments can be superseded by kernel arguments
# TARGET, USER_NAME, USER_PASSWORD, ROOT_PASSWORD, HOSTNAME, NETWORK, DISK_PATH (the disk we're installing the OS to, eg something like /dev/sda or /dev/vda or /dev/nvme0)
# You need to specify that kernel argument as NPF_{ARGUMENT_NAME}=value, example
# append initrd=initrd.img inst.ks=hd:LABEL=MYDISK:/ks.rhel9.cfg NPF_USER_NAME=bob

### Set Partition schema here
# boot and swap partitions are automatically created
# Sizes can be
# - <nn>: Size in MiB (eg IEC bytes, where 1MiB = 1024KiB = 1048576 bytes)
# - <nn%>: Percentage of remaining size after fixed size has been allocated
# - True: Fill up remaining space after fixed and percentage size has been allocated
#         If multiple True values exist, we'll divide by percentages of remaining space

# Partition schema for standard KVM Hypervisor
PARTS_HV = [
    {"size": 30720, "fs": "xfs", "mountpoint": "/"},
    {"size": True, "fs": "xfs", "mountpoint": "/data", "fsoptions": "nodev,nosuid,noexec"},
]

# Partition schema for stateless KVM Hypervisor
PARTS_HV_STATELESS = [
    {"size": 30720, "fs": "xfs", "mountpoint": "/"},
    {"size": True, "fs": "xfs", "mountpoint": "/data", "fsoptions": "nodev,nosuid,noexec"},
    {"size": 30720, "fs": "xfs", "mountpoint": None, "label": "STATEFULRW"},
]

# Partition schema for stateless machines
PARTS_STATELSSS = [
    {"size": True, "fs": "xfs", "mountpoint": "/"},
    {"size": True, "fs": "xfs", "mountpoint": None, "label": "STATEFULRW"},
]

# Partition schema for generic machines with only one big root partition
PARTS_GENERIC = [
    {"size": True, "fs": "xfs", "mountpoint": "/"}
]

# Partition schema for generic web servers (sized for minimum 20GiB web servers)
PARTS_WEB = [
    {"size": 5120, "fs": "xfs", "mountpoint": "/"},
    {"size": True, "fs": "xfs", "mountpoint": "/var/www", "fsoptions": "nodev,nosuid,noexec"},
    {"size": 4096, "fs": "xfs", "mountpoint": "/var/log", "fsoptions": "nodev,nosuid,noexec"},
    {"size": 1024, "fs": "xfs", "mountpoint": "/tmp", "fsoptions": "nodev,nosuid,noexec"},
    {"size": 1024, "fs": "xfs", "mountpoint": "/var/tmp", "fsoptions": "nodev,nosuid,noexec"},
]

# Example partition schema for ANSSI-BP028 high profile
# This example requires at least 65GiB of disk space
# as it will also require swap space depending on memory size, /boot and /boot/efi space
PARTS_ANSSI = [
    {"size": True, "fs": "xfs", "mountpoint": "/"},
    {"size": 4096, "fs": "xfs", "mountpoint": "/usr", "fsoptions": "nodev"},
    {"size": 1024, "fs": "xfs", "mountpoint": "/opt", "fsoptions": "nodev,nosuid"},
    {"size": 1024, "fs": "xfs", "mountpoint": "/home", "fsoptions": "nodev"},
    {"size": 1024 , "fs": "xfs", "mountpoint": "/srv", "fsoptions": "nodev,nosuid"},        # When FTP/SFTP server is used
    {"size": 1024, "fs": "xfs", "mountpoint": "/tmp", "fsoptions": "nodev,nosuid,noexec"},
    {"size": True, "fs": "xfs", "mountpoint": "/var", "fsoptions": "nodev"},
    {"size": 1024, "fs": "xfs", "mountpoint": "/var/tmp", "fsoptions": "nodev,nosuid,noexec"},
    {"size": 1024, "fs": "xfs", "mountpoint": "/var/log", "fsoptions": "nodev,nosuid,noexec"},
    {"size": 1204, "fs": "xfs", "mountpoint": "/var/log/audit", "fsoptions": "nodev,nosuid,noexec"},
]

#################################################################
# DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING
#################################################################


import sys
import os
from typing import Tuple, Optional
import subprocess
import logging
from time import sleep


def dirty_cmd_runner(cmd: str) -> Tuple[int, str]:
    """
    QaD command runner
    """
    try:
        result = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
        return True, result.decode("utf-8")
    except subprocess.CalledProcessError as exc:
        result = exc.output
        return False, result
    

def get_kernel_arguments() -> dict:
    """
    Retrieve additional kernel arguments
    """
    def _get_kernel_argument(argument_name: str) -> Optional[str]:
        """
        Retrieve a kernel argument
        """

        cmd=rf"grep -oi '{argument_name}=\S*' /proc/cmdline | cut -d '=' -f 2"
        result, output = dirty_cmd_runner(cmd)
        if result:
            argument_value = output.split("\n")[0].strip()
            if argument_value is not "":
                logger.info(f"Found kernel argument {argument_name}={argument_value}")
                return argument_value
        return None
    
    argument_list = [
        "TARGET", "DISK_PATH"
    ]

    kernel_arguments = {}

    for argument in argument_list:
        argument_name = f"NPF_{argument}"
        argument_value = _get_kernel_argument(argument_name)
        if argument_value:
            kernel_arguments[argument] = argument_value
    return kernel_arguments


def is_gpt_system() -> bool:
    if DEV_MOCK:
        return True
    is_gpt = os.path.exists("/sys/firmware/efi")
    if is_gpt:
        logger.info("We're running on a UEFI machine")
    else:
        logger.info("We're running on a MBR machine")
    return is_gpt


def get_mem_size() -> int:
    """
    Returns memory size in MiB
    Balantly copied from https://stackoverflow.com/a/28161352/2635443
    """
    if DEV_MOCK:
        return 16384
    mem_bytes = os.sysconf("SC_PAGE_SIZE") * os.sysconf(
        "SC_PHYS_PAGES"
    )  # e.g. 4015976448
    mem_mib = int(mem_bytes / (1024.0**2))  # e.g. 16384
    logger.info(f"Current system has {mem_mib} MiB of memory")
    return mem_mib


def get_first_disk_path() -> list:
    """
    Return list of disks

    First, let's get the all the available disk names (ex "hda","sda","vda","nvme0n1")
    We might have a /dev/zram0 device which is considered as disk, so we need to filter vdX,sdX,hdX
    """
    if DEV_MOCK:
        return "/dev/vdx"
    # -I only include disk types 8 = hard disk, 252 = vdisk, 259 = nvme disk
    # -ndp -n no headers, -d only devices (no partitions), -p show full path
    # --output NAME,TYPE,HOTPLUG only output name and type
    # awk will filter by non hotplug devices and return a line per disk
    cmd = r"lsblk -I 8,252,259 -ndp --output HOTPLUG,NAME | awk '{ if ($1 == 0) { print $2 }}'"
    result, output = dirty_cmd_runner(cmd)
    if result:
        disk_path = output.split("\n")[0].strip()
        logger.info(f"First usable disk is {disk_path}")
        return disk_path

    logger.error(f"Cannot find usable disk: {output}")
    return False


def zero_disk(disk_path: str) -> bool:
    """
    Zero first disk bytes
    We need this instead of "cleanpart" directive since we're partitioning manually
    in order to have a custom partition schema
    We'll also wipe partitions and then the partition table
    """
    cmd = f"dd if=/dev/zero of={disk_path} bs=512 count=1 conv=notrunc; wipefs -a {disk_path}[0-9] -f; wipefs -a {disk_path} -f"
    logger.info(f"Zeroing disk {disk_path}")
    if DEV_MOCK:
        return True
    result, output = dirty_cmd_runner(cmd)
    if not result:
        logger.error(f"Could not zero disk {disk_path}:\n{output}")

    # blockdev -rereadpt works better than partprobe
    # see https://serverfault.com/questions/749258/how-to-reset-a-harddisk-delete-mbr-delete-partitions-from-the-command-line-w
    cmd = f"blockdev --rereadpt {disk_path}"
    logger.info("Reloading partition table")
    result, output = dirty_cmd_runner(cmd)
    if not result:
        logger.error(f"Could not reload partition table:\n{output}")
    return result


def init_disk(disk_path: str) -> bool:
    """
    Create disk label
    """
    if IS_GPT:
        label = "gpt"
    else:
        label = "msdos"
    cmd = f"parted -s {disk_path} mklabel {label}"
    logger.info(f"Making {disk_path} label")
    if DEV_MOCK:
        return True
    result, output = dirty_cmd_runner(cmd)
    if not result:
        logger.error(f"Could not make {disk_path} label: {output}")
    return result


def get_disk_size_mb(disk_path: str) -> int:
    """
    Get disk size in megabytes
    Use parted so we don't rely on other libs
    """
    if DEV_MOCK:
        return 61140  # 60GiB
    cmd = f"parted -s {disk_path} unit mib print | grep {disk_path} | awk '{{ print $3 }}' | cut -d'M' -f1"
    logger.info(f"Getting {disk_path} size")
    result, output = dirty_cmd_runner(cmd)
    if result:
        try:
            disk_size = int(output)
            logger.info(f"Disk {disk_path} size is {disk_size} MiB")
            return disk_size
        except Exception as exc:
            logger.error(f"Cannot get {disk_path} size: {exc}. Result was {output}")
            return False
    else:
        logger.error(f"Cannot get {disk_path} size. Result was {output}")
        return False


def get_allocated_space(partitions_schema: dict) -> int:
    # Let's fill ROOT part with anything we can
    allocated_space = 0
    for key, value in partitions_schema.items():
        if key == "lvm":
            for lvm_value in value.values():
                allocated_space += lvm_value["size"]
            continue
        allocated_space += partitions_schema[key]["size"]
    return allocated_space


def get_partition_schema(selected_partition_schema: dict) -> dict:
    """
    Return a valid partition schema dict to apply with sizes and mountpoints, generated from the selected partition schema dict
    """

    mem_size = get_mem_size()
    # Swap size will be at least 1446MiB since RHEL9 will require at least 3GiB (minus crash kernel) to install
    if mem_size > 16384:
        swap_size = mem_size
    else:
        swap_size = int(mem_size / 2)

    def create_partition_schema():
        if IS_GPT:
            partitions_schema = {
                "0": {"size": 600, "fs": "fat32", "mountpoint": "/boot/efi"},
                "1": {"size": 1024, "fs": "xfs", "mountpoint": "/boot"},
            }
        else:
            partitions_schema = {
                "0": {"size": 1024, "fs": "xfs", "mountpoint": "/boot"}
            }

        if LVM_ENABLED:
            partitions_schema["lvm"] = {
                "99": {"size": swap_size, "fs": "linux-swap", "mountpoint": "swap"}
            }
        else:
            partitions_schema["99"] = {
                "size": swap_size,
                "fs": "linux-swap",
                "mountpoint": "swap",
            }
        return partitions_schema

    def add_fixed_size_partitions(partitions_schema):
        """
        Add fixed size partitions to partition schema
        """
        for index, partition in enumerate(selected_partition_schema):
            # Shift index so we don't overwrite boot partition indexes
            index = str(int(index) + 10)
            if not isinstance(partition["size"], bool) and isinstance(
                partition["size"], int
            ):
                if LVM_ENABLED:
                    partitions_schema["lvm"][index] = {"size": partition["size"]}
                else:
                    partitions_schema[index] = {"size": partition["size"]}
        return partitions_schema

    def add_percent_size_partitions(partitions_schema):
        """
        Add percentage size partitions to partition schema
        """
        total_percentage = 0
        free_space = USABLE_DISK_SPACE - get_allocated_space(partitions_schema)
        for index, partition in enumerate(selected_partition_schema):
            index = str(int(index) + 10)
            if isinstance(partition["size"], str) and partition["size"][-1] == "%":
                percentage = int(partition["size"][:-1])
                total_percentage += percentage
                size = int(free_space * percentage / 100)
                if LVM_ENABLED:
                    partitions_schema["lvm"][index] = {"size": size}
                else:
                    partitions_schema[index] = {"size": size}
        if total_percentage > 100:
            msg = f"Percentages add up to more than 100%: {total_percentage}"
            logger.error(msg)
            return False
        return partitions_schema

    def get_number_of_filler_parts():
        """
        Determine the number of partitions that will fill the remaining space
        """
        filler_parts = 0
        for partition in selected_partition_schema:
            if isinstance(partition["size"], bool):
                filler_parts += 1
        return filler_parts

    def populate_partition_schema_with_other_data(partitions_schema):
        """
        Populate partition schema with FS and mountpoints
        """
        for index, partition in enumerate(selected_partition_schema):
            index = str(int(index + 10))
            for key, value in partition.items():
                if key == "size":
                    continue
                try:
                    if LVM_ENABLED:
                        partitions_schema["lvm"][index][key] = value
                    else:
                        partitions_schema[index][key] = value
                except KeyError:
                    pass
        return partitions_schema

    ## FN ENTRY POINT
    # MBR can have max 4 primary partitions, can't be bothered to code this in 2024
    if len(selected_partition_schema) >= 3 and not IS_GPT and not LVM_ENABLED:
        logger.error(
            "We cannot create more than 4 parts in MBR mode (boot + swap + two other partitions)...Didn't bother to code that path for prehistoric systems. Consider enabling LVM"
        )
        sys.exit(1)

    # Create a basic partition schema
    partitions_schema = create_partition_schema()
    # Add fixed size partitions to partition schema
    partitions_schema = add_fixed_size_partitions(partitions_schema)
    # Add percentage size partitions to partition schema
    partitions_schema = add_percent_size_partitions(partitions_schema)

    filler_parts = get_number_of_filler_parts()
    logger.info(f"Number of filler partitions: {filler_parts}")
    # Depending on how many partitions fill the remaining space, convert filler partitions to percentages
    if filler_parts > 1:
        for index, partition in enumerate(selected_partition_schema):
            # If we already have percentage partitions, we need to drop them now
            if isinstance(partition["size"], str) and partition["size"][-1] == "%":
                selected_partition_schema[index]["size"] = "already calculated"
            if isinstance(partition["size"], bool):
                selected_partition_schema[index]["size"] = str(int(100 / filler_parts)) + "%"
        # Now we have to do the percentage calculations again
        partitions_schema = add_percent_size_partitions(partitions_schema)
    else:
        # Else just fill remaining partition with all space
        free_space = USABLE_DISK_SPACE - get_allocated_space(partitions_schema)
        if free_space < 0:
            logger.error(
                "Cannot fill remaining space with partitions. Not enough space left. Is your partition schema valid ?"
            )
            logger.error(
                f"Usable disk space: {USABLE_DISK_SPACE}, schema allocated space: {get_allocated_space(partitions_schema)}"
            )
            sys.exit(1)
        for index, partition in enumerate(selected_partition_schema):
            index = str(int(index + 10))
            if isinstance(partition["size"], bool):
                if LVM_ENABLED:
                    partitions_schema["lvm"][index] = {"size": free_space}
                else:
                    partitions_schema[index] = {"size": free_space}
    partitions_schema = populate_partition_schema_with_other_data(partitions_schema)

    # Sort partition schema
    partitions_schema = dict(sorted(partitions_schema.items()))
    if LVM_ENABLED:
        partitions_schema["lvm"] = dict(sorted(partitions_schema["lvm"].items()))
    return partitions_schema


def validate_partition_schema(partitions: dict) -> bool:
    """
    Check if our partition schema doesn't exceed disk size
    """
    total_size = 0
    for partition in partitions.keys():
        if partition == "lvm":
            for lvm_partition in partitions["lvm"].keys():
                for key, value in partitions["lvm"][lvm_partition].items():
                    if key == "size":
                        total_size += value
                msg = f"LVMPART {lvm_partition}: {partitions[partition][lvm_partition]}"
                logger.info(msg)
            continue
        for key, value in partitions[partition].items():
            if key == "size":
                total_size += value
        msg = f"PART {partition}: {partitions[partition]}"
        logger.info(msg)

    if total_size > USABLE_DISK_SPACE:
        msg = f"Total required partition space {total_size} exceeds disk space {USABLE_DISK_SPACE}"
        logger.error(msg)
        return False
    logger.info(f"Total allocated disk size: {total_size} / {USABLE_DISK_SPACE}")
    return True


def prepare_non_kickstart_partitions(partitions_schema: dict) -> bool:
    """
    When partitions don't have a mountpoint, we'll have to create the FS ourselves
    If partition has a xfs label, let's create it
    """

    def prepare_non_kickstart_partition(part_properties, part_number):
        if part_properties["mountpoint"] is None:
            logger.info(
                f"Partition {DISK_PATH}{part_number} has no mountpoint and won't be handled by kickstart. Going to create it FS {part_properties['fs']}"
            )
            cmd = f'mkfs.{part_properties["fs"]} -f {DISK_PATH}{part_number}'
            if DEV_MOCK:
                result = True
            else:
                result, output = dirty_cmd_runner(cmd)
            if not result:
                logger.error(f"Command {cmd} failed: {output}")
                return False

        if "label" in part_properties.keys():
            if part_properties["fs"] == "xfs":
                cmd = (
                    f'xfs_admin -L {part_properties["label"]} {DISK_PATH}{part_number}'
                )
            elif part_properties["fs"].lower()[:3] == "ext":
                cmd = f'tune2fs -L {part_properties["label"]} {DISK_PATH}{part_number}'
            else:
                logger.error(
                    f'Setting label on FS {part_properties["fs"]} is not implemented'
                )
                return False
            logger.info(
                f'Setting up partition {DISK_PATH}{part_number} FS {part_properties["fs"]} with label {part_properties["label"]}'
            )
            if DEV_MOCK:
                result = True
            else:
                result, output = dirty_cmd_runner(cmd)
            if not result:
                logger.error(f"Command {cmd} failed: {output}")
                return False
        return True

    part_number = 1
    for part_index, part_properties in partitions_schema.items():
        if part_index == "lvm":
            for lvm_part_properties in partitions_schema["lvm"].values():
                prepare_non_kickstart_partition(lvm_part_properties, part_number)
        else:
            prepare_non_kickstart_partition(part_properties, part_number)
        part_number += 1
    return True


def write_kickstart_partitions_file(partitions_schema: dict) -> bool:
    part_number = 1
    kickstart = ""
    for key, part_properties in partitions_schema.items():
        if key == "lvm":
            kickstart += f"part pv.0 --fstype lvmpv --grow --size=1\n"
            kickstart += f"volgroup {VG_NAME} pv.0 --pesize={PE_SIZE}\n"
            part_number += 1
            continue
        if part_properties["mountpoint"]:
            # parted wants "linux-swap" whereas kickstart needs "swap" as fstype
            if part_properties["fs"] == "linux-swap":
                part_properties["fs"] = "swap"
            try:
                fsoptions = f' --fsoptions={part_properties["fsoptions"]}'
            except KeyError:
                # Don't bother if partition doesn't have fsoptions
                fsoptions = ""
            kickstart += f'part {part_properties["mountpoint"]} --fstype {part_properties["fs"]} --onpart={DISK_PATH}{part_number}{fsoptions}\n'
        part_number += 1

    if LVM_ENABLED:
        for part_properties in partitions_schema["lvm"].values():
            if part_properties["mountpoint"]:
                # parted wants "linux-swap" whereas kickstart needs "swap" as fstype
                if part_properties["fs"] == "linux-swap":
                    part_properties["fs"] = "swap"
                try:
                    fsoptions = f' --fsoptions={part_properties["fsoptions"]}'
                except KeyError:
                    # Don't bother if partition doesn't have fsoptions
                    fsoptions = ""
                if part_properties["mountpoint"] == "/":
                    name = "root"
                else:
                    name = part_properties["mountpoint"].replace("/", "")
                kickstart += f'logvol {part_properties["mountpoint"]} --vgname {VG_NAME} --fstype {part_properties["fs"]} --name={name}{fsoptions} --size={part_properties["size"]}\n'
            part_number += 1
    try:
        with open("/tmp/partitions", "w", encoding="utf-8") as fp:
            fp.write(kickstart)
    except OSError as exc:
        logger.error(f"Cannot write /tmp/partitions: {exc}")
        return False
    return True


def execute_parted_commands(partitions_schema: dict) -> bool:
    """
    We need to manually run partitioning commands since we're not using anaconda to create partitions
    This allows us to have non mounted partitions, eg stateful partitions for readonly-root setups

    Unless specified, parted deals in megabytes
    """
    parted_commands = []
    partition_start = 0
    for part_index, part_properties in partitions_schema.items():
        if partition_start == 0:
            # Properly align first partition to 1MiB for SSD disks
            partition_start = "1024KiB"
            partition_end = 1 + part_properties["size"]

        elif part_index == "lvm":
            # Assume we only have one big lvm partition, don't bother with others
            # Also, we don't need to create it via parted, since this is automagically done by anaconda
            continue

        else:  # Non LVM partitions handling
            partition_start = partition_end
            partition_end = partition_start + part_properties["size"]
        parted_commands.append(
            f'parted -a optimal -s {DISK_PATH} mkpart primary {part_properties["fs"]} {partition_start} {partition_end}'
        )
    for parted_command in parted_commands:
        if DEV_MOCK:
            logger.info(f"Would execute command {parted_command}")
            result = True
        else:
            logger.info(f"Executing command {parted_command}")
            result, output = dirty_cmd_runner(parted_command)
        if not result:
            logger.error(f"Command failed: {output}")
            return False
    # Arbitrary sleep command
    sleep(3)
    return True


def setup_package_lists() -> bool:
    logger.info("Setting up package ignore lists")
    package_ignore_virt_list = [
        "linux-firmware",
        "a*-firmware",
        "i*-firmware",
        "lib*firmware",
        "n*firmware",
        "plymouth",
        "pipewire",
    ]

    package_require_virt_list = [
        "qemu-guest-agent"
    ]

    package_add_physical_list = ["lm_sensors", "smartmontools"]
    try:
        with open("/tmp/packages", "w", encoding="utf-8") as fp:
            if IS_VIRTUAL and REMOVE_VIRTUAL_PACKAGES:
                for package in package_require_virt_list:
                    fp.write(f"{package}\n")
                for package in package_ignore_virt_list:
                    fp.write(f"-{package}\n")
            elif not IS_VIRTUAL and ADD_PHYSICAL_PACKAGES:
                for package in package_add_physical_list:
                    fp.write(f"{package}\n")
            else:
                fp.write("\n")
        return True
    except OSError as exc:
        logger.error(f"Cannot create /tmp/packages file: {exc}")
        return False


def setup_network(network: str) -> bool:
    """
    Setup network using ip and mask, optional gateway and nameserver
    """
    logger.info("Setting up network")
    try:
        ip, mask, gw, ns = network.split(':')
    except Exception:
        try:
            ip, mask, gw = network.split(':')
            ns = gw
        except Exception:
            try:
                ip, mask = network.split(':')
            except Exception:
                ip = mask = gw = ns = None
    
    if ip and mask:
        logger.info(f"Configuring network with {ip}/{mask} gw {gw} ns {ns}")
    elif network == "dhcp":
        logger.info(f"Configuring network with dhcp")
    else:
        logger.info(f"Not configuring network")
    
    try:
        with open("/tmp/network", "w", encoding="utf-8") as fp:
            if ip and mask:
                network_string = f"network --bootproto static --ip {ip} --netmask {mask}"
                if gw:
                    network_string += f" --gateway {gw}"
                if ns:
                    if ',' in ns:
                        ns = ns.split(',')
                    else:
                        ns = [ns]
                    for ns_entry in ns:
                        network_string += f" --nameserver {ns_entry}"
                network_string += " --activate --onboot=yes\n"
                fp.write(network_string)
            elif network == "dhcp":
                fp.write(f"network  --bootproto=dhcp --activate --onboot=yes\n")
            else:
                fp.write("\n")
        return True
    except OSError as exc:
        logger.error(f"Cannot create /tmp/network file: {exc}")
        return False


def setup_hostname(hostname: str = None) -> bool:
    logger.info("Setting up hostname")
    try:
        with open("/tmp/hostname", "w", encoding="utf-8") as fp:
            fp.write(f"network --hostname={hostname}\n")
        return True
    except OSError as exc:
        logger.error(f"Cannot create /tmp/hostname file: {exc}")
        return False


def setup_users() -> bool:
    """
    Root password non encrypted version
    rootpw MyNonEncryptedPassword
    user --name=user --password=MyNonEncryptedUserPassword

    Or password with encryption
    password SHA-512 with openssl passwd -6 (used here)
    password SHA-256 with openssl passwd -5
    password MD5 (don't) with openssl passwd -1
    rootpw --isencrypted <somestring>
    user --name user --isencrypted --password=<somestring>
    """
    logger.info("Setting up password file")
    if IS_ROOT_PASSWORD_CRYPTED:
        is_crypted = "--iscrypted "
    else:
        is_crypted = ""
    root = rf"rootpw {is_crypted}{ROOT_PASSWORD}"
    if IS_USER_PASSWORD_CRYPTED:
        is_crypted = "--iscrypted "
    else:
        is_crypted = ""
    user = rf"user --name {USER_NAME} {is_crypted}--password={USER_PASSWORD}"

    try:
        with open("/tmp/users", "w", encoding="utf-8") as fp:
            fp.write(f"{root}\n{user}\n")
        return True
    except OSError as exc:
        logger.error(f"Cannot create /tmp/users file: {exc}")
        return False


######################
# SCRIPT ENTRY POINT #
######################
# Set DEV_MOCK to True to avoid executing any command and just create the required files for anaconda
# Of course, we won't be able to get disk size and memory size
DEV_MOCK = False

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.FileHandler("/tmp/prescript.log"), logging.StreamHandler()],
)
logger = logging.getLogger()

if DEV_MOCK:
    logger.info(
        "Running in DEV_MOCK mode. Nothing will be executed or actually done here."
    )

TARGET = TARGET.lower()
if DISK_PATH != "%TARGET_BLOCK_DEVICE%":
    DISK_PATH = get_first_disk_path()

# Supersede settings
kernel_arguments = get_kernel_arguments()
for argument_name, argument_value in kernel_arguments.items():
    logger.info(f"Superseding value {argument_name}={argument_value}")
    # Special case when Superseding passwords
    if argument_name == "ROOT_PASSWORD":
        IS_ROOT_PASSWORD_CRYPTED = False
    if argument_name == "USER_PASSWORD":
        IS_USER_PASSWORD_CRYPTED = False
    globals()[argument_name] = argument_value


if TARGET in ["stateless", "hv-stateless"] and LVM_ENABLED:
    logger.info("Stateless machines are not compatible with LVM. Disabling LVM.")
    LVM_ENABLED = False

PARTS = None
if TARGET == "hv":
    PARTS = PARTS_HV
elif TARGET == "hv-stateless":
    PARTS = PARTS_HV_STATELESS
elif TARGET == "stateless":
    PARTS = PARTS_STATELSSS
elif TARGET == "generic":
    PARTS = PARTS_GENERIC
elif TARGET == "web":
    PARTS = PARTS_WEB
elif TARGET == "anssi":
    PARTS = PARTS_ANSSI
else:
    logger.error(f"Bad target given: {TARGET}")
    sys.exit(222)
logger.info(f"Running script for target: {TARGET}")

IS_VIRTUAL, _ = dirty_cmd_runner("lsmod | grep virtio > /dev/null 2>&1")
if not IS_VIRTUAL:
    IS_VIRTUAL, _ = dirty_cmd_runner(
        r'dmidecode | grep -i "kvm\|qemu\|vmware\|hyper-v\|virtualbox\|innotek\|Manufacturer: Red Hat"'
    )
IS_GPT = is_gpt_system()

if not DISK_PATH:
    errno=1
    logger.critical(f"Error {errno}")
    sys.exit(errno)
if not zero_disk(DISK_PATH):
    errno=2
    logger.critical(f"Error {errno}")
    sys.exit(errno)
if not init_disk(DISK_PATH):
    errno=3
    logger.critical(f"Error {errno}")
    sys.exit(errno)
disk_space_mb = get_disk_size_mb(DISK_PATH)
if not disk_space_mb:
    errno=4
    logger.critical(f"Error {errno}")
    sys.exit(errno)
USABLE_DISK_SPACE = disk_space_mb - 2  # keep 1KiB empty at beginning and 1MiB at end
if not IS_VIRTUAL and REDUCE_PHYSICAL_DISK_SPACE:
    # Let's reserve 5% of disk space on physical machine
    REAL_USABLE_DISK_SPACE = USABLE_DISK_SPACE
    USABLE_DISK_SPACE = int(
        USABLE_DISK_SPACE * (100 - REDUCE_PHYSICAL_DISK_SPACE) / 100
    )
    logger.info(
        f"Reducing usable disk space by {REDUCE_PHYSICAL_DISK_SPACE}% from {REAL_USABLE_DISK_SPACE} to {USABLE_DISK_SPACE} since we deal with physical disks"
    )

partitions_schema = get_partition_schema(PARTS)
if not partitions_schema:
    errno=5
    logger.critical(f"Error {errno}")
    sys.exit(errno)
if not validate_partition_schema(partitions_schema):
    errno=6
    logger.critical(f"Error {errno}")
    sys.exit(errno)
if not execute_parted_commands(partitions_schema):
    errno=7
    logger.critical(f"Error {errno}")
    sys.exit(errno)
if not prepare_non_kickstart_partitions(partitions_schema):
    errno=8
    logger.critical(f"Error {errno}")
    sys.exit(errno)
if not write_kickstart_partitions_file(partitions_schema):
    errno=9
    logger.critical(f"Error {errno}")
    sys.exit(errno)

logger.info("partitioning done. Please use '%include /tmp/partitions")

if not setup_package_lists():
    errno=10
    logger.critical(f"Error {errno}")
    sys.exit(errno)

if not setup_hostname(HOSTNAME):
    errno=20
    logger.critical(f"Error {errno}")
    sys.exit(errno)

if not setup_network(NETWORK):
    errno=21
    logger.critical(f"Error {errno}")
    sys.exit(errno)

if not setup_users():
    errno=22
    logger.critical(f"Error {errno}")
    sys.exit(errno)


