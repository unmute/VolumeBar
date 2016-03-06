git clone -b master git@github.com:gizmosachin/VolumeBar.git ./clone

jazzy \
	--clean \
	--source-directory ./clone/VolumeBar \
	--output docs

rm -rf ./clone

open "docs/index.html"