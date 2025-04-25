public class ArchiveAttachmentsToAzure {
  public static void runAll() {
    // Retrieve all Case-linked document IDs
    List<ContentDocumentLink> links = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN (SELECT Id FROM Case)
    ];
    Set<Id> docIds = new Set<Id>();
    for (ContentDocumentLink link : links) {
      docIds.add(link.ContentDocumentId);
    }
    // Query latest versions
    List<ContentVersion> versions = [
      SELECT VersionData, PathOnClient, Title
      FROM ContentVersion
      WHERE ContentDocumentId IN :docIds AND IsLatest = TRUE
    ];
    // Invoke callout per file
    for (ContentVersion cv : versions) {
      uploadBlob(cv);
    }
  }

  private static void uploadBlob(ContentVersion cv) {
    String fileName = cv.PathOnClient != null ? cv.PathOnClient : cv.Title;
    String blobName = EncodingUtil.urlEncode(cv.Id + fileName, 'UTF-8');
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'https://account425.blob.core.windows.net/container1/' +
        blobName +
        '?sp=racwdli' +
        '&st=2025-04-25T15:11:33Z' +
        '&se=2025-04-25T23:11:33Z' +
        '&spr=https' +
        '&sv=2024-11-04' +
        '&sr=c' +
        '&sig=LZM0MdDDCtljKu4CXaw4%2B9NnzUiIlSkNkmf%2BUFvWlFg%3D'
    );
    req.setMethod('PUT');
    req.setHeader('x-ms-blob-type', 'BlockBlob');
    req.setHeader('x-ms-version', '2020-04-08');
    req.setBodyAsBlob(cv.VersionData);
    HttpResponse res = new Http().send(req);
    System.debug('Upload ' + blobName + ' status: ' + res.getStatusCode());
  }
}
