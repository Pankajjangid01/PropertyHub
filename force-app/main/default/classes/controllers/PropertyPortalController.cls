public without sharing class PropertyPortalController {

    public class PropertyWrapper {
        @AuraEnabled public Id propertyId;
        @AuraEnabled public String propertyName;
        @AuraEnabled public String propertyType;
        @AuraEnabled public Decimal areaSqft;
        @AuraEnabled public Decimal price;
        @AuraEnabled public String originalCurrency;
        @AuraEnabled public Decimal convertedPrice;
        @AuraEnabled public String displayCurrency;
        @AuraEnabled public String status;
        @AuraEnabled public String thumbnailUrl;
        @AuraEnabled public String projectName;
    }

    @AuraEnabled(cacheable=true)
    public static List<PropertyWrapper> getAvailableProperties(Id projectId, String preferredCurrency) {

        String query = 'SELECT Id, Name, Property_Type__c, Area_Sqft__c, Price__c, CurrencyIsoCode, Status__c, Property_Project__r.Name ' +
                        'FROM Property__c WHERE Status__c = \'Available\'';

        if (projectId != null) {
            query += ' AND Property_Project__c = :projectId';
        }

        query += ' ORDER BY CreatedDate DESC';

        List<Property__c> properties = Database.query(query);

        List<PropertyWrapper> result = new List<PropertyWrapper>();

        if (properties.isEmpty()) {
            return result;
        }

        Set<Id> propertyIds = new Set<Id>();
        for (Property__c p : properties) {
            propertyIds.add(p.Id);
        }

        Map<Id, String> propertyIdToThumbnailUrl = new Map<Id, String>();

        List<ContentDocumentLink> links = [
            SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId, ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :propertyIds
            AND ContentDocument.FileType IN ('PNG', 'JPG', 'JPEG')
            ORDER BY ContentDocument.CreatedDate DESC
        ];

        for (ContentDocumentLink cdl : links) {
            if (!propertyIdToThumbnailUrl.containsKey(cdl.LinkedEntityId)) {
                String fileUrl = '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId;
                propertyIdToThumbnailUrl.put(cdl.LinkedEntityId, fileUrl);
            }
        }

        String targetCurrency = String.isNotBlank(preferredCurrency) ? preferredCurrency : null;

        for (Property__c p : properties) {
            PropertyWrapper pw = new PropertyWrapper();
            pw.propertyId = p.Id;
            pw.propertyName = p.Name;
            pw.propertyType = p.Property_Type__c;
            pw.areaSqft = p.Area_Sqft__c;
            pw.price = p.Price__c;
            pw.originalCurrency = p.CurrencyIsoCode;
            pw.status = p.Status__c;
            pw.thumbnailUrl = propertyIdToThumbnailUrl.get(p.Id);
            pw.projectName = p.Property_Project__r?.Name;

            if (targetCurrency != null && targetCurrency != p.CurrencyIsoCode) {
                pw.convertedPrice = CurrencyConversionService.convertAmount(p.Price__c, p.CurrencyIsoCode, targetCurrency);
                pw.displayCurrency = targetCurrency;
            } else {
                pw.convertedPrice = p.Price__c;
                pw.displayCurrency = p.CurrencyIsoCode;
            }

            result.add(pw);
        }

        return result;
    }
public class PropertyDetailWrapper {
        @AuraEnabled public String propertyName;
        @AuraEnabled public String propertyType;
        @AuraEnabled public Decimal areaSqft;
        @AuraEnabled public Decimal price;
        @AuraEnabled public String originalCurrency;
        @AuraEnabled public Decimal convertedPrice;
        @AuraEnabled public String displayCurrency;
        @AuraEnabled public Decimal bedrooms;
        @AuraEnabled public String status;
        @AuraEnabled public String projectName;
        @AuraEnabled public List<String> imageUrls;
    }

    @AuraEnabled(cacheable=true)
    public static PropertyDetailWrapper getPropertyDetail(Id propertyId, String preferredCurrency) {

        Property__c prop = [
            SELECT Id, Name, Property_Type__c, Area_Sqft__c, Price__c, CurrencyIsoCode,
                   Bedrooms__c, Status__c, Property_Project__r.Name
            FROM Property__c
            WHERE Id = :propertyId
            LIMIT 1
        ];

        PropertyDetailWrapper detail = new PropertyDetailWrapper();
        detail.propertyName = prop.Name;
        detail.propertyType = prop.Property_Type__c;
        detail.areaSqft = prop.Area_Sqft__c;
        detail.price = prop.Price__c;
        detail.originalCurrency = prop.CurrencyIsoCode;
        detail.bedrooms = prop.Bedrooms__c;
        detail.status = prop.Status__c;
        detail.projectName = prop.Property_Project__r.Name;

        String targetCurrency = String.isNotBlank(preferredCurrency) ? preferredCurrency : null;

        if (targetCurrency != null && targetCurrency != prop.CurrencyIsoCode) {
            detail.convertedPrice = CurrencyConversionService.convertAmount(prop.Price__c, prop.CurrencyIsoCode, targetCurrency);
            detail.displayCurrency = targetCurrency;
        } else {
            detail.convertedPrice = prop.Price__c;
            detail.displayCurrency = prop.CurrencyIsoCode;
        }

        List<String> images = new List<String>();
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :propertyId
            AND ContentDocument.FileType IN ('PNG', 'JPG', 'JPEG')
            ORDER BY ContentDocument.CreatedDate DESC
            LIMIT 1
        ];

        for (ContentDocumentLink cdl : links) {
            String fileUrl = '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId;
            images.add(fileUrl);
        }
        detail.imageUrls = images;

        return detail;
    }

    @AuraEnabled
    public static void updateFileVisibility(List<Id> documentIds, Id recordId) {
        if (documentIds == null || documentIds.isEmpty() || recordId == null) {
            return;
        }

        List<ContentDocumentLink> existingLinks = [
            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId IN :documentIds 
            AND LinkedEntityId = :recordId
        ];

        if (existingLinks.isEmpty()) {
            return;
        }

        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        
        for (ContentDocumentLink oldCdl : existingLinks) {
            ContentDocumentLink newCdl = new ContentDocumentLink();
            newCdl.ContentDocumentId = oldCdl.ContentDocumentId;
            newCdl.LinkedEntityId = oldCdl.LinkedEntityId;
            newCdl.ShareType = oldCdl.ShareType != null ? oldCdl.ShareType : 'V';
            newCdl.Visibility = 'AllUsers';
            newLinks.add(newCdl);
        }

        delete existingLinks;
        insert newLinks;
    }
}