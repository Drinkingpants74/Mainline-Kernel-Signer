# Mainline-Kernel-Signer
Script to Decompress, Sign, and Recompress the Mainline Kernel from the Mainline project

## WARNING! HUGE WARNING!
**THIS SCRIPT IS STUPID! IT WILL NOT CHECK IF YOU ARE MESSING WITH THE KERNEL YOU ARE CURRENTLY RUNNING!**

That means you can seriously break your system if you aren't careful. So always triple check that you are using the correct Kernel Version.

## What This Script Does:
In Steps:
1. Decompress the .ko.zst Kernel Module Files so they can be signed
2. Sign the newly decompressed .ko Kernel Module Files
3. Recompress the .ko Kernel Module Files back to .ko.zst to save system space
4. Sign the Kernel File in /boot
5. Replace the Unsigned Kernel File in /boot with the Signed Kernel File
6. Add the MOK key to Secure Boot
7. Update Grub

## What This Script Does Not Do:
* __Create the necessary MOK files (.priv, .der, .pem):__ There are comments inside the file with commands on what to do.
* __Automatically Pick Which Kernel You're Using:__ The Script is very stupid. It simply runs a set of commands. To pick the kernel, open the script and replcae the KERNEL_VERSION variable with the Version of the Kernel you're installing
