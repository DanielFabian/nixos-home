Due to MacBook Pro (7,1) not supporting UEFI properly, it's best to go with __legacy mode__. This requires __hybrid MBR__ partition table.

I used the approach described in the [Arch Wiki](https://wiki.archlinux.org/index.php/MacBookPro7,1#Bootloader) 
and also added the (BIOS GPT partition layout)[https://wiki.archlinux.org/index.php/Partitioning#Example_layouts] for GRUB.

Not entirely certain the latter was necessary, but it works.
