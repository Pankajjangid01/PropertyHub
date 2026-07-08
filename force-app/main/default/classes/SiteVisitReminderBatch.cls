public with sharing class SiteVisitReminderBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date tomorrow = Date.today().addDays(1);

        return Database.getQueryLocator([
            SELECT Id, Visit_Date__c, Property__r.Name,
                   Portal_Contact__r.Email, Portal_Contact__r.Name,
                   Visit_Status__c, Reminder_Sent__c
            FROM Site_Visit__c
            WHERE DAY_ONLY(Visit_Date__c) = :tomorrow
            AND Visit_Status__c NOT IN ('Cancelled', 'Completed')
            AND Reminder_Sent__c = false
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Site_Visit__c> scope) {

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Site_Visit__c> toMarkSent = new List<Site_Visit__c>();

        for (Site_Visit__c v : scope) {
            if (v.Portal_Contact__r == null || String.isBlank(v.Portal_Contact__r.Email)) {
                continue;
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ v.Portal_Contact__r.Email });
            email.setSubject('Reminder: Site Visit Tomorrow - ' + v.Property__r.Name);
            email.setPlainTextBody(
                'Dear ' + v.Portal_Contact__r.Name + ',\n\n' +
                'This is a reminder that your site visit for ' + v.Property__r.Name +
                ' is scheduled tomorrow, ' + v.Visit_Date__c.format() + '.\n\n' +
                'We look forward to seeing you there.\n\n' +
                'Regards,\nPropertyHub Team'
            );
            email.setSaveAsActivity(false);
            emails.add(email);

            toMarkSent.add(new Site_Visit__c(Id = v.Id, Reminder_Sent__c = true));
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                update toMarkSent;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Site visit reminder email failed: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SiteVisitReminderBatch());
    }
}