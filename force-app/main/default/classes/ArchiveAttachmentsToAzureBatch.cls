public class ArchiveAttachmentsToAzureBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
  private String sasToken;

  public ArchiveAttachmentsToAzureBatch() {
    AzureSAS__c sasRecord = [
      SELECT SASToken__c
      FROM AzureSAS__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    this.sasToken = sasRecord.SASToken__c;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    checkObjectAccess();
    Set<Id> docIds = new Set<Id>();
    for (ContentDocumentLink cdl : [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN (SELECT Id FROM Case)
    ]) {
      docIds.add(cdl.ContentDocumentId);
    }

    if (docIds.isEmpty()) {
      System.debug('No documents found to process');
      return Database.getQueryLocator(
        [SELECT Id FROM ContentVersion WHERE Id = NULL]
      );
    }
    return Database.getQueryLocator(
      [
        SELECT Id, VersionData, PathOnClient, Title, ContentDocumentId
        FROM ContentVersion
        WHERE ContentDocumentId IN :docIds AND IsLatest = TRUE
      ]
    );
  }

  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    Set<Id> contentDocumentIds = getContentDocumentIds(scope);

    List<ContentDocumentLink> contentDocumentLinksToDelete = new List<ContentDocumentLink>();
    Set<Id> contentDocumentIdsToDelete = new Set<Id>();

    for (SObject record : scope) {
      ContentVersion cv = (ContentVersion) record;

      String blobName = EncodingUtil.urlEncode(
        cv.Id + (cv.PathOnClient != null ? cv.PathOnClient : cv.Title),
        'UTF-8'
      );
      if (uploadFileToAzure(cv, blobName)) {
        contentDocumentIdsToDelete.add(cv.ContentDocumentId);
      }
    }
    deleteRecords(contentDocumentIdsToDelete);
  }

  private Set<Id> getContentDocumentIds(List<SObject> scope) {
    Set<Id> contentDocumentIds = new Set<Id>();
    for (SObject record : scope) {
      ContentVersion cv = (ContentVersion) record;
      contentDocumentIds.add(cv.ContentDocumentId);
    }
    return contentDocumentIds;
  }

  private Boolean uploadFileToAzure(ContentVersion cv, String blobName) {
    Http http = new Http();
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
      return res.getStatusCode() == 201;
    } catch (Exception e) {
      System.debug('Error uploading ' + blobName + ': ' + e.getMessage());
      return false;
    }
  }

  private void deleteRecords(Set<Id> contentDocumentIdsToDelete) {
    List<ContentDocument> contentDocumentsToDelete = new List<ContentDocument>();
    for (Id docId : contentDocumentIdsToDelete) {
      contentDocumentsToDelete.add(new ContentDocument(Id = docId));
    }

    if (!contentDocumentsToDelete.isEmpty()) {
      try {
        delete contentDocumentsToDelete;
        System.debug(
          'Deleted ContentDocuments: ' + contentDocumentsToDelete.size()
        );
      } catch (DmlException e) {
        System.debug('Error deleting ContentDocument: ' + e.getMessage());
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
