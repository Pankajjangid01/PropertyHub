public with sharing class BookingPrefillController {

    public class QuotationPrefillData {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Id propertyId;
        @AuraEnabled public String quotationStatus;
    }

    @AuraEnabled(cacheable=true)
    public static QuotationPrefillData getQuotationPrefillData(Id quotationId) {

        List<Quotation__c> quotationList = [
            SELECT Id, Opportunity__c, Property__c, Quotation_Status__c
            FROM Quotation__c
            WHERE Id = :quotationId
            LIMIT 1
        ];

        if (quotationList.isEmpty()) {
            return null;
        }

        Quotation__c quotation = quotationList[0];

        QuotationPrefillData data = new QuotationPrefillData();
        data.opportunityId = quotation.Opportunity__c;
        data.propertyId = quotation.Property__c;
        data.quotationStatus = quotation.Quotation_Status__c;

        return data;
    }
}