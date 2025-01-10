public with sharing class UrgentOpportunitiesController {

    @AuraEnabled(cacheable=true)
    public static OpportunityResponse fetchUrgentOpportunities(String searchKey, Id accountId, Integer offset, Integer limitValue) {
        try {
            String searchFilter = (searchKey == null) ? '%' : '%' + searchKey + '%';
            List<Opportunity> opportunities = [
                SELECT Id, Name, StageName, Amount, CloseDate
                FROM Opportunity
                WHERE Urgent__c = true
                AND AccountId = :accountId
                AND Name LIKE :searchFilter
                ORDER BY CloseDate DESC
                LIMIT :limitValue OFFSET :offset
            ];

            Integer totalRecords = [
                SELECT COUNT()
                FROM Opportunity
                WHERE Urgent__c = true
                AND AccountId = :accountId
                AND Name LIKE :searchFilter
            ];

            return new OpportunityResponse(opportunities, totalRecords);

        } catch (Exception e) {
            ErrorHandler.logError(e, 'UrgentOpportunitiesController', 'fetchUrgentOpportunities', 'ERROR');
            throw new AuraHandledException('An error occurred while fetching opportunities.');
        }
    }

    @AuraEnabled
    public static Boolean saveNewOpportunity(Opportunity opportunity) {
        Boolean isSuccess = true;
        try {
            insert opportunity;
        } catch (Exception e) {
            System.debug('Exception caught in saveNewOpportunity: ' + e.getMessage());
            ErrorHandler.logError(e, 'UrgentOpportunitiesController', 'saveNewOpportunity', 'ERROR');
            isSuccess = false;
        }
        return isSuccess;
    }
}