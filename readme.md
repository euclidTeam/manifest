# euclidOS

<a href="#"><img src="Banner.png" /></a>


 Getting Started
---------------
To get started with the EuclidOS sources, you'll need to get
familiar with [Git and Repo](https://source.android.com/setup/build/downloading).

 To initialize your local repository, use command:

```bash
repo init -u https://github.com/euclidTeam/manifest.git -b 14 --git-lfs
```

Then sync up:

```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
```

Building the System
-------------------
 Initialize the ROM environment with the envsetup.sh script.

```bash
. build/envsetup.sh
```

Lunch your device after cloning all device sources if needed.

```bash
lunch euclid_$device-userdebug
```

Start compilation

```bash
m euclid
```
