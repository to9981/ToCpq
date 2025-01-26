public with sharing class PDFRenderController {
    private final Account account;

    public PDFRenderController(ApexPages.StandardController stdController) {
        this.account = (Account) stdController.getRecord();
    }

    public void uploadPDF() {
        try {
            // Generate the PDF from the current page
            PageReference pdfPage = ApexPages.currentPage();
            Blob pdfBlob = pdfPage.getContentAsPDF();

            // Save the PDF as an Attachment (or ContentDocument)
            Attachment pdfAttachment = new Attachment();
            pdfAttachment.ParentId = account.Id;
            pdfAttachment.Body = pdfBlob;
            pdfAttachment.ContentType = 'application/pdf';
            pdfAttachment.Name = 'AgreementWithSignature.pdf';
            insert pdfAttachment;

            System.debug('PDF uploaded successfully with Id: ' + pdfAttachment.Id);
        } catch (Exception e) {
            System.debug('Error uploading PDF: ' + e.getMessage());
        }
    }
}
