public with sharing class QuotationExpiryBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Expiry_Date__c, Quotation_Status__c
            FROM Quotation__c
            WHERE Expiry_Date__c < TODAY
            AND Quotation_Status__c = 'Sent'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Quotation__c> scope) {
        List<Quotation__c> toUpdate = new List<Quotation__c>();
        for (Quotation__c q : scope) {
            toUpdate.add(new Quotation__c(Id = q.Id, Quotation_Status__c = 'Expired'));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new QuotationExpiryBatch());
    }
}