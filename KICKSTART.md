# Creating A Kickstart with IDE.device
This is a quick guide on how to create a ROMable kickstart with the IDE.device to allow auto booting.

# Warning
This design has not been compliance tested and will not be. It may cause damage to your A500. I take no responsibility for this. I accept no responsibility for any damage to any equipment that results from the use of this design and its components. IT IS ENTIRELY AT YOUR OWN RISK!

# Copyright
This guide assumes you have a legal copy of a suitable kickstart ROM. I use kickstart 3.1, however the sames / similar steps apply for different versions.

# Tools
These tools and devices are required;

- https://github.com/cnvogelg/amitools
- https://gitlab.com/MHeinrichs/AIDE/-/blob/master/device/new-version/IDE-DEVICE2.59.zip

# Reference material
Here is a guide to using romtool which is a part of the amitools package. Follow the installation steps referred to in the amitools package to get the installation running. 

- https://amitools.readthedocs.io/en/latest/tools/romtool.html

# Steps
Use the following command to _split_ your ROM image. Note, paths will vary for your setup so use this only as a guide;

`python.exe romtool.py split kick31.rom -o .`

This will create a folder named after the ROM image and fill folder with the split ROM modules. To make room for the `IDE.device` and `BOOTIDE.device` you will need to _remove_ the `SCSI.device` for the created `INDEX.txt` file.

`python.exe romtool.py build -o New31.rom -t kick -s 512 ide.device bootide.device -r 40.258`

It is a good idea to use the -r command to bump the ROM REV version to the version of the `IDE.device` you are used, im my case I changed this to 40.258.

Custom kickstart version as tested with WinUAE;

![Kickstart version](/Images/customKickstart.png)