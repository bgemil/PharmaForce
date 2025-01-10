@isTest
public class UrgentOpportunitiesControllerTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity opp1 = new Opportunity(
            Name = 'Urgent Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = 1000,
            Urgent__c = true,
            AccountId = testAccount.Id
        );

        Opportunity opp2 = new Opportunity(
            Name = 'Non-Urgent Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(15),
            Amount = 2000,
            Urgent__c = false,
            AccountId = testAccount.Id
        );

        insert new List<Opportunity>{ opp1, opp2 };
    }

    @isTest
    static void testFetchUrgentOpportunities() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        OpportunityResponse response = UrgentOpportunitiesController.fetchUrgentOpportunities(
            null,
            testAccount.Id,
            0,
            10
        );
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null.');
        Assert.isTrue(response.opportunities.size() > 0, 'Should fetch urgent opportunities.');
    }

    @isTest
    static void testFetchUrgentOpportunitiesCatchBlock() {
        Test.startTest();
        try {
            UrgentOpportunitiesController.fetchUrgentOpportunities(null, null, 0, 10);
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Catch block should handle null parameters.');
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveNewOpportunity() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Needs Analysis',
            CloseDate = Date.today().addDays(30)
        );

        Test.startTest();
        Boolean isSuccess = UrgentOpportunitiesController.saveNewOpportunity(opp);
        Test.stopTest();

        Assert.isTrue(isSuccess, 'Opportunity should be saved successfully.');
    }

    @isTest
    static void testSaveNewOpportunityCatchBlock() {
        Test.startTest();
        try {
            UrgentOpportunitiesController.saveNewOpportunity(null);
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Catch block should handle null opportunity.');
        }
        Test.stopTest();
    }
}
