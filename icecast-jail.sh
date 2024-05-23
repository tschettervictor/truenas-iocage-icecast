#!/bin/sh
# Build an iocage jail under TrueNAS 13.0 and install Icecast
# git clone https://github.com/tschettervictor/truenas-iocage-icecast

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

#####
#
# General configuration
#
#####

# Initialize defaults
JAIL_IP=""
JAIL_INTERFACES=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
POOL_PATH=""
JAIL_NAME="icecast"
CONFIG_NAME="icecast-config"

# Check for icecast-config and set configuration
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"

JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)
RELEASE=$(freebsd-version | cut -d - -f -1)"-RELEASE"
# If release is 13.1-RELEASE, change to 13.2-RELEASE
if [ "${RELEASE}" = "13.1-RELEASE" ]; then
  RELEASE="13.2-RELEASE"
fi 

#####
#
# Input/Config Sanity checks
#
#####

# Check that necessary variables were set by uptimekuma-config
if [ -z "${JAIL_IP}" ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${JAIL_INTERFACES}" ]; then
  echo 'JAIL_INTERFACES not set, defaulting to: vnet0:bridge0'
JAIL_INTERFACES="vnet0:bridge0"
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z "${POOL_PATH}" ]; then
  echo 'Configuration error: POOL_PATH must be set'
  exit 1
fi

# Extract IP and netmask, sanity check netmask
IP=$(echo ${JAIL_IP} | cut -f1 -d/)
NETMASK=$(echo ${JAIL_IP} | cut -f2 -d/)
if [ "${NETMASK}" = "${IP}" ]
then
  NETMASK="24"
fi
if [ "${NETMASK}" -lt 8 ] || [ "${NETMASK}" -gt 30 ]
then
  NETMASK="24"
fi

#####
#
# Jail Creation
#
#####

# Create the jail and install previously listed packages
if ! iocage create --name "${JAIL_NAME}" -r "${RELEASE}" interfaces="${JAIL_INTERFACES}" ip4_addr="${INTERFACE}|${IP}/${NETMASK}" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"
then
	echo "Failed to create jail"
	exit 1
fi

#####
#
# Directory Creation and Mounting
#
#####

# Create and mount directories
mkdir -p "${POOL_PATH}"/icecast
iocage exec "${JAIL_NAME}" mkdir -p /usr/local/etc/icecast
iocage exec "${JAIL_NAME}" mkdir -p /var/log/icecast
iocage fstab -a "${JAIL_NAME}" "${POOL_PATH}"/icecast /usr/local/etc/icecast nullfs rw 0 0

#####
#
# Icecast Installation 
#
#####

if ! iocage exec "${JAIL_NAME}" pkg install -y icecast
then
	echo "Failed to create jail"
	exit 1
fi
if [ -z "${POOL_PATH}/icecast" ]; then
iocage exec "${JAIL_NAME}" cp /usr/local/etc/icecast.xml* /usr/local/etc/icecast/
fi
iocage exec "${JAIL_NAME}" sysrc icecast_config="/usr/local/etc/icecast/icecast.xml"
iocage exec "${JAIL_NAME}" sysrc icecast_enable="YES"

# Restart
iocage restart "${JAIL_NAME}"

echo "---------------"
echo "Installation Complete!"
echo "---------------"
echo "Icecast will not run as root. Change the user to "www" or some other user at the end of the icecast.xml file."
echo "Don't forget to uncomment the "changeowner" section, and change the owner of "/var/log/icecast" to the user that icecast will run as."
echo "---------------"
