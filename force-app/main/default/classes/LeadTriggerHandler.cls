public with sharing class LeadTriggerHandler {
    public static void handleBeforeInsert(List<Lead> newLeads) {
        RoundRobinAssignmentService.assignAgentsRoundRobin(newLeads);
    }
}