public without sharing class AgreementValidationService {
    public static void checkAgreementBookingStatus(List<Agreement__c> newAgreements) {
        Set<Id> bookingIds = new Set<Id>();
        for (Agreement__c agreement : newAgreements) {
            if (agreement.Booking__c != null) {
                bookingIds.add(agreement.Booking__c);
            }
        }

        if (bookingIds.isEmpty()) {
            return;
        }

        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>(
            [SELECT Id, Booking_Status__c FROM Booking__c WHERE Id IN :bookingIds]
        );

        for (Agreement__c agreement : newAgreements) {
            if (agreement.Booking__c == null) {
                continue;
            }
            Booking__c booking = bookingMap.get(agreement.Booking__c);
            if (booking == null || booking.Booking_Status__c != 'Approved') {
                agreement.addError('The linked Booking must have a status of "Approved" to create an Agreement.');
            }
        }
    }
}