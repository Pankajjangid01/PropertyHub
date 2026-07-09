public without sharing class PortalAuthController {
    @AuraEnabled
    public static String loginUser(String username, String password, String startUrl) {
        try {
            // Site.login throws exception on invalid creds or returns null
            PageReference pageRef = Site.login(username, password, startUrl);
            if (pageRef != null) {
                return pageRef.getUrl();
            }
            throw new CalloutException('Your login attempt failed. Please check your credentials.');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
