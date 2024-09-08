#!/system/bin/sh

# Super_Tool
# By Zonik

# variables 
TOOLS_DIR="/data/local/Super_Image"
EXTRACT_DIR="$TOOLS_DIR/UNPACKED"

# Función para montar una imagen
mount_img() {
  local img_file="$1"
  local mount_point="$2"
  
  # Encontrar un dispositivo loop libre
  local loop_device=$(losetup -f)

  # Verificar si el dispositivo de loop está disponible
  if [ -z "$loop_device" ]; then
    echo "There are no loop devices available. Creating a new loop device"
    
    # Obtener el próximo número de dispositivo loop
    local next_loop_number=$(losetup -a | awk -F'[/:]' '/loop/ {print $4}' | sort -n | tail -n 1)
    if [ -z "$next_loop_number" ]; then
      next_loop_number=0
    else
      next_loop_number=$((next_loop_number + 1))
    fi

    # Crear un nuevo dispositivo de loop
    mknod /dev/block/loop"$next_loop_number" b 7 "$next_loop_number"
    
    # Intentar encontrar el nuevo dispositivo de loop
    loop_device="/dev/block/loop$next_loop_number"
  fi
  
  # Asociar la imagen con el dispositivo loop
  losetup "$loop_device" "$img_file"
  
  # Montar la partición con el tipo de sistema de archivos especificado
  mount -t ext4 -w "$loop_device" "$mount_point"
}

# Montar todas las imágenes en el directorio
for img_file in "$EXTRACT_DIR"/*.img; do
  part_name=$(basename "$img_file" .img)
  mount_point="$part_name"
  
  # Crear el punto de montaje si no existe
  mkdir -p "$mount_point"
  
  # Montar la imagen
  if mount_img "$img_file" "$mount_point"; then
    echo "Mounted $img_file en $mount_point"
  else
    echo "Error mounting $img_file"
  fi
done

