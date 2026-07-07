public without sharing class PortalUserProvisioningService {

    private static final String PORTAL_PROFILE_NAME = 'PropertyHub Customer Portal User';

    public static void createPortalUsersForApprovedBookings(List<Booking__c> approvedBookings) {

        Set<Id> contactIds = new Set<Id>();
        for (Booking__c booking : approvedBookings) {
            if (booking.Portal_Contact__c != null) {
                contactIds.add(booking.Portal_Contact__c);
            }
        }

        if (contactIds.isEmpty()) {
            return;
        }

        // Find which of these Contacts already have a Portal User (avoid duplicates)
        Set<Id> contactsWithExistingUser = new Set<Id>();
        for (User u : [SELECT ContactId FROM User WHERE ContactId IN :contactIds]) {
            contactsWithExistingUser.add(u.ContactId);
        }

        Set<Id> contactsNeedingUser = new Set<Id>();
        for (Id contactId : contactIds) {
            if (!contactsWithExistingUser.contains(contactId)) {
                contactsNeedingUser.add(contactId);
            }
        }

        if (contactsNeedingUser.isEmpty()) {
            return; // everyone already has portal access
        }

        Id portalProfileId = getPortalProfileId();
        if (portalProfileId == null) {
            return; // profile not found — safety guard, avoid crashing the booking approval
        }

        Map<Id, Contact> contactsToProvision = new Map<Id, Contact>(
            [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id IN :contactsNeedingUser AND Email != null]
        );

        List<User> usersToInsert = new List<User>();

        for (Contact con : contactsToProvision.values()) {
            User newUser = new User();
            newUser.ContactId = con.Id;
            newUser.ProfileId = portalProfileId;
            newUser.FirstName = con.FirstName;
            newUser.LastName = con.LastName;
            newUser.Email = con.Email;
            newUser.Username = con.Email + '.propertyhub';
            newUser.Alias = generateAlias(con.FirstName, con.LastName);
            newUser.CommunityNickname = con.Id; // guarantees uniqueness
            newUser.TimeZoneSidKey = 'Asia/Kolkata';
            newUser.LocaleSidKey = 'en_IN';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.LanguageLocaleKey = 'en_US';
            newUser.IsActive = true;

            usersToInsert.add(newUser);
        }

        if (!usersToInsert.isEmpty()) {
            insert usersToInsert; // triggers Salesforce's built-in "set your password" welcome email automatically
        }
    }

    private static Id getPortalProfileId() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :PORTAL_PROFILE_NAME LIMIT 1];
        return profiles.isEmpty() ? null : profiles[0].Id;
    }

    private static String generateAlias(String firstName, String lastName) {
        String rawAlias = (firstName != null ? firstName : '') + (lastName != null ? lastName : '');
        return rawAlias.length() > 8 ? rawAlias.substring(0, 8) : rawAlias;
    }
}