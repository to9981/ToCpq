public with sharing class ArchiveAttachmentsToAzure {
  private static final Integer BATCH_SIZE = 50; // Adjust based on callout limits

  public static void runAll() {
    // Security checks
    checkObjectAccess();

    // Get Case document links in bulk
    List<ContentDocumentLink> links = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN (SELECT Id FROM Case)
    ];

    Set<Id> docIds = new Set<Id>();
    for (ContentDocumentLink link : links) {
      docIds.add(link.ContentDocumentId);
    }

    // Query latest versions in bulk
    List<ContentVersion> versions = [
      SELECT VersionData, PathOnClient, Title
      FROM ContentVersion
      WHERE ContentDocumentId IN :docIds AND IsLatest = TRUE
    ];

    // Get SAS token once for all operations
    AzureSAS__c sasRecord = [
      SELECT SASToken__c
      FROM AzureSAS__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    // Process versions in batches to respect callout limits
    List<ContentVersion> batch = new List<ContentVersion>();
    List<String> results = new List<String>();

    for (Integer i = 0; i < versions.size(); i++) {
      batch.add(versions[i]);

      if (batch.size() == BATCH_SIZE || i == versions.size() - 1) {
        results.addAll(uploadBlobBatch(batch, sasRecord.SASToken__c));
        batch.clear();
      }
    }

    // Log results
    for (String result : results) {
      System.debug(result);
    }
  }

  private static List<String> uploadBlobBatch(
    List<ContentVersion> versions,
    String sasToken
  ) {
    List<String> results = new List<String>();

    for (ContentVersion cv : versions) {
      String fileName = cv.PathOnClient != null ? cv.PathOnClient : cv.Title;
      String blobName = EncodingUtil.urlEncode(cv.Id + fileName, 'UTF-8');

      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        'https://account425.blob.core.windows.net/container1/' +
          blobName +
          '?' +
          sasToken
      );
      req.setMethod('PUT');
      req.setHeader('x-ms-blob-type', 'BlockBlob');
      req.setHeader('x-ms-version', '2020-04-08');
      req.setBodyAsBlob(cv.VersionData);

      try {
        HttpResponse res = new Http().send(req);
        results.add('Upload ' + blobName + ' status: ' + res.getStatusCode());
      } catch (Exception e) {
        results.add('Error uploading ' + blobName + ': ' + e.getMessage());
      }
    }

    return results;
  }

  private static void checkObjectAccess() {
    if (!Schema.sObjectType.Case.isAccessible()) {
      throw new System.SecurityException(
        'Insufficient permissions to access Case object.'
      );
    }
    if (!Schema.sObjectType.ContentDocumentLink.isAccessible()) {
      throw new System.SecurityException(
        'Insufficient permissions to access ContentDocumentLink object.'
      );
    }
    if (!Schema.sObjectType.ContentVersion.isAccessible()) {
      throw new System.SecurityException(
        'Insufficient permissions to access ContentVersion object.'
      );
    }
    if (!Schema.sObjectType.AzureSAS__c.isAccessible()) {
      throw new System.SecurityException(
        'Insufficient permissions to access AzureSAS__c object.'
      );
    }
  }
}
