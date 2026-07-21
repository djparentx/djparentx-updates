#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

clear
UPDATE_DATE="07202026"
LOG_FILE="/home/ark/dArkOSen-update$UPDATE_DATE.log"
UPDATE_DONE="/home/ark/.config/.dArkOSen-update$UPDATE_DATE"

if [ -f "$UPDATE_DONE" ] || [ -z "$UPDATE_DONE" ]; then
	msgbox "No more updates available.  Check back later."
	rm -- "$0"
	exit 187
fi

if [ -f "$LOG_FILE" ]; then
	rm "$LOG_FILE"
fi

LOCATION="https://raw.githubusercontent.com/djparentx/dArkOSen-updates/main"

msgbox "ONCE YOU PROCEED WITH THIS UPDATE SCRIPT, DO NOT STOP THIS SCRIPT UNTIL IT IS COMPLETED OR THIS DISTRIBUTION MAY BE LEFT IN A STATE OF UNUSABILITY.  Make sure you've created a backup of this sd card as a precaution in case something goes very wrong with this process.  You've been warned!  Type OK in the next screen to proceed."
my_var=`osk "Enter OK here to proceed." | tail -n 1`

echo "$my_var" | tee -a "$LOG_FILE"
sleep 1

if [ "$my_var" != "OK" ] && [ "$my_var" != "ok" ]; then
	msgbox "You didn't type OK.  This script will exit now and no changes have been made from this process."
	printf "You didn't type OK.  This script will exit now and no changes have been made from this process." | tee -a "$LOG_FILE"
	rm -- "$0"
	exit 187
fi

c_brightness="$(cat /sys/class/backlight/backlight/brightness)"
chmod 666 /dev/tty1
echo 255 > /sys/class/backlight/backlight/brightness
touch $LOG_FILE
tail -f $LOG_FILE >> /dev/tty1 &

if [ ! -f "/home/ark/.config/.dArkOSen-update07042026" ]; then
	printf "\nInstalling update 07042026\n" >> "$LOG_FILE" 2>&1
	sleep 2
	rm -rf /dev/shm/*
	wget -t 3 -T 60 --no-check-certificate "$LOCATION"/07042026/dArkOSen-update07042026.zip -O /dev/shm/dArkOSen-update07042026.zip -a "$LOG_FILE" || rm -f /dev/shm/dArkOSen-update07042026.zip | tee -a "$LOG_FILE"
	if [ -f "/dev/shm/dArkOSen-update07042026.zip" ]; then
        unzip -X -o /dev/shm/dArkOSen-update07042026.zip -d / | tee -a "$LOG_FILE"
		chmod -R +x /opt/system
		rm -f "/opt/system/System/RetroArch One-Click Backup.sh"
		rm -f "/opt/system/System/djparentx-Update.sh"
		touch "/home/ark/.config/.dArkOSen-update07042026"
		printf "\nUpdate successful" >> "$LOG_FILE" 2>&1
	else
		printf "\nThe update couldn't complete because the package did not download correctly.\nPlease retry the update again." >> "$LOG_FILE" 2>&1
		rm -fv /dev/shm/dArkOSen-update07042026.z* | tee -a "$LOG_FILE"
		sleep 3
		echo $c_brightness > /sys/class/backlight/backlight/brightness
		exit 1
	fi
fi

if [ ! -f "/home/ark/.config/.dArkOSen-update07202026" ]; then
	printf "\nInstalling update 07202026\n" >> "$LOG_FILE" 2>&1
	sleep 2
	rm -rf /dev/shm/*
	wget -t 3 -T 60 --no-check-certificate "$LOCATION"/07202026/dArkOSen-update07202026.zip -O /dev/shm/dArkOSen-update07202026.zip -a "$LOG_FILE" || rm -f /dev/shm/dArkOSen-update07202026.zip | tee -a "$LOG_FILE"

	if [ -f "/dev/shm/dArkOSen-update07202026.zip" ]; then
		# remove old scripts
		rm -f /opt/system/Wi-Fi\ Manager*.sh
		rm -f /opt/system/BT\ Manager*.sh
		# backup old BMPs and JPGs folders
		cp -rf /boot/BMPs /boot/BMPs.old
		rm -rf /boot/BMPs
		cp -rf /roms/launchimages/JPGs /roms/launchimages/JPGs.old
		rm -rf /roms/launchimages/JPGs
		rm -f /boot/low_battery2.bmp /boot/low_battery3.bmp /boot/low_battery4.bmp
		# unzip
		unzip -X -o /dev/shm/dArkOSen-update07202026.zip -d / | tee -a "$LOG_FILE"
		sleep 1
		# update fstab:
		bash /tmp/fix_fstab.sh
		# run dtb battery patch
		bash /tmp/patch_dtb_battery.sh
		# promax setup
		if [[ -f "/boot/arkos4clone-uboot.dtb" ]]; then
			cp -rf "/boot/dtb/r36s/HL-R45H-V20 2025-11-18/". /boot/
			rm -f "/boot/arkos4clone-uboot.dtb"
		fi
		# set permissions
		chmod +x /etc/NetworkManager/dispatcher.d/99-disable-ipv6.sh
		chmod +x "/opt/system/Advanced/Switch to SD2 for Roms.sh"
		chmod +x "/usr/local/bin/Switch to SD2 for Roms.sh"
		chmod +x /lib/systemd/system-sleep/volume-resume-fix
		chmod +x /usr/local/bin/recovery-runner.sh
		chmod -R +x /opt/system/
		chown root:root /
		depmod -a
		# enable recovery service
		systemctl enable recovery-check.service
		systemctl enable boot_volume.service
		systemctl restart NetworkManager
		# remove old patchers, old updater
		rm -f "/opt/system/Tools/R36H Pro Max Theme Patcher.sh" "/opt/system/Tools/R36S Theme Patcher.sh" "/opt/system/System/Update-djparentx.sh"
		touch "/home/ark/.config/.dArkOSen-update07202026"
		printf "\nUpdate successful" >> "$LOG_FILE" 2>&1
		# rebuilt uboot for all screen sizes
		bash /tmp/flash_uboot.sh
	else
		printf "\nThe update couldn't complete because the package did not download correctly.\nPlease retry the update again." >> "$LOG_FILE" 2>&1
		rm -fv /dev/shm/dArkOSen-update07202026.z* | tee -a "$LOG_FILE"
		sleep 3
		echo $c_brightness > /sys/class/backlight/backlight/brightness
		exit 1
	fi

	rm -v -- "$0" | tee -a "$LOG_FILE"
	printf "\033c" >> /dev/tty1
	msgbox "Updates have been completed.  System will now restart after you hit the A button to continue.  If the system doesn't restart after pressing A, just restart the system manually."
	echo $c_brightness > /sys/class/backlight/backlight/brightness
	reboot
	exit 187

fi