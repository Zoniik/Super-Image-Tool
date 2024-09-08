#!/bin/bash

# Super Image Tool
# By Zonik

# Configuración del archivo de registro
LOG_FILE="/data/local/Super_Image/SUPER_BIN/super_image_tool.log"

# Función log
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Función check files
check_unpacked_files() {
  local extract_dir="$1"
  
  # Comprobar si el directorio contiene archivos con la extensión .img
  if find "$extract_dir" -type f -name "*.img" | grep -q .; then
    return 0  # Contiene archivos .img
  else
    return 1  # No contiene archivos .img
  fi
}

# Check sparse image 
check_sparse_image() {
  local img_file="$1"
  local magic

  # Leer los primeros 4 bytes para verificar el "header magic" de los archivos sparse
  magic=$(head -c 4 "$img_file" | xxd -p)
  if [[ "$magic" == "3aff26ed" ]]; then
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')$img_file $(colorize 'yellow' 'Sparse format detected')"
    log_message "│ $img_file Sparse format detected"
    return 0
  else
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')$img_file $(colorize 'yellow' 'Raw format detected')"
    log_message "│ img_file Raw format detected"
    return 1
  fi
}

# Convert sparse image to raw
sparse_to_raw() {
  local img_file="$1"    
  local output_file="$2"
  # Ruta y Tool 
  local script_dir="/data/local/Super_Image/SUPER_BIN"
  local simg2img_tool="$script_dir/simg2img"

  # Convertir la imagen sparse a raw
  "$simg2img_tool" "$img_file" "$output_file"
  if [[ $? -ne 0 ]]; then
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1 
    echo -e "$(colorize 'yellow' '│ ')Error converting $img_file to format raw."
    log_message "│ Error converting $img_file to format raw."
    return 1
  fi
  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│ ')Conversion to raw format completed. File saved in $output_file."
  log_message "│ Conversion to raw format completed. File saved in $output_file."
}

raw_to_sparse() {
  local img_file="$1"    
  local output_file="$2"
  # Ruta y Tool 
  local script_dir="/data/local/Super_Image/SUPER_BIN"
  local img2simg_tool="$script_dir/img2simg"

  # Convertir la imagen sparse a raw
  "$img2simg_tool" "$img_file" "$output_file"
  if [[ $? -ne 0 ]]; then
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1 
    echo -e "$(colorize 'yellow' '│ ')Error converting $img_file to format sparse."
    log_message "│ Error converting $img_file to format sparse."
    return 1
  fi
  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│ ')Conversion to sparse format completed. File saved in $output_file."
  log_message "│ Conversion to sparse format completed. File saved in $output_file."
}

# Variables
declare -A colors
colors=(
  ["black"]="\033[0;30m"
  ["red"]="\033[0;31m"
  ["green"]="\033[0;32m"
  ["yellow"]="\033[0;33m"
  ["blue"]="\033[0;34m"
  ["magenta"]="\033[0;35m"
  ["cyan"]="\033[0;36m"
  ["white"]="\033[0;37m"
  ["bright_black"]="\033[1;30m"
  ["bright_red"]="\033[1;31m"
  ["bright_green"]="\033[1;32m"
  ["bright_yellow"]="\033[1;33m"
  ["bright_blue"]="\033[1;34m"
  ["bright_magenta"]="\033[1;35m"
  ["bright_cyan"]="\033[1;36m"
  ["bright_white"]="\033[1;37m"
  ["bright_orange"]="\033[5;91m"
)

# Función para aplicar color
colorize() {
  local color=$1
  local text=$2
  local reset_color="\033[0m"
  echo -e "${colors[$color]}${text}${reset_color}"
}

animated_text() {
    local text="$1"
    local color="$2"
    local delay=0.07
    for ((i=0; i<${#text}; i++)); do
        # colorize 
        printf "%s" "$(colorize "$color" "${text:$i:1}")"
        sleep $delay
    done
    printf "\n"
}

scrolling_text_animation() {
    local pid=$1
    local text=" • Unpacking Super Image please wait..."
    local width=$(stty size | cut -d' ' -f2)
    local len=${#text}
    local delay=0.1
    local i=0

    # Colores para el texto estático y en movimiento
    local static_color="\033[0;36m"  # orange 
    local moving_color="\033[5;91m"  # white
    local reset_color="\033[0m"

    while kill -0 "$pid" 2>/dev/null; do
        # Texto estático (parte no movida)
        printf "\r${static_color}%s" "${text:0:i}"

        # Texto en movimiento (parte movida)
        printf "${moving_color}%s${static_color}" "${text:i:width-i}"

        sleep "$delay"
        i=$((i + 1))
        if [ $i -ge $len ]; then
            i=0
        fi
    done

    # Al finalizar, aseguramos que el texto completo se muestre en el color estático y restablecemos el color al final
    printf "\r${static_color}%s${static_color}\n" "${text}"
    echo " "
}

animation_bar() {
    # Obtener el ancho de la terminal automáticamente
    ancho=$(stty size | cut -d' ' -f2)
    
    while true; do
        # Movimiento de izquierda a derecha
        for (( i=o; i<ancho; i++ )); do
            printf "\r%*s" $i "ᗧ••"
            sleep 0.1
        done

        # Movimiento de derecha a izquierda
        for (( i=ancho; i>=0; i-- )); do
            printf "\r%*s" $i "•"
            sleep 0.1
        done
    done
}

# Unpack Super image 
unpack_super() {
    local img_file="$1"
    local output_file="$2"

    # Obtener la ruta del directorio del script
    local script_dir="/data/local/Super_Image/SUPER_BIN"

    # Tool folder 
    local lpunpack_tool="$script_dir/lpunpack"

    # Mensaje de inicio
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')"  
    echo -e "$(colorize 'yellow' '│• Unpacking partitions') $img_file $(colorize 'yellow' 'in') $output_file..."
    log_message "│ Unpacking partitions $img_file in $output_file"

    # Ejecutar el comando real en segundo plano
    sleep 1
    "$lpunpack_tool" "$img_file" "$output_file" >/dev/null 2>&1 &
    local process_pid=$!

    # Ejecutar la animación en segundo plano
    echo -e "$(colorize 'yellow' '│ ')"
    scrolling_text_animation "$process_pid" &
    # Esperar a que el proceso principal termine
    wait $process_pid

    # Mensaje de resultado
    if [[ $? -ne 0 ]]; then
        echo -e "$(colorize 'yellow' '│ ')"
        sleep 1
        echo -e "$(colorize 'red' '│• Unpacking error') $img_file"
        log_message "│ Unpacking error $img_file"
    else
        echo " "
        echo -e "$(colorize 'yellow' '│ ')"
        sleep 1
        animated_text "│• Unpacking completed" "yellow"
        log_message "│ Unpacking completed."
    fi

    echo -e "$(colorize 'yellow' "╰──────")"
}

# Edit & Repack Super 
edit_repack_super() {
  local img_file="$1"
  local output_dir="$2"
  local repack_image="$3"

  local script_dir="/data/local/Super_Image/SUPER_BIN"
  local lpdump_tool="$script_dir/lpdump"
  local lpmake_tool="$script_dir/lpmake"
  local resize2fs_tool="$script_dir/resize2fs"
  local e2fsck_tool="$script_dir/e2fsck"
  local tune2fs="$script_dir/tune2fs"
  local mount_img="$script_dir/mount.sh"
  local umount_img="$script_dir/umount.sh"
  local img2simg_tool="$script_dir/img2simg"
  local super_images="/data/local/Super_Image/FILES/SUPER"
  local super_raw="$super_images/repacked_super_rw.img"
  local super_sparse="$super_images/repacked_super_sparse_rw.img"
  local lpdump_output="$script_dir/lpdump_output.txt"
  
  echo $(colorize 'yellow' "╭────── INFO OF SUPER IMAGE") 
  sleep 1
  echo -e "$(colorize 'yellow' '│•') Obtaining info of Super"
  log_message "│Obtaining info of Super"
  "$lpdump_tool" "$img_file" > "$lpdump_output" 2>&1

  if [[ $? -ne 0 ]]; then
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')Error obtaining info of Super."
    log_message "│Error obtaining info of Super."
    return 1
  fi

  local partition_params=""
  declare -A partitions
  local part_name=""
  local part_group=""
  local part_size=""
  local in_extents=0

  local group_name=""
  local metadata_slots=2
  local metadata_size=65536

  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│•') Processing info of Super..."
  log_message "│ Processing info of Super..."

  while IFS= read -r line; do
    if [[ $line == "Metadata slot count:"* ]]; then
      metadata_slots=$(echo $line | awk -F "Metadata slot count: " '{print $2}' | awk '{print $1}')
      echo " Metadata slots found: $metadata_slots" &>> "$LOG_FILE"
    elif [[ $line == "Metadata max size:"* ]]; then
      metadata_size=$(echo $line | awk -F "Metadata max size: " '{print $2}' | awk '{print $1}')
      echo " Metadata size found: $metadata_size" &>> "$LOG_FILE"
    elif [[ $line == "  Name:"* ]]; then
      part_name=$(echo $line | awk -F "Name: " '{print $2}')
      echo " Name found: $part_name" &>> "$LOG_FILE"
    elif [[ $line == "  Group:"* ]]; then
      part_group=$(echo $line | awk -F "Group: " '{print $2}')
      echo " Group Partition found: $part_group" &>> "$LOG_FILE"
      if [[ -z "$group_name" ]]; then
        group_name="$part_group"
        echo " Assigned group name: $group_name" &>> "$LOG_FILE"
      fi
    elif [[ $line == *" linear super "* ]]; then
      in_extents=1
      local sectors=$(echo $line | awk -F' linear super ' '{print $1}' | awk '{print $NF}')
      local size=$((sectors * 512))
      if [[ $size -gt 0 ]]; then
        part_size=$size
        echo " Partition size: $part_size bytes" &>> "$LOG_FILE"
      fi
    elif [[ $line == "------------------------" && $in_extents -eq 1 ]]; then
      if [[ -n "$part_name" && -n "$part_group" && -n "$part_size" ]]; then
        partitions[$part_name]="--partition $part_name:readonly:$part_size:$part_group --image $part_name=$output_dir/$part_name.img"
        echo " Added partition parameters: ${partitions[$part_name]}" &>> "$LOG_FILE"
      fi
      echo "Partition $part_name size: $part_size bytes" &>> "$LOG_FILE"
      part_name=""
      part_group=""
      part_size=""
      in_extents=0
    fi
  done < "$lpdump_output"

  for partition in "${!partitions[@]}"; do
    partition_params+=" ${partitions[$partition]}"
  done

  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│•') Building partition parameters"
  echo "Building partition parameters: $partition_params" &>> "$LOG_FILE"

  if [[ -z "$partition_params" ]]; then
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1
    echo -e "$(colorize 'yellow' '│•') Error: No partition parameters were constructed. Check the content of lpdump_output.txt."
    log_message "│ Error: No partition parameters were constructed. Check the content of lpdump_output.txt."
    return 1
  fi

  local original_size=$(stat -c%s "$img_file")

  local default_reserved_space=4194304
  local factor_de_seguridad=3
  local reserved_space=$(($metadata_size * $metadata_slots * $factor_de_seguridad))

  if [[ $reserved_space -lt $default_reserved_space ]]; then
    reserved_space=$default_reserved_space
  fi

  echo " Calculated Reserved Space: $reserved_space bytes" &>> "$LOG_FILE"

  local group_size=$(($original_size - $metadata_size * $metadata_slots - $reserved_space))
  
  # Obtener el tamaño total de la partición super
  local super_size=$(grep -m1 'Partition name: super' -A2 "$lpdump_output" | grep 'Size:' | awk '{print $2}')
  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│•') Super Image Size: $super_size bytes"
  log_message "│ Super Image Size: $super_size bytes"

  # Inicializar variables para el cálculo
  local total_partition_size=0

  # Calcular el tamaño total de todas las subparticiones
  while IFS= read -r line; do
    if [[ $line == *" linear super "* ]]; then
      local sectors=$(echo $line | awk -F' linear super ' '{print $1}' | awk '{print $NF}')
      local size=$((sectors * 512))
      total_partition_size=$((total_partition_size + size))
    fi
  done < "$lpdump_output"
  
  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│•') Total size of all partitions: $total_partition_size bytes"
  log_message "│ Total size of all partitions: $total_partition_size bytes"

  # Calcular el espacio libre en la partición super
  local free_space=$((super_size - total_partition_size - reserved_space))
  local free_space_mb=$((free_space / 1024 / 1024))
  local max_safe_size_mb=$free_space_mb
  
  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│•') The free size is: $max_safe_size_mb MB"
  log_message "│ The free size is: $max_safe_size_mb MB"
  echo $(colorize 'yellow' "╰──────")

  if [[ $max_safe_size_mb -le 99999999 ]]; then
    echo " "
    echo $(colorize 'yellow' "╭────── ADJUST SIZES") 
    sleep 1
    echo -e "$(colorize 'yellow' '│')$(colorize 'bright_cyan' '• Adjusting partitions to get more free size in:')"
    log_message "│ Adjusting partitions to get more free size:"
    for part in "${!partitions[@]}"; do
      local part_img="$output_dir/$part.img"
      echo -e "$(colorize 'yellow' '│ ')- $part_img"
      log_message "│- Adjusting size of $part_img"
      $e2fsck_tool -fy "$part_img" &>> "$LOG_FILE"
      $resize2fs_tool -f -M "$part_img" &>> "$LOG_FILE"
      $e2fsck_tool -fy "$part_img" &>> "$LOG_FILE"
      if [[ $? -ne 0 ]]; then
        echo -e "$(colorize 'yellow' '│•') Error minimizing $part_img"
        log_message "│ Error minimizing $part_img"
      fi
    done

    # Recalcular el tamaño de cada subpartición
    for part in "${!partitions[@]}"; do
      local part_img="$output_dir/$part.img"
      local size=$(stat -c%s "$part_img")
      partitions[$part]=$size
    done

    # Recalcular el tamaño total de las subparticiones
    total_partition_size=0
    for size in "${partitions[@]}"; do
      total_partition_size=$((total_partition_size + size))
    done

    # Recalcular el espacio libre después de minimizar
    free_space=$((super_size - total_partition_size - reserved_space))
    free_space_mb=$((free_space / 1024 / 1024))
    echo $(colorize 'yellow' "╰──────")
    echo " "
    echo $(colorize 'yellow' "╭────── EXPAND PARTITIONS") 
    sleep 1
    echo -e "$(colorize 'yellow' '│')$(colorize 'bright_cyan' '• The new free size is:') $free_space_mb MB"
    log_message "│ The new free size is: $free_space_mb MB"
  fi

  # Solicitar al usuario el espacio extra en MB para cada partición
  declare -A extra_sizes
  local remaining_space_mb=$free_space_mb
  for part in "${!partitions[@]}"; do
    while true; do
      echo -e "$(colorize 'yellow' '│ ')"
      sleep 0.2
      echo -e "$(colorize 'yellow' '│•') ¿How many MB do you want to add to $part?"
      echo -e "$(colorize 'yellow' '│')- Available size: $remaining_space_mb MB"
      log_message "│ ¿How many MB do you want to add to $part? (Available size: $remaining_space_mb MB)"
      spacer="   "
      echo -ne "${spacer}$(colorize 'green' 'Please enter a value: ')"

      # Leer el valor del usuario
      read extra_mb
            
      if [[ $extra_mb -le $remaining_space_mb ]]; then
        local extra_space=$((extra_mb * 1024 * 1024))
        extra_sizes[$part]=$extra_space
        remaining_space_mb=$((remaining_space_mb - extra_mb))
        break
      else
        echo -e "$(colorize 'yellow' '│ ')"
        sleep 1
        echo -e "$(colorize 'yellow' '│ ')Invalid size. Try again."
      fi
    done
  done
  echo $(colorize 'yellow' "╰──────")
  echo " "
  echo $(colorize 'yellow' " ⦾ RESIZE AND FREE SPACE")

  # Ajustar el tamaño de cada partición con el espacio extra
  declare -A new_sizes
  for part in "${!extra_sizes[@]}"; do
    local part_img="$output_dir/$part.img"
    local extra_space=${extra_sizes[$part]}
    local current_size=$(stat -c%s "$part_img")
    local new_size=$((current_size + extra_space))
    local new_size_blocks=$(( (new_size + 4095) / 4096 ))
    echo " "
    sleep 1
    echo $(colorize 'bright_cyan' " ➤ Resizing $part_img to $new_size bytes ($new_size_blocks blocks)")
    log_message " ➤ Resizing $part_img to $new_size bytes ($new_size_blocks blocks)"
    $e2fsck_tool -fy "$part_img" &>> "$LOG_FILE"
    $resize2fs_tool -f "$part_img" "$new_size_blocks"s &>> "$LOG_FILE"
    $e2fsck_tool -fy "$part_img" &>> "$LOG_FILE"
    if [[ $? -ne 0 ]]; then
      echo " "
      sleep 1
      echo -e "$(colorize 'yellow' '│ ')Error resizing $part_img"
      log_message "│ Error resizing $part_img"
      exit 1
    fi
    new_sizes[$part]=$new_size
  done
  
  for img_file_resize in "$output_dir"/*.img; do
    part_name=$(basename "$img_file_resize" .img)

    # Obtener tamaño del bloque y bloques libres 
    local block_size=$($tune2fs -l "$img_file_resize" | grep "Block size" | awk '{print $3}')
    local free_blocks=$($tune2fs -l "$img_file_resize" | grep "Free blocks" | awk '{print $3}')
    local free_space_mb_img=$((free_blocks * block_size / 1024 / 1024))

    echo " "
    sleep 1
    echo $(colorize 'bright_yellow' " ➤ Free space on partition $img_file_resize $free_space_mb_img MB")
    log_message " ➤ Free space on partition $img_file_resize $free_space_mb_img MB"
  done
    
    # Edit Partitions 
    echo " "
    echo $(colorize 'yellow' "╭────── EDIT YOUR PARTITIONS") 
    sleep 1
    echo -e "$(colorize 'yellow' '│•') It's time to edit your partitions"
    log_message "│ It's time to edit your partitions"
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1
    echo -e "$(colorize 'yellow' '│•') Use$(colorize 'bright_cyan' ' MT Manager app')"
    log_message "│ Use Mt Manager app"
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│•')$(colorize 'bright_cyan' ' Go to') $output_dir"
    log_message "│ Go to $output_dir"
    cp $mount_img "$output_dir"
    cp $umount_img "$output_dir"
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│•') To edit your partitions$(colorize 'bright_cyan' ' run the file mount.sh (Mark root)')"
    log_message "│ To edit your partitions run the file mount.sh (Mark root)"
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│•') When you finish editing,$(colorize 'bright_cyan' ' run the umount.sh file')"
    log_message "│ When you finish editing, run the umount.sh file"
            
    # pause
    while true; do
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│')$(colorize 'bright_red' ' SCRIPT PAUSED')"
    log_message "│ Script paused"
    sleep 1
    echo -e "$(colorize 'yellow' '│ ')"
      read -p "│ When you have finished the process, type done and press enter to continue   " input
       if [[ "$input" == "$PAUSE_SCRIPT" ]]; then
          echo $(colorize 'yellow' "│ The process continue...")
          log_message "│ The process continue..."
          break  # Salir del bucle y continuar el script
       else
          echo $(colorize 'red' "│ Incorrect word.  try again")
          log_message "│ Incorrect word.  try again."
       fi
       done

       for img_file in "$output_dir"/*.img; do
          part_name=$(basename "$img_file" .img)

          # Check and repair image 
          echo -e "$(colorize 'yellow' '│ ')"
          sleep 1
          echo -e "$(colorize 'yellow' '│•') Checking and repairing any errors in:"
          echo "- $img_file"
          log_message "│ Checking and repairing any errors in: $img_file"
          $e2fsck_tool -fy "$img_file" &>> "$LOG_FILE"
       done
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1
    echo -e "$(colorize 'yellow''│ ')• The process has been completed successfully"
    log_message " The process has been completed successfully"
    echo $(colorize 'yellow' "╰──────")
    rm -f $output_dir/mount.sh
    rm -f $output_dir/umount.sh

   # Calcular el tamaño total de todas las particiones expandidas
  local total_partition_size=0
  for part in "${!partitions[@]}"; do
    local size=$(stat -c%s "$output_dir/$part.img")
    total_partition_size=$((total_partition_size + size))
  done

  # Agregar un margen de reserva si es necesario
  local reserved_space=4194304 # o el valor calculado
  local new_group_size=$((total_partition_size + reserved_space))

  echo " "
  echo $(colorize 'yellow' "╭────── COMPILE YOUR SUPER IMAGE") 
  sleep 1
  echo -e "$(colorize 'yellow' '│•') New partition group size: $new_group_size bytes"
  log_message "│ New partition group size: $new_group_size bytes"

  # Reconstruir los parámetros de partición con los nuevos tamaños
  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│•') Building all the changes to be able to compile super.img"
  log_message "│ Building all the changes to be able to compile super.img"
  for part in "${!partitions[@]}"; do
    local new_size=${new_sizes[$part]:-${partitions[$part]}}
    partitions[$part]="--partition $part:none:$new_size:$group_name --image $part=$output_dir/$part.img"
  done

  partition_params=""
  for partition in "${!partitions[@]}"; do
    partition_params+=" ${partitions[$partition]}"
  done

  # Actualizar el comando lpmake con el nuevo tamaño del grupo
  local lpmake_cmd="$lpmake_tool --metadata-size $metadata_size --super-name super --metadata-slots $metadata_slots --device super:$original_size --group $group_name:$new_group_size --output $repack_image $partition_params"

  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│• Repacking Super Image:') $lpmake_cmd"
  log_message "│ Repacking Super Image: $lpmake_cmd"
  eval "$lpmake_cmd"

  if [[ $? -ne 0 ]]; then
    echo -e "$(colorize 'yellow' '│ ')"
    sleep 1
    echo -e "$(colorize 'yellow' '│•') Error packing partitions."
    log_message "│ Error packing partitions."
    exit 1
  fi

  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│')$(colorize 'bright_cyan' '• Repacking completed. The new super.img file is in') $repack_image"
  log_message "│ Repacking completed. The new super.img file is in $repack_image"
  
  # Confirmación para exportar en sparse
  echo -e "$(colorize 'yellow' '│ ')"
  echo -e "$(colorize 'yellow' '│• ¿You want to export the super.img in sparse format?')"
  echo -e "$(colorize 'yellow' '│•') Type $(colorize 'bright_cyan' 'yes') to export in sparse or $(colorize 'bright_cyan' 'no') to skip"
  read -p " Write your selection: " user_choice

  # Manejar la elección del usuario
  if [ "$user_choice" == "yes" ]; then
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│• Converting super.img Raw image to Sparse image format')"
    echo " "
    sleep 1
    echo "$(colorize 'bright_orange' ' Please wait, this may take a while')"
    "$img2simg_tool" "$super_raw" "$super_sparse"
    echo -e "$(colorize 'bright_cyan' '│ Conversion to sparse format completed. File saved in:') $super_sparse."
    log_message "│ Conversion to sparse format completed. File saved in $super_sparse."
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│• Process finished')"
    if [[ $? -ne 0 ]]; then
      echo -e "$(colorize 'yellow' '│ ')"
      sleep 1
      echo -e "$(colorize 'yellow' '│ ')Error converting $super_raw to sparse format."
      log_message "│ Error converting $super_raw to sparse format."
      return 1
    fi
  elif [ "$user_choice" == "no" ]; then
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│• ')Skipping conversion to sparse image"
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│• Process finished')"
  else
    echo "Invalid option. Sparse format export was not performed"
  fi
  echo "$(colorize 'yellow' '╰──────')"
}

# Disable vbmeta 
disable_vbmeta_verification() {

    # Variables
    local AVBCTL_TOOL="/data/local/Super_Image/SUPER_BIN/avbctl"
    local BACKUP_DIR="/data/local/Super_Image/FILES/VBMETA"
    local BLOCK_DIR="/dev/block/by-name"

    # Crear directorio de backup si no existe
    mkdir -p "$BACKUP_DIR"

    # Obtener todas las particiones vbmeta
    vbmeta_partitions=$(ls $BLOCK_DIR | grep vbmeta)

    # Comprobar si se encontraron particiones vbmeta
    if [ -z "$vbmeta_partitions" ]; then
        echo -e "$(colorize 'red' 'No vbmeta partitions found.')"
        return 1
    fi

    # Hacer backup, aplicar avbctl y exportar los vbmeta modificados
    for partition in $vbmeta_partitions; do
        # Definir rutas
        vbmeta_path="$BLOCK_DIR/$partition"
        vbmeta_backup="$BACKUP_DIR/${partition}_backup.img"
        vbmeta_modified="$BACKUP_DIR/${partition}_patched.img"

        # Hacer backup del vbmeta original
        echo " "
        sleep 1
        echo -e "$(colorize 'yellow' '╭──────')"
        echo -e "$(colorize 'yellow' '│ ')Backing up $partition to $vbmeta_backup..."
        dd if="$vbmeta_path" of="$vbmeta_backup" bs=4096 &> /dev/null

        # Aplicar avbctl para deshabilitar verity y verification
        echo " "
        sleep 1
        echo -e "$(colorize 'yellow' '│ ')Disabling verity and verification on $partition..."
        $AVBCTL_TOOL disable-verity --partition "$vbmeta_path" &> /dev/null
        disable_verity_status=$?
        $AVBCTL_TOOL disable-verification --partition "$vbmeta_path" &> /dev/null
        disable_verification_status=$?

        # Si ambos comandos de avbctl se ejecutaron con éxito
        if [ $disable_verity_status -eq 0 ] && [ $disable_verification_status -eq 0 ]; then
            # Exportar el vbmeta modificado
            echo -e "$(colorize 'yellow' '│ ')"
            sleep 1
            echo -e "$(colorize 'yellow' '│ ')Exporting modified $partition to $vbmeta_modified..."
            dd if="$vbmeta_path" of="$vbmeta_modified" bs=4096 &> /dev/null
            echo -e "$(colorize 'yellow' '│ ')"
            echo -e "$(colorize 'green' ' Process completed successfully!')"
            echo -e "$(colorize 'yellow' '╰──────')"
        else
            echo -e "$(colorize 'yellow' '│ ')"
            sleep 1
            echo -e "$(colorize 'red' 'Failed to disable verity and verification on $partition. Keeping only the backup.')"
            echo -e "$(colorize 'yellow' '╰──────')"
        fi

        # Restaurar los vbmeta originales
        dd if="$vbmeta_backup" of="$vbmeta_path" bs=4096 &> /dev/null

        # Eliminar el backup después de la restauración
        rm -f "$vbmeta_backup"
    done   
}

# Función para mostrar el espacio libre de la partición en MB
show_free_space() {
    local img_file=$1

    # Tool
    local script_dir="/data/local/Super_Image/SUPER_BIN"
    local tune2fs="$script_dir/tune2fs"
    
    # Obtener tamaño del bloque y bloques libres usando tune2fs
    local block_size=$($tune2fs -l "$img_file" | grep "Block size" | awk '{print $3}')
    local free_blocks=$($tune2fs -l "$img_file" | grep "Free blocks" | awk '{print $3}')

    # Calcular espacio libre en MB
    local free_space_mb=$((free_blocks * block_size / 1024 / 1024))
    echo " "
    sleep 1
    echo " $free_space_mb MB"
    log_message " $free_space_mb MB"
}

# Función para mostrar el espacio libre de la partición en MB
check_repair_image() {
    local img_file=$1

    # Tool
    local script_dir="/data/local/Super_Image/SUPER_BIN"
    local e2fsck="$script_dir/e2fsck"
    
    # Revisar y repersr errores
    $e2fsck -f -y "$img_file" >> "$LOG_FILE"
}

# Función para comprobar si hay archivos EROFS
check_erofs_images() {
  local img_dir="$1"
  local system="/data/local/Super_Image/UNPACKED/system.img"
  local system_a="/data/local/Super_Image/UNPACKED/system_a.img"
  local erofs_detected=false

  # Verifica si system.img existe y es EROFS
  if [[ -f "$system" ]]; then
    if magic_file -type erofs "$system" 2>/dev/null; then
      echo "EROFS file detected: $system"
      erofs_detected=true
    else
      echo "File is not EROFS: $system" &>> "$LOG_FILE"
    fi
  fi

  # Si no se detectó EROFS en system.img, verifica system_a.img
  if [[ "$erofs_detected" == false && -f "$system_a" ]]; then
    if magic_file -type erofs "$system_a" 2>/dev/null; then
      echo "EROFS file detected: $system_a"
      erofs_detected=true
    else
      echo "File is not EROFS: $system_a" &>> "$LOG_FILE"
    fi
  fi

  # Si no se detectó EROFS en ninguno de los dos archivos, sal con error
  echo "No EROFS files detected ." &>> "$LOG_FILE"
  if [[ "$erofs_detected" == false ]]; then
    return 1
  fi
}

z_repack_super() {
  local img_file="$1"
  local output_dir="$2"
  local repack_image="$3"

  local script_dir="/data/local/Super_Image/SUPER_BIN"
  local lpdump_tool="$script_dir/lpdump"
  local lpmake_tool="$script_dir/lpmake"
  local lpdump_output="$script_dir/lpdump_output.txt"
  local super_images="/data/local/Super_Image/FILES/SUPER"
  local super_raw="$super_images/repacked_super_rw.img"
  local super_sparse="$super_images/repacked_super_sparse_rw.img"
  local img2simg_tool="$script_dir/img2simg"
  local reservation_margin=10485760  # 10MB

  echo " "
  echo $(colorize 'yellow' "╭────── INFO OF SUPER IMAGE") 
  sleep 1
  echo -e "$(colorize 'yellow' '│ ')Obtaining info of Super"
  "$lpdump_tool" "$img_file" > "$lpdump_output" 2>&1

  if [[ $? -ne 0 ]]; then
     echo "│ Error obtaining info of Super."
     return 1
  fi

  local partition_params=""
  declare -A partitions
  local part_name=""
  local part_group=""
  local part_size=""
  local in_extents=0

  local group_name=""
  local metadata_slots=2
  local metadata_size=65536

  echo " "
  sleep 1
  echo -e "$(colorize 'yellow' '│ ')Processing info of Super..."
  while IFS= read -r line; do
  if [[ $line == "Metadata slot count:"* ]]; then
    metadata_slots=$(echo $line | awk -F "Metadata slot count: " '{print $2}' | awk '{print $1}')
  elif [[ $line == "Metadata max size:"* ]]; then
    metadata_size=$(echo $line | awk -F "Metadata max size: " '{print $2}' | awk '{print $1}')
  elif [[ $line == "  Name:"* ]]; then
    part_name=$(echo $line | awk -F "Name: " '{print $2}')
  elif [[ $line == "  Group:"* ]]; then
    part_group=$(echo $line | awk -F "Group: " '{print $2}')
  
  # Filtrar particiones cuyo grupo termine en _b (para dispositivos A/B)
  if [[ "$part_group" == *"_b" ]]; then
    # Reiniciar los valores si es un grupo _b y continuar con la siguiente línea
    part_name=""
    part_group=""
    continue
  fi

    if [[ -z "$group_name" ]]; then
      group_name="$part_group"
    fi
  elif [[ $line == *" linear super "* ]]; then
    in_extents=1
  elif [[ $line == "------------------------" && $in_extents -eq 1 ]]; then
    if [[ -n "$part_name" && -n "$part_group" ]]; then
      # Obtener el tamaño de la partición usando `stat`
      if [[ -f "$output_dir/$part_name.img" ]]; then
        part_size=$(stat -c%s "$output_dir/$part_name.img")
      else
        echo "│ Error: Image file for partition $part_name not found."
        return 1
      fi

      partitions[$part_name]="--partition $part_name:none:$part_size:$part_group --image $part_name=$output_dir/$part_name.img"
    fi
    part_name=""
    part_group=""
    part_size=""
    in_extents=0
  fi
done < "$lpdump_output"

  for partition in "${!partitions[@]}"; do
    partition_params+=" ${partitions[$partition]}"
  done

  local total_partition_size=0
  for part in "${!partitions[@]}"; do
    local size=$(stat -c%s "$output_dir/$part.img")
    total_partition_size=$((total_partition_size + size))
  done

  local group_size=$total_partition_size
  local device_size=$(stat -c%s "$img_file")

  echo " "
  sleep 1
  echo -e "$(colorize 'yellow' '│ ')Building partition parameters: $partition_params" 2>&1

  if [[ -z "$partition_params" ]]; then
    echo "│ Error: No partition parameters were constructed."
    return 1
  fi

  echo " "
  sleep 1
  echo -e "$(colorize 'yellow' '│ ')Repacking Super Image..."
  local lpmake_cmd="$lpmake_tool --metadata-size $metadata_size --super-name super --metadata-slots $metadata_slots --device super:$device_size --group $group_name:$group_size --output $repack_image $partition_params"
  
  eval "$lpmake_cmd"

  if [[ $? -ne 0 ]]; then
    echo -e "$(colorize 'red' ' ⛔ Error repacking Check if you have space available on your device to compile the super image')"
    echo " "
    sleep 1
    echo -e "$(colorize 'yellow' ' Use the extra menu options to debloat and free up space.')"
    echo " "
    sleep 1
    echo -e "$(colorize 'yellow' ' And you use this option again.')"
    echo "$(colorize 'yellow' '╰──────')"
    return 1
  fi

  echo -e "$(colorize 'yellow' '│ ')"
  sleep 1
  echo -e "$(colorize 'yellow' '│')$(colorize 'bright_cyan' '• Repacking completed. The new super.img file is in') $repack_image"
  log_message "│ Repacking completed. The new super.img file is in $repack_image"
  
  # Confirmación para exportar en sparse
  echo -e "$(colorize 'yellow' '│ ')"
  echo -e "$(colorize 'yellow' '│• ¿You want to export the super.img in sparse format?')"
  echo -e "$(colorize 'yellow' '│•') Type $(colorize 'bright_cyan' 'yes') to export in sparse or $(colorize 'bright_cyan' 'no') to skip"
  read -p " Write your selection: " user_choice

  # Manejar la elección del usuario
  if [ "$user_choice" == "yes" ]; then
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│• Converting super.img Raw image to Sparse image format')"
    echo " "
    sleep 1
    echo "$(colorize 'bright_orange' ' Please wait, this may take a while')"
    "$img2simg_tool" "$super_raw" "$super_sparse"
    echo -e "$(colorize 'bright_cyan' '│ Conversion to sparse format completed. File saved in:') $super_sparse."
    log_message "│ Conversion to sparse format completed. File saved in $super_sparse."
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│• Process finished')"
    if [[ $? -ne 0 ]]; then
      echo -e "$(colorize 'yellow' '│ ')"
      sleep 1
      echo -e "$(colorize 'yellow' '│ ')Error converting $super_raw to sparse format."
      log_message "│ Error converting $super_raw to sparse format."
      return 1
    fi
  elif [ "$user_choice" == "no" ]; then
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│• ')Skipping conversion to sparse image"
    echo -e "$(colorize 'yellow' '│ ')"
    echo -e "$(colorize 'yellow' '│• Process finished')"
  else
    echo "Invalid option. Sparse format export was not performed"
  fi
  echo "$(colorize 'yellow' '╰──────')"
}

# Función para calcular el tamaño del sistema de archivos en bytes
get_filesystem_size_bytes() {
    local img_file="$1"
    local block_size
    local block_count

    block_size=$($tune2fs -l "$img_file" | grep "Block size" | awk '{print $3}')
    block_count=$($tune2fs -l "$img_file" | grep "Block count" | awk '{print $3}')
    
    local size_bytes=$((block_size * block_count))
    echo "$size_bytes"
}

# Función para calcular el espacio libre en MB
get_free_space_mb() {
    local img_file="$1"
    local block_size
    local free_blocks

    block_size=$($tune2fs -l "$img_file" | grep "Block size" | awk '{print $3}')
    free_blocks=$($tune2fs -l "$img_file" | grep "Free blocks" | awk '{print $3}')
    
    local free_space_mb=$((free_blocks * block_size / 1024 / 1024))
    echo "$free_space_mb"
}

# Función para contar directorios que contienen APKs
count_apk_dirs() {
    local dir="$1"
    local count=0
    for folder in "$dir"/*/; do
        if compgen -G "$folder"/*.apk > /dev/null; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

# Función para listar y navegar directorios
navigate_directory() {
    local current_dir="$1"
    local depth="$2"

    while true; do
        echo -e "\n ⩥ Current directory: $(colorize bright_cyan "$current_dir")"
        subdirs=()
        apk_dirs=()
        non_apk_dirs=()

        while IFS= read -r -d $'\0' dir; do
            subdirs+=("$dir")
            if compgen -G "$dir"/*.apk > /dev/null; then
                apk_dirs+=("$dir")
            else
                non_apk_dirs+=("$dir")
            fi
        done < <(find "$current_dir" -maxdepth 1 -type d -not -path '*/\.*' -not -path "$current_dir" -print0 | sort -z)

        local count_apks=${#apk_dirs[@]}

        # Si hay más de dos directorios con APKs, muestra la opción para eliminarlos
        if [[ $count_apks -gt 1 ]]; then
            delete_items "$current_dir" "apk"
            return
        fi

        # Verifica si estamos en el nivel 3 o más
        if [[ "$depth" -ge 3 || ${#subdirs[@]} -eq 0 ]]; then
            delete_items "$current_dir"
            return
        fi

        if [[ ${#subdirs[@]} -eq 0 ]]; then
            colorize red " No subdirectories found."
            return
        fi

        for i in "${!subdirs[@]}"; do
            folder_name=$(basename "${subdirs[$i]}")
            if compgen -G "${subdirs[$i]}"/*.apk > /dev/null; then
                echo " $((i + 1))) $(colorize red "$folder_name") [Contains APK]"
            else
                echo " $((i + 1))) $(colorize yellow "$folder_name")"
            fi
        done
        echo " $(( ${#subdirs[@]} + 1 ))) $(colorize bright_green "Go back")"

        read -p " Select an option: " choice

        if [[ "$choice" -eq $(( ${#subdirs[@]} + 1 )) ]]; then
            return
        elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#subdirs[@]} )); then
            next_dir="${subdirs[$((choice - 1))]}"
            if compgen -G "$next_dir"/*.apk > /dev/null && [[ $count_apks -gt 2 ]]; then
                delete_items "$next_dir"
            else
                navigate_directory "$next_dir" $((depth + 1))
            fi
        else
            colorize red " Invalid option. Please try again."
        fi
    done
}

# Función para eliminar files
delete_items() {
    local current_dir="$1"
    local mode="$2"
    local items_per_page=20  # Número de elementos por página
    local current_page=1

    while true; do
        echo -e "\n ⩥ Current directory: $(colorize bright_cyan "$current_dir")"
        items=()
        while IFS= read -r -d $'\0' dir; do
            if [[ "$mode" == "apk" ]]; then
                if compgen -G "$dir"/*.apk > /dev/null; then
                    items+=("$dir")
                fi
            else
                items+=("$dir")
            fi
        done < <(find "$current_dir" -maxdepth 1 -type d -not -path '*/\.*' -not -path "$current_dir" -print0 | sort -z)

        total_items=${#items[@]}
        total_pages=$(( (total_items + items_per_page - 1) / items_per_page ))

        start_index=$(( (current_page - 1) * items_per_page ))
        end_index=$(( start_index + items_per_page - 1 ))
        [ $end_index -ge $total_items ] && end_index=$((total_items - 1))

        # Mostrar elementos en la página actual
        for i in $(seq $start_index $end_index); do
            echo " $((i + 1))) $(colorize yellow "$(basename "${items[$i]}")")"
        done
        echo " $(( ${total_items} + 1 ))) $(colorize bright_green "Back")"

        # Mostrar control de paginación
        if (( total_pages > 1 )); then
            echo -e "\n Page $current_page of $total_pages"
            [[ $current_page -gt 1 ]] && echo " $(colorize yellow "< Prev [Type p to go to the previous page] ")"
            [[ $current_page -lt $total_pages ]] && echo " $(colorize cyan "Next >[Type 'n' to go to the next page]")" 
        fi

        read -p " Select one or more folders to delete, or navigate pages (example: 1,10,12, n,p): " selection

        if [[ "$selection" =~ ^[0-9,]+$ ]]; then
            IFS=',' read -ra selected_items <<< "$selection"

            colorize bright_yellow " Deleting selected files..."
            for index in "${selected_items[@]}"; do
                if [[ "$index" =~ ^[0-9]+$ ]] && (( index > 0 && index <= ${#items[@]} )); then
                    item_to_delete="${items[$((index - 1))]}"
                    echo -e "\n Deleting: $(colorize bright_orange "$item_to_delete")"
                    rm -rf "$item_to_delete"
                elif [[ "$index" -eq $(( ${total_items} + 1 )) ]]; then
                    return
                else
                    colorize red " Invalid option: $index"
                fi
            done
        elif [[ "$selection" == "n" && $current_page -lt $total_pages ]]; then
            current_page=$((current_page + 1))
        elif [[ "$selection" == "p" && $current_page -gt 1 ]]; then
            current_page=$((current_page - 1))
        elif [[ "$selection" -eq $(( ${total_items} + 1 )) ]]; then
            return
        else
            colorize red " Invalid option. Please try again."
        fi
    done
}

# Función principal del menú
main_menu() {
    local base_dir="$BASE_DIR"

    while true; do
        echo -e "\n ⩥ Base directory: $(colorize bright_cyan "$base_dir")"
        subdirs=()
        while IFS= read -r -d $'\0' dir; do
            subdirs+=("$dir")
        done < <(find "$base_dir" -maxdepth 1 -type d -not -path '*/\.*' -not -path "$base_dir" -print0 | sort -z)

        for i in "${!subdirs[@]}"; do
            echo " $((i + 1))) $(colorize bright_yellow "$(basename "${subdirs[$i]}")")"
        done
        echo " $(( ${#subdirs[@]} + 1 ))) $(colorize bright_green "Exit Menu")"

        read -p " Select an option: " base_choice

        if [[ "$base_choice" -eq $(( ${#subdirs[@]} + 1 )) ]]; then
            colorize red " Exiting..."
            break
        elif [[ "$base_choice" =~ ^[0-9]+$ ]] && (( base_choice > 0 && base_choice <= ${#subdirs[@]} )); then
            selected_dir="${subdirs[$((base_choice - 1))]}"
            navigate_directory "$selected_dir" 1
        else
            colorize red " Invalid option. Please try again..."
        fi
    done
}

# Función para aplicar color
colorize2() {
  local color=$1
  local text=$2
  local reset_color="\033[0m"
  echo -ne "${colors[$color]}${text}${reset_color}"
}

print_powered_by() {
  local reset_color="\033[0m"
  echo -e "${colors['green']}   — Powered by ${colors['yellow']}Zonik —${reset_color}"
}

# Obtener el espacio total y libre en /data
size_data=$(df -h | grep '/data' | head -n 1 | awk '{print $2}')
free_data=$(df -h | grep '/data' | head -n 1 | awk '{print $4}')
tool_version=1.2

Main="/data/local/Super_Image"
EXTRACT_DIR="$Main/UNPACKED"
EXTRACT_DIR_MOUNT="$Main/UNPACKED/MOUNT"
FILES_SUPER="$Main/FILES/SUPER"
FILES_VBMETA="$Main/FILES/VBMETA"
EXTRACT_DIR_EROFS="$Main/UNPACKED/EROFS"
SUPER_BIN="$Main/SUPER_BIN"
erofs_extract="$SUPER_BIN/extract.erofs"
MAKE_EXT4FS="$SUPER_BIN/make_ext4fs"
E2FSCK="$SUPER_BIN/e2fsck"
resize="$SUPER_BIN/resize2fs"
tune2fs="$SUPER_BIN/tune2fs"
SUPER="$FILES_SUPER/super.img"
SUPER_BLOCK=$(find_block super)
REPACKED_IMG="$FILES_SUPER/repacked_super_rw.img"
INSTALLER=$SUPER_BIN/Super_Image-INSTALLER.zip
XIAOMI="$Main/XIAOMI"
PAUSE_SCRIPT="done"
# Factor de seguridad
safety_factor=1.2

cp $INSTALLER "/sdcard"

# Verifica si la carpeta ya existe
echo " "
echo $(colorize 'bright_yellow' " Checking if Super_Image folder exists")
echo " "
if [ -d "$Main" ]; then
    sleep 0.5
    echo $(colorize 'bright_cyan' " The folder '$Main' already exists.")
    echo " "
else
    # Crea la nueva carpeta
    mkdir -p "$Main" "$FILES_SUPER" "$FILES_VBMETA" "$EXTRACT_DIR" "$XIAOMI"
    if [ $? -eq 0 ]; then
        sleep 0.5
        echo $(colorize 'bright_green' " Folders created successfully, please add your files!")
        echo " "
    else
        echo $(colorize 'bright_red' " ❌ Error creating folders")
    fi
fi

sleep 0.5
echo " "

echo $(colorize 'cyan' "   █▀█ █──█ █▀█ █▀▀ █▀█  ") 
echo $(colorize 'cyan' "   ▀▀▄ █──█ █▄█ █▀▀ █▄▀  ") 
echo $(colorize 'cyan' "   █▄█ ▀▄▄▀ █── █▄▄ █─█  ") 
echo " "
echo $(colorize 'cyan' "   █ ▀█▀ █▀▄▀█ █▀█ █▀▀█ █▀▀  ")
echo $(colorize 'cyan' "   █ ─█─ █─█─█ █▄█ █─▄▄ █▀▀  ")
echo $(colorize 'cyan' "   █ ▄█▄ █───█ █─█ █▄▄█ █▄▄  ")
echo " "
sleep 1
echo " "
PS3='𝗣𝗟𝗘𝗔𝗦𝗘 𝗘𝗡𝗧𝗘𝗥 𝗬𝗢𝗨𝗥 𝗖𝗛𝗢𝗜𝗖𝗘: '
echo " "
options=(
)

while true; do
clear
echo " "
echo $(colorize 'cyan' "   █▀█ █──█ █▀█ █▀▀ █▀█  ") 
echo $(colorize 'cyan' "   ▀▀▄ █──█ █▄█ █▀▀ █▄▀  ") 
echo $(colorize 'cyan' "   █▄█ ▀▄▄▀ █── █▄▄ █─█  ")
echo " "
echo $(colorize 'cyan' "   ▀█▀ █▀▄▀█ █▀█ █▀▀█ █▀▀  ")
echo $(colorize 'cyan' "   ─█─ █─█─█ █▄█ █─▄▄ █▀▀  ")
echo $(colorize 'cyan' "   ▄█▄ █───█ █─█ █▄▄█ █▄▄  ")
echo " "
echo $(colorize 'cyan' "   Version $tool_version | Size Data: $size_data / Free: $free_data")
echo " "
sleep 0.5
print_powered_by
echo " "
    sleep 0.5
    echo $(colorize 'yellow' " ╭────── FEATURES⃤彡")
    echo -e "$(colorize 'yellow' ' │') "
    echo -e "$(colorize 'yellow' ' │ 1)') Unpack Super Image"
    echo -e "$(colorize 'yellow' ' │ 2)') Edit Partitions & Repack Super"
    echo -e "$(colorize 'yellow' ' │ 3)') Disable verity vbmeta"
    echo -e "$(colorize 'yellow' ' │ 4)') Clean folder Project"
    echo -e "$(colorize 'yellow' ' │ 5)') Quit"
    echo -e "$(colorize 'yellow' ' │') "
    echo $(colorize 'yellow' " ╰──────")
    echo " "
    echo -n "$PS3"
    read opt

  case $opt in
        1)
            # SUPER EXTRACTION
            if [[ ! -f "$SUPER" ]]; then
              echo " "
              echo $(colorize 'yellow' "╭────── EXTRACTION OF SUPER IMAGE") 
              echo -e "$(colorize 'yellow' '│•') The file $SUPER has not been added"
              log_message " The file $SUPER has not been added"
              echo -e "$(colorize 'yellow' '│ ')"
              sleep 1
              echo -e "$(colorize 'yellow' '│•Extracting Super image from partition')"
              log_message " Extracting Super image from partition"
              echo -e "$(colorize 'yellow' '│ ')"
              sleep 1
              animated_text "│ Please wait this may take a while" "bright_orange"
              animation_bar &
              pid_animation_bar=$!
              update "$SUPER_BLOCK" "$SUPER"
              kill $pid_animation_bar
              printf "\r\033[K"
              echo -e "$(colorize 'yellow' '│ ')"
              sleep 1
              echo -e "$(colorize 'cyan' '│• Done! Super image is saved in:') $FILES_SUPER"
              log_message "Done! Super image is saved in: $FILES_SUPER"
              echo $(colorize 'yellow' "╰──────")
            fi

            # Verificar si ya hay archivos desempaquetados en el directorio de extracción
            echo " "
            echo $(colorize 'yellow' "╭────── UNPACKING OF SUPER IMAGE") 
            echo -e "$(colorize 'cyan' '│• Checking if you already have the partitions unpacked')"
            log_message " Checking if you already have the partitions unpacked"
            if check_unpacked_files "$EXTRACT_DIR"; then
              echo -e "$(colorize 'yellow' '│ ')"
              sleep 1
              echo -e "$(colorize 'green' '│• Existing files img in') $EXTRACT_DIR"
              echo -e "$(colorize 'yellow' '│ ')"
              echo -e "$(colorize 'yellow' '│ Skipping process unpack...')"
              log_message "│ Existing files in $EXTRACT_DIR. Skipping process unpack"
              echo $(colorize 'yellow' "╰──────")
              find "$EXTRACT_DIR" -type f -name "*_b.img" -exec rm -f {} \;
            else
              # Si no hay archivos, proceder con el desempaquetado
              if check_sparse_image "$SUPER"; then
                echo -e "$(colorize 'yellow' '│ ')"
                sleep 1
                echo -e "$(colorize 'yellow' '│•') $SUPER $(colorize 'yellow' 'It is in sparse format.  Converting to raw format...')"
                log_message "│ $SUPER It is in sparse format.  Converting to raw format..."
    
                # Convertir a formato raw
                sparse_to_raw "$SUPER" "$Main/super.raw" >> "$LOG_FILE" 2>&1
    
                # Usar la imagen raw para desempaquetar
                SUPER_RAW="$Main/super.raw"
                mv "$SUPER_RAW" "$SUPER"
                unpack_super "$SUPER" "$EXTRACT_DIR"
                find "$EXTRACT_DIR" -type f -name "*_b.img" -exec rm -f {} \;
              else
                # La imagen ya está en formato raw, desempaquetar directamente
                unpack_super "$SUPER" "$EXTRACT_DIR"
                find "$EXTRACT_DIR" -type f -name "*_b.img" -exec rm -f {} \;
              fi
            fi
            echo " "
            sleep 1
            echo $(colorize 'bright_green' " (Press enter to go back)")
            echo " "
            read enter
            ;;
        2)
            echo " "
            echo $(colorize 'yellow' "╭────── SUPER IMAGE")
              echo -e "$(colorize 'yellow' '│•') Starting the process"
              log_message " Starting the process"

              # Comprobar archivos EROFS
              echo -e "$(colorize 'yellow' '│ ')"
              sleep 1
              echo -e "$(colorize 'yellow' '│•') Checking for EROFS partitions"
              log_message " Checking for EROFS partitions"
              if check_erofs_images "$EXTRACT_DIR"; then
                echo -e "$(colorize 'yellow' '│ ')"
                sleep 1
                echo -e "$(colorize 'yellow' '│•') EROFS files detected. Continuing the process..."
                log_message " EROFS files detected. Continuing the process..."
                echo -e "$(colorize 'yellow' '─────────────────────────────────────────')"

                if check_unpacked_files "$EXTRACT_DIR"; then
                  rm -rf "$EXTRACT_DIR_EROFS"
                  mkdir -p "$EXTRACT_DIR_EROFS"
                  find "$EXTRACT_DIR" -type f -name "*_b.img" -exec rm -f {} \;
                  # Iterar sobre cada archivo .img en el directorio
                  find "$EXTRACT_DIR" -type f -name "*.img" -print0 | while IFS= read -r -d '' img_file; do
                    part_name=$(basename "$img_file" .img)
                    echo -e "$(colorize 'yellow' ' ')"
                    sleep 1
                    echo -e "$(colorize 'bright_cyan' '• Extracting EROFS format content of') $img_file'"
                    log_message " Extracting EROFS format content in $output_file from $img_file..."
                    echo -e "$(colorize 'yellow' ' ')"
                    sleep 1
                    echo -e "$(colorize 'bright_orange' '• Please wait this may take a while')"
                    "$erofs_extract" -i "$img_file" -x -o "$EXTRACT_DIR_EROFS" || continue
                    output_file="${img_file%.img}_ext4.img" &>> "$LOG_FILE"

                    # Obtener el directorio donde se extrajo la partición
                    part_dir="$EXTRACT_DIR_EROFS/$part_name"
                    used_size=$(du -sb "$part_dir" | awk '{print $1}')
                    echo -e "$(colorize 'yellow' '│• Space used by') $part_name: $used_size bytes" &>> "$LOG_FILE"

                    min_size=10485760
                    target_size=$(echo "$used_size * $safety_factor" | bc | awk '{print int($1)}')

                    if [ "$target_size" -lt "$min_size" ]; then
                        target_size="$min_size"
                    fi
                    echo -e "$(colorize 'yellow' '•') Target size for $part_name: $target_size bytes" &>> "$LOG_FILE"

                    # Verificar si el directorio de la partición contiene archivos
                    if [ -d "$part_dir" ] && [ "$(ls -A "$part_dir")" ]; then
                      echo -e "$(colorize 'yellow' ' ')"
                      sleep 1
                      echo -e "$(colorize 'bright_cyan' '│• Creating ext4 partitions')"
                      log_message " Creating ext4 partitions"
                      echo -e "$(colorize 'yellow' ' ')"
                      sleep 1
                      echo -e "$(colorize 'bright_orange' '│• Please wait this may take a while')"
                      $MAKE_EXT4FS -J -T 1722816000 -S "$EXTRACT_DIR_EROFS/config/${part_name}_file_contexts" -C "$EXTRACT_DIR_EROFS/config/${part_name}_fs_config" -a "$part_name" -L "$part_name" -l "$target_size" "$output_file" "$part_dir"
                      if [[ $? -ne 0 ]]; then
                        echo -e "$(colorize 'red' '•') Error creating EXT4 file system for $part_name"
                        log_message " Error creating EXT4 file system for $part_name"
                        continue
                      fi
                    else
                      echo -e "$(colorize 'yellow' '•') Warning: No files found in $part_dir. Skipping creation of EXT4 filesystem for $part_name."
                      log_message " Warning: No files found in $part_dir. Skipping creation of EXT4 filesystem for $part_name."
                    fi
                    echo -e "$(colorize 'yellow' ' ')"
                    sleep 1
                    echo -e "$(colorize 'bright_cyan' '│• Cleaning the work area for') $part_dir"
                    rm -rf "$part_dir"
                    echo -e "$(colorize 'yellow' ' ')"
                    sleep 1
                    echo -e "$(colorize 'bright_cyan' '• Checking and repairing possible errors in') $output_file"
                    $E2FSCK -fy "$output_file" &>> "$LOG_FILE"
                    echo -e "$(colorize 'yellow' ' ')"
                    sleep 1
                    echo -e "$(colorize 'bright_cyan' '• Exporting img ext4 file')"
                    mv "$output_file" "$img_file"
                    echo -e "$(colorize 'yellow' ' ')"
                    sleep 1
                    echo -e "$(colorize 'bright_cyan' '• Process finished')"
                    log_message " Process finished"
                    echo -e "$(colorize 'yellow' '─────────────────────────────────────────')"
                  done
                else
                  echo -e "$(colorize 'yellow' '│•') There are no .img files in the directory $EXTRACT_DIR."
                  log_message " There are no .img files in the directory $EXTRACT_DIR."
                fi
              else
                echo -e "$(colorize 'yellow' ' ')"
                echo -e "$(colorize 'bright_green' '• No EROFS device detected. The Process continue')"
                log_message " No EROFS device detected.The Process continue"
              fi
            # Eliminando el área de trabajo
            rm -rf "$EXTRACT_DIR_EROFS"
            # AJUSTANDO LAS PARTICIONES 
            ########################
            for img_file in "$EXTRACT_DIR"/*.img; do
                echo " "
                echo -e "$(colorize 'bright_cyan' '• Processing file:') $img_file"
                # Limpiar errores en el sistema de archivos
                echo -e "$(colorize 'yellow' '-- Checking and repairing any errors in:')"
                echo "- $img_file"
                $E2FSCK -fy "$img_file" &>> "$LOG_FILE"

                # Obtener y mostrar el espacio libre antes del redimensionamiento
                free_space_before_mb=$(get_free_space_mb "$img_file")
                echo -e "$(colorize 'yellow' '-- Free space before resizing for')" $img_file: ${free_space_before_mb} MB
                   
                # Redimensionar el sistema de archivos al mínimo
                echo -e "$(colorize 'yellow' '• Applying resize for') $img_file"
                $resize -f -M "$img_file" &>> "$LOG_FILE"

                # Obtener el tamaño del sistema de archivos en bytes
                fs_size_bytes=$(get_filesystem_size_bytes "$img_file")
                echo -e "$(colorize 'yellow' '-- File size after resizing:') ${fs_size_bytes} bytes"

                # Ajustar el tamaño del archivo de imagen
                echo -e "$(colorize 'yellow' '-- Fixing size file for:') $img_file"
                truncate -s "$fs_size_bytes" "$img_file" &>> "$LOG_FILE"
                   
                # Obtener y mostrar el espacio libre después del redimensionamiento
                free_space_after_mb=$(get_free_space_mb "$img_file")
                echo -e "$(colorize 'yellow' '-- Free space after resizing for:') $img_file: ${free_space_after_mb} MB"
                echo -e "$(colorize 'yellow' '─────────────────────────────────────────')"
                sleep 2
            done

            ####################
            # MISCELLANEOUS MENU #
            ####################
            while true; do
                echo " "
                echo $(colorize 'yellow' "╭────── MENU EXTRAS") 
                PARTITIONS="$EXTRACT_DIR_MOUNT"

                echo -e "$(colorize 'yellow' '│')$(colorize 'bright_green' ' 1') for$(colorize 'bright_cyan' ' AUTOMATIC DEBLOAT')"
                echo -e "$(colorize 'yellow' '│')$(colorize 'bright_green' ' 2') for$(colorize 'bright_cyan' ' MANUAL DEBLOAT CONSOLE')"
                echo -e "$(colorize 'yellow' '│')$(colorize 'bright_green' ' 3') for$(colorize 'bright_cyan' ' MANUAL DEBLOAT')"
                echo -e "$(colorize 'yellow' '│')$(colorize 'bright_green' ' 4') for$(colorize 'bright_cyan' ' FIX OVERLAY RW XIAOMI DEVICES')"
                echo -e "$(colorize 'yellow' '│')$(colorize 'bright_green' ' 5') for$(colorize 'bright_cyan' ' DFE DECRYPT')"
                echo -e "$(colorize 'yellow' '│')$(colorize 'bright_green' ' 6') for$(colorize 'bright_cyan' ' ADJUST & COMPILE YOU SUPER IMAGE')"
                echo -e "$(colorize 'yellow' '│')$(colorize 'bright_green' ' 7') for$(colorize 'bright_cyan' ' EXIT MENU')"
                echo $(colorize 'yellow' "╰──────")
                echo " "

                read -p " Select an option (1-7): " mode
#──────────────────────────────────────────────────────────────────────────        
                if [ "$mode" == "1" ]; then
                echo " "
                echo -e "$(colorize 'yellow' ' List of Apps to remove')"
                echo -e "$(colorize 'bright_cyan' ' Google Chrome')"
                echo -e "$(colorize 'bright_cyan' ' Google Drive')"
                echo -e "$(colorize 'bright_cyan' ' Google Gmail')"
                echo -e "$(colorize 'bright_cyan' ' Google Google One')"
                echo -e "$(colorize 'bright_cyan' ' Google Maps')"
                echo -e "$(colorize 'bright_cyan' ' Google Meet')"
                echo -e "$(colorize 'bright_cyan' ' Google')"
                echo -e "$(colorize 'bright_cyan' ' Google TV')"
                echo -e "$(colorize 'bright_cyan' ' Youtube')"
                echo -e "$(colorize 'bright_cyan' ' YouTube music')"
                echo -e "$(colorize 'bright_cyan' ' Google Photos')"
                echo -e "$(colorize 'bright_cyan' ' Google Play Music')"
                echo -e "$(colorize 'bright_cyan' ' Google Play Books')"
                echo -e "$(colorize 'bright_cyan' ' Google Photos')"
                echo -e "$(colorize 'bright_cyan' ' Google Play Newsstand')"
                echo -e "$(colorize 'bright_cyan' ' Google Calendar')"
                echo -e "$(colorize 'bright_cyan' ' Talback')"
                echo -e "$(colorize 'bright_cyan' ' Mi Doc Viewer Xioami')"
                echo -e "$(colorize 'bright_cyan' ' Xiaomi Community')"
                echo -e "$(colorize 'bright_cyan' ' ShareMe Xiaomi')"
                echo -e "$(colorize 'bright_cyan' ' Store Xiaomi')"
                echo -e "$(colorize 'bright_cyan' ' Mi Mover Xioami')"
                echo -e "$(colorize 'bright_cyan' ' Mi Notes')"
                echo -e "$(colorize 'bright_cyan' ' Opera Browser')"
                echo -e "$(colorize 'bright_cyan' ' Poco Community')"
                echo -e "$(colorize 'bright_cyan' ' POCO Store')"
                echo -e "$(colorize 'bright_cyan' ' Mi Remoto')"
                echo -e "$(colorize 'bright_cyan' ' Device Health Services')"
                echo -e "$(colorize 'bright_cyan' ' Wellbeing')"
                sleep 2

                    echo " "
                    echo -e "$(colorize 'yellow' ' Type')$(colorize 'bright_green' ' yes')$(colorize 'yellow' ' if you want to remove the list of apps')"
echo -e "$(colorize 'yellow' ' Type')$(colorize 'bright_green' ' no')$(colorize 'yellow' ' if you want to want to return to the menu')"
                    read -p " Write your selection: " user_choice

                    if [ "$user_choice" == "yes" ]; then
                        # DEBLOAT MENU
                        ###############
                        echo $(colorize 'yellow' "╭────── AUTOMATIC DEBLOAT") 
                        echo $(colorize 'cyan' " Processing the list of apps, please wait a moment")
                        PARTITIONS="$EXTRACT_DIR_MOUNT"
                        PACKAGE_FILE="$SUPER_BIN/debloat.txt"

                        # MOUNT OPCIÓN
                        ##############
                        echo $(colorize 'yellow' "── MOUNTING") &>> "$LOG_FILE"
                        for img_file in "$EXTRACT_DIR"/*.img; do
                           part_name=$(basename "$img_file" .img)
                           mount_point="$EXTRACT_DIR_MOUNT/$part_name"

                           mkdir -p $EXTRACT_DIR_MOUNT
                           echo $(colorize 'green' "-- Mounting") $img_file &>> "$LOG_FILE"
                           try_mount -rw -file $img_file $mount_point &>> "$LOG_FILE"
                           echo $(colorize 'yellow' " ───────────────") &>> "$LOG_FILE"
                        done
                        echo -e "$(colorize 'yellow' '│ ')"
                        sleep 2

                        apk_found=false
                        while IFS= read -r APK; do
                           DIR=$(dirname "$APK")
                           echo -e "$(colorize 'yellow' '⨠ Deleting') $(basename "$APK")..."
                           rm -rf "$DIR"
                           apk_found=true
                        done < <(find_apk $(read_file $PACKAGE_FILE) "$PARTITIONS")
                
                        # Comprobar si no se eliminaron APKs
                        if ! $apk_found; then
                           echo " "
                           echo -e "$(colorize 'red' '• The apps have already been removed or are not present in your partitions.')"
                           sleep 1
                        fi
                        echo $(colorize 'yellow' "╰──────")
                        # UMOUNT OPCIÓN
                        ##############
                        echo " "
                        echo $(colorize 'yellow' "╭────── UNMOUNTING") &>> "$LOG_FILE"
                        umount_all &>> "$LOG_FILE"
                        echo $(colorize 'yellow' "╰──────") &>> "$LOG_FILE"
                        rm -rf $EXTRACT_DIR_MOUNT
                        # repairs 
                        echo $(colorize 'yellow' "╭────── ") 
                        for img_file in "$EXTRACT_DIR"/*.img; do
                           echo $(colorize 'yellow' "-- Checking and repairing any errors")
                           echo " for $img_file"
                           $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                           echo $(colorize 'bright_green' "-- Done")
                        done
                        echo $(colorize 'yellow' "╰──────")
                    elif [ "$user_choice" == "no" ]; then
                            echo "Back to the menu...."
                    else
                    echo " "
                       echo $(colorize 'bright_orange' "Invalid option. Back to the menu....")
                    fi
#──────────────────────────────────────────────────────────────────────────     
                elif [ "$mode" == "2" ]; then
                PARTITIONS="$EXTRACT_DIR_MOUNT"
                echo $(colorize 'yellow' "╭────── MANUAL DEBLOAT CONSOLE")
                # MOUNT OPCIÓN
                ##############
                BASE_DIR="$EXTRACT_DIR_MOUNT"
                echo $(colorize 'yellow' "── MOUNTING") &>> "$LOG_FILE"
                for img_file in "$EXTRACT_DIR"/*.img; do
                   part_name=$(basename "$img_file" .img)
                   mount_point="$EXTRACT_DIR_MOUNT/$part_name"

                   mkdir -p $EXTRACT_DIR_MOUNT
                   echo $(colorize 'green' "-- Mounting") $img_file &>> "$LOG_FILE"
                   try_mount -rw -file $img_file $mount_point &>> "$LOG_FILE"
                   echo $(colorize 'yellow' " ───────────────") &>> "$LOG_FILE"
                done
                
                #Debloat console
                main_menu
                
                echo $(colorize 'yellow' "╰──────")
                # UMOUNT OPCIÓN
                ##############
                echo " "
                echo $(colorize 'yellow' "╭────── UNMOUNTING") &>> "$LOG_FILE"
                umount_all &>> "$LOG_FILE"
                echo $(colorize 'yellow' "╰──────") &>> "$LOG_FILE"
                rm -rf $EXTRACT_DIR_MOUNT
                # repairs 
                echo $(colorize 'yellow' "╭────── ") 
                for img_file in "$EXTRACT_DIR"/*.img; do
                   echo $(colorize 'yellow' "-- Checking and repairing any errors")
                   echo " for $img_file"
                   $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                   echo $(colorize 'bright_green' "-- Done")
                done
                echo $(colorize 'yellow' "╰──────")

#──────────────────────────────────────────────────────────────────────────        
                elif [ "$mode" == "3" ]; then
                # Manual Debloat 
                mount_img="$SUPER_BIN/mount.sh"
                umount_img="$SUPER_BIN/umount.sh"
                mount_img2="$EXTRACT_DIR/mount.sh"
                umount_img2="$EXTRACT_DIR/umount.sh"
    
                echo $(colorize 'yellow' "╭────── MANUAL DEBLOAT") 
                sleep 1
                echo -e "$(colorize 'yellow' '│•') Use$(colorize 'bright_cyan' ' MT Manager app')"
                log_message "│ Use Mt Manager app"
                sleep 1
                echo -e "$(colorize 'yellow' '│ ')"
                echo -e "$(colorize 'yellow' '│•')$(colorize 'bright_cyan' ' Go to') $EXTRACT_DIR"
                log_message "│ Go to $EXTRACT_DIR"
                cp $mount_img "$EXTRACT_DIR"
                cp $umount_img "$EXTRACT_DIR"
                sleep 1
                echo -e "$(colorize 'yellow' '│ ')"
                echo -e "$(colorize 'yellow' '│•') To edit your partitions$(colorize 'bright_cyan' ' run the file mount.sh (Mark root)')"
                log_message "│ To edit your partitions run the file mount.sh (Mark root)"
                sleep 1
                echo -e "$(colorize 'yellow' '│ ')"
                echo -e "$(colorize 'yellow' '│•') When you finish editing,$(colorize 'bright_cyan' ' run the umount.sh file')"
                log_message "│ When you finish editing, run the umount.sh file"
            
                # pause
                while true; do
                sleep 1
                echo -e "$(colorize 'yellow' '│ ')"
                echo -e "$(colorize 'yellow' '│')$(colorize 'bright_red' ' SCRIPT PAUSED')"
                log_message "│ Script paused"
                sleep 1
                echo -e "$(colorize 'yellow' '│ ')"
                  read -p "│ When you have finished the process, type done and press enter to continue   " input
                   if [[ "$input" == "$PAUSE_SCRIPT" ]]; then
                      echo $(colorize 'yellow' "│ The process continue...")
                      log_message "│ The process continue..."
                      echo " "
                      break  # Salir del bucle y continuar el script
                   else
                      echo $(colorize 'red' "│ Incorrect word.  try again")
                      log_message "│ Incorrect word.  try again."
                   fi
                   done
                   echo $(colorize 'yellow' "╰──────")
                   rm -f $mount_img2
                   rm -f $umount_img2
                   # repairs 
                   echo $(colorize 'yellow' "╭────── ") 
                   for img_file in "$EXTRACT_DIR"/*.img; do
                      echo $(colorize 'yellow' "-- Checking and repairing any errors")
                      echo " for $img_file"
                      $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                      echo $(colorize 'bright_green' "-- Done")
                   done
                   echo $(colorize 'yellow' "╰──────")

#──────────────────────────────────────────────────────────────────────────       
                elif [ "$mode" == "4" ]; then
                echo $(colorize 'yellow' "╭────── FIX OVERLAY RW FOR REDMI") 
                    # FIX OVERLAY RW FOR REDMI
                    ##############
                    for img_file in "$EXTRACT_DIR"/*.img; do
                        part_name=$(basename "$img_file" .img)
                        mount_point="$EXTRACT_DIR_MOUNT/$part_name"
                        additional_size_bytes=$((10 * 1024 * 1024))
                        vendor="$EXTRACT_DIR/vendor.img"
                        vendor_a="$EXTRACT_DIR/vendor_a.img"

                        if [[ -f "$vendor" ]]; then
                            current_size=$(stat -c%s "$vendor")
                            fallocate -l $((current_size + additional_size_bytes)) "$vendor"
                            $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                            $resize "$img_file" &>> "$LOG_FILE"
                            $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                            mkdir -p $EXTRACT_DIR_MOUNT
                            echo $(colorize 'green' "-- Mounting") $img_file &>> "$LOG_FILE"
                            try_mount -rw -file "$img_file" "$mount_point" &>> "$LOG_FILE"
                        elif [[ -f "$vendor_a" ]]; then
                            current_size_a=$(stat -c%s "$vendor_a")
                            fallocate -l $((current_size_a + additional_size_bytes)) "$vendor_a"
                            $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                            $resize "$img_file" &>> "$LOG_FILE"
                            $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                            mkdir -p $EXTRACT_DIR_MOUNT
                            echo $(colorize 'green' "-- Mounting") $img_file &>> "$LOG_FILE"
                            try_mount -rw -file "$img_file" "$mount_point" &>> "$LOG_FILE"
                        else
                            echo "files don't found"
                        fi
                    done
                    # Procesando fstab 
                    if [[ -f "$vendor" ]]; then
                       SEARCH_DIR="$EXTRACT_DIR_MOUNT/vendor/etc"
                       find "$SEARCH_DIR" -type f -name 'fstab*' | while read -r fstab_file; do
                           echo "-- Processing file :$fstab_file"
                           sleep 1
                           # Eliminar las líneas que comienzan con la palabra 'overlay'
                           remove -a "overlay" $fstab_file

                           if [ $? -eq 0 ]; then
                               echo " "
                               echo "$(colorize 'yellow' '-- The fix has been applied successfully') $fstab_file"
                               sleep 1
                           else
                            echo " Error, device not supported"
                           fi
                       done
                    elif [[ -f "$vendor_a" ]]; then
                       SEARCH_DIR="$EXTRACT_DIR_MOUNT/vendor_a/etc"
                       find "$SEARCH_DIR" -type f -name 'fstab*' | while read -r fstab_file; do
                           echo "-- Processing file :$fstab_file"
                           sleep 1
                           # Eliminar las líneas que comienzan con la palabra 'overlay'
                           remove -a "overlay" $fstab_file

                           if [ $? -eq 0 ]; then
                               echo " "
                               echo "$(colorize 'yellow' '-- The fix has been applied successfully') $fstab_file"
                               sleep 1
                           else
                            echo " Error, device not supported"
                           fi
                       done
                       else
                            echo "files don't found"
                    fi
                    echo $(colorize 'yellow' "╰──────")
                    # UMOUNT OPCIÓN
                    ##############
                    umount_all &>> "$LOG_FILE"
                    rm -rf $EXTRACT_DIR_MOUNT
                    # repairs 
                    echo $(colorize 'yellow' "╭────── ") 
                    for img_file in "$EXTRACT_DIR"/*.img; do
                       echo $(colorize 'yellow' "-- Checking and repairing any errors")
                       echo " for $img_file"
                       $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                       echo $(colorize 'bright_green' "-- Done")
                    done
                    echo $(colorize 'yellow' "╰──────")                          
                    
                #################
                # Kernel & Vendor_boot
                #################
                echo " "
                echo $(colorize 'yellow' "╭────── KERNEL PATCH") 
                . "$SUPER_BIN/boot_patch.sh"
                Boot=$(find_block boot)
                Boot_file="$XIAOMI/boot.img"
                Boot_file_build="$XIAOMI/boot_patched.img"
                Output_patch="/data/boot"
                Ramdisk_boot="$Output_patch/ramdisk"
                temp_file=$(mktemp)

                # Extraer el kernel stock
                echo -e "$(colorize 'cyan' ' • Checking restriction in kernel')"
                sleep 1
                echo " "
                if exist file "$Boot_file"; then
                   echo -e "$(colorize 'green' ' • File detected...')"
                   sleep 1
                   # Desempaquetar kernel
                   echo " "
                   echo -e "$(colorize 'yellow' ' -- Unpacking kernel')"
                   unpack_boot "$Boot_file" "$Output_patch" &>> "$LOG_FILE"
                   echo " "
                   echo -e "$(colorize 'cyan' ' • Checking if exist restrictions in your kernel')"
                   echo " "

                   # Buscar y almacenar fstab con 'overlay'
                   find "$Ramdisk_boot" -type f -name '*fstab*' | while read -r fstab_file; do
                       if grep -q "overlay" "$fstab_file"; then
                           echo -e "$(colorize 'green' ' • Restriction found')"
                           echo " "
                           echo "$fstab_file" >> "$temp_file"
                       else
                           echo -e "$(colorize 'red' ' • Restriction not found in:') $fstab_file"
                       fi
                   done

                   # Si se encontraron archivos con 'overlay', aplicar cambios y repacar
                   if [ -s "$temp_file" ]; then
                       while read -r fstab_file; do
                           remove -a "overlay" "$fstab_file"
                           echo "$(colorize 'yellow' ' × Removing restriction on:') $fstab_file"
                       done < "$temp_file"

                       sleep 1
                       echo " "
                       echo -e "$(colorize 'yellow' ' -- Repacking kernel')"
                       repack_boot "$Output_patch" "$Boot_file_build" &>> "$LOG_FILE"
                       echo " "
                       echo -e "$(colorize 'green' ' • Kernel modified saved in:') $Boot_file_build"
                       sleep 1
                   else
                       echo " "
                       echo -e "$(colorize 'cyan' ' • There is no restriction on your device, skipping...')"
                       rm -rf "$Output_patch"
                   fi

                   # Eliminar archivo temporal
                   rm -f "$temp_file"
                else
                   echo -e "$(colorize 'red' ' • Kernel not found')"
                   sleep 1
                   echo " "
                   echo -e "$(colorize 'green' ' •Extraction Boot kernel')"
                   echo "Extraction Boot kernel"
                   update "$Boot" "$Boot_file"
                   # Desempaquetar kernel
                   echo " "
                   echo -e "$(colorize 'yellow' ' -- Unpacking kernel')"
                   unpack_boot "$Boot_file" "$Output_patch" &>> "$LOG_FILE"
                   echo " "
                   echo -e "$(colorize 'cyan' ' • Checking if exist restrictions in your kernel')"
                   echo " "

                   # Buscar y almacenar fstab con 'overlay'
                   find "$Ramdisk_boot" -type f -name '*fstab*' | while read -r fstab_file; do
                       if grep -q "overlay" "$fstab_file"; then
                           echo -e "$(colorize 'green' ' • Restriction found')"
                           echo " "
                           echo "$fstab_file" >> "$temp_file"
                       else
                           echo -e "$(colorize 'red' ' • Restriction not found in:') $fstab_file"
                       fi
                   done

                   # Si se encontraron archivos con 'overlay', aplicar cambios y repacar
                   if [ -s "$temp_file" ]; then
                       while read -r fstab_file; do
                           remove -a "overlay" "$fstab_file"
                           echo "$(colorize 'yellow' ' × Removing restriction on:') $fstab_file"
                       done < "$temp_file"

                       sleep 1
                       echo " "
                       echo -e "$(colorize 'yellow' ' -- Repacking kernel')"
                       repack_boot "$Output_patch" "$Boot_file_build" &>> "$LOG_FILE"
                       echo " "
                       echo -e "$(colorize 'green' ' • Kernel modified saved in:') $Boot_file_build"
                       sleep 1
                   else
                       echo " "
                       echo -e "$(colorize 'cyan' ' × There is no restriction on your device, skipping...')"
                       rm -rf "$Output_patch"
                   fi

                   # Eliminar archivo temporal
                   rm -f "$temp_file"
                fi
                echo $(colorize 'yellow' "╰──────")

#──────────────────────────────────────────────────────────────────────────        
                elif [ "$mode" == "5" ]; then
                echo $(colorize 'yellow' "╭────── DISABLE ANDROID FILE ENCRYPTION 'DFE") 
                    # Disable DFE
                    ##############
                    for img_file in "$EXTRACT_DIR"/*.img; do
                        part_name=$(basename "$img_file" .img)
                        mount_point="$EXTRACT_DIR_MOUNT/$part_name"
                        additional_size_bytes=$((10 * 1024 * 1024))
                        vendor="$EXTRACT_DIR/vendor.img"
                        vendor_a="$EXTRACT_DIR/vendor_a.img"

                        if [[ -f "$vendor" ]]; then
                            current_size=$(stat -c%s "$vendor")
                            fallocate -l $((current_size + additional_size_bytes)) "$vendor"
                            $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                            $resize "$img_file" &>> "$LOG_FILE"
                            $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                            mkdir -p $EXTRACT_DIR_MOUNT
                            echo $(colorize 'green' "-- Mounting") $img_file &>> "$LOG_FILE"
                            try_mount -rw -file "$img_file" "$mount_point" &>> "$LOG_FILE"
                        elif [[ -f "$vendor_a" ]]; then
                            current_size_a=$(stat -c%s "$vendor_a")
                            fallocate -l $((current_size_a + additional_size_bytes)) "$vendor_a"
                            $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                            $resize "$img_file" &>> "$LOG_FILE"
                            $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                            mkdir -p $EXTRACT_DIR_MOUNT
                            echo $(colorize 'green' "-- Mounting") $img_file &>> "$LOG_FILE"
                            try_mount -rw -file "$img_file" "$mount_point" &>> "$LOG_FILE"
                        else
                            echo "files don't found"
                        fi
                        echo $(colorize 'yellow' " ───────────────") &>> "$LOG_FILE"
                    done
                    # Procesando fstab 
                    if [[ -f "$vendor" ]]; then
                       SEARCH_DIR="$EXTRACT_DIR_MOUNT/vendor/etc"
                       fstab="$SUPER_BIN/fstab.txt"
                       find "$SEARCH_DIR" -type f -name 'fstab*' | while read -r fstab_file; do
                           echo " "
                           echo "$(colorize 'green' '-- Processing file :') $fstab_file "
                           sleep 1
                           #Parchando Fstab
                           eval patch_fstab $(read_file $fstab) $fstab_file
                           echo $(colorize 'yellow' "─────────────────")
                           echo " "
                           ########################################
                           echo "-- Processing file :$fstab_file"
                           sleep 1
                           #Parchando Fstab
                           remove  ,inlinecrypt ,quota ,wrappedkey $fstab_file
                           echo $(colorize 'yellow' "─────────────────")
                           echo " "
                           add_lines_string "#Super_Image-Tool" $fstab_file &>> "$LOG_FILE"
                       done
                    elif [[ -f "$vendor_a" ]]; then
                       SEARCH_DIR="$EXTRACT_DIR_MOUNT/vendor_a/etc"
                       fstab="$SUPER_BIN/fstab.txt"
                       find "$SEARCH_DIR" -type f -name 'fstab*' | while read -r fstab_file; do
                           echo " "
                           echo "$(colorize 'green' '-- Processing file :') $fstab_file "
                           sleep 1
                           #Parchando Fstab
                           eval patch_fstab $(read_file $fstab) $fstab_file
                           echo $(colorize 'yellow' "─────────────────")
                           echo " "
                           ########################################
                           echo "$(colorize 'green' '-- Processing file :') $fstab_file "
                           sleep 1
                           #Parchando Fstab
                           remove  ,inlinecrypt ,quota ,wrappedkey $fstab_file
                           echo $(colorize 'yellow' "─────────────────")
                           echo " "
                           add_lines_string "#Super_Image-Tool" $fstab_file &>> "$LOG_FILE"
                       done
                       else
                            echo "files don't found"
                    fi
                    echo $(colorize 'yellow' "╰──────")
                    # UMOUNT OPCIÓN
                    ##############
                    echo " "
                    echo $(colorize 'yellow' "╭────── UNMOUNTING") &>> "$LOG_FILE"
                    umount_all &>> "$LOG_FILE"
                    echo $(colorize 'yellow' "╰──────") &>> "$LOG_FILE"
                    rm -rf $EXTRACT_DIR_MOUNT
                    # repairs 
                    echo $(colorize 'yellow' "╭────── ") 
                    for img_file in "$EXTRACT_DIR"/*.img; do
                       echo $(colorize 'yellow' "-- Checking and repairing any errors")
                       echo " for $img_file"
                       $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                       echo $(colorize 'bright_green' "-- Done")
                    done
                    echo $(colorize 'yellow' "╰──────")

#──────────────────────────────────────────────────────────────────────────  
                elif [ "$mode" == "6" ]; then
                    ########################
                    # AJUSTANDO LAS PARTICIONES 
                    ########################
                    for img_file in "$EXTRACT_DIR"/*.img; do
                        echo " "
                        echo -e "$(colorize 'bright_cyan' '• Processing file:') $img_file"
                        # Limpiar errores en el sistema de archivos
                        echo -e "$(colorize 'yellow' '-- Checking and repairing any errors in:')"
                        echo "- $img_file"
                        $E2FSCK -fy "$img_file" &>> "$LOG_FILE"

                        # Obtener y mostrar el espacio libre antes del redimensionamiento
                        free_space_before_mb=$(get_free_space_mb "$img_file")
                        echo -e "$(colorize 'yellow' '-- Free space before resizing for')" $img_file: ${free_space_before_mb} MB
                   
                        # Redimensionar el sistema de archivos al mínimo
                        echo -e "$(colorize 'yellow' '• Applying resize for') $img_file"
                        $resize -f -M "$img_file" &>> "$LOG_FILE"

                        # Obtener el tamaño del sistema de archivos en bytes
                        fs_size_bytes=$(get_filesystem_size_bytes "$img_file")
                        echo -e "$(colorize 'yellow' '-- File size after resizing:') ${fs_size_bytes} bytes"

                        # Ajustar el tamaño del archivo de imagen
                        echo -e "$(colorize 'yellow' '-- Fixing size file for:') $img_file"
                        truncate -s "$fs_size_bytes" "$img_file" &>> "$LOG_FILE"
                   
                        # Obtener y mostrar el espacio libre después del redimensionamiento
                        free_space_after_mb=$(get_free_space_mb "$img_file")
                        echo -e "$(colorize 'yellow' '-- Free space after resizing for:') $img_file: ${free_space_after_mb} MB"
                   
                        echo -e "$(colorize 'yellow' '-- Checking and repairing any errors in:')"
                        echo "- $img_file"
                        $E2FSCK -fy "$img_file" &>> "$LOG_FILE"
                        echo -e "$(colorize 'yellow' '─────────────────────────────────────────')"
                        sleep 2         
                    done
                    echo -e "$(colorize 'yellow' '│ ')"
                    sleep 1
                    echo -e "$(colorize 'yellow' ' All files have been processed successfully')"
                    echo $(colorize 'yellow' "╰──────")
                    echo " "
                    sleep 1
          
                    ###############
                    # EXPAND 
                    echo $(colorize 'yellow' "╭────── EXTRA SPACE") 
                    RESERVED_SPACE_MB=10
                    super_img_size=$(stat -c%s "$SUPER")

                    # Calcular la suma de los tamaños de las subparticiones
                    total_subpartitions_size=0
                    for img_file in "$EXTRACT_DIR"/*.img; do
                        img_size=$(stat -c%s "$img_file")
                        total_subpartitions_size=$((total_subpartitions_size + img_size))
                    done

                    # Convertir el tamaño de super_img_size y total_subpartitions_size a MB
                    super_img_size_mb=$((super_img_size / 1024 / 1024))
                    total_subpartitions_size_mb=$((total_subpartitions_size / 1024 / 1024))

                    # Calcular el espacio disponible en MB y restar el espacio reservado
                    available_space=$((super_img_size_mb - total_subpartitions_size_mb - RESERVED_SPACE_MB))

                    # Mostrar el resultado
                    if (( available_space < 0 )); then
                        echo -e "$(colorize 'bright_orange' ' Insufficient space, you need') $((-available_space)) $(colorize 'yellow' 'MB to be able to compile')"
                        echo " "
                        sleep 1
                        echo -e "$(colorize 'green' ' Use some debloat option to get more space and use this option again')"
                        echo " "
                        sleep 1
                        echo -e "$(colorize 'yellow' ' returning to the menu')"
                    else
                    echo -e "$(colorize 'green' ' You have') $available_space $(colorize 'green' ' MB available.')"
                    # Preguntar al usuario cuánto espacio asignar a cada subpartición
                    declare -A allocated_space
                    remaining_space=$available_space

                    for img_file in "$EXTRACT_DIR"/*.img; do
                        part_name=$(basename "$img_file" .img)
                        echo -e "$(colorize 'yellow' ' ¿How many MB do you want to add to the') $part_name partition?"
                        echo -e "$(colorize 'bright_cyan' ' [Remaining space:') ${remaining_space}MB]"
                        read -p " Assignment for $part_name: " allocated_size
                        echo " "

                        # Verificar que el usuario no asigne más espacio del disponible
                        if (( allocated_size > remaining_space )); then
                            echo " You cannot assign more than ${remaining_space}MB. Please try again."
                            continue
                        fi

                        # Almacenar la asignación y actualizar el espacio restante
                        allocated_space[$part_name]=$allocated_size
                        remaining_space=$((remaining_space - allocated_size))
                    done

                    # EXPANDIR LAS PARTICIONES 
                    for img_file in "$EXTRACT_DIR"/*.img; do
                        part_name=$(basename "$img_file" .img)
                        current_size=$(stat -c%s "$img_file")
                        echo " "
                        echo -e "$(colorize 'bright_cyan' '• Processing file:') $img_file"

                        # Convertir el tamaño adicional de MB a bytes
                        additional_size_bytes=$((allocated_space[$part_name] * 1024 * 1024))
    
                        # Obtener y mostrar el espacio libre antes del redimensionamiento
                        free_space_before_mb=$(get_free_space_mb "$img_file")
                        echo -e "$(colorize 'yellow' '-- Free space before resizing for')" $img_file: ${free_space_before_mb} MB
                        sleep 2

                        # Ajustar el tamaño del archivo img con fallocate
                        echo "Adjusting the file size $part_name..."
                        fallocate -l $((current_size + additional_size_bytes)) "$img_file"

                        # Limpiar errores en el sistema de archivos
                        echo -e "$(colorize 'yellow' '-- Checking and repairing any errors in:')"
                        echo "- $img_file"
                        $E2FSCK -fy "$img_file" &>> "$LOG_FILE"

                        # Redimensionar el sistema de archivos
                        echo " -- Expanding $part_name..."
                        $resize "$img_file" &>> "$LOG_FILE"

                        # Limpiar errores en el sistema de archivos
                        echo " "
                        echo -e "$(colorize 'yellow' '-- Checking and repairing any errors in:')"
                        echo "- $img_file"
                        $E2FSCK -fy "$img_file" &>> "$LOG_FILE"

                        # Obtener y mostrar el espacio libre después del redimensionamiento
                        free_space_after_mb=$(get_free_space_mb "$img_file")
                        echo -e "$(colorize 'yellow' '-- Free space after resizing for:') $img_file: ${free_space_after_mb} MB"
                        echo -e "$(colorize 'yellow' '─────────────────────────────────────────')"
                        sleep 2
                    done
                    echo -e "$(colorize 'yellow' '│ ')"
                    sleep 1
                    echo -e "$(colorize 'yellow' ' All files have been processed successfully')"
                    echo " "
                    echo -e "$(colorize 'yellow' ' Is time to compile your super image')"
                    echo $(colorize 'yellow' "╰──────")
                    echo " "
                    sleep 1
                    # COMPILANDO SUPER IMG
                    ##################
                    z_repack_super $SUPER $EXTRACT_DIR $REPACKED_IMG
                    fi

#──────────────────────────────────────────────────────────────────────────       
                elif [ "$mode" == "7" ]; then
                    break
                else
                    echo "Invalid option. Please choose a valid option (1-7)."
                fi
                echo -e "$(colorize 'bright_green' '-- Press Enter to return to the menu...')"
            done
            echo " "
            sleep 1
            echo $(colorize 'bright_green' " (Press enter to go back)")
            echo " "
            read enter
            ;;
        3)
            disable_vbmeta_verification
            echo " "
            sleep 1
            echo $(colorize 'bright_green' " (Press enter to go back)")
            echo " "
            read enter
            ;;
        4)
           #clean folders 
            sleep 1
            # Selector for Compile 
            ruta_principal="/data/local/Super_Image"

            # Verificar si la ruta principal existe y es un directorio
            if [ -d "$ruta_principal" ]; then
                # Cambiar al directorio principal
                cd "$ruta_principal"

                # Mostrar un mensaje de selección
                sleep 1
                echo " "
                echo $(colorize 'bright_yellow' " ⩥ Select your folder to clean (or choose 'Exit' to return):")

                # Listar todas las carpetas dentro del directorio principal
                carpetas=$(find . -maxdepth 1 -type d ! -name .)

                # Añadir una opción de salida
                options=("Exit" $carpetas)

                # Mostrar las carpetas disponibles para selección junto con la opción de salida
                PS3=$(colorize 'bright_yellow' " ⩥ Select option: ")

                select carpeta in "${options[@]}"; do
                    if [ "$carpeta" == "Exit" ]; then
                        echo " "
                        echo $(colorize 'yellow' " ⩥ Exiting... Returning to previous menu.")
                        break  # Salir del select para regresar al menú anterior o al inicio
                    elif [ -n "$carpeta" ]; then
                        sleep 1
                        echo " "
                        echo $(colorize 'bright_yellow' " ⩥ You have selected: $carpeta")
                        echo " "
                        nombre_carpeta=$(basename "$carpeta")
                        rm -r "$nombre_carpeta"
                        mkdir -p "$nombre_carpeta" "$FILES_SUPER" "$FILES_VBMETA"
                        echo " "
                        echo $(colorize 'bright_yellow' " ⩥ Project folder cleaned")
                        break
                    else
                        echo $(colorize 'bright_red' " ⩥ Invalid selection. Please choose a valid option.")
                    fi
                done
            else
                echo $(colorize 'bright_red' " ⩥ The folder $ruta_principal does not exist or is not a valid directory.")
            fi
            echo " "
            sleep 1
            echo $(colorize 'bright_green' " (Press enter to go back)")
            echo " "
            read enter
            ;;
        5)
            printf " Press enter for Quit"
            read enter
            animated_text " Goodbye.." "red"  
            exit 1
            ;;
        *)
            echo " "
            sleep 2
            echo " Invalid option. Please try again."
            echo " "
            ;;
    esac
done