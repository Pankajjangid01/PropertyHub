public without sharing class PropertyStatusService {

    public static void applyStatusForNewBookings(List<Booking__c> bookings) {
        Map<Id, String> propertyIdToNewStatus = new Map<Id, String>();
        for (Booking__c booking : bookings) {
            if (booking.Property__c != null) {
                propertyIdToNewStatus.put(booking.Property__c, 'On Hold');
            }
        }
        updateProperties(propertyIdToNewStatus);
        notifyCustomers(bookings, propertyIdToNewStatus);
    }

    public static void applyStatusForUpdatedBookings(List<Booking__c> bookings) {
        Map<Id, String> propertyIdToNewStatus = new Map<Id, String>();

        for (Booking__c booking : bookings) {
            if (booking.Property__c == null) {
                continue;
            }
            String newPropertyStatus = mapBookingStatusToPropertyStatus(booking.Booking_Status__c);
            if (newPropertyStatus != null) {
                propertyIdToNewStatus.put(booking.Property__c, newPropertyStatus);
            }
        }

        updateProperties(propertyIdToNewStatus);
        notifyCustomers(bookings, propertyIdToNewStatus);
    }

    public static void checkPropertyAvailability(List<Booking__c> bookings) {
        Set<Id> propertyIds = new Set<Id>();
        Set<Id> quotationIds = new Set<Id>();

        for (Booking__c booking : bookings) {
            if (booking.Property__c != null) {
                propertyIds.add(booking.Property__c);
            }
            if (booking.Quotation__c != null) {
                quotationIds.add(booking.Quotation__c);
            }
        }

        // ---- Property availability check ----
        Map<Id, String> propertyStatusMap = new Map<Id, String>();
        if (!propertyIds.isEmpty()) {
            for (Property__c property : [SELECT Id, Status__c FROM Property__c WHERE Id IN :propertyIds FOR UPDATE]) {
                propertyStatusMap.put(property.Id, property.Status__c);
            }
        }

        // ---- Quotation status + Opportunity check  ----
        Map<Id, Quotation__c> quotationMap = new Map<Id, Quotation__c>();
        if (!quotationIds.isEmpty()) {
            quotationMap = new Map<Id, Quotation__c>(
                [SELECT Id, Quotation_Status__c, Opportunity__c FROM Quotation__c WHERE Id IN :quotationIds]
            );
        }

        // ---- Validate each booking ----
        for (Booking__c booking : bookings) {

            // Property must exist and be Available
            if (booking.Property__c != null && propertyStatusMap.containsKey(booking.Property__c)) {
                String propStatus = propertyStatusMap.get(booking.Property__c);
                if (propStatus != 'Available') {
                    booking.addError('The selected property is not available for booking.');
                    continue;
                }
            }

            // Quotation must be linked and Accepted
            if (booking.Quotation__c == null) {
                booking.addError('A Booking cannot be created without a linked Quotation.');
                continue;
            }

            Quotation__c quotation = quotationMap.get(booking.Quotation__c);
            if (quotation == null) {
                booking.addError('The linked Quotation could not be found.');
                continue;
            }

            if (quotation.Quotation_Status__c != 'Accepted') {
                booking.addError('The linked Quotation must be Accepted before a Booking can be created.');
                continue;
            }

            // Opportunity on Booking must match Opportunity on the linked Quotation
            if (booking.Opportunity__c != null && quotation.Opportunity__c != null
                && booking.Opportunity__c != quotation.Opportunity__c) {
                booking.addError('The Opportunity on this Booking does not match the Opportunity on the linked Quotation.');
            }
        }
    }

    // Called from PaymentTrigger — checks if total received payments now cover the quotation amount
    public static void evaluateFullPayment(List<Payment__c> receivedPayments) {
        Set<Id> bookingIds = new Set<Id>();
        for (Payment__c pay : receivedPayments) {
            bookingIds.add(pay.Booking__c);
        }

        // Pull Booking -> Property + Quotation Total_Amount__c
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>(
            [SELECT Id, Property__c, Quotation__c, Quotation__r.Total_Amount__c
             FROM Booking__c
             WHERE Id IN :bookingIds]
        );

        if (bookingMap.isEmpty()) {
            return;
        }

        // Sum of ALL Received payments per Booking (not just the ones just inserted/updated)
        Map<Id, Decimal> bookingIdToReceivedSum = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Booking__c bId, SUM(Amount__c) totalReceived
            FROM Payment__c
            WHERE Booking__c IN :bookingIds AND Payment_Status__c = 'Received'
            GROUP BY Booking__c
        ]) {
            bookingIdToReceivedSum.put((Id) ar.get('bId'), (Decimal) ar.get('totalReceived'));
        }

        // Determine which Bookings have now reached full payment
        Map<Id, String> propertyIdToNewStatus = new Map<Id, String>();
        List<Booking__c> fullyPaidBookings = new List<Booking__c>();

        for (Id bookingId : bookingMap.keySet()) {
            Booking__c booking = bookingMap.get(bookingId);

            if (booking.Property__c == null || booking.Quotation__c == null) {
                continue;
            }

            Decimal totalDue = booking.Quotation__r.Total_Amount__c;
            Decimal totalReceived = bookingIdToReceivedSum.containsKey(bookingId)
                ? bookingIdToReceivedSum.get(bookingId)
                : 0;

            if (totalDue != null && totalReceived >= totalDue) {
                propertyIdToNewStatus.put(booking.Property__c, 'Sold');
                fullyPaidBookings.add(booking);
            }
        }

        if (propertyIdToNewStatus.isEmpty()) {
            return;
        }

        // Reuse existing shared logic — no duplication
        updateProperties(propertyIdToNewStatus);
        notifyCustomersForFullPayment(fullyPaidBookings, propertyIdToNewStatus);
    }

    private static void notifyCustomersForFullPayment(List<Booking__c> fullyPaidBookings, Map<Id, String> propertyIdToNewStatus) {
        Set<Id> bookingIds = new Set<Id>();
        for (Booking__c b : fullyPaidBookings) {
            bookingIds.add(b.Id);
        }

        List<Booking__c> bookingsWithOpp = [
            SELECT Id, Property__c, Opportunity__c
            FROM Booking__c
            WHERE Id IN :bookingIds
        ];

        notifyCustomers(bookingsWithOpp, propertyIdToNewStatus);
    }

    private static String mapBookingStatusToPropertyStatus(String bookingStatus) {
        if (bookingStatus == 'Approved') {
            return 'Reserved';
        } else if (bookingStatus == 'Rejected' || bookingStatus == 'Cancelled') {
            return 'Available';
        }
        return null; // 'Sold' will still be set later by Payment logic (full payment received)
    }

    private static void updateProperties(Map<Id, String> propertyIdToNewStatus) {
        if (propertyIdToNewStatus.isEmpty()) {
            return;
        }

        List<Property__c> propertiesToUpdate = new List<Property__c>();
        for (Id propId : propertyIdToNewStatus.keySet()) {
            propertiesToUpdate.add(new Property__c(
                Id = propId,
                Status__c = propertyIdToNewStatus.get(propId)
            ));
        }

        update propertiesToUpdate;
    }

    private static void notifyCustomers(List<Booking__c> bookings, Map<Id, String> propertyIdToNewStatus) {
        Map<Id, String> propertyIdToEmailStatus = new Map<Id, String>();
        for (Id propId : propertyIdToNewStatus.keySet()) {
            String status = propertyIdToNewStatus.get(propId);
            if (status == 'Reserved' || status == 'Sold') {
                propertyIdToEmailStatus.put(propId, status);
            }
        }

        if (propertyIdToEmailStatus.isEmpty()) {
            return;
        }

        Map<Id, Id> propertyIdToOpportunityId = new Map<Id, Id>();
        for (Booking__c booking : bookings) {
            if (propertyIdToEmailStatus.containsKey(booking.Property__c) && booking.Opportunity__c != null) {
                propertyIdToOpportunityId.put(booking.Property__c, booking.Opportunity__c);
            }
        }

        if (propertyIdToOpportunityId.isEmpty()) {
            return;
        }

        Map<Id, Id> opportunityIdToContactId = new Map<Id, Id>();
        for (OpportunityContactRole ocr : [
            SELECT OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :propertyIdToOpportunityId.values() AND IsPrimary = true
        ]) {
            opportunityIdToContactId.put(ocr.OpportunityId, ocr.ContactId);
        }

        Set<Id> contactIds = new Set<Id>(opportunityIdToContactId.values());
        Map<Id, Contact> contactMap = new Map<Id, Contact>(
            [SELECT Id, FirstName, Email FROM Contact WHERE Id IN :contactIds AND Email != null]
        );

        Map<Id, Property__c> propertyMap = new Map<Id, Property__c>(
            [SELECT Id, Name FROM Property__c WHERE Id IN :propertyIdToEmailStatus.keySet()]
        );

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Id propId : propertyIdToEmailStatus.keySet()) {
            Id oppId = propertyIdToOpportunityId.get(propId);
            Id contactId = (oppId != null) ? opportunityIdToContactId.get(oppId) : null;
            Contact con = (contactId != null) ? contactMap.get(contactId) : null;

            if (con == null || String.isBlank(con.Email)) {
                continue;
            }

            String status = propertyIdToEmailStatus.get(propId);
            String propertyName = propertyMap.containsKey(propId) ? propertyMap.get(propId).Name : '';
            String firstName = String.isNotBlank(con.FirstName) ? con.FirstName : 'Customer';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ con.Email });
            email.setSaveAsActivity(false);

            if (status == 'Reserved') {
                email.setSubject('Your Property Booking is Confirmed - ' + propertyName);
                email.setHtmlBody(buildReservedEmailBody(propertyName, firstName));
            } else if (status == 'Sold') {
                email.setSubject('Congratulations! Your Property Purchase is Confirmed - ' + propertyName);
                email.setHtmlBody(buildSoldEmailBody(propertyName, firstName));
            }

            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    private static String buildReservedEmailBody(String propertyName, String contactFirstName) {
        return '<p>Dear ' + contactFirstName + ',</p>'
             + '<p>Thank you for choosing us.</p>'
             + '<p>We have successfully received your booking request for the following property:</p>'
             + '<p><b>Property:</b> ' + propertyName + '<br/>'
             + '<b>Current Status:</b> Pending Approval</p>'
             + '<p>Your booking is currently under review by our sales team. We will notify you once it is confirmed.</p>'
             + '<p>Thank you for your patience.</p>';
    }

    private static String buildSoldEmailBody(String propertyName, String contactFirstName) {
        return '<p>Dear ' + contactFirstName + ',</p>'
             + '<p><b>Congratulations!</b> Your property purchase has been confirmed.</p>'
             + '<p><b>Property:</b> ' + propertyName + '<br/>'
             + '<b>Status:</b> Sold</p>'
             + '<p>Our Accounts team will reach out shortly with the payment schedule and next steps for the agreement.</p>'
             + '<p>Thank you for choosing us.</p>';
    }
}