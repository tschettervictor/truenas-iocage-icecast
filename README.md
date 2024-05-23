# truenas-iocage-icecast
Script to create an iocage jail on TrueNAS with icecast
This script will create an iocage jail on TrueNAS CORE 13.0 with the latest release of icecast pkg. It will configure the jail to store the config outside the jail, so it will not be lost in the event you need to rebuild the jail.

## Status
This script will work with TrueNAS CORE 13

## Usage

### Prerequisites

You will need to create
- 1 Dataset named `icecast` in your pool.
e.g. `/mnt/mypool/apps/icecast`

If this is not present, a directory `/icecast` will be created in `$POOL_PATH`. You will want to create the dataset, otherwise a directory will just be created. Datasets make it easy to do snapshots etc...

### Installation
Download the repository to a convenient directory on your TrueNAS system by changing to that directory and running `git clone https://github.com/tschettervictor/truenas-iocage-icecast`.  Then change into the new `truenas-iocage-icecast` directory and create a file called `icecast-config` with your favorite text editor.  In its minimal form, it would look like this:
```
JAIL_IP="192.168.1.199"
DEFAULT_GW_IP="192.168.1.1"
POOL_PATH="/mnt/mypool/apps"
```
Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory.  The mandatory options are:

* JAIL_IP is the IP address for your jail.  You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24).  If not specified, the netmask defaults to 24 bits.  Values of less than 8 bits or more than 30 bits are invalid.
* DEFAULT_GW_IP is the address for your default gateway
* POOL_PATH is the path for your data pool.
 
In addition, there are some other options which have sensible defaults, but can be adjusted if needed.  These are:

* JAIL_NAME: The name of the jail, defaults to "icecast"
* INTERFACE: The network interface to use for the jail.  Defaults to `vnet0`.
* JAIL_INTERFACES: Defaults to `vnet0:bridge0`, but you can use this option to select a different network bridge if desired.  This is an advanced option; you're on your own here.
* VNET: Whether to use the iocage virtual network stack.  Defaults to `on`.

### Execution
Once you've downloaded the script and prepared the configuration file, run this script (`script icecast.log ./icecast-jail.sh`).  The script will run for maybe a minute.  When it finishes, your jail will be created, Icecast will be installed, and you can edit the config file to suit your needs.

### Notes
* The config file "icecast.xml" is located in `$POOL_PATH/icecast`
* Icecast will not run as root. Two things need to be manually done for it to run.
  1. Uncomment the "changeowner" section at the end of the "icecast.xml" file and change the user to "www" or some other user
  2. Change the owner of "/var/log/icecast" to be the user that icecast will run as
