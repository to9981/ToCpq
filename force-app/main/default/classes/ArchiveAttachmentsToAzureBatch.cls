public class ArchiveAttachmentsToAzureBatch implements Database.Batchable<SObject>, Database.Stateful {
  private String sasToken;

  public ArchiveAttachmentsToAzureBatch() {
    // Get SAS token in constructor
    AzureSAS__c sasRecord = [
      SELECT SASToken__c
      FROM AzureSAS__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    this.sasToken = sasRecord.SASToken__c;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    // Security checks
    checkObjectAccess();

    // First, get the Case-related ContentDocumentIds
    Set<Id> docIds = new Set<Id>();
    for (ContentDocumentLink cdl : [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN (SELECT Id FROM Case)
    ]) {
      docIds.add(cdl.ContentDocumentId);
    }

    // Then query ContentVersions using the collected IDs
    return Database.getQueryLocator(
      [
        SELECT VersionData, PathOnClient, Title
        FROM ContentVersion
        WHERE ContentDocumentId IN :docIds AND IsLatest = TRUE
      ]
    );
  }

  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Http http = new Http();

    // Loop through records and perform HTTP callouts
    for (SObject record : scope) {
      ContentVersion cv = (ContentVersion) record;

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
        HttpResponse res = http.send(req);
        System.debug('Upload ' + blobName + ' status: ' + res.getStatusCode());
      } catch (Exception e) {
        System.debug('Error uploading ' + blobName + ': ' + e.getMessage());
      }
    }
  }

  public void finish(Database.BatchableContext bc) {
    System.debug('Batch processing complete!');
  }

  private void checkObjectAccess() {
    // Implement security checks here
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
    System.debug('Security checks performed.');
  }
}
