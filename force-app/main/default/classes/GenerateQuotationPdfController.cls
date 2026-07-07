public with sharing class GenerateQuotationPdfController {

    private final Id quotationId;
    public Boolean isSuccess { get; set; }

    public Id getQuotationId() {
        return quotationId;
    }

    public GenerateQuotationPdfController(ApexPages.StandardController stdController) {
        this.quotationId = stdController.getId();
        this.isSuccess = false;
    }

    public PageReference generatePdf() {
        try {
            QuotationPdfService.generateAndAttachPdf(quotationId);
            this.isSuccess = true;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
}