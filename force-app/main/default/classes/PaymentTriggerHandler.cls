public with sharing class PaymentTriggerHandler {

    public static void handleAfterInsert(List<Payment__c> newPayments) {
        List<Payment__c> receivedPayments = filterReceived(newPayments, null);
        if (!receivedPayments.isEmpty()) {
            PropertyStatusService.evaluateFullPayment(receivedPayments);
        }
    }

    public static void handleAfterUpdate(List<Payment__c> newPayments, Map<Id, Payment__c> oldPaymentsMap) {
        List<Payment__c> receivedPayments = filterReceived(newPayments, oldPaymentsMap);
        List<Payment__c> paidPayments = new List<Payment__c>();
        
        for (Payment__c p : newPayments) {
            Payment__c oldP = oldPaymentsMap.get(p.Id);
            if (p.Payment_Status__c == 'Received' && oldP.Payment_Status__c != 'Received') {
                paidPayments.add(p);
            }
        }
        if (!receivedPayments.isEmpty()) {
            PropertyStatusService.evaluateFullPayment(receivedPayments);
        }

        if (!paidPayments.isEmpty()) {
            PaymentEmailService.sendPaymentSuccessEmail(paidPayments);
        }
    }

    private static List<Payment__c> filterReceived(List<Payment__c> payments, Map<Id, Payment__c> oldPaymentsMap) {
        List<Payment__c> result = new List<Payment__c>();
        for (Payment__c pay : payments) {
            if (pay.Payment_Status__c != 'Received' || pay.Booking__c == null) {
                continue;
            }
            if (oldPaymentsMap != null) {
                Payment__c oldPay = oldPaymentsMap.get(pay.Id);
                if (oldPay.Payment_Status__c == 'Received') {
                    continue;
                }
            }
            result.add(pay);
        }
        return result;
    }

    public static void setPortalContact(List<Payment__c> payments) {
        Set<Id> bookingIds = new Set<Id>();
        for (Payment__c p : payments) {
            if (p.Booking__c != null) {
                bookingIds.add(p.Booking__c);
            }
        }

        if (bookingIds.isEmpty()) return;

        Map<Id, Id> bookingToContactMap = new Map<Id, Id>();
        for (Booking__c b : [
            SELECT Id, Portal_Contact__c
            FROM Booking__c
            WHERE Id IN :bookingIds
        ]) {
            bookingToContactMap.put(b.Id, b.Portal_Contact__c);
        }

        for (Payment__c p : payments) {
            if (p.Booking__c != null && bookingToContactMap.containsKey(p.Booking__c)) {
                p.Portal_Contact__c = bookingToContactMap.get(p.Booking__c);
            }
        }
    }
}