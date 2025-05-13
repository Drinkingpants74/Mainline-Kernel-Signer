#!/bin/bash

# IF MOKUTIL FAILS:
# 1.) Copy command and replcae "$MOK_DER" with actual file Path
# 2.) run: sudo update-grub
# 3.) Reboot and boot new kernel

# To create MOK.priv and MOK.der run the following command:
# openssl req -new x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -nodes -days 3650 -subj "/CN=Custom MOK/"

# To create MOK.pem run the following command:
# openssl x509 -inform DER -in MOK.der -out MOK.pem

# Change MOK_PRIV, MOK_DER and MOK_PEM to locations of each file on your system (ex: /home/<user>/MOK.priv)

# Change Kernel Version to name of Folder in /lib/modules/ (ex: /lib/modules/6.14.4-061404-generic -> 6.14.4-061404-generic)

KERNEL_VERSION="6.14.4-061404-generic"
MOK_PRIV="<PATH TO>/MOK.priv"
MOK_DER="<PATH TO>/MOK.der"
MOK_PEM="<PATH TO>/MOK.pem"

echo -e "Decompressing .ko.zst files..."

if ! command -v zstd >/dev/null; then
    echo -e "Error: zstd not installed"
    exit 1
fi

if ! find /lib/modules/"$KERNEL_VERSION" -name "*.ko.zst" | grep -q .; then
    echo -e "Error: No .ko.zst files found"
    exit 1
fi

find /lib/modules/"$KERNEL_VERSION" -type f -name "*.ko.zst" | while read -r zst_file; do
    sudo zstd -d "$zst_file" || {
        echo -e "Failed to decompress"
        exit 1
    }
    sudo rm "$zst_file"
done

echo -e "All .ko.zst files decompressed to .ko\n\n"


echo -e "Signing Modules..."

if [[ ! -f "$MOK_PRIV" || ! -f "$MOK_DER" ]]; then
    echo -e "Missing MOK File"
    exit 1
fi

if [[ ! -f /usr/src/linux-headers-"$KERNEL_VERSION"/scripts/sign-file ]]; then
    echo -e "Error: sign-file missing"
    exit 1
fi

if ! find /lib/modules/"$KERNEL_VERSION" -name "*.ko" | grep -q .; then
    echo -e "Error: No .ko files found. Run Decompress Script first"
    exit 1
fi

find /lib/modules/"$KERNEL_VERSION" -type f -name "*.ko" | while read -r module; do
    sudo /usr/src/linux-headers-"$KERNEL_VERSION"/scripts/sign-file sha512 "$MOK_PRIV" "$MOK_DER" "$module" || {
        echo -e "Failed to Sign: $module"
        exit 1
    }
done

echo -e "Modules Signed Successfully\n\n"


echo -e "Recompressing Kernel Modules..."

find /lib/modules/"$KERNEL_VERSION" -type f -name "*.ko" | while read -r module; do
    sudo zstd "$module" || {
        echo -e "Failed to Sign: $module"
        exit 1
    }
    sudo rm "$module"
done

echo -e "Modules Compressed Successfully\n\n"


echo -e "Signing Kernel..."
sudo sbsign --key "$MOK_PRIV" --cert "$MOK_PEM" /boot/vmlinuz-"$KERNEL_VERSION" --output /boot/vmlinuz-"$KERNEL_VERSION".signed
if [ `echo $?` == 0 ]; then
    sudo mv /boot/vmlinuz-"$KERNEL_VERSION".signed /boot/vmlinuz-"$KERNEL_VERSION"
    if [ `echo $?` == 0 ]; then
        echo -e "Kernel Signed Successfully"
        sudo mokutil --import "$MOK_DER"
        sudo update-grub
        echo -e "Please Reboot System"
    else
        echo -e "Failed to Replace Unsigned Kernel"
    fi
else
    echo -e "Failed to Sign Kernel"
fi
