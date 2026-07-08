public with sharing class GeneratePaymentPdfController {

    public Id paymentId { get; private set; }
    public Boolean isSuccess { get; set; }

    public GeneratePaymentPdfController(ApexPages.StandardController stdController) {
        this.paymentId = stdController.getId();
        this.isSuccess = false;
    }

    public PageReference generatePdf() {
        try {
            PaymentPdfService.generateAndAttachPdf(paymentId);
            isSuccess = true;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PDF generation failed: ' + e.getMessage()));
            isSuccess = false;
        }
        return null;
    }
}