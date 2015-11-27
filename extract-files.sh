VENDOR=huawei
DEVICE=angler
RELEASE_ID=mdb08m
FACTORY_IMG_FILE=$DEVICE-$RELEASE_ID-factory-dbc17940.tgz
FACTORY_IMG_URL=https://dl.google.com/dl/android/aosp/$FACTORY_IMG_FILE
FACTORY_IMG_MD5=f7464cbaa4bfff29c551a8de92882b01
DESTROOT=$ANDROID_BUILD_TOP/vendor/$VENDOR/$DEVICE/proprietary

mkdir -p $DESTROOT

WORKDIR=~/.tmp/$DEVICE

checkutil() {
	echo -n " * Checking for $1..."
	which $1 2>&1 > /dev/null
	if [ $? -eq 0 ]; then
		printf " ok!\n";
		return 0;
	else
		printf " not found!\n";
		exit 1;
	fi
}

checkutil simg2img
checkutil unzip
checkutil md5sum
checkutil sudo

mkdir -p $WORKDIR

if [ ! -f $WORKDIR/$FACTORY_IMG_FILE ]; then
  wget $FACTORY_IMG_URL -O $WORKDIR/$FACTORY_IMG_FILE
fi

md5sum --quiet -c <( echo "$FACTORY_IMG_MD5 $WORKDIR/$FACTORY_IMG_FILE" )
if [ $? -ne 0 ]; then
  echo "$WORKDIR/$FACTORY_IMG_FILE failed MD5 hash check"
fi

tar -C $WORKDIR -xvzf $WORKDIR/$FACTORY_IMG_FILE

unzip  -d $WORKDIR/factory_images/ -o \
	$WORKDIR/$DEVICE-$RELEASE_ID/image-$DEVICE-${RELEASE_ID}.zip

for image in system vendor; do
  simg2img $WORKDIR/factory_images/${image}.img \
    $WORKDIR/factory_images/${image}.ext4.img
	mkdir -p $WORKDIR/factory_mounts/${image}
	# I really hate using sudo here but I see no other choice
	# Any other ideas to extract these are welcome
	sudo mount -o loop $WORKDIR/factory_images/${image}.ext4.img \
		$WORKDIR/factory_mounts/${image}
done

ls $WORKDIR/factory_mounts/system
ls $WORKDIR/factory_mounts/vendor

for FILE in $(egrep -v '(^\#|^$)' proprietary-blobs.txt | sed "s/^-//g"); do

	DESTFILE=$(echo "$FILE" | sed 's|^system/||')
  DESTDIR=$(dirname "$DESTFILE")
	if [ ! -d "$DESTROOT/$DESTDIR" ]; then
		mkdir -p "$DESTROOT/$DESTDIR"
  fi

	echo "$FILE -> $DESTROOT/$DESTFILE"
	cp "$WORKDIR/factory_mounts/$FILE" "$DESTROOT/$DESTFILE"

done

sudo umount $WORKDIR/factory_mounts/system
sudo umount $WORKDIR/factory_mounts/vendor
