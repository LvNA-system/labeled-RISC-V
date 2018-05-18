
## sidewinder

To make the SD card work, do the followings
* `fsbl/psu_init.c`: search for `IOU_SLCR_BANK1_CTRL5_OFFSET`, change `0x2000FFFU` to `0x3FFFFFFU`
* add "no-1-8-v;" property to the node of "sdhci@ff170000" in device tree
