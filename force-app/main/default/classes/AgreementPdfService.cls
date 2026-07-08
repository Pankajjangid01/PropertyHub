public with sharing class AgreementPdfService {

    public static Id generateAndAttachPdf(Id agreementId) {
        PageReference pdfPage = Page.AgreementPDF;
        pdfPage.getParameters().put('id', agreementId);
        pdfPage.setRedirect(false);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        Agreement__c agreement = [SELECT Id, Name FROM Agreement__c WHERE Id = :agreementId LIMIT 1];

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Agreement - ' + agreement.Name;
        cv.PathOnClient = agreement.Name + '.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCv.ContentDocumentId;
        cdl.LinkedEntityId = agreementId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        // NEW
        update new Agreement__c(Id = agreementId, PDF_Generated__c = true);

        return insertedCv.ContentDocumentId;
    }
}