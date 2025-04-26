/**
 * @description Apex class to archive Salesforce Case ContentVersions (Files) to Azure Blob Storage.
 * It uses a Named Credential for authentication and constructs the Azure Blob URL.
 * This version archives the files but does NOT delete them from Salesforce.
 */
public with sharing class AzureContentVersionArchiver {
  // Named Credential API Name for Azure Blob Storage
  private static final String NAMED_CREDENTIAL_API_NAME = 'Azure_Blob_Storage';
  // Azure Blob Storage Container Name
  private static final String AZURE_CONTAINER_NAME = 'container1';

  /**
   * @description Archives ContentVersions (Files) related to Cases to Azure Blob Storage.
   * This method queries for ContentVersions, uploads them to Azure, but does NOT delete them from Salesforce.
   * Consider adding specific SOQL filters to process only relevant files.
   */
  @InvocableMethod(
    label='Archive Case Files to Azure (No Delete)'
    description='Archives ContentVersions (Files) related to Cases to Azure Blob Storage, without deleting them from Salesforce.'
  )
  public static void archiveCaseContentVersions() {
    // Step 1: Get ContentDocumentIds linked to Case records
    Set<Id> contentDocumentIds = new Set<Id>();
    List<ContentDocumentLink> cdlLinks = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN (SELECT Id FROM Case)
      LIMIT 200 // Limit the initial query as well
    ];

    for (ContentDocumentLink cdl : cdlLinks) {
      contentDocumentIds.add(cdl.ContentDocumentId);
    }

    if (contentDocumentIds.isEmpty()) {
      System.debug('No ContentDocumentLinks found for Cases.');
      return;
    }

    // Step 2: Query ContentVersion using the collected ContentDocumentIds
    List<ContentVersion> contentVersionsToArchive = [
      SELECT Id, Title, VersionData, ContentDocumentId, FileExtension
      FROM ContentVersion
      WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE // Ensure we only get the latest version of the file
      // You might want to add more filters here, e.g., AND CreatedDate < LAST_N_DAYS:30
    ];

    if (contentVersionsToArchive.isEmpty()) {
      System.debug(
        'No latest ContentVersions found for the linked ContentDocuments.'
      );
      return;
    }

    List<Id> archivedContentVersionIds = new List<Id>();

    for (ContentVersion cv : contentVersionsToArchive) {
      try {
        // Construct the Azure Blob URL using the Named Credential and container name.
        // The Named Credential URL should be the base URL for the storage account
        // or the container, including the SAS token.
        // Example: callout:Azure_Blob_Storage/container1/path/to/blob
        // Use Title and FileExtension for the blob name
        String blobName =
          EncodingUtil.urlEncode(cv.Title, 'UTF-8') +
          '.' +
          cv.FileExtension;
        String blobUrl =
          'callout:' +
          NAMED_CREDENTIAL_API_NAME +
          '/' +
          AZURE_CONTAINER_NAME +
          '/' +
          blobName;

        // Create an HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(blobUrl);
        req.setMethod('PUT'); // Use PUT method to upload the blob
        req.setHeader('x-ms-blob-type', 'BlockBlob'); // Specify blob type
        req.setBodyAsBlob(cv.VersionData); // Set the file data as the request body
        req.setTimeout(60000); // Set a timeout (in milliseconds)

        // Send the HTTP request
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Check the response status
        if (res.getStatusCode() == 201) {
          // 201 Created indicates success for PUT
          System.debug(
            'Successfully archived file: ' +
              cv.Title +
              ' (Id: ' +
              cv.Id +
              ') to Azure Blob Storage.'
          );
          archivedContentVersionIds.add(cv.Id);
          // Note: Deletion logic has been removed as requested.
        } else {
          // Use System.debug for logging errors
          System.debug(
            'ERROR: Failed to archive file: ' +
              cv.Title +
              ' (Id: ' +
              cv.Id +
              '). Status Code: ' +
              res.getStatusCode() +
              ', Body: ' +
              res.getBody()
          );
          // Optionally, log the error or handle it differently
        }
      } catch (Exception e) {
        // Use System.debug for logging errors
        System.debug(
          'ERROR: An error occurred while archiving file ' +
            cv.Title +
            ' (Id: ' +
            cv.Id +
            '): ' +
            e.getMessage()
        );
        // Handle exceptions, e.g., log them, send notifications, etc.
      }
    }

    // Deletion logic has been removed as requested.
    // If you need to delete files later, you would need a separate process.
  }

  // You can add more methods here, e.g., to retrieve files from Azure,
  // handle specific error scenarios, or process files in batches using Queueable or Batch Apex.
}
