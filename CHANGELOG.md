# Changelog

## 5.0.3-railway.1 (2026-11-24)

First release of the template.

- kkFileView `v5.0.3` (security release of 2026-10-08), built from commit `3b82689a676e8a7e7d3ec4cc0c74de0676b0dac9`.
- Runtime `eclipse-temurin:21.0.13_9-jre-noble` with LibreOffice 24.2 from Ubuntu 24.04; build `maven:3.9.16-eclipse-temurin-21`; both pinned by digest.
- Open-source build: Aspose.CAD and the commercial CAD viewer removed, so CAD (dwg/dxf) preview is not included.
- `start.sh` sizes JVM heap, LibreOffice processes and converter threads from cgroup limits (fits 0.5 GB); video transcoding off below 1.5 GB.
- Trust list from `KK_TRUST_HOST` plus the service's own domain; private, loopback, link-local and Railway-internal addresses always refused; upload/delete off.
- Data on the `/data` volume (converted files, RocksDB cache).
