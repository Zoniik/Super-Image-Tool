#!/system/bin/sh

# Super_Tool
# By Zonik

# Variables
TOOLS_DIR="/data/local/Super_Image"
EXTRACT_DIR="$TOOLS_DIR/UNPACKED"

# Función para desmontar una imagen
umount_img() {
  local mount_point="$1"
  
  # Desmontar la partición
  umount "$mount_point"
  
  # Encontrar y desasociar el dispositivo loop asociado
  local loop_device=$(losetup -j "$mount_point" | awk '{print $1}' | cut -d ':' -f 1)
  if [ -n "$loop_device" ]; then
    losetup -d "$loop_device"
  fi
}

# Desmontar todas las imágenes en el directorio
for img_file in "$EXTRACT_DIR"/*.img; do
  part_name=$(basename "$img_file" .img)
  mount_point="$part_name"
  
  if mountpoint -q "$mount_point"; then
    # Desmontar la imagen
    umount_img "$mount_point"
    
    echo "Unmounted $mount_point"
    rm -rf "$mount_point"
  else
    echo "$mount_point is not mounted"
  fi
done
