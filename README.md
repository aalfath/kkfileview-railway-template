[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/kkfileview?utm_medium=integration&utm_source=button&utm_campaign=kkfileview)

# kkFileView on Railway

One-click [Railway](https://railway.com) template for **[kkFileView](https://github.com/kekingcn/kkFileView) 5.0.3**: an open-source online file preview server. Give it a file URL and it shows Word, Excel, PowerPoint, PDF, OFD, images, archives (zip, rar, 7z, tar), Markdown, code, text, CSV, mail (eml/msg), ePub, draw.io, XMind, BPMN and 3D models in the browser.

## What the template deploys

| Service | What it does |
|---|---|
| `kkFileView` | kkFileView 5.0.3 with headless LibreOffice 24.2 (Ubuntu 24.04, Java 21). Public, port 8012, health check `/actuator/health`, volume at `/data` for converted files and the RocksDB conversion cache. |

There is no database and no other service.

- **Version:** kkFileView `v5.0.3` (commit `3b82689a676e8a7e7d3ec4cc0c74de0676b0dac9`), built from source in this repo's `Dockerfile`, because upstream publishes no 5.x image (Docker Hub `keking/kkfileview` stops at 4.1.0). Base images are pinned by digest: `maven:3.9.16-eclipse-temurin-21` (build) and `eclipse-temurin:21.0.13_9-jre-noble` (runtime).
- **Open-source build:** upstream's CAD preview (dwg/dxf) uses the proprietary Aspose.CAD library and a commercial CAD viewer. This build removes both (`patches/`), so CAD files show a clear "not included" message. Everything else is upstream code, unchanged.
- **Small plans:** `start.sh` sizes the JVM heap (about 30% of the memory limit), the LibreOffice process count and converter threads from the container's cgroup limits. On 0.5 GB / 1 vCPU it runs one LibreOffice process; a 160-page document rendered to page images peaked at about 370 MB of process memory (no OOM kill). Video transcoding (avi/mov/mkv to mp4) needs more memory and is switched off below 1.5 GB; browser-playable media still play.
- **Crash = restart:** the JVM exits on `OutOfMemoryError`, and `tini` passes on the exit code, so Railway's on-failure restart policy restarts the service.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `KK_TRUST_HOST` | *(you set it)* | Comma-separated hosts kkFileView may download files from, e.g. `files.example.com,*.example.org`. The service's own Railway domain is always added. Leave it empty and every preview is refused (the service still starts); `*` allows any public host, which makes your instance a public fetcher. |
| `PORT` | `8012` | Port kkFileView listens on. |

Fixed in `start.sh` (override on the service if you need to): private, loopback, link-local and `*.railway.internal` addresses are always refused (`KK_NOT_TRUST_HOST`); the base URL is `https://$RAILWAY_PUBLIC_DOMAIN/` (`KK_BASE_URL`); file upload, folder creation and delete on the demo page are off. Any other upstream `KK_*` setting from [`application.properties`](https://github.com/kekingcn/kkFileView/blob/v5.0.3/server/src/main/config/application.properties), such as `KK_OFFICE_PREVIEW_TYPE`, `WATERMARK_TXT` or `KK_PDF_DOWNLOAD_DISABLE`, can be added as a service variable.

## Using it

Open `https://YOUR-DOMAIN/` for the demo page, or link to a preview from your own app. The file URL is Base64-encoded, then URL-encoded:

```js
const previewUrl = 'https://YOUR-DOMAIN/onlinePreview?url=' + encodeURIComponent(btoa(fileUrl));
```

The file's host must be in `KK_TRUST_HOST`. kkFileView has no login of its own: anyone with your service URL can preview files from your trusted hosts, so only trust hosts whose files may be seen, or put the service behind your own gateway.

## Updates

The service builds from this repo's `main` branch. When we move to a new kkFileView release, we change the pinned commit in the `Dockerfile`, note it in [`CHANGELOG.md`](CHANGELOG.md) (breaking changes first), and Railway shows deployers an "update available" notice; you choose when to apply it. Converted files and cache on `/data` are kept across updates.

## Testing

`tests/fixtures/` holds the sample files the template is checked with (docx, pdf, png, zip, md, txt, csv and a 160-page docx for the memory test).

## Licence

kkFileView is Apache-2.0 (© kekingcn). This repo's wrapper files are Apache-2.0 too.
