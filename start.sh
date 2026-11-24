#!/bin/sh
# kkFileView start script for Railway (aalfath/kkfileview-railway-template).
# Any failure exits non-zero so Railway's ON_FAILURE restart policy restarts the service.
set -eu

APP=/opt/kkFileView
DATA=${KK_DATA_DIR:-/data}
CONF="$APP/config/application.properties"
log() { echo "[kkfileview-start] $*"; }

# ---- trust list: kkFileView only fetches files from these hosts (it is not an open proxy) ----
TRUST=$(printf '%s' "${KK_TRUST_HOST:-}" | tr -d ' ')
if [ -z "$TRUST" ] || [ "$TRUST" = "default" ]; then
  log "KK_TRUST_HOST is empty: set it to the comma-separated hosts whose files may be previewed (e.g. files.example.com,*.example.org)." >&2
  exit 1
fi
# The app's own domain must be trusted for its converted-image pages to load.
for d in "${RAILWAY_PUBLIC_DOMAIN:-}" "${KK_EXTRA_SELF_HOST:-}"; do
  [ -n "$d" ] && TRUST="$TRUST,$d"
done
export KK_TRUST_HOST="$TRUST"
# Private, loopback, link-local and Railway-internal addresses are always refused (blocklist wins over the trust list).
export KK_NOT_TRUST_HOST="${KK_NOT_TRUST_HOST:-localhost,*.localhost,*.railway.internal,*.internal,metadata.google.internal,127.0.0.0/8,0.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10,169.254.0.0/16,[::1],::1,[::],::}"

# ---- port and public URL ----
export KK_SERVER_PORT="${PORT:-8012}"
if [ -z "${KK_BASE_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export KK_BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}/"
fi

# ---- persistent data on the volume ----
mkdir -p "$DATA/file" "$DATA/cache"
export KK_FILE_DIR="$DATA/file/"
export KK_CACHE_TYPE="${KK_CACHE_TYPE:-default}"   # RocksDB, stored in $DATA/cache
ln -sfn "$DATA/cache" "$APP/cache"

# ---- size workers and the JVM from the container's limits, not the host's ----
CPUS=1
if [ -r /sys/fs/cgroup/cpu.max ]; then
  read -r q p < /sys/fs/cgroup/cpu.max || true
  if [ "${q:-max}" != "max" ] && [ -n "${p:-}" ]; then CPUS=$(( (q + p - 1) / p )); else CPUS=$(nproc); fi
else
  CPUS=$(nproc)
fi
[ "$CPUS" -gt 4 ] && CPUS=4
[ "$CPUS" -lt 1 ] && CPUS=1

MEM_MB=0
if [ -r /sys/fs/cgroup/memory.max ] && [ "$(cat /sys/fs/cgroup/memory.max)" != "max" ]; then
  MEM_MB=$(( $(cat /sys/fs/cgroup/memory.max) / 1048576 ))
fi
if [ "$MEM_MB" -eq 0 ] || [ "$MEM_MB" -gt 65536 ]; then
  MEM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
fi
# Heap: about 30% of the limit (LibreOffice and native libraries need the rest), 128-1024 MB.
HEAP=$(( MEM_MB * 30 / 100 ))
[ "$HEAP" -lt 128 ] && HEAP=128
[ "$HEAP" -gt 1024 ] && HEAP=1024
OFFICE_PROCS=1
[ "$MEM_MB" -ge 1800 ] && [ "$CPUS" -ge 2 ] && OFFICE_PROCS=2
# Video transcoding (ffmpeg via JavaCV) does not fit small plans; plain mp4/mp3 playback still works.
if [ -z "${KK_MEDIA_CONVERT_DISABLE:-}" ]; then
  if [ "$MEM_MB" -lt 1500 ]; then export KK_MEDIA_CONVERT_DISABLE=true; else export KK_MEDIA_CONVERT_DISABLE=false; fi
fi
log "limits: ${MEM_MB} MB, ${CPUS} CPU -> heap ${HEAP} MB, ${OFFICE_PROCS} LibreOffice process(es), video conversion disabled=${KK_MEDIA_CONVERT_DISABLE}"

# ---- config file: upstream defaults plus our worker caps ----
PORTS=2001; [ "$OFFICE_PROCS" -ge 2 ] && PORTS=2001,2002
sed -e "s|^office.plugin.server.ports *=.*|office.plugin.server.ports = $PORTS|" \
    -e "s|^pdf.max.threads *=.*|pdf.max.threads = $CPUS|" \
    -e "s|^tif.thread *=.*|tif.thread = $CPUS|" \
    -e "s|^office.plugin.task.maxtasksperprocess *=.*|office.plugin.task.maxtasksperprocess = 50|" \
    -e "s|^file.upload.disable *=.*|file.upload.disable = true|" \
    -e "s|^kk.enable.redirect *=.*|kk.enable.redirect = false|" \
    "$APP/application.properties.dist" > "$CONF"
grep -q "^office.plugin.server.ports = $PORTS" "$CONF" || { log "config patch failed" >&2; exit 1; }

chown -R kkfileview:kkfileview "$DATA" "$APP/config"

set -- java \
  -Xms64m -Xmx${HEAP}m -Xss512k \
  -XX:MaxMetaspaceSize=192m -XX:ReservedCodeCacheSize=48m -XX:MaxDirectMemorySize=64m \
  -XX:+UseSerialGC -XX:ActiveProcessorCount=$CPUS \
  -XX:TieredStopAtLevel=1 -XX:CICompilerCount=1 \
  -XX:+ExitOnOutOfMemoryError \
  -Djava.awt.headless=true -Dfile.encoding=UTF-8 \
  -Djava.io.tmpdir=/tmp \
  -Dspring.config.location="$CONF" \
  -jar "$APP/bin/kkFileView.jar"

log "starting kkFileView on port $KK_SERVER_PORT (trusted hosts: $KK_TRUST_HOST)"
cd /home/kkfileview
exec setpriv --reuid=kkfileview --regid=kkfileview --init-groups env HOME=/home/kkfileview "$@"
