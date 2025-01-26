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
            a.Name = 'SignatureCapture.png';
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
            pdfPage.getParameters().put('id', ApexPages.currentPage().getParameters().get('id'));
            pdfPage.getParameters().put('latestAttachmentId', ApexPages.currentPage().getParameters().get('latestAttachmentId'));
            pdfPage.setRedirect(false);

            // Generate the PDF
            Blob pdfBlob = pdfPage.getContentAsPDF();
            System.debug('Generated PDF Blob Size: ' + pdfBlob.size());

            // Upload the PDF as an Attachment
            Attachment pdfAttachment = new Attachment();
            pdfAttachment.ParentId = ApexPages.currentPage().getParameters().get('id');
            pdfAttachment.Body = pdfBlob;
            pdfAttachment.ContentType = 'application/pdf';
            pdfAttachment.Name = 'AgreementWithSignature.pdf';
            insert pdfAttachment;

            System.debug('PDF uploaded successfully with Id: ' + pdfAttachment.Id);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'PDF uploaded successfully.'));

            // Optionally, redirect to the Account record
            return new PageReference('/' + ApexPages.currentPage().getParameters().get('id'));
        } catch (Exception e) {
            System.debug('Error uploading PDF: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error uploading PDF: ' + e.getMessage()));
            return null;
        }
    }
}
