#!/system/bin/sh
#Simple Patch Kernel Plugin for Dynamic Installer
#by @BlassGO

#Inspired/use Magisk method by @topjohnwu
#magiskboot by @topjohnwu
#Also inspired in AnyKernel3 by @osm0sis

#Supported compression formats:
#gzip zopfli xz lzma bzip2 lz4 lz4_legacy lz4_lg

#VARS: KERNEL_FORMAT RAMDISK_FORMAT
#In these variables you can include a default compression format for ramdisk and kernel for all functions
#(It is not necessary, the stock format is always used by default)
#
#Example:
#KERNEL_FORMAT=gzip
#RAMDISK_FORMAT=lz4

#Pre-load
#Ensure $addons space
mkdir -p "$addons/chromeos"

#Default dumpping speed (bytes)
spk_bs=1048576

#Getting boot_patch complement
if [ -f ./boot_patch ]; then unzip -qo ./boot_patch -d "$addons/chromeos"
elif [ -f "$addons/boot_patch" ]; then unzip -qo "$addons/boot_patch" -d "$addons/chromeos"
elif [ -d "./addons/chromeos" ]; then cp -prf "./addons/chromeos" "$addons"
else echo2 "CANT FIND: boot_patch complement" && return 1
fi

chmod -R 755 "$addons/chromeos"
if [ -f "$addons/chromeos/magiskboot" ]; then magiskboot="$addons/chromeos/magiskboot"
else echo2 "CANT FIND: magiskboot" && return 1
fi

#Updating/Adding cpio/ramdisk formats in file_types.config for magic_file function
force_update_file_string "cpio = 30373037 : 07070" "ramdisk = 30373037 : 07070" "$l/file_types.config" 2>/dev/null


#Start functions

#update_ramdisk "New ramdisk" "IMG/Partition to edit"
update_ramdisk() {
    local rdk=$(fullpath "$1") part="$2" space return=0
    [ ! -e "$rdk" ] && return 1
    [ -z "$part" ] && return 1
    space=$(mktemp -d -t update.XXXXXX)
    if unpack_boot "$part" "$space" 1; then
        if [ ! -f "$space/ramdisk.cpio" ]; then echo2 "CANT FIND: ramdisk"; rm -rf "$space"; return 1; fi
        echo2 " -- Updating ramdisk: $(basename "$rdk")"
        cp -pf "$rdk" "$space/ramdisk.cpio"
        repack_boot "$space" "$2"
        return=$?
    else return=1
    fi
    rm -rf "$space"
    return $return
}

#update_kernel "New kernel" "IMG/Partition to edit"
update_kernel() {
    local rdk=$(fullpath "$1") part="$2" space return=0
    [ ! -e "$rdk" ] && return 1
    [ -z "$part" ] && return 1
    space=$(mktemp -d -t update.XXXXXX)
    if unpack_boot "$part" "$space" 1; then
        echo2 " -- Updating kernel: $(basename "$rdk")"
        cp -pf "$rdk" "$space/kernel"
        repack_boot "$space" "$2"
        return=$?
    else return=1
    fi
    rm -rf "$space"
    return $return
}

#patch_cmdline "new prop" "new prop" "..."
#You can patch or add multiple cmdline properties in the current decompiled boot path (First use "cd")
patch_cmdline() {
    local file cmd cmd2 add try properties
    local fix='s/[]\/$*.^[]/\\&/g'
    if [ -f "${!#}" ]; then file=$(fullpath "${!#}") && properties=${*%${!#}}
    elif [ -f header ]; then file=$(fullpath header) && properties="$*"
    else echo2 "patch_cmdline: CANT FIND valid file to patch" && return 1
    fi
    if [ -f "$file" ]; then
        cmd=$(grep -m1 "^cmdline=" "$file" | sed -e "s/cmdline=//" | tr ' ' '\n' | grep -E ".")
        cmd2="$cmd"
        for add in $properties; do
            test "${add#*=}" != "$add" || continue
            try=
            try=$(echo "$add" | cut -d= -f1)
            [ -z "$try" ] && continue
            if echo "$cmd2" | grep -q "^$try="; then
               echo2 "updating: $try"
               try=$(echo "$try" | sed -e $fix)
               add=$(echo "$add" | sed -e $fix)
               cmd2=$(echo "$cmd2" | sed -e "/^$try=/s/.*/$add/")
            else
               echo2 "adding: $try"
               cmd2=$(echo -e "$cmd2\n$add\n")
            fi
        done
        if [ -n "$cmd2" ] && [ "$cmd" != "$cmd2" ]; then
            cmd2=$(echo "$cmd2" | grep -E "." | tr '\n' ' ' | sed -e $fix)
            sed -i -e "/cmdline=/s/.*/cmdline=$cmd2/" "$file"
        else echo2 "patch_cmdline: No changes" && return 1
        fi
    else echo2 "CANT FIND: $file" && return 1
    fi
}

#remove_cmdline "prop to remove" "prop to remove" "..."
#You can remove multiple cmdline properties in the current decompiled boot path (First use "cd")
remove_cmdline() {
    local file cmd cmd2 remove try properties
    local fix='s/[]\/$*.^[]/\\&/g'
    if [ -f "${!#}" ]; then file=$(fullpath "${!#}") && properties=${*%${!#}}
    elif [ -f header ]; then file=$(fullpath header) && properties="$*"
    else echo2 "remove_cmdline: CANT FIND valid file to patch" && return 1
    fi
    if [ -f "$file" ]; then
        cmd=$(grep -m1 "^cmdline=" "$file" | sed -e "s/cmdline=//" | tr ' ' '\n' | grep -E ".")
        cmd2="$cmd"
        for remove in $properties; do
            try=
            try=$(echo "$remove" | cut -d= -f1)
            [ -z "$try" ] && continue
            if echo "$cmd2" | grep -q "^$try="; then
               echo2 "removing: $try"
               try=$(echo "$try" | sed -e $fix)
               cmd2=$(echo "$cmd2" | sed -e "/^$try=/d")
            fi
        done
        if [ "$cmd" != "$cmd2" ]; then
            cmd2=$(echo "$cmd2" | grep -E "." | tr '\n' ' ' | sed -e $fix)
            sed -i -e "/cmdline=/s/.*/cmdline=$cmd2/" "$file"
        else echo2 "remove_cmdline: No changes" && return 1
        fi
    else echo2 "CANT FIND: $file" && return 1
    fi
}

#unpack_boot "IMG/Partition to extract" "Output Folder" <1>
#if third argument is "1" it will not unpack the ramdisk
unpack_boot() {
    local part=$(fullpath "$1") space="$2" skip="$3" original info return=0 chromeos=false current="$PWD" kernel_type ramdisk_type
    [ ! -e "$part" ] && return 1
    [ -z "$space" ] && return 1
    original="$space/original.img"
    info="$space/original.info"
    [ -d "$space" ] && rm -rf "$space"
    mkdir -p "$space"
    if [ ! -d "$space" ]; then echo2 "CANT CREATE DIR: $space" && return 1; fi
    echo2 '>> Unpack Boot 1.0.0 '
    echo2 " "
    echo2 " -- Getting $(basename "$part")..."
    ( if [ -c "$part" ]; then
       nanddump -f "$original" "$part"
    else
       dd if="$part" of="$original" bs=$spk_bs
    fi ) >/dev/null 2>&1
    if ! is_valid "$original"; then echo2 "FATAL ERROR: CANT GET: $part" && return 1; fi
    cd "$space"
    echo2 " -- Extracting components..."
    $magiskboot unpack -h -n "$original" >/dev/null 2>&1
    case $? in
      0 ) ;;
      1 )
        echo2 "FATAL ERROR: UNSUPPORTED: $part" && return=1
        ;;
      2 )
        echo -e "\nchromeos=true" >> "$info"
        ;;
      * )
        echo2 "FATAL ERROR: CANT EXTRACT: $part" && return=1
        ;;
    esac
    if [ "$skip" != 1 ] && [ $return != 1 ] && [ -f ramdisk.cpio ]; then
        ramdisk_type=$(check_compression ramdisk.cpio)
        [ -n "$ramdisk_type" ] && echo -e "\nramdisk_type=$ramdisk_type" >> "$info"
        $magiskboot cpio ramdisk.cpio test >/dev/null 2>&1
        [ $? == 1 ] && echo -e "\nMAGISK_PRE_INSTALLED=true" >> "$info"
        unpack_ramdisk ramdisk.cpio || return=1
    elif [ "$skip" != 1 ] && [ ! -f ramdisk.cpio ]; then 
        echo2 "CANT FIND: ramdisk" && return=1
    fi
    if [ $return != 1 ] && [ -f kernel ]; then
        kernel_type=$(check_compression kernel)
        [ -n "$kernel_type" ] && echo -e "\nkernel_type=$kernel_type" >> "$info"
    elif [ ! -f kernel ]; then
        echo2 "CANT FIND: kernel" && return=1
    fi
    [ -d "$current" ] && cd "$current" || cd /
    return $return
}

#repack_boot "Folder to build" "Output File/Partition" <recovery>
#If third argument is "recovery" it will use AVB1 signing (only if needed) for recovery images
repack_boot() {
    local boot="$2" space="$1" mode=$3 avb1=false sign=false skipavb=false return=0 current="$PWD"
    local chromeos=false MAGISK_PRE_INSTALLED=false kernel_type ramdisk_type
    [ -z "$boot" ] && return 1
    [ -z "$space" ] && return 1
    [ ! -d "$(dirname "$boot")" ] && mkdir -p "$(dirname "$boot")"
    if [ ! -e "$boot" ]; then
        touch "$boot" && boot=$(fullpath "$boot")
        if [ -f "$boot" ]; then rm -f "$boot"
        else "CANT WRITE IN: $boot" && return 1
        fi
    else
        boot=$(fullpath "$boot")
        [ -f "$boot" ] && rm -f "$boot"
    fi
    if [ ! -f "$space/kernel" ] || [ ! -f "$space/original.img" ]; then echo2 "INVALID/UNSSUPORTED: $space" && return 1; fi
    cd "$space"
    echo2 '>> Repack Boot 1.0.0 '
    echo2 " "
    if [ -d ramdisk ]; then
       if ! repack_ramdisk ramdisk ramdisk.cpio 1; then
           cd "$current"; return 1
       fi
    fi
    kernel_type=$(check_compression kernel)
    [ -f ramdisk.cpio ] && ramdisk_type=$(check_compression ramdisk.cpio)
    [ -f original.info ] && import_config original.info
    #Magisk Checking / Patch
    $magiskboot cpio ramdisk.cpio test >/dev/null 2>&1
    if [ $? == 1 ]; then
        echo2 " -- Fixing Magisk pre-installation..."
        if ! patch_with_magisk; then
            cd "$current"; return 1
        fi
    elif $MAGISK_PRE_INSTALLED; then
        echo2 " -- Removing Magisk pre-installation..."
        remove_magisk
        return=2
    else return=2
    fi
    if [ -z "$RAMDISK_FORMAT" ]; then
       if [ -f original.info ] && grep -q ramdisk_type original.info && [ -z "$(check_compression ramdisk.cpio 1)" ]; then recompress ramdisk.cpio $ramdisk_type; fi
    else
        [ -z "$(check_compression ramdisk.cpio 1)" ] && recompress ramdisk.cpio $RAMDISK_FORMAT
    fi
    if [ -z "$KERNEL_FORMAT" ]; then
       if [ -f original.info ] && grep -q kernel_type original.info && [ -z "$(check_compression kernel 1)" ]; then recompress kernel $kernel_type; fi
    else
        [ -z "$(check_compression kernel 1)" ] && recompress kernel $KERNEL_FORMAT
    fi
    echo2 " -- Repacking $(basename "$space")..."
    if ! $magiskboot repack original.img new-boot.img >/dev/null 2>&1; then echo2 "FATAL ERROR: CANT REPACK: $space"; cd "$current"; return 1; fi
    if [ ! -f new-boot.img ]; then echo2 "FATAL ERROR: CANT REPACK: $space"; cd "$current"; return 1; fi
    echo2 " -- Checking signature..."
    if [ -f "$addons/chromeos/magisk.jar" ]; then
       if ! $BOOTMODE && ! dalvikvm -showversion >/dev/null; then
          echo2 "    WARNING: Cant verify BOOT.img AVB1"
          echo2 "    Please enable setdefault apex_mount in the updater-script"
          skipavb=true
       else
          run_jar "$addons/chromeos/magisk.jar" -verify < original.img >/dev/null 2>&1 && avb1=true
          $avb1 && echo2 "    Detected: AVB1 Signature"
       fi
    else
       echo2 "    Cant find: magisk.jar"
       echo2 "    Skipping AVB1 check..."
       skipavb=true
    fi
    if $chromeos; then
        if can_run "$addons/chromeos/futility"; then
           echo2 " -- Signing with futility..."
           echo > empty
           "$addons/chromeos/futility" vbutil_kernel --pack new-boot.img.signed \
           --keyblock "$addons/chromeos/kernel.keyblock" --signprivate "$addons/chromeos/kernel_data_key.vbprivk" \
           --version 1 --vmlinuz new-boot.img --config empty --arch arm --bootloader empty --flags 0x1 && sign=true
           rm -f empty new-boot.img
           mv new-boot.img.signed new-boot.img
        fi
        if ! $sign || [ ! -f new-boot.img ]; then
            echo2 "FATAL ERROR: CANT SIGN: $boot"; cd "$current"; return 1
        fi
    fi
    if ! $skipavb && $avb1; then
        echo2 " -- Signing with magisk.jar..."
        if [ "$mode" != "recovery" ]; then
           cat new-boot.img | run_jar "$addons/chromeos/magisk.jar" -sign > new-boot.img.signed
        else
           echo2 "    Custom mode: recovery"
           cat new-boot.img | run_jar "$addons/chromeos/magisk.jar" -sign /recovery > new-boot.img.signed
        fi
        rm -f new-boot.img
        mv new-boot.img.signed new-boot.img
        if ! run_jar "$addons/chromeos/magisk.jar" -verify < new-boot.img >/dev/null 2>&1; then
           echo2 "FATAL ERROR: CANT SIGN AVB1: $boot"; cd "$current"; return 1
        fi
    fi
    flash_image new-boot.img "$boot"
    case $? in
    1)
      echo2 "FATAL ERROR: Insufficient space: $boot" && return=1
      ;;
    2)
      echo2 "FATAL ERROR: Read Only: $boot" && return=1
      ;;
    esac
    [ -d "$current" ] && cd "$current" || cd /
    return $return
}

#unpack_ramdisk "ramdisk to unpack"
#By default unpacked in "ramdisk" folder in the same path of the ramdisk file
unpack_ramdisk() {
    #Inspired in AnyKernel3 method
    local rdk=$(fullpath "$1") current="$PWD" result return=0
    local chromeos=false MAGISK_PRE_INSTALLED=false kernel_type ramdisk_type
    [ ! -f "$rdk" ] && return 1
    result="$(dirname "$rdk")/ramdisk"
    ramdisk_type=$(check_compression "$rdk")
    if [ ! -f "$(dirname "$rdk")/original.info" ]; then
        [ -n "$ramdisk_type" ] && echo -e "\nramdisk_type=$ramdisk_type" >> "$(dirname "$rdk")/original.info"
    fi
    echo2 " -- Unpacking $(basename "$rdk")..."
    [ -d "$result" ] && rm -rf "$result"
    mkdir -p "$result"
    chmod 755 "$result"
    if [ ! -d "$result" ]; then echo2 "CANT CREATE DIR: $result" && return 1; fi
    cd "$result"
    EXTRACT_UNSAFE_SYMLINKS=1 cpio -d -F "$rdk" -i
    if [ $? != 0 ] || [ -z "$(ls)" ]; then
       echo2 "CANT EXTRACT: $rdk"
       return=1
    fi
    [ -d "$current" ] && cd "$current" || cd /
    return $return
}

#repack_ramdisk "ramdisk folder" "Output file" <1>
#if third argument is "1" it will not try to recompress ramdisk with some extra default compression format (like .gz/.lz4)
repack_ramdisk() {
    #Inspired in AnyKernel3 method
    local rdk=$(fullpath "$1") result="$2" mode=$3 current="$PWD" return=0
    local chromeos=false MAGISK_PRE_INSTALLED=false kernel_type ramdisk_type
    [ ! -d "$rdk" ] && return 1
    [ -z "$result" ] && return 1
    [ ! -d "$(dirname "$result")" ] && mkdir -p "$(dirname "$result")"
    if [ ! -e "$result" ]; then
        touch "$result" && result=$(fullpath "$result")
        if [ -f "$result" ]; then rm -f "$result"
        else "CANT WRITE IN: $result" && return 1
        fi
    else
        result=$(fullpath "$result")
        rm -f "$result"
    fi
    cd "$rdk"
    echo2 " -- Repacking ramdisk: $(basename "$rdk")"
    find . -mindepth 1 | cpio -H newc -o > "$result" || return=1
    is_valid "$result" || return=1
    [ -f "$(dirname "$rdk")/original.info" ] && import_config "$(dirname "$rdk")/original.info"
    if [ "$mode" != 1 ] && [ -n "$RAMDISK_FORMAT" ]; then recompress "$result" $RAMDISK_FORMAT
    elif [ "$mode" != 1 ] && [ -n "$ramdisk_type" ]; then recompress "$result" $ramdisk_type
    fi
    if ! is_valid "$result"; then
        echo2 "CANT REPACK: $rdk" && return=1
    fi
    [ -d "$current" ] && cd "$current" || cd /
    return $return
}

#check_compression "file" <1>
#Checking and Auto-Unpacking possible extra compression and return the compression format
#if second argument is "1" it will only return the compression format (Without decompress it)
check_compression() {
    #Inspired in AnyKernel3 method
    local rdk=$(fullpath "$1") format_type_001 mode=$2
    format_type_001=$($magiskboot decompress "$rdk" 2>&1 | grep -v 'raw')
    format_type_001=$(string inside '[' ']' "$format_type_001")
    if [ -z "$format_type_001" ]; then return 0
    elif [ "$mode" == 1 ]; then echo "$format_type_001"; return 0
    fi
    echo2 " -- Decompressing: $(basename "$rdk").$format_type_001..."
    mv -f "$rdk" "$rdk.$format_type_001";
    echo2 "    Attempt:1: $format_type_001"
    if ! $magiskboot decompress "$rdk.$format_type_001" "$rdk" >/dev/null 2>&1; then
        echo2 "    Attempt:2: $format_type_001"
        $format_type_001 -dc "$rdk.$format_type_001" > "$rdk"
    fi
    rm -f "$rdk.$format_type_001"
    echo "$format_type_001"
    echo2 " "
    echo2 " -- Unpacked img success!.. check in /data/MyProjects/"
}

#recompress "file" "compression format"
#Recompress file in some supported format
recompress() {
    #Inspired in AnyKernel3 method
    local rdk=$(fullpath "$1") format=$2
    [ -z "$format" ] && return 1
    [ ! -f "$rdk" ] && return 1
    echo2 " -- Compressing: $(basename "$rdk").$format"
    if ! $magiskboot compress=$format "$rdk" "$rdk.$format"; then
        $format -9c "$rdk" > "$rdk.$format" || return=1
    fi
    rm -f "$rdk"
    mv "$rdk.$format" "$rdk"
    [ ! -f "$rdk" ] && return 1
}


#Restore/Apply old Magisk configs in the current path
patch_with_magisk() {
    #Inspired in AnyKernel3 method / Magisk installation script
    local fstab return=0
    local chromeos=false MAGISK_PRE_INSTALLED=false kernel_type ramdisk_type
    if [ -f kernel ]; then
        kernel_type=$(check_compression kernel)
        [ -n "$KERNEL_FORMAT" ] && kernel_type=$KERNEL_FORMAT
        ($magiskboot split kernel) >/dev/null 2>&1
        $magiskboot hexpatch kernel 736B69705F696E697472616D6673 77616E745F696E697472616D6673
        [ -n "$kernel_type" ] && recompress kernel $kernel_type
        if ! is_valid kernel; then
            echo2 "CANT PATCH: kernel" && return=1
        fi
    else return=1
    fi
    #Getting previous Magisk configs
    if [ ! -f .magisk ]; then
       echo2 " -- Getting info: .backup/.magisk"
       $magiskboot cpio ramdisk.cpio "extract .backup/.magisk .magisk" >/dev/null 2>&1
    fi
    [ -f .magisk ] && export $(cat .magisk) || return 1
    #Patching dtb fstabs
    for fstab in dtb extra kernel_dtb recovery_dtbo; do
       [ -f $fstab ] && $magiskboot dtb $fstab patch >/dev/null 2>&1
    done
    unset KEEPFORCEENCRYPT KEEPVERITY SHA1 TWOSTAGEINIT
    return $return
}

#Remove old Magisk configs in the current path
remove_magisk() {
    #Inspired in Ofox method / Magisk installation script
    local type fstab return=0
    local chromeos=false MAGISK_PRE_INSTALLED=false kernel_type ramdisk_type
    if [ -f kernel ]; then
        kernel_type=$(check_compression kernel)
        [ -n "$KERNEL_FORMAT" ] && kernel_type=$KERNEL_FORMAT
        ($magiskboot split kernel) >/dev/null 2>&1
        $magiskboot hexpatch kernel 77616E745F696E697472616D6673 736B69705F696E697472616D6673
        [ -n "$kernel_type" ] && recompress kernel $kernel_type
        if ! is_valid kernel; then
            echo2 "CANT PATCH: kernel" && return=1
        fi
    else return=1
    fi
    [ -f header ] && remove_cmdline skip_override 2>/dev/null
    return $return
}

#flash_image "IMG to install" "Partition/Output File"
flash_image() {
  #From Magisk
  local return=0
  local blk_sz=$(blockdev --getsize64 "$2" 2>/dev/null)
  if [ -b "$2" ] && [ -n "$blk_sz" ]; then
    local img_sz=$(stat -c '%s' "$1")
    [ "$img_sz" -gt "$blk_sz" ] && return 1
    blockdev --setrw "$2"
    local blk_ro=$(blockdev --getro "$2")
    [ "$blk_ro" -eq 1 ] && return 2
    echo2 " -- Installing in: $2"
    cat "$1" | cat - /dev/zero > "$2" 2>/dev/null
  elif [ -c "$2" ]; then
    echo2 " -- Installing in: $2"
    flash_eraseall "$2" >&2
    cat "$1" | nandwrite -p "$2" - >&2
  else
    echo2 " -- Writing in: $2"
    cat "$1" > "$2"
  fi
  return $return
}