public with sharing class BookingTriggerHandler {

    public static void handleBeforeInsert(List<Booking__c> newBookings) {
        PropertyStatusService.checkPropertyAvailability(newBookings);
    }

    public static void handleAfterInsert(List<Booking__c> newBookings) {
        PropertyStatusService.applyStatusForNewBookings(newBookings);
    }

    public static void handleAfterUpdate(List<Booking__c> newBookings, Map<Id, Booking__c> oldBookingsMap) {
        List<Booking__c> changedBookings = new List<Booking__c>();
        List<Booking__c> approvedBookings = new List<Booking__c>();

        for (Booking__c booking : newBookings) {
            Booking__c oldBooking = oldBookingsMap.get(booking.Id);
            if (booking.Booking_Status__c != oldBooking.Booking_Status__c) {
                changedBookings.add(booking);

                if (booking.Booking_Status__c == 'Approved') {
                    approvedBookings.add(booking);
                }
            }
        }

        if (!changedBookings.isEmpty()) {
            PropertyStatusService.applyStatusForUpdatedBookings(changedBookings);
        }

        if (!approvedBookings.isEmpty()) {
            PortalUserProvisioningService.createPortalUsersForApprovedBookings(approvedBookings);
        }
    }

    public static void setPortalContact(List<Booking__c> bookings) {
        Set<Id> oppIds = new Set<Id>();
        for (Booking__c b : bookings) {
            if (b.Opportunity__c != null) {
                oppIds.add(b.Opportunity__c);
            }
        }

        if (oppIds.isEmpty()) return;
        Map<Id, Id> oppToContactMap = new Map<Id, Id>();
        for (OpportunityContactRole ocr : [
            SELECT OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds AND IsPrimary = true
        ]) {
            oppToContactMap.put(ocr.OpportunityId, ocr.ContactId);
        }

        for (Booking__c b : bookings) {
            if (b.Opportunity__c != null && oppToContactMap.containsKey(b.Opportunity__c)) {
                b.Portal_Contact__c = oppToContactMap.get(b.Opportunity__c);
            }
        }
    }
}