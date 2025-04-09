public with sharing class AccountAgreementController {
  public Account acc { get; set; }
  public String signatureBase64 { get; set; }

  public AccountAgreementController() {
    String accountId = ApexPages.currentPage().getParameters().get('id');
    if (accountId != null) {
      acc = [SELECT Id, I_Agree__c, Name FROM Account WHERE Id = :accountId];
    }
  }

  public PageReference saveAgreement() {
    try {
      // Update the account record with the new values
      update acc;

      if (String.isNotBlank(signatureBase64)) {
        // Convert base64 signature to Blob
        Blob signatureBlob = EncodingUtil.base64Decode(
          signatureBase64.substring(signatureBase64.indexOf(',') + 1)
        );

        // Create a new ContentVersion record
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Account Signature -' + acc.Name;
        cv.PathOnClient = 'account_signature.png';
        cv.VersionData = signatureBlob;
        insert cv;

        // Get the newly created ContentDocumentId
        ContentVersion newCV = [
          SELECT ContentDocumentId
          FROM ContentVersion
          WHERE Id = :cv.Id
        ];

        // Create a ContentDocumentLink to relate the document to the account
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = newCV.ContentDocumentId;
        cdl.LinkedEntityId = acc.Id;
        cdl.ShareType = 'V';
        insert cdl;

        ApexPages.addMessage(
          new ApexPages.Message(
            ApexPages.Severity.CONFIRM,
            'Signature saved successfully.'
          )
        );
      } else {
        ApexPages.addMessage(
          new ApexPages.Message(
            ApexPages.Severity.ERROR,
            'Signature data is missing.'
          )
        );
      }
    } catch (Exception e) {
      ApexPages.addMessage(
        new ApexPages.Message(
          ApexPages.Severity.ERROR,
          'Error:: ' + e.getMessage()
        )
      );
    }
    return null;
  }
}
