public with sharing class BookingPortalController {

    public class BookingWrapper {
        @AuraEnabled public Id bookingId;
        @AuraEnabled public String bookingName;
        @AuraEnabled public String propertyName;
        @AuraEnabled public String propertyType;
        @AuraEnabled public String bookingStatus;
        @AuraEnabled public String bookingDate;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public Decimal amountPaid;
        @AuraEnabled public Decimal balanceDue;
        @AuraEnabled public Decimal paidPercentage;
        @AuraEnabled public String thumbnailUrl;
    }

    @AuraEnabled(cacheable=true)
    public static List<BookingWrapper> getMyBookings() {

        Id currentContactId = [
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        List<BookingWrapper> result = new List<BookingWrapper>();

        if (currentContactId == null) {
            return result;
        }

        List<Booking__c> bookings = [
            SELECT Id, Name, Booking_Status__c, Booking_Date__c,
                   Property__c, Property__r.Name, Property__r.Property_Type__c,
                   Quotation__c, Quotation__r.Total_Amount__c
            FROM Booking__c
            WHERE Portal_Contact__c = :currentContactId
            ORDER BY CreatedDate DESC
        ];

        if (bookings.isEmpty()) {
            return result;
        }

        Set<Id> bookingIds = new Set<Id>();
        Set<Id> propertyIds = new Set<Id>();
        for (Booking__c b : bookings) {
            bookingIds.add(b.Id);
            if (b.Property__c != null) {
                propertyIds.add(b.Property__c);
            }
        }

        // Sum of Received payments per Booking
        Map<Id, Decimal> bookingIdToPaidAmount = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Booking__c bId, SUM(Amount__c) totalPaid
            FROM Payment__c
            WHERE Booking__c IN :bookingIds AND Payment_Status__c = 'Received'
            GROUP BY Booking__c
        ]) {
            bookingIdToPaidAmount.put((Id) ar.get('bId'), (Decimal) ar.get('totalPaid'));
        }

        // First uploaded image per Property (thumbnail), same pattern as Property Catalog
        Map<Id, String> propertyIdToThumbnailUrl = new Map<Id, String>();
        if (!propertyIds.isEmpty()) {
            List<ContentDocumentLink> links = [
                SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :propertyIds
            ];
            for (ContentDocumentLink cdl : links) {
                Boolean alreadyHasThumbnail = propertyIdToThumbnailUrl.containsKey(cdl.LinkedEntityId);
                if (alreadyHasThumbnail == false) {
                    String fileUrl = '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId;
                    propertyIdToThumbnailUrl.put(cdl.LinkedEntityId, fileUrl);
                }
            }
        }

        for (Booking__c b : bookings) {
            BookingWrapper bw = new BookingWrapper();
            bw.bookingId = b.Id;
            bw.bookingName = b.Name;
            bw.propertyName = b.Property__r != null ? b.Property__r.Name : null;
            bw.propertyType = b.Property__r != null ? b.Property__r.Property_Type__c : null;
            bw.bookingStatus = b.Booking_Status__c;
            bw.bookingDate = b.Booking_Date__c != null ? b.Booking_Date__c.format() : null;

            Decimal total = (b.Quotation__c != null && b.Quotation__r.Total_Amount__c != null)
                ? b.Quotation__r.Total_Amount__c
                : 0;
            Decimal paid = bookingIdToPaidAmount.containsKey(b.Id) ? bookingIdToPaidAmount.get(b.Id) : 0;
            Decimal balance = total - paid;

            bw.totalAmount = total;
            bw.amountPaid = paid;
            bw.balanceDue = balance;
            bw.paidPercentage = (total > 0) ? ((paid / total) * 100).setScale(0) : 0;

            bw.thumbnailUrl = propertyIdToThumbnailUrl.get(b.Property__c);

            result.add(bw);
        }

        return result;
    }
}