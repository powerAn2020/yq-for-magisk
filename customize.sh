SKIPUNZIP=1

bindir=/system/bin
xbindir=/system/xbin

if [ "$BOOTMODE" ! = true ] ; then
  ui_print "-----------------------------------------------------------"
  ui_print "! Please install in Magisk Manager or KernelSU Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ] ; then
  abort "ERROR: Please update your KernelSU and KernelSU Manager or KernelSU Manager"
fi

# check Magisk
if [ "$KSU" ! = true ] ; then
    ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi


if [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10683 ] ; then
  busybox="/data/adb/ksu/bin/busybox"
else 
  busybox="/data/adb/magisk/busybox"
fi

ui_print "- Installing yq for Magisk/KernelSU"
ui_print "- Extract the ZIP file and skip the META-INF folder into the $MODPATH folder"
unzip -o "${ZIPFILE}" -x 'META-INF/*' -d "${MODPATH}" >&2

get_latest_release() {
  curl --silent "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}
yq_version=$(get_latest_release)
if [ -z "$yq_version" ];then
  yq_version="v4.33.3"
  ui_print "Failed to obtain the latest version, using built-in version:$yq_version"
fi

download_url="https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_"
# check OS
ui_print "OS ARCH is $ARCH"
case $ARCH in
arm|arm64)
download_url="${download_url}$ARCH"
;;
x86)
download_url="${download_url}386"
;;
x64)
download_url="${download_url}amd64"
;;
*)
abort "Installed failed,Current ARCH is $ARCH,only support arm/arm64/x86/x64"
;;
esac
ui_print ""
ui_print "-----------------------------------------------------------"
ui_print "- Do you want to use the github proxy service to download?"
ui_print "- Vol UP: Yes"
ui_print "- Vol DOWN: No"
while true ; do
  getevent -lc 1 2>&1 | grep KEY_VOLUME > $TMPDIR/events
  sleep 1
  if $(cat $TMPDIR/events | grep -q KEY_VOLUMEUP) ; then
    download_url="https://ghproxy.com/$download_url"
    break
  elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEDOWN) ; then
    break
  fi
done

ui_print "- Make sure you have a good internet connection."
ui_print "yq download url is :$download_url"
ui_print "- Vol UP: Strat download yq."
ui_print "- Vol DOWN: Cancel installation."
while true ; do
  getevent -lc 1 2>&1 | grep KEY_VOLUME > $TMPDIR/events
  sleep 1
  if $(cat $TMPDIR/events | grep -q KEY_VOLUMEUP) ; then
    ui_print "- it will take a while...."
    wget -O $MODPATH$xbindir/yq $download_url
    if [ ! -e $MODPATH$xbindir/yq ]; then
      abort "Download failed, Please check network connection!"
    fi
    # Check for existence of /system/xbin directory.
    if [ ! -d /sbin/.magisk/mirror$xbindir ]; then
        # Use /system/bin instead of /system/xbin.
        mkdir -p $MODPATH$bindir
        mv $MODPATH$xbindir/yq $MODPATH$bindir
        rmdir $MODPATH$xbindir
        xbindir=$bindir
    fi
    break
  elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEDOWN) ; then
    abort "Cancel installation."
  fi
done


ui_print "- Installed to $xbindir"

set_perm_recursive $MODPATH 0 0 0755 0755