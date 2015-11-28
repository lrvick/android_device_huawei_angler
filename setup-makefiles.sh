#!/bin/bash

VENDOR=huawei
DEVICE=angler
OUTDIR=$ANDROID_BUILD_TOP/vendor/$VENDOR/$DEVICE
MAKEFILE=$OUTDIR/$DEVICE-vendor-blobs.mk
VENDOR_MAKEFILE=$OUTDIR/device-vendor.mk

self_dir="$(dirname $(readlink -f $0))"
proprietary_files=$self_dir/proprietary-blobs.txt

mkdir -p $OUTDIR

(cat << EOF) > $MAKEFILE
# This file is generated by device/$VENDOR/$DEVICE/setup-makefiles.sh

PRODUCT_COPY_FILES += \\
EOF

BLOBLIST=""

LINEEND=" \\"
COUNT=`wc -l $proprietary_files| awk {'print $1'}`
DISM=`egrep -c '(^#|^$)' $proprietary_files`
COUNT=`expr $COUNT - $DISM`
for FILE in `egrep -v '(^#|^$)' $proprietary_files`; do
  COUNT=`expr $COUNT - 1`
  if [ $COUNT = "0" ]; then
    LINEEND=""
  fi
  # Split the file from the destination (format is "file[:destination]")
  OLDIFS=$IFS IFS=":" PARSING_ARRAY=($FILE) IFS=$OLDIFS

  FILE=${PARSING_ARRAY[0]}
  FILEFLAG=""
  if [[ "$FILE" =~ ^- ]]; then
      FILEFLAG="-"
      FILE=$(echo $FILE | sed -e "s/^-//g")
  fi
  DEST=${PARSING_ARRAY[1]}
  if [ -n "$DEST" ]; then
      FILE=$DEST
  fi
  FILE=$(echo "$FILE" | sed 's|^system/||')
  if [ -z "$FILEFLAG" ]; then
    echo "    $OUTDIR/proprietary/$FILE:system/$FILE$LINEEND" >> $MAKEFILE
  fi
  BLOBLLIST=$(echo "$BLOBLLIST"; echo "$FILEFLAG$FILE")
done

# for debug
#for i in $(echo $BLOBLLIST); do echo "blob=$i"; done
#exit 0

(cat << EOF) > $VENDOR_MAKEFILE
# This file is generated by device/$VENDOR/$DEVICE/setup-makefiles.sh

\$(call inherit-product, vendor/$VENDOR/$DEVICE/$DEVICE-vendor-blobs.mk)

EOF

(cat << EOF) > $OUTDIR/BoardConfigVendor.mk
# This file is generated by device/$VENDOR/$DEVICE/setup-makefiles.sh
EOF

if [ -d $OUTDIR/proprietary/app ]; then
(cat << EOF) > $OUTDIR/proprietary/app/Android.mk
# This file is generated by device/$VENDOR/$DEVICE/setup-makefiles.sh

LOCAL_PATH := \$(call my-dir)

EOF

echo "ifeq (\$(TARGET_DEVICE),$DEVICE)" >> $OUTDIR/proprietary/app/Android.mk
echo ""  >> $OUTDIR/proprietary/app/Android.mk
echo "# Prebuilt APKs" >> $VENDOR_MAKEFILE
echo "PRODUCT_PACKAGES += \\" >> $VENDOR_MAKEFILE

LINEEND=" \\"
COUNT=`ls -1 $OUTDIR/proprietary/app/*/*.apk | wc -l`
for APK in `ls $OUTDIR/proprietary/app/*/*apk`; do
  COUNT=`expr $COUNT - 1`
  if [ $COUNT = "0" ]; then
    LINEEND=""
  fi
    apkname=`basename $APK`
    apkmodulename=`echo $apkname|sed -e 's/\.apk$//gi'`
  if [[ $apkmodulename = VZWAPNLib ]]; then
    signature="PRESIGNED"
  else
    signature="platform"
  fi
    (cat << EOF) >> $OUTDIR/proprietary/app/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := $apkmodulename
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $apkmodulename/$apkname
LOCAL_CERTIFICATE := $signature
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
include \$(BUILD_PREBUILT)

EOF

echo "    $apkmodulename$LINEEND" >> $VENDOR_MAKEFILE
done
echo "" >> $VENDOR_MAKEFILE
echo "endif" >> $OUTDIR/proprietary/app/Android.mk
fi

if [ -d $OUTDIR/proprietary/framework ]; then
(cat << EOF) > $OUTDIR/proprietary/framework/Android.mk
# This file is generated by device/$VENDOR/$DEVICE/setup-makefiles.sh

LOCAL_PATH := \$(call my-dir)

EOF

echo "ifeq (\$(TARGET_DEVICE),$DEVICE)" >> $OUTDIR/proprietary/framework/Android.mk
echo ""  >> $OUTDIR/proprietary/framework/Android.mk
echo "# Prebuilt jars" >> $VENDOR_MAKEFILE
echo "PRODUCT_PACKAGES += \\" >> $VENDOR_MAKEFILE

LINEEND=" \\"
COUNT=`ls -1 $OUTDIR/proprietary/framework/*.jar | wc -l`
for JAR in `ls $OUTDIR/proprietary/framework/*jar`; do
  COUNT=`expr $COUNT - 1`
  if [ $COUNT = "0" ]; then
    LINEEND=""
  fi
    jarname=`basename $JAR`
    jarmodulename=`echo $jarname|sed -e 's/\.jar$//gi'`
    (cat << EOF) >> $OUTDIR/proprietary/framework/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := $jarmodulename
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $jarname
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_SUFFIX := \$(COMMON_JAVA_PACKAGE_SUFFIX)
include \$(BUILD_PREBUILT)

EOF

echo "    $jarmodulename$LINEEND" >> $VENDOR_MAKEFILE
done
echo "" >> $VENDOR_MAKEFILE
echo "endif" >> $OUTDIR/proprietary/framework/Android.mk
fi

if [ -d $OUTDIR/proprietary/priv-app ]; then
(cat << EOF) > $OUTDIR/proprietary/priv-app/Android.mk
# This file is generated by device/$VENDOR/$DEVICE/setup-makefiles.sh

LOCAL_PATH := \$(call my-dir)

EOF

echo "ifeq (\$(TARGET_DEVICE),$DEVICE)" >> $OUTDIR/proprietary/priv-app/Android.mk
echo ""  >> $OUTDIR/proprietary/priv-app/Android.mk
echo "# Prebuilt privileged APKs" >> $VENDOR_MAKEFILE
echo "PRODUCT_PACKAGES += \\" >> $VENDOR_MAKEFILE

LINEEND=" \\"
COUNT=`ls -1 $OUTDIR/proprietary/priv-app/*/*.apk | wc -l`
for PRIVAPK in `ls $OUTDIR/proprietary/priv-app/*/*apk`; do
  COUNT=`expr $COUNT - 1`
  if [ $COUNT = "0" ]; then
    LINEEND=""
  fi
    privapkname=`basename $PRIVAPK`
    privmodulename=`echo $privapkname|sed -e 's/\.apk$//gi'`
  if [[ $privmodulename = BuaContactAdapter || $privmodulename = MotoSignatureApp ||
      $privmodulename = TriggerEnroll || $privmodulename = TriggerTrainingService ||
      $privmodulename = VZWAPNService ]]; then
    signature="PRESIGNED"
  else
    signature="platform"
  fi
    (cat << EOF) >> $OUTDIR/proprietary/priv-app/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := $privmodulename
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $privmodulename/$privapkname
LOCAL_CERTIFICATE := $signature
LOCAL_MODULE_CLASS := APPS
LOCAL_PRIVILEGED_MODULE := true
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
include \$(BUILD_PREBUILT)

EOF

echo "    $privmodulename$LINEEND" >> $VENDOR_MAKEFILE
done
echo "" >> $VENDOR_MAKEFILE
echo "endif" >> $OUTDIR/proprietary/priv-app/Android.mk
fi

LIBS=`echo "$BLOBLIST" | grep '\-lib' | cut -d'-' -f2 | head -1`

if [ -f $OUTDIR/proprietary/$LIBS ]; then
(cat << EOF) > $OUTDIR/proprietary/lib/Android.mk

# This file is generated by device/$VENDOR/$DEVICE/setup-makefiles.sh

LOCAL_PATH := \$(call my-dir)

EOF

echo "ifeq (\$(TARGET_DEVICE),$DEVICE)" >> $OUTDIR/proprietary/lib/Android.mk
echo ""  >> $OUTDIR/proprietary/lib/Android.mk
echo "# Prebuilt libs needed for compilation" >> $VENDOR_MAKEFILE
echo "PRODUCT_PACKAGES += \\" >> $VENDOR_MAKEFILE

LINEEND=" \\"
COUNT=`echo "$BLOBLLIST" | grep '^-.*/lib/' | wc -l`
for LIB in `echo "$BLOBLLIST" | grep '^-.*/lib/' | cut -d'/' -f2`;do
  COUNT=`expr $COUNT - 1`
  if [ $COUNT = "0" ]; then
    LINEEND=""
  fi
    libname=`basename $LIB`
    libmodulename=`echo $libname|sed -e 's/\.so$//gi'`
    (cat << EOF) >> $OUTDIR/propri/Android.mk
include \$(CLEAR_VARS)
LOCAL_MODULE := $libmodulename
LOCAL_MODULE_OWNER := $VENDOR
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $libname
LOCAL_MODULE_PATH := \$(TARGET_OUT_SHARED_LIBRARIES)
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
include \$(BUILD_PREBUILT)

EOF

echo "    $libmodulename$LINEEND" >> $VENDOR_MAKEFILE
done
echo "" >> $VENDOR_MAKEFILE
echo "endif" >> $OUTDIR/proprietary/lib/Android.mk
fi