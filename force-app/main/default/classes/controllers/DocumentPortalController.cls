public with sharing class DocumentPortalController {

    public class DocumentWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String downloadUrl;
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getMyDocuments() {

        Id currentContactId = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        List<DocumentWrapper> result = new List<DocumentWrapper>();

        if (currentContactId == null) {
            return result;
        }

        Set<Id> bookingIds = new Set<Id>();
        for (Booking__c b : [SELECT Id FROM Booking__c WHERE Portal_Contact__c = :currentContactId]) {
            bookingIds.add(b.Id);
        }

        if (bookingIds.isEmpty()) {
            return result;
        }

        Set<Id> recordIds = new Set<Id>();
        Map<Id, String> recordLabels = new Map<Id, String>();

        Set<Id> quotationIds = new Set<Id>();
        for (Booking__c b : [SELECT Id, Quotation__c FROM Booking__c WHERE Id IN :bookingIds AND Quotation__c != null]) {
            quotationIds.add(b.Quotation__c);
        }
        for (Quotation__c q : [SELECT Id, Name FROM Quotation__c WHERE Id IN :quotationIds]) {
            recordIds.add(q.Id);
            recordLabels.put(q.Id, 'Quotation - ' + q.Name);
        }

        for (Agreement__c a : [SELECT Id, Name FROM Agreement__c WHERE Booking__c IN :bookingIds]) {
            recordIds.add(a.Id);
            recordLabels.put(a.Id, 'Agreement - ' + a.Name);
        }

        if (recordIds.isEmpty()) {
            return result;
        }

        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
        ]) {
            DocumentWrapper doc = new DocumentWrapper();
            doc.title = recordLabels.get(cdl.LinkedEntityId) + ' (' + cdl.ContentDocument.Title + ')';
            doc.downloadUrl = '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId;
            result.add(doc);
        }

        return result;
    }
}