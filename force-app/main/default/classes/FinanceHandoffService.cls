public with sharing class FinanceHandoffService {

    public static void createFinanceTask(List<Booking__c> approvedBookings) {

        Group financeQueue = [
            SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Finance_Queue' LIMIT 1
        ];

        if (financeQueue == null) {
            return; // queue not configured — skip silently, avoid breaking booking approval
        }

        List<Task> tasksToInsert = new List<Task>();

        for (Booking__c booking : approvedBookings) {
            Task t = new Task();
            t.Subject = 'Create Agreement & Payment for Booking ' + booking.Name;
            t.WhatId = booking.Id;
            t.OwnerId = financeQueue.Id;
            t.Status = 'Not Started';
            t.Priority = 'High';
            t.ActivityDate = Date.today().addDays(2);
            tasksToInsert.add(t);
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}