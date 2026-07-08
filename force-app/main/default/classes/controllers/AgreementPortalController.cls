public with sharing class AgreementPortalController {

    public class AgreementWrapper {
        @AuraEnabled public Id agreementId;
        @AuraEnabled public String agreementName;
        @AuraEnabled public String agreementStatus;
        @AuraEnabled public String agreementDate;
        @AuraEnabled public String registrationDate;
        @AuraEnabled public String propertyName;
        @AuraEnabled public String bookingName;
    }

    public class DocumentWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String downloadUrl;
    }

    @AuraEnabled(cacheable=true)
    public static List<AgreementWrapper> getMyAgreements() {

        Id currentContactId = [
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        List<AgreementWrapper> result = new List<AgreementWrapper>();
        if (currentContactId == null) {
            return result;
        }

        List<Agreement__c> agreements = [
            SELECT Id, Name, Agreement_Status__c, Agreement_Date__c, Registration_Date__c,
                   Booking__r.Name, Booking__r.Property__r.Name
            FROM Agreement__c
            WHERE Portal_Contact__c = :currentContactId
            ORDER BY CreatedDate DESC
        ];

        for (Agreement__c a : agreements) {
            AgreementWrapper aw = new AgreementWrapper();
            aw.agreementId = a.Id;
            aw.agreementName = a.Name;
            aw.agreementStatus = a.Agreement_Status__c;
            aw.agreementDate = a.Agreement_Date__c != null ? a.Agreement_Date__c.format() : null;
            aw.registrationDate = a.Registration_Date__c != null ? a.Registration_Date__c.format() : null;
            aw.propertyName = a.Booking__r != null && a.Booking__r.Property__r != null ? a.Booking__r.Property__r.Name : null;
            aw.bookingName = a.Booking__r != null ? a.Booking__r.Name : null;
            result.add(aw);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getAgreementFiles(Id agreementId) {

        List<DocumentWrapper> result = new List<DocumentWrapper>();

        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :agreementId
        ];

        for (ContentDocumentLink cdl : links) {
            DocumentWrapper dw = new DocumentWrapper();
            dw.title = cdl.ContentDocument.Title;
            dw.downloadUrl = '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId;
            result.add(dw);
        }

        return result;
    }
}