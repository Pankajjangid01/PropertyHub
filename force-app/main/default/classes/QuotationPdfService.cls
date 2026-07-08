public with sharing class QuotationPdfService {

    public static Id generateAndAttachPdf(Id quotationId) {
        PageReference pdfPage = Page.QuotationPDF;
        pdfPage.getParameters().put('id', quotationId);
        pdfPage.setRedirect(false);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        Quotation__c quotation = [SELECT Id, Name FROM Quotation__c WHERE Id = :quotationId LIMIT 1];

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Quotation - ' + quotation.Name;
        cv.PathOnClient = quotation.Name + '.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCv.ContentDocumentId;
        cdl.LinkedEntityId = quotationId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        // NEW — mark PDF as generated so the "Sent" status becomes eligible
        update new Quotation__c(Id = quotationId, PDF_Generated__c = true);

        return insertedCv.ContentDocumentId;
    }
}