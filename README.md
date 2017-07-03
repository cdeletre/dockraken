# dockraken
A dockerized version of A5/1 kraken tool (server mode)

## Important note
This repository and the procedure detailed here are provided as is and for educational purposes only and **must not be used with bad intentions**.

## Clone repository
```
cd $HOME
mkdir devel
cd devel
git clone https://github.com/cdeletre/dockraken.git
```

## Prepare A5/1 rainbow tables

> **Disclaimer**: the steps described here require you to deeply care of what you are doing ! You may broke you system and/or lose data. You have been warned...

Of course you need the rainbow tables files. I let you google for it. You'll need 1.6 TB of storage.

Then you need to import and index the tables on dedicated disk(s) (not the same as the one where you downloaded the files). You can perform all the operation as root or with sudo but I prefer to do it a little be less dirty.

The procedure detailed here assumes that we are using ```/dev/sdb``` and ```/dev/sdc``` as dedicated disks (empty partition table) and that rainbow tables files are stored on /dev/sdd1 which is mount on ```/mnt/rainbow-tables```.

### Configure the dedicated disks

First add a udev rule to be the owner of the two dedicated disks (by default it's root:disk) by creating ```/etc/udev/rules.d/10-a51disk-cde.rules```:

```
KERNEL=="sdb", OWNER="YOUR_USERNAME", GROUP="disk"
KERNEL=="sdc", OWNER="YOUR_USERNAME", GROUP="disk"
```

After a reboot check that you now own sdb and sdc.

```
$ ls -l /dev/sd[bc]
brw------- 1 YOUR_USERNAME disk 8, 16 Jul  1 17:55 /dev/sdb
brw------- 1 YOUR_USERNAME disk 8, 32 Jul  1 20:31 /dev/sdc
```

### Import and index rainbow tables
Unpack on the host the kraken archive

```
cd $HOME/devel/dockraken
tar -xzf ./ressources/kraken.tgz
```

Edit ```./kraken/indexes/tables.conf``` and setup the two disk entries to spread 20 tables on each:

```
#Devices:  dev/node max_tables
Device: /dev/sdb 20
Device: /dev/sdc 20

#Tables: dev id(advance) offset
```

Then run the Behemoth script that will import and index the rainbow tables. It requires 3 GB of freespace in the current directory and may tale a while depending on you disk speed.
 	
```
cd $HOME/devel/dockraken/kraken/indexes
./Behemoth.py /mnt/rainbow-tables/
```

Once done 40 ```.idx``` files should be present in the directory and tables.conf should contain additionnal lines like:

```
...
Table: 0 188 0
...
```

## Build docker image
```
cd $HOME/devel/dockraken
docker build -t dockraken .
```

## Start docker image
The following command start the image in background, kraken will load the 3 GB index files (it takes few seconds)

```
docker run -d -h kraken-01 \
-p 127.0.0.1:1982:1982 \
-v $HOME/devel/dockraken/kraken/indexes:/home/kraken/tools/indexes:ro \
--device /dev/sdb:/dev/sdb --device /dev/sdc:/dev/sdc \
dockraken
```

Once the kraken server is ready you can connect from host with ```telnet 127.0.0.1 1982``` and try to perform a crack test:

```
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
crack 001101110011000000001000001100011000100110110110011011010011110001101010100100101111111010111100000110101001101011
Found de6bb5e60617f95c @ 12  #0  (table:340)
Found 6fb7905579e28bfc @ 23  #0  (table:372)
crack #0 took 129621 msec
```
### Additionnal options
You can change the username and timezone in the container by setting environment  variable TZ and USERNAME when running the image:

```
docker run -d -h kraken-01 \
-e TZ="Africa/Ouagadougou"
-e USERNAME="myusername"
-p 127.0.0.1:1982:1982 \
-v $HOME/devel/dockraken/kraken/indexes:/home/kraken/tools/indexes:ro \
--device /dev/sdb:/dev/sdb --device /dev/sdc:/dev/sdc \
dockraken
```