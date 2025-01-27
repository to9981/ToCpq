public with sharing class SignaturePadController {
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        return [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
    }

    @AuraEnabled
    public static void saveSignature(String signatureData, Id accountId) {
        // Logic to save the signature data to the database or related record
        // This could involve creating a new record or updating an existing one
    }
}