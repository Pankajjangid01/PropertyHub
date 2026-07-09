public with sharing class PaymentEmailService {

    public static void sendPaymentSuccessEmail(List<Payment__c> payments) {

        Set<Id> paymentIds = new Set<Id>();
        for (Payment__c p : payments) {
            paymentIds.add(p.Id);
        }

        List<Payment__c> paymentDetails = [
            SELECT Id, Amount__c, Booking__r.Name,
                   Portal_Contact__r.Email, Portal_Contact__r.Name
            FROM Payment__c
            WHERE Id IN :paymentIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Payment__c p : paymentDetails) {
            if (p.Portal_Contact__r == null || String.isBlank(p.Portal_Contact__r.Email)) {
                continue;
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ p.Portal_Contact__r.Email });
            email.setSubject('Payment Received - ' + p.Booking__r.Name);
            email.setPlainTextBody(
                'Dear ' + p.Portal_Contact__r.Name + ',\n\n' +
                'We have successfully received your payment of Rs. ' + p.Amount__c +
                ' for booking ' + p.Booking__r.Name + '.\n\n' +
                'Thank you for your payment. You can view your payment history anytime on the PropertyHub portal.\n\n' +
                'Regards,\nPropertyHub Team'
            );
            email.setSaveAsActivity(false);
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Payment success email failed: ' + e.getMessage());
            }
        }
    }
}