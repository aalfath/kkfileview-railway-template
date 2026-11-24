#!/bin/sh
# Build-time patches for the open-source-only kkFileView image.
set -eu
SRC=${1:-/src}
POM="$SRC/server/pom.xml"
# 1. Drop Aspose.CAD (proprietary, evaluation build from repository.aspose.com) and its repository.
perl -0pi -e 's#<dependency>\s*<groupId>com\.aspose</groupId>.*?</dependency>##s; s#<repositories>.*?</repositories>##s' "$POM"
# 2. Drop the Windows-only native classifiers (opencv/openblas/ffmpeg windows-x86_64): smaller image.
perl -0pi -e 's#<dependency>(?:(?!</dependency>).)*?<classifier>windows-x86_64</classifier>(?:(?!</dependency>).)*?</dependency>##gs' "$POM"
if grep -q 'aspose\|windows-x86_64' "$POM"; then echo "pom patch failed" >&2; exit 1; fi
# 3. CAD conversion needs Aspose.CAD or the commercial CADViewer converter: replace it with a stub that fails clearly.
cp /patches/CadToPdfService.java "$SRC/server/src/main/java/cn/keking/service/CadToPdfService.java"
# 4. Remove the bundled commercial CADViewer front end (Tailor Made Software, licence-key based).
rm -r "$SRC/server/src/main/resources/static/cadviewer"
echo "patches applied"
