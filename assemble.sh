#!/bin/sh
#
# This script creates the whole Windows zipball!
#

set -ex

PLATFORM=win
WORKDIR=./work.${PLATFORM}
DESTDIR=./rite_club_companion-0.0.0a-windows64

# Start fresh. XXX
#test -d ${WORKDIR} && rm -rf ${WORKDIR}
#mkdir -p ${WORKDIR}
rm -rf ${DESTDIR}
mkdir -p ${DESTDIR}

# Download all the things.
make fetch PLATFORM=${PLATFORM}

# We need to compile our Tcl/Tk from source.
make tcl PLATFORM=${PLATFORM}
make tk PLATFORM=${PLATFORM}
make gpatch PLATFORM=${PLATFORM}

# Generate the "fused" LOVE app and clean our LOVE distribution.
pushd analytics
  zip -r ../${WORKDIR}/analytics.love ./
popd

pushd ${WORKDIR}
  unzip ../dist/love-11.3-win64.zip
  pushd love-11.3-win64
    cat ./love.exe ../analytics.love > RiteClubCompanion.exe
    cat ./lovec.exe ../analytics.love > RiteClubCompanionC.exe
    rm -f love.exe lovec.exe
    test -f license.txt && mv license.txt LOVE-LICENSE.txt
    rm -f readme.txt changes.txt
  popd
popd

# Clean our FFmpeg distribution.
pushd ${WORKDIR}
  unzip ../dist/ffmpeg-4.3.1-win64-static.zip
  pushd ffmpeg-4.3.1-win64-static
    rm -f bin/ffplay.exe bin/ffprobe.exe
    rm -rf doc
    test -f LICENSE.txt && mv LICENSE.txt FFMPEG-LICENSE.txt
    test -f README.txt && mv README.txt FFMPEG-README.txt
  popd
popd

# Clean our Ruby distribution.
pushd ${WORKDIR}
  7z x ../dist/rubyinstaller-2.6.6-1-x64.7z
  pushd rubyinstaller-2.6.6-1-x64
    rm -rf include share
    test -f LICENSE.txt 7& mv LICENSE.txt RUBY-LICENSE.txt
  popd
popd

# Unpack the audio grabber DLL distribution.
pushd ${WORKDIR}
  unzip ../dist/virtual-audio-capture-grabber-device-master.zip
popd

# Put it all in a DESTDIR.
mkdir -p ${DESTDIR}/bin
mkdir -p ${DESTDIR}/dll

cp ${WORKDIR}/tk8.6.9/win/wish86s.exe ${DESTDIR}/bin
rsync -ar ./script ${DESTDIR}
rsync -ar ${WORKDIR}/tcl8.6.9/library ${DESTDIR}
mkdir -p ${DESTDIR}/library/tk8.6
rsync -ar ${WORKDIR}/tk8.6.9/library/ ${DESTDIR}/library/tk8.6/

cp ${WORKDIR}/gpatsch.exe ${DESTDIR}/bin
cp ${WORKDIR}/virtual-audio-capture-grabber-device-master/source_code/x64/Release/audio_sniffer-x64.dll ${DESTDIR}/dll

rsync -ar ${WORKDIR}/love-11.3-win64/ ${DESTDIR}/bin
rsync -ar ${WORKDIR}/ffmpeg-4.3.1-win64-static/ ${DESTDIR}
rsync -ar ${WORKDIR}/rubyinstaller-2.6.6-1-x64/ ${DESTDIR}
rsync -ar ./overlay/${PLATFORM}/ ${DESTDIR}
rsync -ar ./overlay/common/ ${DESTDIR}
rsync -ar ./recorder ${DESTDIR}
cp ./analytics/RiteClubConfig.lua ${DESTDIR}/bin # XXX

# Zip it all up.
zip -r ${DESTDIR}.zip ${DESTDIR}
