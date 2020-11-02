osp_detect() {
  case $1 in
    *.conf) SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *music {/p}" $1 | sed -r "s/( *).*/\1/")
            EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\music {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
            for EFFECT in ${EFFECTS}; do
              SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
              [ "$EFFECT" != "atmos" ] && sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#/g}" $1
            done;;
     *.xml) EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"music\">$/,/^ *<\/stream>$/ {/<stream type=\"music\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
            for EFFECT in ${EFFECTS}; do
              [ "$EFFECT" != "atmos" ] && sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--<apply effect=\"$EFFECT\"\/>-->/" $1
            done;;
  esac
}

# Tell user aml is needed if applicable
if $MAGISK && ! $SYSOVERRIDE; then
  if $BOOTMODE; then LOC="/sbin/.core/img/*/system $MOUNTPATH/*/system"; else LOC="$MOUNTPATH/*/system"; fi
  FILES=$(find $LOC -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" 2>/dev/null)
  if [ ! -z "$FILES" ] && [ ! "$(echo $FILES | grep '/aml/')" ]; then
    ui_print " "
    ui_print "   ! Conflicting audio mod found!"
    ui_print "   ! You will need to install !"
    ui_print "   ! Audio Modification Library !"
    sleep 3
  fi
fi

# GET HQ/MQ FROM ZIP NAME
case $(basename $ZIP) in
  *mq*|*Mq*|*MQ*) QUAL=mq;;
  *hq*|*Hq*|*HQ*) QUAL=hq;;
esac

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
chmod 755 $INSTALLER/common/keycheck

keytest() {
  ui_print "- Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

chooseport() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseportold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $INSTALLER/common/keycheck
  $INSTALLER/common/keycheck
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    ui_print "   Vol key not detected!"
    abort "   Use name change method in TWRP"
  fi
}
ui_print " "
<<<<<<< Updated upstream
if [ -z $QUAL ]; then
  if keytest; then
    FUNCTION=chooseport
  else
    FUNCTION=chooseportold
    ui_print "   ! Legacy device detected! Using old keycheck method"
    ui_print " "
    ui_print "- Vol Key Programming -"
    ui_print "   Press Vol Up Again:"
    $FUNCTION "UP"
    ui_print "   Press Vol Down"
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print "- Select Driver -"
  ui_print "   Choose which drivers you want installed:"
  ui_print "   Vol Up = HQ, Vol Down = MQ"
  if $FUNCTION; then
    QUAL=hq
  else
    QUAL=mq
  fi
else
  ui_print "   Driver quality specified in zipname!"
fi

cp_ch $INSTALLER/custom/$QUAL/$ABI/libjamesdsp.so $INSTALLER/system/lib/soundfx/libjamesdsp.so
cp_ch $INSTALLER/custom/$ABI/libjamesDSPImpulseToolbox.so $INSTALLER/system/lib/libjamesDSPImpulseToolbox.so
# App only works when installed normally to data in oreo
if [ $API -ge 26 ]; then
  cp -f $INSTALLER/system/app/JamesDSPManager/JamesDSPManager.apk $SDCARD/JamesDSPManager.apk
  if $BOOTMODE; then
    ui_print " "
    ui_print "   Installing JamesDSPManager apk..."
    pm install $INSTALLER/system/app/JamesDSPManager/JamesDSPManager.apk >/dev/null 2>&1
    ui_print "   JamesDSPManager.apk copied to root of internal storage (sdcard)"
    ui_print "   Install manually if apk install didn't work"
    sleep 2
  else
    ui_print " "
    ui_print "   JamesDSPManager.apk copied to root of internal storage (sdcard)"
    ui_print "   Install manually after booting"
    sleep 2
=======
ui_print "- Select Huawei -"
ui_print "   Is this a Huawei device?"
ui_print "   Vol Up = Yes, Vol Down = No"
if chooseport; then
  QARCH="huawei"
  cp_ch $MODPATH/common/lib/$QARCH/libjamesdsp.so $MODPATH/system/lib64/soundfx/libjamesdsp.so
  cp_ch $MODPATH/common/lib/$QARCH/libjamesDSPImpulseToolbox.so $MODPATH/system/lib64/libjamesDSPImpulseToolbox.so
else
  QARCH=$ARCH32
fi

cp -rf $MODPATH/common/JamesDSP /storage/emulated/0/
cp_ch $MODPATH/common/lib/$QARCH/libjamesdsp.so $MODPATH/system/lib/soundfx/libjamesdsp.so
cp_ch $MODPATH/common/lib/$QARCH/libjamesDSPImpulseToolbox.so $MODPATH/system/lib/libjamesDSPImpulseToolbox.so
[ $API -lt 30 ] && rm -rf $MODPATH/system/product

# Lib fix for pixel 2's, 3's, and essential phone
ui_print " "
if device_check -m "Essential Products" || device_check -m "Google"; then
  ui_print "   Applying lib workaround..."
  if [ -f $ORIGDIR/system/lib/libstdc++.so ] && [ ! -f $ORIGDIR/vendor/lib/libstdc++.so ]; then
    cp_ch $ORIGDIR/system/lib/libstdc++.so $MODPATH/system/vendor/lib/libstdc++.so
  elif [ -f $ORIGDIR/vendor/lib/libstdc++.so ] && [ ! -f $ORIGDIR/system/lib/libstdc++.so ]; then
    cp_ch $ORIGDIR/vendor/lib/libstdc++.so $MODPATH/system/lib/libstdc++.so
>>>>>>> Stashed changes
  fi
  rm -rf $INSTALLER/system/app
fi
ui_print "   Patching existing audio_effects files..."
for OFILE in ${CFGS}; do
  FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
  cp_ch_nb $ORIGDIR$OFILE $FILE 0644 false
  osp_detect $FILE
  case $FILE in
    *.conf) sed -i "/jamesdsp {/,/}/d" $FILE
            sed -i "/jdsp {/,/}/d" $FILE
            sed -i "s/^effects {/effects {\n  jamesdsp { #$MODID\n    library jdsp\n    uuid f27317f4-c984-4de6-9a90-545759495bf2\n  } #$MODID/g" $FILE
            sed -i "s/^libraries {/libraries {\n  jdsp { #$MODID\n    path $LIBPATCH\/lib\/soundfx\/libjamesdsp.so\n  } #$MODID/g" $FILE;;
    *.xml) sed -i "/jamesdsp/d" $FILE
           sed -i "/jdsp/d" $FILE
           sed -i "/<libraries>/ a\        <library name=\"jdsp\" path=\"libjamesdsp.so\"\/><!--$MODID-->" $FILE
           sed -i "/<effects>/ a\        <effect name=\"jamesdsp\" library=\"jdsp\" uuid=\"f27317f4-c984-4de6-9a90-545759495bf2\"\/><!--$MODID-->" $FILE;;
  esac
done
