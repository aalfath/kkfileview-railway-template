package cn.keking.service;

import cn.keking.model.FileAttribute;
import cn.keking.utils.FileConvertStatusManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

/**
 * Open-source build (aalfath/kkfileview-railway-template): CAD conversion in upstream kkFileView uses the
 * proprietary Aspose.CAD library or the commercial CADViewer converter, neither of which is included here.
 * CAD files therefore fail with a clear message instead of a stack trace.
 */
@Component
public class CadToPdfService {
    private static final Logger logger = LoggerFactory.getLogger(CadToPdfService.class);
    static final String MESSAGE = "CAD preview (dwg/dxf/...) is not included in this open-source build of kkFileView.";

    public CompletableFuture<Boolean> cadToPdfAsync(String inputFilePath, String outputFilePath, String cacheName,
                                                    String cadPreviewType, FileAttribute fileAttribute) {
        return unsupported(cacheName);
    }

    public CompletableFuture<Boolean> cadViewerConvert(String sDwgFile, String outFilePath, String cachefilepath,
                                                       String cadPreviewType, String cacheName) {
        return unsupported(cacheName);
    }

    public void cancelConversion(String fileName) {
        // nothing runs
    }

    private CompletableFuture<Boolean> unsupported(String cacheName) {
        logger.warn("{} ({})", MESSAGE, cacheName);
        FileConvertStatusManager.markError(cacheName, MESSAGE);
        return CompletableFuture.completedFuture(false);
    }
}
