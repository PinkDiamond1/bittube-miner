# Compile **bittube-miner** for FreeBSD

## Install Dependencies

*Note: This guide is tested for FreeBSD 11.0-RELEASE*

From the root shell, run the following commands:

    pkg install git libmicrohttpd hwloc cmake

Type 'y' and hit enter to proceed with installing the packages.

    git clone https://github.com/fireice-uk/bittube-miner.git
    mkdir bittube-miner/build
    cd bittube-miner/build
    cmake ..
    make install

Now you have the binary located at "bin/bittube-miner" and the needed shared libraries.
