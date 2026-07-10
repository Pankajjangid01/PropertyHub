public with sharing class QuotationPortalController {

    public class QuotationWrapper {
        @AuraEnabled public Id quotationId;
        @AuraEnabled public String quotationName;
        @AuraEnabled public String quotationStatus;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public String originalCurrency;
        @AuraEnabled public Decimal convertedTotal;
        @AuraEnabled public String displayCurrency;
        @AuraEnabled public String propertyName;
    }

    public class DocumentWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String downloadUrl;
    }

    @AuraEnabled(cacheable=true)
    public static List<QuotationWrapper> getMyQuotations(String preferredCurrency) {

        Id currentContactId = [
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        List<QuotationWrapper> result = new List<QuotationWrapper>();
        if (currentContactId == null) {
            return result;
        }

        String targetCurrency = String.isNotBlank(preferredCurrency) ? preferredCurrency : null;

        List<Quotation__c> quotations = [
            SELECT Id, Name, Quotation_Status__c, Total_Amount__c, CurrencyIsoCode, Property__r.Name
            FROM Quotation__c
            WHERE Portal_Contact__c = :currentContactId
            ORDER BY CreatedDate DESC
        ];

        for (Quotation__c q : quotations) {
            QuotationWrapper qw = new QuotationWrapper();
            qw.quotationId = q.Id;
            qw.quotationName = q.Name;
            qw.quotationStatus = q.Quotation_Status__c;
            qw.totalAmount = q.Total_Amount__c;
            qw.originalCurrency = q.CurrencyIsoCode;
            qw.propertyName = q.Property__r != null ? q.Property__r.Name : null;

            if (targetCurrency != null && targetCurrency != q.CurrencyIsoCode && q.Total_Amount__c != null) {
                qw.convertedTotal = CurrencyConversionService.convertAmount(q.Total_Amount__c, q.CurrencyIsoCode, targetCurrency);
                qw.displayCurrency = targetCurrency;
            } else {
                qw.convertedTotal = q.Total_Amount__c;
                qw.displayCurrency = q.CurrencyIsoCode;
            }

            result.add(qw);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getQuotationFiles(Id quotationId) {

        List<DocumentWrapper> result = new List<DocumentWrapper>();

        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :quotationId
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