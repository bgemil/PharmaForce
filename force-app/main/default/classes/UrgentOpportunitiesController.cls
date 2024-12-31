public with sharing class UrgentOpportunitiesController {
    // Static flag to simulate exceptions during tests
    @TestVisible private static Boolean forceFailure = false;

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> fetchUrgentOpportunities(String searchKey, Id accountId, Integer offset, Integer limitValue) {
        try {
            if (forceFailure) { // Simulate exception during tests
                throw new QueryException('Simulated query failure');
            }

            String searchFilter = (searchKey == null) ? '%' : '%' + searchKey + '%';
            return [
                SELECT Id, Name, StageName, Amount, CloseDate
                FROM Opportunity
                WHERE Urgent__c = true
                AND AccountId = :accountId
                AND Name LIKE :searchFilter
                ORDER BY CloseDate DESC
                LIMIT :limitValue OFFSET :offset
            ];
        } catch (Exception e) {
            ErrorHandler.logError(e, 'UrgentOpportunitiesController', 'fetchUrgentOpportunities', 'ERROR');
            throw new AuraHandledException('An error occurred while fetching opportunities.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer fetchTotalRecordCount(String searchKey, Id accountId) {
        try {
            if (forceFailure) { // Simulate exception during tests
                throw new QueryException('Simulated query failure');
            }

            String searchFilter = (searchKey == null) ? '%' : '%' + searchKey + '%';
            return [
                SELECT COUNT()
                FROM Opportunity
                WHERE Urgent__c = TRUE
                AND AccountId = :accountId
                AND Name LIKE :searchFilter
            ];
        } catch (Exception e) {
            ErrorHandler.logError(e, 'UrgentOpportunitiesController', 'fetchTotalRecordCount', 'ERROR');
            throw new AuraHandledException('An error occurred while fetching the total record count.');
        }
    }

    @AuraEnabled
    public static void saveNewOpportunity(Opportunity opportunity) {
        try {
            if (forceFailure && Test.isRunningTest()) { // Simulate exception during tests
                Database.insert(opportunity, false);
                throw new DmlException('Simulated DML failure');
            }

            insert opportunity;
        } catch (Exception e) {
            System.debug('Exception caught in saveNewOpportunity: ' + e.getMessage());
            ErrorHandler.logError(e, 'UrgentOpportunitiesController', 'saveNewOpportunity', 'ERROR');
            throw new AuraHandledException('An error occurred while saving the opportunity. Please try again later.');
        }
    }
}