#!/bin/bash
set +x

cat > /root/temp_update_menu.sh <<\END
#!/bin/bash

REPO_URL="https://github.com/New-Tech-Consulting/NTC-Bitrix24-VM.git"

DIR_NAME_MENU="ntc_bx_env"
DEST_DIR_MENU="/root"

FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"

DEST_DIR_BACKUP_MENU="$DEST_DIR_MENU/backup_ntc_bx_env"

apt update -y
apt upgrade -y
apt install -y git

# Backup ntc_bx_env
current_date=$(date "+%d.%m.%Y %H:%M:%S")
full_path_backup_menu="$DEST_DIR_BACKUP_MENU/$current_date"

mkdir -p "${full_path_backup_menu}"
mv -f "${DEST_DIR_MENU}/${DIR_NAME_MENU}" "${full_path_backup_menu}"


# Clone directory ntc_bx_env with repositories
git clone --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/Bitrix-ENV-DEBIAN12"
cd "$DEST_DIR_MENU/Bitrix-ENV-DEBIAN12"
git sparse-checkout set $DIR_NAME_MENU

# Move ntc_bx_env in /root and clean
rm -rf $DEST_DIR_MENU/$DIR_NAME_MENU
mv -f $DIR_NAME_MENU $DEST_DIR_MENU
rm -rf "$DEST_DIR_MENU/Bitrix-ENV-DEBIAN12"

chmod -R +x $DEST_DIR_MENU/$DIR_NAME_MENU

# Check script in .profile and add to .profile if not exist
if ! grep -qF "$FULL_PATH_MENU_FILE" /root/.profile; then
  cat << INSTALL_MENU >> /root/.profile

if [ -n "\$SSH_CONNECTION" ]; then
  $FULL_PATH_MENU_FILE
fi

INSTALL_MENU
fi

rm -f "/tmp/configs.tmp"
rm -f "/tmp/new_version_menu.tmp"

ln -s $FULL_PATH_MENU_FILE "$DEST_DIR_MENU/menu.sh"

echo -e "\n\n";
echo "Menu updated! Backup directory old menu: $full_path_backup_menu";
echo -e "\n";

END

bash /root/temp_update_menu.sh

rm /root/temp_update_menu.sh

