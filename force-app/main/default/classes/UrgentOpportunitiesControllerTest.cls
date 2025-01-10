@isTest
private class UrgentOpportunitiesControllerTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity urgentOpp = new Opportunity(
            Name = 'Urgent Opportunity',
            StageName = 'Prospecting',
            Amount = 1000,
            CloseDate = Date.today(),
            Urgent__c = true,
            AccountId = testAccount.Id
        );
        insert urgentOpp;
    }

    // Test searchKey != null branch
    @isTest
    static void testFetchTotalRecordCount_WithSearchKey() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Integer result = UrgentOpportunitiesController.fetchTotalRecordCount('Urgent', acc.Id);
        Test.stopTest();

        System.assertEquals(1, result, 'One opportunity should match the searchKey.');
    }

    // Test searchKey != null branch
    @isTest
    static void testFetchUrgentOpportunities_WithSearchKey() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<Opportunity> result = UrgentOpportunitiesController.fetchUrgentOpportunities('Urgent', acc.Id, 0, 10);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One opportunity should match the searchKey.');
    }

    // Test fetchUrgentOpportunities exception handling
    @isTest
    static void testFetchUrgentOpportunities_Exception() {
        UrgentOpportunitiesController.forceFailure = true;
        Test.startTest();
        try {
            UrgentOpportunitiesController.fetchUrgentOpportunities(null, null, 0, 10);
            System.assert(false, 'Exception should have been thrown.');
        } catch (AuraHandledException e) {
            System.debug('Exception caught: ' + e.getMessage());
            System.assert(e.getMessage() != null, 'Exception message should not be null.');
            System.assert(e.getMessage().contains('fetching opportunities') || 
                          e.getMessage().contains('Script-thrown exception'),
                          'Error message should indicate the failure.');
        }
        Test.stopTest();
    }

    // Test fetchTotalRecordCount exception handling
    @isTest
    static void testFetchTotalRecordCount_Exception() {
        UrgentOpportunitiesController.forceFailure = true;
        Test.startTest();
        try {
            // Force failure
            UrgentOpportunitiesController.fetchTotalRecordCount(null, null);
            System.assert(false, 'Exception should have been thrown.');
        } catch (AuraHandledException e) {
            System.debug('Exception caught: ' + e.getMessage());
            System.assert(e.getMessage() != null, 'Exception message should not be null.');
            System.assert(e.getMessage().contains('fetching the total record count') || 
                          e.getMessage().contains('Script-thrown exception'),
                          'Error message should indicate the failure.');
        }
        Test.stopTest();
    }

    // Test saveNewOpportunity exception handling
    @isTest
    static void testSaveNewOpportunity_Exception() {
        UrgentOpportunitiesController.forceFailure = true;

        Opportunity invalidOpp = new Opportunity(Name = null, StageName = 'Prospecting', CloseDate = Date.today());
        Test.startTest();
        try {
            UrgentOpportunitiesController.saveNewOpportunity(invalidOpp);
            System.assert(false, 'Exception should have been thrown.');
        } catch (AuraHandledException e) {
            System.debug('Exception caught: ' + e.getMessage());
            System.assert(e.getMessage() != null, 'Exception message should not be null.');
            System.assert(e.getMessage().contains('saving the opportunity') || 
                          e.getMessage().contains('Script-thrown exception'),
                          'Error message should indicate the failure.');
        }
        Test.stopTest();
    }
}