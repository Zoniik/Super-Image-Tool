# Super-Image-Tool
A tool for unpacking, editing, and repacking Android super images

![Logo](https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEjbQ1TBn8msSrl5RH_B2Hq45bzY-LKxOvg15kT76a6DWSkVgQdnRRQhQ3iyo9hNi_WeCRmaVbblhstYAjvWZ6R5nTlqhSfaM7hbBGP8ABFnxbXi_enfiYm0uiPHMbn6XNlepiw6fhwYgtPpsOpZO8GTMKqrg16fgEqS7-1Q1yXz_1u6fSiWG44_wNgguQlq/s706/IMG_2024_07_27_084732.png)

## Features:
- Support for Erofs / Ext4 / Ext2 / F2fs devices
- Unpack your desired super.img or extract super.img from your device automatically
- You can unpack any super.img (In Raw or Sparse format)
- Adjust and expand your partitions
- You can edit your partitions at any time (You only need to use option 2 directly if you already used option 1)
- Menu extras (Debloat Automatic / Debloat Manual Console / Debloat Manual / Fix Overlay RW / Expand & Adjust Partitions)
- Super image in RW
- Compile without changing the super image signature
- Export in raw and sparse formats
- Remove verification on your vbmeta files
- Interactive menu, easy to use

## Installation & Requirements
- Magisk or Ksu
- Termux
- Flash the zip and reboot your device

## Info and Use of the Tool:
- Open Termux App and type: `su -c super` (then press enter)

### Unpack Super Image
It will unpack the subpartitions inside the super image. You can add the super image you want or directly edit the super image of your device in use. If you want to edit a different super image than the one in use, add the super.img manually.

### Edit Partitions & Repack Super
Use this option once you have used "option 1." The process will read the information from your super image and subpartitions.

1. **Automatic Debloat:**
   - The tool will automatically mount your extracted partitions to perform a predefined debloat and then unmount them to save the changes.
   - You can add your desired apps to remove in the `debloat.txt` file located at:
     ```
     /data/local/Super_Image/SUPER_BIN/debloat.txt
     ```

2. **Debloat Manual Console:**
   - The tool will mount your extracted partitions and show you a list in the Termux console where you can navigate the paths and delete the selected files interactively.

3. **Manual Debloat:**
   - You will extract two files (`mount.sh` and `umount.sh`) and run them using an MT Manager application to delete the files you want. When done, return to Termux and type `done`.

4. **Fix Overlay RW for Xiaomi Devices:**
   - This will patch the vendor's fstab to remove the RW restriction on the product and my_ext partitions.

5. **Adjust & Compile Super Image:**
   - You can distribute the free space to your partitions as you wish. The tool will guide you through the process. Once done, you can choose to export your modified super image as a raw or sparse format. 
   
   > **Note:** If free space is negative, you may need to perform a debloat and try again.
   
   - The final super image will be located at:
     ```
     /data/local/Super_Image/FILES/SUPER
     ```

### Disable Verity vbmeta
Use this option only if necessary. The vbmeta file can be found at: /data/local/Super_Image/FILES/VBMETA

### Clean Project Folders
You can choose which project folders to clean up.

## Extras:
When you run the Tool in Termux, it will export a zip file named `Super_Image-INSTALLER.zip` to your internal memory. This installer allows you to flash your modified super image and vbmeta files in a custom recovery.

- **Super Image Option:** Use `vol +` to install the super image and `vol -` to skip. If you choose `vol +`, select raw or sparse format.
- **VBMETA Option:** Use `vol +` to flash vbmeta files and `vol -` to skip.
- **Wipe Option:** Use `vol +` to format data, `vol -` to skip.

## Notes:
> **Important:** Make sure you have enough free space before starting the process. Incorrect modifications may brick your device.
