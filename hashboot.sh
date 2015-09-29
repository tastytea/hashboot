#!/bin/sh
#Hashes all files in /boot to check them during early boot
#Exit codes: 0 = success, 1 = checksum mbr mismatch, 2 = checksum /boot mismatch,
#3 = checksum mbr/boot mismatch, 4 = not root, 5 = no hasher found, 6 = wrong usage,
#7 = write error, 8 = dd error, 9 config file error

VERSION="0.7.2"
PATH="/bin:/usr/bin:/sbin:/usr/sbin:${PATH}"

DIGEST_FILE="/var/lib/hashboot.digest"
LOG_FILE="/tmp/hashboot.log"
MBR_DEVICE="/dev/sda"
MBR_TMP="/tmp/mbr"
BACKUP_FILE="/var/cache/boot-backup.tar.gz"
HASHER=""
BOOT_MOUNTED=0
CONFIG_FILE="/etc/hashboot.cfg"


#Umount /boot if we mounted it, exit with given exit code
function die
{
    if [ ${BOOT_MOUNTED} -gt 0 ]
    then
        umount /boot
    fi

    [ -z "${2}" ] || echo "${2}" >&2
    exit ${1}
}

#If we're not root: exit
if [ ${UID} -ne 0 ]
then
    die 4 "You have to be root"
fi

#If /boot is in fstab but not mounted: mount, mark as mounted
if grep -q '/boot.*noauto' /etc/fstab && ! grep -q /boot /etc/mtab
then
    mount /boot
    BOOT_MOUNTED=1
fi


if [ "${1}" == "index" ]
then
    #Try different hashers, use the most secure
    HASHER=$(/usr/bin/which --skip-dot sha512sum 2> /dev/null)
    test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot sha384sum 2> /dev/null)
    test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot sha256sum 2> /dev/null)
    test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot sha224sum 2> /dev/null)
    #It gets insecure below here, but better than nothing?
    test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot sha1sum 2> /dev/null)
    test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot md5sum 2> /dev/null)
    #If we found no hasher: exit
    [ -z ${HASHER} ] && die 5 "No hash calculator found"

    #Look for config file and set ${MBR_DEVICE}.
    if [ -f ${CONFIG_FILE} ]
    then
        MBR_DEVICE=$(grep ^mbr_device ${CONFIG_FILE} | awk '{print $3}')
        [ $? != 0 ] && die 9 "Error reading config file"
    #If not found, create one and ask for ${MBR_DEVICE}
    else
        echo -n "Which device contains the MBR? [/dev/sda] "
        read -r MBR_DEVICE
        [ -z "${MBR_DEVICE}" ] && MBR_DEVICE="/dev/sda"
        echo "#Device with the MBR on it" > ${CONFIG_FILE}
        echo "mbr_device = ${MBR_DEVICE}" >> ${CONFIG_FILE}
    fi

    #Write header
    echo "#hashboot ${VERSION} - Algorithm: $(basename ${HASHER})" > ${DIGEST_FILE}
    #Write MBR of MBR_DEVICE to ${DIGEST_FILE}
    dd if=${MBR_DEVICE} of=${MBR_TMP} bs=1M count=1 status=none || die 8
    #Write hashes of all regular files to ${DIGEST_FILE}
    ${HASHER} ${MBR_TMP} >> ${DIGEST_FILE}
    find /boot -type f -exec ${HASHER} --binary {} >> ${DIGEST_FILE} +
    if [ $? == 0 ]
    then
        echo "List of hashes written to ${DIGEST_FILE}"
    else
        die 7 "Error writing ${DIGEST_FILE}"
    fi

    #Backup of good files
    tar -czpPf ${BACKUP_FILE} ${MBR_TMP} /boot ${DIGEST_FILE}
    if [ $? == 0 ]
    then
        echo "Backup written to ${BACKUP_FILE}"
    else
        die 7 "Error writing ${BACKUP_FILE}"
    fi
elif [ "${1}" == "check" ]
then
    COUNTER=0
    HASHER=$(head -n1 ${DIGEST_FILE} | awk '{print $5}')

    dd if=${MBR_DEVICE} of=${MBR_TMP} bs=1M count=1 status=none  || die 8
    if $(grep ${MBR_TMP} ${DIGEST_FILE} | ${HASHER} --check --warn --quiet --strict > ${LOG_FILE})
    then
        echo "MBR ok"
    else
        echo "    !! TIME TO PANIK: MBR WAS MODIFIED !!"
        COUNTER=$((COUNTER + 1))
    fi
    if $(grep -v ${MBR_TMP} ${DIGEST_FILE} | ${HASHER} --check --warn --quiet --strict >> ${LOG_FILE})
    then
        echo "/boot ok"
    else
        echo "    !! TIME TO PANIK: AT LEAST 1 FILE WAS MODIFIED !!"
        COUNTER=$((COUNTER + 2))
        die $COUNTER
    fi
elif [ "${1}" == "recover" ]
then
    echo "Restoring files from backup... (type yes or no for each file)"

    #For each failed file: ask if it should be recovered from backup
    for file in $(cut -d: -f1 ${LOG_FILE})
    do
        tar -xzpPvwf ${BACKUP_FILE} ${file}
        [ $? != 0 ] && echo "Error restoring ${file} from backup, continuing" >&2
        #If the MBR is to be recovered, copy to ${MBR_DEVICE}
        if [ "${file}" == ${MBR_TMP} ]
        then
            cp ${MBR_TMP} ${MBR_DEVICE}
            [ $? != 0 ] && echo "Error restoring MBR from backup, continuing" >&2
        fi
    done
else
    die 6 "Usage: ${0} index|check|recover"
fi

die 0
