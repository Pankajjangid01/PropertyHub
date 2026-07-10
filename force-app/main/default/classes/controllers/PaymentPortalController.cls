public with sharing class PaymentPortalController {

    public class PaymentWrapper {
        @AuraEnabled public Id paymentId;
        @AuraEnabled public String paymentName;
        @AuraEnabled public String bookingName;
        @AuraEnabled public String propertyName;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String originalCurrency;
        @AuraEnabled public Decimal convertedAmount;
        @AuraEnabled public String displayCurrency;
        @AuraEnabled public String paymentDate;
        @AuraEnabled public String paymentStatus;
        @AuraEnabled public String paymentMode;
    }

    public class DocumentWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String downloadUrl;
    }

    @AuraEnabled(cacheable=true)
    public static List<PaymentWrapper> getMyPayments(String preferredCurrency) {
        Id currentContactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;

        List<PaymentWrapper> result = new List<PaymentWrapper>();
        if (currentContactId == null) {
            return result;
        }

        String targetCurrency = String.isNotBlank(preferredCurrency) ? preferredCurrency : null;

        List<Payment__c> payments = [
            SELECT Id, Name, Amount__c, CurrencyIsoCode, Payment_Date__c, Payment_Status__c, Payment_Mode__c,
                   Booking__r.Name, Booking__r.Property__r.Name
            FROM Payment__c
            WHERE Portal_Contact__c = :currentContactId
            ORDER BY Payment_Date__c DESC
        ];

        for (Payment__c p : payments) {
            PaymentWrapper pw = new PaymentWrapper();
            pw.paymentId = p.Id;
            pw.paymentName = p.Name;
            pw.bookingName = p.Booking__r != null ? p.Booking__r.Name : null;
            pw.propertyName = (p.Booking__r != null && p.Booking__r.Property__r != null)
                ? p.Booking__r.Property__r.Name
                : null;
            pw.amount = p.Amount__c;
            pw.originalCurrency = p.CurrencyIsoCode;
            pw.paymentDate = p.Payment_Date__c != null ? p.Payment_Date__c.format() : null;
            pw.paymentStatus = p.Payment_Status__c;
            pw.paymentMode = p.Payment_Mode__c;

            if (targetCurrency != null && targetCurrency != p.CurrencyIsoCode && p.Amount__c != null) {
                pw.convertedAmount = CurrencyConversionService.convertAmount(p.Amount__c, p.CurrencyIsoCode, targetCurrency);
                pw.displayCurrency = targetCurrency;
            } else {
                pw.convertedAmount = p.Amount__c;
                pw.displayCurrency = p.CurrencyIsoCode;
            }

            result.add(pw);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getPaymentFiles(Id paymentId) {
        List<DocumentWrapper> result = new List<DocumentWrapper>();
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :paymentId
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