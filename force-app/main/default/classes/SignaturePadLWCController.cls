public with sharing class SignaturePadLWCController {
    public String signatureData { get; set; }
    
    public SignaturePadLWCController(ApexPages.StandardController controller) {
        signatureData = ApexPages.currentPage().getParameters().get('signatureData');
    }
}