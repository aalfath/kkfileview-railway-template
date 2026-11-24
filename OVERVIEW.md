# Deploy and Host kkFileView on Railway

kkFileView is an open-source online file preview server built on Spring Boot. Give it the URL of a file and it renders the file in the browser: Word, Excel and PowerPoint documents, PDF and OFD, images, archives (zip, rar, 7z, tar), Markdown, code, text, CSV, eml/msg mail, ePub, draw.io, XMind, BPMN and 3D models.

## About Hosting kkFileView

kkFileView is one Java service with headless LibreOffice inside, which converts Office documents to PDF or page images. This template builds kkFileView 5.0.3 from the release source in our GitHub repo (there is no official 5.x image) and runs it as a single Railway service. Converted files and the RocksDB conversion cache live on a volume at `/data`, so previews stay cached across restarts and redeploys. The JVM heap, LibreOffice process count and converter threads are sized from the service's memory and CPU limits, so it runs on a 0.5 GB plan. kkFileView only fetches files from the hosts you list in `KK_TRUST_HOST`; private, loopback and Railway-internal addresses are always refused, so it is not an open proxy.

## Common Use Cases

* Add "preview" buttons for Office, PDF and archive files to an intranet, CMS, ticketing or document system without installing Office plugins
* Preview attachments stored in S3, MinIO, Nextcloud or any HTTPS file host directly in the browser
* Render documents as images or PDF for read-only viewing, with optional watermarks

## Dependencies for kkFileView Hosting

* A file host that serves the files you want to preview over HTTP(S), listed in `KK_TRUST_HOST`
* A Railway volume for converted files and the conversion cache (included)

### Deployment Dependencies

* kkFileView source: https://github.com/kekingcn/kkFileView (Apache-2.0)
* Template repo: https://github.com/aalfath/kkfileview-railway-template
* kkFileView docs: https://kkview.cn

### Implementation Details

**Service:** `kkFileView` (public, port 8012, health check `/actuator/health`, volume `/data`). There is no database and no other service.

**The one setting:** `KK_TRUST_HOST` is the comma-separated list of hosts kkFileView may download files from, for example `files.example.com,*.example.org`. Change it on the service's Variables tab at any time; the service redeploys. The service's own Railway domain is always added. `*` would allow any public host and turn your instance into a public fetcher, so avoid it.

**After deploy:** open `https://YOUR-DOMAIN/` for the demo page, or link straight to a preview from your app. The file URL is Base64-encoded and then URL-encoded:

```
https://YOUR-DOMAIN/onlinePreview?url=BASE64-OF-FILE-URL
```

In JavaScript: `'https://YOUR-DOMAIN/onlinePreview?url=' + encodeURIComponent(btoa(fileUrl))`.

**Security defaults:** the demo page's file upload, folder creation and delete are off; private, loopback, link-local and `*.railway.internal` addresses are always refused; the actuator exposes only an aggregate health status. There is no login: anyone with the URL can preview files from your trusted hosts, so only trust hosts whose files may be public, or put the service behind your own gateway.

**Memory:** at 0.5 GB the service runs one LibreOffice process and one converter thread; a 160-page document rendered to page images peaked at about 370 MB of process memory (no OOM kill). Video transcoding (avi/mov/mkv to mp4) is switched off below 1.5 GB of RAM; mp4, mp3 and other browser-playable media still play.

**Not included:** CAD preview (dwg/dxf). Upstream renders CAD files with the proprietary Aspose.CAD library and a commercial CAD viewer, so this open-source build leaves them out and CAD files show a clear "not included" message.

**Updates:** the service builds from our GitHub repo. When we publish a new kkFileView version there, Railway shows an update notice on your project and you choose when to apply it. Read the repo's `CHANGELOG.md` first.

## Why Deploy kkFileView on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying kkFileView on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
