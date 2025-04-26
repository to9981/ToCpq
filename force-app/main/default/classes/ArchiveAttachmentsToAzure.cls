public with sharing class ArchiveAttachmentsToAzure {
  public static void runAll() {
    List<ContentDocumentLink> links = new List<ContentDocumentLink>();
    List<ContentVersion> versions;

    // First check Case object access
    if (!Schema.sObjectType.Case.isAccessible()) {
      throw new System.SecurityException(
        'Insufficient permissions to access Case object.'
      );
    }

    // Then check ContentDocumentLink access
    if (!Schema.sObjectType.ContentDocumentLink.isAccessible()) {
      throw new System.SecurityException(
        'Insufficient permissions to access ContentDocumentLink object.'
      );
    }

    // Finally check field level security
    if (
      !Schema.sObjectType.ContentDocumentLink.fields.ContentDocumentId.isAccessible()
    ) {
      throw new System.SecurityException(
        'Insufficient permissions to access ContentDocumentId field.'
      );
    }

    // After all security checks, perform the query
    links = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN (SELECT Id FROM Case)
    ];

    Set<Id> docIds = new Set<Id>();
    for (ContentDocumentLink link : links) {
      docIds.add(link.ContentDocumentId);
    }

    // Query latest versions
    if (!Schema.sObjectType.ContentVersion.isAccessible()) {
      throw new System.SecurityException(
        'Insufficient permissions to access ContentVersion object.'
      );
    }

    versions = [
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
    if (!Schema.sObjectType.AzureSAS__c.isAccessible()) {
      throw new System.SecurityException(
        'Insufficient permissions to access AzureSAS__c object.'
      );
    }

    String fileName = cv.PathOnClient != null ? cv.PathOnClient : cv.Title;
    String blobName = EncodingUtil.urlEncode(cv.Id + fileName, 'UTF-8');

    AzureSAS__c sasRecord = [
      SELECT SASToken__c
      FROM AzureSAS__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    String sasToken = sasRecord.SASToken__c;
    System.debug('SAS Token: ' + sasToken);

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

    HttpResponse res = new Http().send(req);
    System.debug('Upload ' + blobName + ' status: ' + res.getStatusCode());
  }
}
