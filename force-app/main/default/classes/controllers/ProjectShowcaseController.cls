public with sharing class ProjectShowcaseController {

    public class ProjectWrapper {
        @AuraEnabled public Id projectId;
        @AuraEnabled public String projectName;
        @AuraEnabled public String location;
        @AuraEnabled public String builderName;
        @AuraEnabled public String projectStatus;
        @AuraEnabled public Integer propertyCount;
        @AuraEnabled public Decimal minPrice;
        @AuraEnabled public Decimal maxPrice;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProjectWrapper> getFeaturedProjects() {

        List<Property_Project__c> projects = [
            SELECT Id, Name, Location__c, Builder_Name__c, Project_Status__c
            FROM Property_Project__c
            ORDER BY CreatedDate DESC
            LIMIT 6
        ];

        if (projects.isEmpty()) {
            return new List<ProjectWrapper>();
        }

        Set<Id> projectIds = new Set<Id>();
        for (Property_Project__c proj : projects) {
            projectIds.add(proj.Id);
        }

        Map<Id, Integer> countMap = new Map<Id, Integer>();
        Map<Id, Decimal> minPriceMap = new Map<Id, Decimal>();
        Map<Id, Decimal> maxPriceMap = new Map<Id, Decimal>();

        for (Property__c prop : [
            SELECT Id, Property_Project__c, Price__c
            FROM Property__c
            WHERE Property_Project__c IN :projectIds AND Status__c = 'Available'
        ]) {
            Id projId = prop.Property_Project__c;

            Integer currentCount = countMap.containsKey(projId) ? countMap.get(projId) : 0;
            countMap.put(projId, currentCount + 1);

            if (prop.Price__c != null) {
                if (!minPriceMap.containsKey(projId) || prop.Price__c < minPriceMap.get(projId)) {
                    minPriceMap.put(projId, prop.Price__c);
                }
                if (!maxPriceMap.containsKey(projId) || prop.Price__c > maxPriceMap.get(projId)) {
                    maxPriceMap.put(projId, prop.Price__c);
                }
            }
        }

        List<ProjectWrapper> result = new List<ProjectWrapper>();
        for (Property_Project__c proj : projects) {
            ProjectWrapper pw = new ProjectWrapper();
            pw.projectId = proj.Id;
            pw.projectName = proj.Name;
            pw.location = proj.Location__c;
            pw.builderName = proj.Builder_Name__c;
            pw.projectStatus = proj.Project_Status__c;
            pw.propertyCount = countMap.containsKey(proj.Id) ? countMap.get(proj.Id) : 0;
            pw.minPrice = minPriceMap.get(proj.Id);
            pw.maxPrice = maxPriceMap.get(proj.Id);
            result.add(pw);
        }

        return result;
    }
}