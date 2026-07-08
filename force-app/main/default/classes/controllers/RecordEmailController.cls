public with sharing class RecordEmailController {

    @AuraEnabled
    public static void sendRecordEmail(Id recordId, String objectType) {
        if (objectType == 'Quotation__c') {
            sendQuotationEmail(recordId);
        } else if (objectType == 'Agreement__c') {
            sendAgreementEmail(recordId);
        } else {
            throw new AuraHandledException('Unsupported object type: ' + objectType);
        }
    }

    private static void sendQuotationEmail(Id quotationId) {
        List<Quotation__c> quotationList = [
            SELECT Id, Name, PDF_Generated__c, OwnerId, Opportunity__c,
                Opportunity__r.Portal_Contact__r.Email,
                Opportunity__r.Portal_Contact__r.Name
            FROM Quotation__c
            WHERE Id = :quotationId
            LIMIT 1
        ];

        if (quotationList.isEmpty()) {
            throw new AuraHandledException('Quotation not found.');
        }

        Quotation__c quotation = quotationList[0];

        if (quotation.PDF_Generated__c != true) {
            throw new AuraHandledException('Please generate the PDF before sending the email.');
        }

        if (quotation.Opportunity__r == null ||
            quotation.Opportunity__r.Portal_Contact__r == null ||
            String.isBlank(quotation.Opportunity__r.Portal_Contact__r.Email)) {
            throw new AuraHandledException('No valid customer email found for this quotation.');
        }

        String recipientEmail = quotation.Opportunity__r.Portal_Contact__r.Email;
        String recipientName = quotation.Opportunity__r.Portal_Contact__r.Name;

        sendEmailWithLatestFile(
            quotationId,
            recipientEmail,
            recipientName,
            'Your Property Quotation - ' + quotation.Name,
            'your property quotation (' + quotation.Name + ')'
        );

        update new Quotation__c(Id = quotationId, Quotation_Status__c = 'Sent');
        notifySalesRep(quotation.OwnerId, 'Quotation Emailed to Customer', 'Quotation ' + quotation.Name + ' has been emailed to ' + recipientEmail + '.');

        // NEW — advance Opportunity stage
        OpportunityStageService.advanceStage(quotation.Opportunity__c, 'Quotation Sent');
    }

    private static void sendAgreementEmail(Id agreementId) {
        List<Agreement__c> agreementList = [
            SELECT Id, Name, PDF_Generated__c, OwnerId,
                   Booking__r.Portal_Contact__r.Email,
                   Booking__r.Portal_Contact__r.Name
            FROM Agreement__c
            WHERE Id = :agreementId
            LIMIT 1
        ];

        if (agreementList.isEmpty()) {
            throw new AuraHandledException('Agreement not found.');
        }

        Agreement__c agreement = agreementList[0];

        if (agreement.PDF_Generated__c != true) {
            throw new AuraHandledException('Please generate the PDF before sending the email.');
        }

        if (agreement.Booking__r == null ||
            agreement.Booking__r.Portal_Contact__r == null ||
            String.isBlank(agreement.Booking__r.Portal_Contact__r.Email)) {
            throw new AuraHandledException('No valid customer email found for this agreement.');
        }

        String recipientEmail = agreement.Booking__r.Portal_Contact__r.Email;
        String recipientName = agreement.Booking__r.Portal_Contact__r.Name;

        sendEmailWithLatestFile(
            agreementId,
            recipientEmail,
            recipientName,
            'Your Property Agreement - ' + agreement.Name,
            'your property agreement (' + agreement.Name + ')'
        );

        notifySalesRep(agreement.OwnerId, 'Agreement Emailed to Customer', 'Agreement ' + agreement.Name + ' has been emailed to ' + recipientEmail + '.');
    }

    private static void sendEmailWithLatestFile(Id recordId, String recipientEmail, String recipientName, String subject, String bodyDescription) {

        List<ContentDocumentLink> links = [
            SELECT ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY ContentDocument.CreatedDate DESC
            LIMIT 1
        ];

        if (links.isEmpty()) {
            throw new AuraHandledException('No PDF file found attached to this record.');
        }

        ContentVersion cv = [
            SELECT VersionData, PathOnClient
            FROM ContentVersion
            WHERE Id = :links[0].ContentDocument.LatestPublishedVersionId
            LIMIT 1
        ];

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(cv.PathOnClient);
        attachment.setBody(cv.VersionData);
        attachment.setContentType('application/pdf');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ recipientEmail });
        email.setSubject(subject);
        email.setPlainTextBody(
            'Dear ' + recipientName + ',\n\n' +
            'Please find attached ' + bodyDescription + ' from CodeTrade.io PropertyHub.\n\n' +
            'If you have any questions, feel free to reach out to our team.\n\n' +
            'Regards,\nPropertyHub Team'
        );
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        email.setSaveAsActivity(false);

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            throw new AuraHandledException('Failed to send email: ' + e.getMessage());
        }
    }

    private static void notifySalesRep(Id ownerId, String title, String body) {
        try {
            CustomNotificationType notifType = [
                SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Quotation_Email_Sent' LIMIT 1
            ];

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(notifType.Id);
            notification.setTargetId(ownerId);

            notification.send(new Set<String>{ ownerId });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Notification failed: ' + e.getMessage());
        }
    }
}