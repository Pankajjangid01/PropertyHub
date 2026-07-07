public with sharing class AgreementPortalContactService {

    public static void setPortalContact(List<Agreement__c> agreements) {
        Set<Id> bookingIds = new Set<Id>();
        for (Agreement__c a : agreements) {
            if (a.Booking__c != null) {
                bookingIds.add(a.Booking__c);
            }
        }

        if (bookingIds.isEmpty()) {
            return;
        }

        Map<Id, Id> bookingToContactMap = new Map<Id, Id>();
        for (Booking__c b : [
            SELECT Id, Portal_Contact__c
            FROM Booking__c
            WHERE Id IN :bookingIds
        ]) {
            bookingToContactMap.put(b.Id, b.Portal_Contact__c);
        }

        for (Agreement__c a : agreements) {
            if (a.Booking__c != null && bookingToContactMap.containsKey(a.Booking__c)) {
                a.Portal_Contact__c = bookingToContactMap.get(a.Booking__c);
            }
        }
    }
}