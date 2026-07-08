public with sharing class SiteVisitEmailService {

    public static void sendVisitScheduledEmail(List<Site_Visit__c> visits) {

        Set<Id> visitIds = new Set<Id>();
        for (Site_Visit__c v : visits) {
            visitIds.add(v.Id);
        }

        List<Site_Visit__c> visitDetails = [
            SELECT Id, Visit_Date__c, Property__r.Name,
                   Portal_Contact__r.Email, Portal_Contact__r.Name
            FROM Site_Visit__c
            WHERE Id IN :visitIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Site_Visit__c v : visitDetails) {
            if (v.Portal_Contact__r == null || String.isBlank(v.Portal_Contact__r.Email)) {
                continue; // no valid recipient, skip silently
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ v.Portal_Contact__r.Email });
            email.setSubject('Your Site Visit is Scheduled - ' + v.Property__r.Name);
            email.setPlainTextBody(
                'Dear ' + v.Portal_Contact__r.Name + ',\n\n' +
                'Your site visit for ' + v.Property__r.Name + ' has been scheduled on ' +
                v.Visit_Date__c.format() + '.\n\n' +
                'Our team will meet you at the property. If you need to reschedule, please contact us.\n\n' +
                'Regards,\nPropertyHub Team'
            );
            email.setSaveAsActivity(false);
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Site visit scheduled email failed: ' + e.getMessage());
            }
        }
    }
}