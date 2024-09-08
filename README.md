# Super-Image-Tool

![Logo](https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEjbQ1TBn8msSrl5RH_B2Hq45bzY-LKxOvg15kT76a6DWSkVgQdnRRQhQ3iyo9hNi_WeCRmaVbblhstYAjvWZ6R5nTlqhSfaM7hbBGP8ABFnxbXi_enfiYm0uiPHMbn6XNlepiw6fhwYgtPpsOpZO8GTMKqrg16fgEqS7-1Q1yXz_1u6fSiWG44_wNgguQlq/s706/IMG_2024_07_27_084732.png)

## FEATURES:
>- Support for Erofs / Ext4 / Ext2 /F2fs devices
>- Unpack your desired super.img or extract super.img from your device automatically
>- You can unpack any super.img (In Raw or Sparse format)
>- Adjust and expand your partitions
>- You can edit your partitions at any time (You only need to use option 2 directly if you already used option 1)
>- Menu Extras (Debloat Automatic / Debloat Manual Console / Debloat Manual / Fix Overlay RW / Expand & Adjust you Partitions)
>- Super image in RW
>- Compile without changing the super image signature
>- Export in raw and sparse your super image
>- Remove verification on your vbmeta files
>- Interactive menu, easy to use`

## Installation & Requirements
>- Magisk or Ksu
>- Termux
>- Flash the zip and reboot you device.

## Info and use of the Tool:
>- Open Termux App and type: su -c super (then press enter)


#### Unpack Super Image

> It will unpack the subpartitions inside super , you can add the super image you want or directly edit the super of your device in use. If you want to edit a different super image than the one in use add the super.img

#### Edit Partitions & Repack Super
> Use this option once you have used "option 1"
Here the process will read the information from your super image and subpartitions.
Then the Tool will detect if your device is Erofs (If it is Erofs it will do the whole process to convert it to ext4 automatically you just have to wait for the process to finish)
If your Device is not Erofs the process will continue and will make an adjustment of your partitions to obtain the largest free size possible and then be able to make a custom expansion for your partitions. When the previous process finishes you will reach the Extras Menu I will explain how this section works below:

>- 1)Automatic Debloat:
The Tool will automatically mount your extracted partitions to do a predefined debloat and then unmount to save the changes.
You can add your desired apps here so that they will be automatically removed.
Just go to /data/local/Super_Image/SUPER_BIN/debloat.txt
In the debloat.txt file you can add your list (You need to add your apps by package name)

>- 2)Debloat Manual Console:
The Tool will mount your extracted partitions and then show you a list in the Termux console where you will see your partitions,you can freely navigate through the paths you want and when you are in the options where the folders with apps are, the Tool will tell you to choose one or multiple options to delete the selected files,the interaction is comfortable you can see by pages if the list is long click on next page or previous page,go back to a previous subdirectory until you reach the main path where you can exit the menu when you have finished deleting what you wanted, the tool unmounts the partitions with your changes.

>- 3)Manual Debloat:
The tool will give you on-screen instructions on what to do, and it will extract two files (mount.sh and umount.sh)
Run as root with the MT manager application the mount.sh file to edit your partitions, here you can delete the files you want.
When you finish making your adjustments you will run as root in mt manager the umount.sh file, you must go back to termux and type done for the Tool to continue ...

>- This option is for those who want to do it this way and not through the console, you are free to choose which one to use.

>- 4)Fix Overlay RW for Xioami Devices:
The Tool will mount the extracted partitions and then make a patch in the vendor's fstab, and remove the RW restriction on the product and my_ext partitions. When the process is finished, the tool unmounts the partitions and saves the changes.

>- 5)Adjust & Compile your Super Image:
Here you can distribute the free space independently to your partitions.
The tool will tell you how much free space you have in MB, here you decide how to divide this amount to your partitions,all the partitions will be listed and it will ask you how much MB you want to assign to that partition (It will also show you the remaining MB in each process)
Note: If you get free space in - (negative) example -300mb you need to do a debloat, go back to the Extras Menu and do debloat, then use this option again)

>- When The Settings and Space Distribution process is finished then the compilation of Super.img begins and when the process ends will ask you if you want to export your super as sparse format.
(This format can be useful to be flashed by fastboot/ fastbootd)
type "yes" if you want to export it in sparse or type "no" if you want to skip this process.
You can find your modified super image at: /data/local/Super_Image/FILES/SUPER

>- file in /data/local/Super_Image/FILES/SUPER

#### Disable verity vbmeta

> Use this option only if it is necessary for you. The super image compiles with the original signature so there is no need to disable the signature on the vbmeta files. But in case your device needs it you can use this option. The vbmeta modified is on the path /data/local/Super_Image/FILES/VBMETA

#### Clean Folder Projects
> You can choose which folder to clean from the project

#### EXTRAS
> When you run the Tool in termux it will export a zip file to your phone's internal memory with the name "Super_Image-INSTALLER.zip" for be flashed in a custom recovery, this zip is an installer where you can flash your modified super image (both in raw and sparse format) it can also flash the vbmeta. The zip has options where you can choose what to select.


>- For SUPER IMAGE OPTION:
Use volume + to install the super image and vol - to skip the installation. If you choose vol + it will tell you if you want to install the super image in raw or sparse format . Vol + select raw and proceed with the installation / vol - select sparse and use vol + again to select and proceed with the installation.


>- For VBMETA OPTION: Use vol + to flash the vbmeta files and vol - to skip this process.


>- For WIPE OPTION: vol + to do a format data of your device , vol - to skip this process . Then you can reboot
