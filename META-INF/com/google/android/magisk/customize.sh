#Super-Image Project 
# By Zonik 

echo "  █▀█ █──█ █▀█ █▀▀ █▀█  "
echo "  ▀▀▄ █──█ █▄█ █▀▀ █▄▀  "
echo "  █▄█ ▀▄▄▀ █── █▄▄ █─█  "
echo " "
echo "  █ ▀█▀ █▀▄▀█ █▀█ █▀▀█ █▀▀  "
echo "  █ ─█─ █─█─█ █▄█ █─▄▄ █▀▀  "
echo "  █ ▄█▄ █───█ █─█ █▄▄█ █▄▄  "

ui_print " "
sleep 1
ui_print "  ╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮" 
ui_print "  │ 𝙔𝙤𝙪 𝘿𝙚𝙫𝙞𝙘𝙚 𝙞𝙨           ►   $(getprop ro.product.model)"
sleep 1
ui_print "  │ 𝙔𝙤𝙪 𝘼𝙣𝙙𝙧𝙤𝙞𝙙 𝙫𝙚𝙧𝙨𝙞𝙤𝙣 𝙞𝙨    ►   $(getprop ro.build.version.release)"
sleep 1
ui_print "  │ 𝙑𝙚𝙧𝙨𝙞𝙤𝙣 𝙀𝙭𝙩𝙧𝙖𝙘𝙩 𝙋𝙖𝙧𝙩𝙞𝙩𝙞𝙤𝙣𝙨   ►   1.2"
sleep 1
ui_print "  │ 𝘽𝙪𝙞𝙡𝙙 𝘿𝙖𝙩𝙚              ►   2024-09-08"
sleep 2
ui_print "  ╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮" 
ui_print "  │              𝘿𝙚𝙫 :  𝙕𝙤𝙣𝙞𝙠"
ui_print "  ╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯"

# Variables
Main="/data/local/Super_Image"
EXTRACT_DIR="$Main/UNPACKED"
FILES_SUPER="$Main/FILES/SUPER"
FILES_VBMETA="$Main/FILES/VBMETA"
SUPER_BIN="$Main/SUPER_BIN"

ui_print " "
     sleep 1
     ui_print "  ╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮"
     sleep 2
     ui_print "  │- ¡𝘾𝙝𝙚𝙘𝙠𝙞𝙣𝙜 𝙞𝙣𝙨𝙩𝙖𝙡𝙡𝙖𝙩𝙞𝙤𝙣 𝙯𝙞𝙥"
     ui_print "  │"
     if [ $CUSTOM_SETUP = 0 ]; then
     sleep 2
     ui_print "  │- 𝙄𝙣𝙨𝙩𝙖𝙡𝙡𝙖𝙩𝙞𝙤𝙣 𝙗𝙮 𝙈𝙖𝙜𝙞𝙨𝙠 "
     else
     ui_print "  │- 𝙄𝙣𝙨𝙩𝙖𝙡𝙡𝙖𝙩𝙞𝙤𝙣 𝙗𝙮 𝙆𝙚𝙧𝙣𝙚𝙡𝙎𝙐 𝙤𝙧 𝘼𝙥𝙖𝙩𝙘𝙝 "
     fi
     ui_print "  │"
     ui_print "  │- ¡𝘾𝙝𝙚𝙘𝙠𝙞𝙣𝙜 𝙞𝙛 𝙎𝙪𝙥𝙚𝙧_𝙄𝙢𝙖𝙜𝙚 𝙛𝙤𝙡𝙙𝙚𝙧 𝙚𝙭𝙞𝙨𝙩𝙨"
     if [ -d "$Main" ]; then
     sleep 2
     ui_print "  │- 𝙏𝙝𝙚 𝙛𝙤𝙡𝙙𝙚𝙧 '$Main' 𝙞𝙩 𝙖𝙡𝙧𝙚𝙖𝙙𝙮 𝙚𝙭𝙞𝙨𝙩𝙨."
     rm -rf $SUPER_BIN
     mkdir -p "$Main" "$SUPER_BIN" "$FILES_SUPER" "$FILES_VBMETA" "$EXTRACT_DIR"
     else
     ui_print "  │"
     sleep 2
    # Crea la nueva carpeta
     mkdir -p "$Main" "$SUPER_BIN" "$FILES_SUPER" "$FILES_VBMETA" "$EXTRACT_DIR"
     if [ $? -eq 0 ]; then
        sleep 2
     ui_print "  │- 𝙁𝙤𝙡𝙙𝙚𝙧𝙨 𝙘𝙧𝙚𝙖𝙩𝙚𝙙 𝙨𝙪𝙘𝙘𝙚𝙨𝙨𝙛𝙪𝙡𝙡𝙮, 𝙥𝙡𝙚𝙖𝙨𝙚 𝙖𝙙𝙙 𝙮𝙤𝙪 𝙛𝙞𝙡𝙚𝙨!"
     else
        sleep 2
     ui_print "  │- 𝙀𝙧𝙧𝙤𝙧 𝙘𝙧𝙚𝙖𝙩𝙞𝙣𝙜 𝙛𝙤𝙡𝙙𝙚𝙧𝙨"
     fi
fi
     # Super Image support files
     sleep 2
     ui_print "  │"
     ui_print "  │- 𝙀𝙭𝙩𝙧𝙖𝙘𝙩𝙞𝙣𝙜 𝙣𝙚𝙘𝙚𝙨𝙨𝙖𝙧𝙮 𝙛𝙞𝙡𝙚𝙨"
     setdefault permissions "0 : 0 : 0755: 0777"
     package_extract_dir META-INF/zbin "$SUPER_BIN"
     package_extract_dir zonik/s_i/SUPER_BIN "$SUPER_BIN"
     # Menu
     sleep 2
     setdefault permissions "0 : 0 : 0755: 0777"
     package_extract_dir zonik/s_i/bin "$MODPATH/system/bin"
     set_context /system "$MODPATH/system"
     ui_print "  │"
     sleep 2
     ui_print "  │- 𝘿𝙤𝙣𝙚 𝙣𝙤𝙬 𝙧𝙚𝙗𝙤𝙤𝙩 𝙮𝙤𝙪𝙧 𝙙𝙚𝙫𝙞𝙘𝙚"
     ui_print "  │"
     sleep 2
     ui_print "  │- 𝙊𝙥𝙚𝙣 𝙩𝙚𝙧𝙢𝙪𝙭 𝙖𝙣𝙙 𝙩𝙮𝙥𝙚 𝙨𝙪 -𝙘 super"
     nohup am start -a android.intent.action.VIEW -d https://t.me/+5qqviO_5Hck5ZTc5 >/dev/null 2>&1 &
     ui_print "  ╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯"