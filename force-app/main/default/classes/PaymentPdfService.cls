public with sharing class PaymentPdfService {

    public static Id generateAndAttachPdf(Id paymentId) {
        PageReference pdfPage = Page.PaymentPDF;
        pdfPage.getParameters().put('id', paymentId);
        pdfPage.setRedirect(false);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        Payment__c payment = [SELECT Id, Name FROM Payment__c WHERE Id = :paymentId LIMIT 1];

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Payment Receipt - ' + payment.Name;
        cv.PathOnClient = payment.Name + '.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCv.ContentDocumentId;
        cdl.LinkedEntityId = paymentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        return insertedCv.ContentDocumentId;
    }
}