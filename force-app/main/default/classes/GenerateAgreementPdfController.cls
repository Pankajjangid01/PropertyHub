public with sharing class GenerateAgreementPdfController {

    public Id agreementId { get; private set; }
    public Boolean isSuccess { get; set; }

    public GenerateAgreementPdfController(ApexPages.StandardController stdController) {
        this.agreementId = stdController.getId();
        this.isSuccess = false;
    }

    public PageReference generatePdf() {
        try {
            AgreementPdfService.generateAndAttachPdf(agreementId);
            isSuccess = true;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PDF generation failed: ' + e.getMessage()));
            isSuccess = false;
        }
        return null;
    }
}