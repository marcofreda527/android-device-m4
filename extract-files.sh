#!/bin/bash

# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEVICE=m4
COMMON=common
MANUFACTURER=lge

if [[ -z "${ANDROIDFS_DIR}" && -d ../../../backup-${DEVICE}/system ]]; then
    ANDROIDFS_DIR=../../../backup-${DEVICE}
fi

if [[ -z "${ANDROIDFS_DIR}" ]]; then
    echo Pulling files from device
    DEVICE_BUILD_ID=`adb shell cat /system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n\r'`
else
    echo Pulling files from ${ANDROIDFS_DIR}
    DEVICE_BUILD_ID=`cat ${ANDROIDFS_DIR}/system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n\r'`
fi

echo Found firmware with build ID $DEVICE_BUILD_ID >&2

if [[ ! -d ../../../backup-${DEVICE}/system  && -z "${ANDROIDFS_DIR}" ]]; then
    echo Backing up system partition to backup-${DEVICE}
    mkdir -p ../../../backup-${DEVICE} &&
    adb pull /system ../../../backup-${DEVICE}/system
    cp ../../../backup-${DEVICE}/system/etc/wifi/WCN* ../../../backup-${DEVICE}/system/etc/firmware/wlan/volans
fi

BASE_PROPRIETARY_COMMON_DIR=vendor/$MANUFACTURER/$COMMON/proprietary
PROPRIETARY_DEVICE_DIR=../../../vendor/$MANUFACTURER/$DEVICE/proprietary
PROPRIETARY_COMMON_DIR=../../../$BASE_PROPRIETARY_COMMON_DIR

mkdir -p $PROPRIETARY_DEVICE_DIR

for NAME in audio hw wifi etc
do
    mkdir -p $PROPRIETARY_COMMON_DIR/$NAME
done


COMMON_BLOBS_LIST=../../../vendor/$MANUFACTURER/$COMMON/vendor-blobs.mk

(cat << EOF) | sed s/__COMMON__/$COMMON/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > $COMMON_BLOBS_LIST
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prebuilt libraries that are needed to build open-source libraries
PRODUCT_COPY_FILES := device/sample/etc/apns-full-conf.xml:system/etc/apns-conf.xml

# All the blobs
PRODUCT_COPY_FILES += \\
EOF

# copy_file
# pull file from the device and adds the file to the list of blobs
#
# $1 = src name
# $2 = dst name
# $3 = directory path on device
# $4 = directory name in $PROPRIETARY_COMMON_DIR
copy_file()
{
    echo Pulling \"$1\"
    if [[ -z "${ANDROIDFS_DIR}" ]]; then
        adb pull /$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    else
           # Hint: Uncomment the next line to populate a fresh ANDROIDFS_DIR
           #       (TODO: Make this a command-line option or something.)
           # adb pull /$3/$1 ${ANDROIDFS_DIR}/$3/$1
        cp ${ANDROIDFS_DIR}/$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    fi

    if [[ -f $PROPRIETARY_COMMON_DIR/$4/$2 ]]; then
        echo   $BASE_PROPRIETARY_COMMON_DIR/$4/$2:$3/$2 \\ >> $COMMON_BLOBS_LIST
    else
        echo Failed to pull $1. Giving up.
        exit -1
    fi
}

# copy_files
# pulls a list of files from the device and adds the files to the list of blobs
#
# $1 = list of files
# $2 = directory path on device
# $3 = directory name in $PROPRIETARY_COMMON_DIR
copy_files()
{
    for NAME in $1
    do
        copy_file "$NAME" "$NAME" "$2" "$3"
    done
}

# copy_local_files
# puts files in this directory on the list of blobs to install
#
# $1 = list of files
# $2 = directory path on device
# $3 = local directory path
copy_local_files()
{
    for NAME in $1
    do
        echo Adding \"$NAME\"
        echo device/$MANUFACTURER/$DEVICE/$3/$NAME:$2/$NAME \\ >> $COMMON_BLOBS_LIST
    done
}

COMMON_LIBS="
	libauth.so
	libcm.so
	libdiag.so
	libdsi_netctrl.so
	libdsm.so
	libdsutils.so
	libidl.so
	libnetmgr.so
	libnv.so
	liboncrpc.so
	libpbmlib.so
	libqdp.so
	libqmi.so
	libqmiservices.so
	libqueue.so
	libril-qc-1.so
	libril-qc-qmi-1.so
	libril-qcril-hook-oem.so
	libwms.so
	libwmsts.so
	libcamera_client.so
	libcommondefs.so
	libgenlock.so
	libgps.utils.so
	libril.so
	libmmjpeg.so
	libmmipl.so
	liboemcamera.so
	libloc_adapter.so
	libloc_api-rpc-qc.so
	libloc_eng.so
	libqdi.so
	librpc.so
	liblgeat.so
	libwcnftm.so
	liboem_rapi.so
	liblge_security.so
	liblgdrm.so
	libwfcu.so
	liblgsecclk.so
	libchromatix_hi542_ar.so
	libchromatix_hi542_preview.so
	libchromatix_hi542_video.so
	libchromatix_mt9v113_ar.so
	libchromatix_mt9v113_preview.so
	libchromatix_mt9v113_video.so
	libhardware_legacy.so
	"

copy_files "$COMMON_LIBS" "system/lib" ""

COMMON_BINS="
	ATFWD-daemon
	bridgemgrd
	fm_qsoc_patches
	fmconfig
	hci_qcomm_init
	netmgrd
	port-bridge
	qmiproxy
	qmuxd
	rild
	sensord
	lgsecclkserver
	morningcall
	"

copy_files "$COMMON_BINS" "system/bin" ""

COMMON_HW="
	sensors.m4.so
	camera.msm7627a.so
	gps.default.so
	audio_policy.msm7627a.so
	audio.primary.msm7627a.so
	"

copy_files "$COMMON_HW" "system/lib/hw" "hw"

COMMON_WIFI="
	librasdioif.ko
	wlan.ko
	"

copy_files "$COMMON_WIFI" "system/lib/modules" "wifi"

COMMON_WLAN_VOLANS="
	WCN1314_cfg.dat
	WCN1314_qcom_fw.bin
	WCN1314_qcom_cfg.ini
	WCN1314_qcom_wlan_nv.bin
	"
copy_files "$COMMON_WLAN_VOLANS" "system/etc/firmware/wlan/volans" "wifi"

COMMON_WLAN="
	WCN1314_qcom_cfg.ini
	WCN1314_qcom_wlan_nv.bin
	"
#copy_files "$COMMON_WLAN" "system/etc/wifi" "wifi"

COMMON_ETC="init.qcom.bt.sh gps.conf"
copy_files "$COMMON_ETC" "system/etc" "etc"

COMMON_AUDIO="
	"
#copy_files "$COMMON_AUDIO" "system/lib" "audio"

if [ ! -f "../../../Adreno200-AU_LINUX_ANDROID_ICS_CHOCO_CS.04.00.03.06.001.zip" ]; then
	echo Adreno driver not found. Please download the ARMv7 adreno driver from
	echo https://developer.qualcomm.com/mobile-development/mobile-technologies/gaming-graphics-optimization-adreno/tools-and-resources
	echo and put it in the top level B2G directory
	exit -1
fi

unzip -o -d ../../../vendor/$MANUFACTURER/$DEVICE ../../../Adreno200-AU_LINUX_ANDROID_ICS_CHOCO_CS.04.00.03.06.001.zip
(cat << EOF) | sed s/__DEVICE__/$DEVICE/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > ../../../vendor/$MANUFACTURER/$DEVICE/$DEVICE-vendor-blobs.mk
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := vendor/$MANUFACTURER/$DEVICE

PRODUCT_COPY_FILES := \
    \$(LOCAL_PATH)/system/etc/firmware/yamato_pfp.fw:system/etc/firmware/yamato_pfp.fw \\
    \$(LOCAL_PATH)/system/etc/firmware/yamato_pm4.fw:system/etc/firmware/yamato_pm4.fw \\
    \$(LOCAL_PATH)/system/lib/libC2D2.so:system/lib/libC2D2.so \\
    \$(LOCAL_PATH)/system/lib/libsc-a2xx.so:system/lib/libsc-a2xx.so \\
    \$(LOCAL_PATH)/system/lib/libgsl.so:system/lib/libgsl.so \\
    \$(LOCAL_PATH)/system/lib/libOpenVG.so:system/lib/libOpenVG.so \\
    \$(LOCAL_PATH)/system/lib/egl/egl.cfg:system/lib/egl.cfg \\
    \$(LOCAL_PATH)/system/lib/egl/libGLESv1_CM_adreno200.so:system/lib/egl/libGLESv1_CM_adreno200.so \\
    \$(LOCAL_PATH)/system/lib/egl/libEGL_adreno200.so:system/lib/egl/libEGL_adreno200.so \\
    \$(LOCAL_PATH)/system/lib/egl/eglsubAndroid.so:system/lib/egl/eglsubAndroid.so \\
    \$(LOCAL_PATH)/system/lib/egl/libGLESv2_adreno200.so:system/lib/egl/libGLESv2_adreno200.so \\
    \$(LOCAL_PATH)/system/lib/egl/libq3dtools_adreno200.so:system/lib/egl/libq3dtools_adreno200.so \\
    \$(LOCAL_PATH)/system/lib/egl/libGLES_android.so:system/lib/egl/libGLES_android.so
EOF

