public with sharing class PaymentPortalController {

    @AuraEnabled(cacheable=true)
    public static List<Payment__c> getMyPayments() {

        Id currentContactId = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        if (currentContactId == null) {
            return new List<Payment__c>();
        }

        return [
            SELECT Id, Name, Amount__c, Payment_Date__c, Payment_Status__c, Payment_Mode__c, Booking__r.Name
            FROM Payment__c
            WHERE Portal_Contact__c = :currentContactId
            ORDER BY Payment_Date__c DESC
        ];
    }
}