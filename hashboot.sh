#!/bin/sh
#Hashes all files in /boot to check them during early boot
#Exit codes: 0 = success, 1 = wrong usage, 2 = not root, 3 = no hasher found,
#4 = checksum mismatch, 5 = write error

VERSION="0.5"
PATH="/bin:/usr/bin:/sbin:/usr/sbin"

DIGEST_FILE="/var/lib/hashboot.digest"
LOG_FILE="/tmp/hashboot.log"
BACKUP_FILE="/var/cache/boot-backup.tar.gz"
HASHER=""
BOOT_MOUNTED=""


#Umount /boot if we mounted it, exit with given exit code
function die
{
	if [ ! -z ${BOOT_MOUNTED} ]
	then
		umount /boot
	fi

	exit ${1}
}

function recover
{
	echo "Restoring files from backup... (type yes or no for each file)"
		
	#For each failed file: ask if it should be recovered from backup
	for file in $(cut -d: -f1 ${LOG_FILE})
	do
		tar -xzpPvwf ${BACKUP_FILE} ${file}
		[ $? != 0 ] && echo "Error restoring ${file} from backup, continuing"
	done
}

#If we're not root: exit
if [ ${UID} -ne 0 ]
then
	echo "You have to be root" >&2
	die 2
fi

#Try different hashers, use the most secure
HASHER=$(/usr/bin/which --skip-dot sha512sum 2> /dev/null)
test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot sha384sum 2> /dev/null)
test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot sha256sum 2> /dev/null)
test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot sha224sum 2> /dev/null)
#It gets insecure below here, but better than nothing?
test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot sha1sum 2> /dev/null)
test -z ${HASHER} && HASHER=$(/usr/bin/which --skip-dot md5sum 2> /dev/null)

#If we found no hasher: exit
if [ -z ${HASHER} ]
then
	echo "No hash calculator found" >&2
	die 3
fi

#If /boot is in fstab but not mounted: mount, mark as mounted
if grep -q '/boot.*noauto' /etc/fstab && ! grep -q /boot /etc/mtab
then
	mount /boot
	BOOT_MOUNTED=1
fi

if [ "${1}" == "index" ]
then
	#Write header
	echo "#hashboot ${VERSION} - Algorithm: $(basename ${HASHER})" > ${DIGEST_FILE}
	#Write hashes of all regular files to ${DIGEST_FILE}
	find /boot -type f -exec ${HASHER} --binary {} >> ${DIGEST_FILE} +
	if [ $? == 0 ]
	then
		echo "List of hashes written to ${DIGEST_FILE}"
	else
		echo "Error writing ${DIGEST_FILE}" >&2
		die 5
	fi

	#Backup of good files
	tar -czpPf ${BACKUP_FILE} /boot
	if [ $? == 0 ]
	then
		echo "Backup written to ${BACKUP_FILE}"
	else
		echo "Error writing ${BACKUP_FILE}" >&2
		die 5
	fi
elif [ "${1}" == "check" ]
then
	if $(${HASHER} --check --warn --quiet --strict ${DIGEST_FILE} > ${LOG_FILE})
	then
		die 0
	else
		echo "    !! TIME TO PANIK: AT LEAST 1 FILE WAS MODIFIED !!"
		die 4
	fi
elif [ "${1}" == "recover" ]
then
	recover
else
	echo "Usage: ${0} index|check|recover" >&2
	die 1
fi

die 0
