global with sharing class SignaturePadController {
    private final Account account;
    
    public SignaturePadController(ApexPages.StandardController controller) {
        this.account = (Account) controller.getRecord();
    }
    
    @RemoteAction
    global static String saveSignature(String signatureBody, Id parentId) {
        try {
            // Save the signature as an attachment
            Attachment a = new Attachment();
            a.ParentId = parentId;
            a.Body = EncodingUtil.base64Decode(signatureBody);
            a.ContentType = 'image/png';
            a.Name = 'SignatureCapture-'+ system.now() + '.png';
            insert a;
            
            System.debug('Signature saved with Id: ' + a.Id);
            
            // Return the ID of the saved attachment
            return a.Id;
        } catch (Exception e) {
            System.debug('Error saving signature: ' + e.getMessage());
            return null;
        }
    }
    
    public PageReference uploadPDF() {
        try {
            // Get the current page and parameters
            PageReference pdfPage = Page.GeneratePDFPage;
            String accountId = ApexPages.currentPage().getParameters().get('id');
            String attachmentId = ApexPages.currentPage().getParameters().get('latestAttachmentId');
            
            if (accountId != null) {
                pdfPage.getParameters().put('id', accountId);
            }
            if (attachmentId != null) {
                pdfPage.getParameters().put('latestAttachmentId', attachmentId);
            }
            
            pdfPage.setRedirect(false);
            
            // Generate the PDF
            Blob pdfBlob = pdfPage.getContentAsPDF();
            System.debug('Generated PDF Blob Size: ' + pdfBlob.size());
            
            // Upload the PDF as an Attachment
            Attachment pdfAttachment = new Attachment();
            pdfAttachment.ParentId = ApexPages.currentPage().getParameters().get('id');
            pdfAttachment.Body = pdfBlob;
            pdfAttachment.ContentType = 'application/pdf';
            pdfAttachment.Name = 'SignedAgreement-' + system.now() + '.pdf';
            insert pdfAttachment;
            
            System.debug('PDF uploaded successfully with Id: ' + pdfAttachment.Id);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Agreement saved successfully.'));
            
            // Optionally, redirect to the Account record
            // return new PageReference('/' + ApexPages.currentPage().getParameters().get('id'));
            return null;
        } catch (Exception e) {
            System.debug('Error uploading PDF: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error uploading Agreement: ' + e.getMessage()));
            return null;
        }
    }
    
    global String getUploadMessage() {
        if (ApexPages.hasMessages()) {
            System.debug('Messages are present on the page.');
            for (ApexPages.Message message : ApexPages.getMessages()) {
                System.debug('Message summary: ' + message.getSummary());
                return message.getSummary();
            }
        }
        System.debug('No messages found on the page.');
        return null;
}}