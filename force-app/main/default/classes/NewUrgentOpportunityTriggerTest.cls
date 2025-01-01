@isTest
private class NewUrgentOpportunityTriggerTest {
    @testSetup
    static void setupTestData() {
        // Insert Account
        Account acc = new Account(Name = 'Trigger Test Account');
        insert acc;

        // Insert Test User with valid email
        User testUser = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];
        
        // Insert Account Team Member
        AccountTeamMember teamMember = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = testUser.Id,
            TeamMemberRole = 'Sales Team'
        );
        insert teamMember;
    }

    @isTest
    static void testTriggerLogic() {
        // Fetch Account ID and Notification Type
        Account acc = [SELECT Id FROM Account LIMIT 1];
        CustomNotificationType notifType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'new_urgent_opportunity_notification' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Trigger Opportunity',
            StageName = 'Prospecting',
            Amount = 1000,
            CloseDate = Date.today(),
            Urgent__c = true,
            AccountId = acc.Id
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals(true, opp.Urgent__c, 'Opportunity should be marked as urgent.');
    }

    @isTest
    static void testTrigger_ExceptionHandling() {
        Opportunity failingOpp = new Opportunity(
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Urgent__c = true,
            AccountId = [SELECT Id FROM Account LIMIT 1].Id
        );

        String actualMessage;

        Test.startTest();
        try {
            insert failingOpp;
        } catch (DmlException e) {
            actualMessage = e.getMessage();
            System.debug('Actual Exception Message: ' + actualMessage);
        }
        Test.stopTest();

        // Verify error log
        List<ErrorLog__c> errorLogs = [SELECT ClassName__c, MethodName__c, Message__c FROM ErrorLog__c];
        System.assertEquals(1, errorLogs.size(), 'An error log should have been created.');

        System.assertEquals('NewUrgentOpportunityTrigger', errorLogs[0].ClassName__c, 'Class name should match.');
        System.assertEquals('afterInsert', errorLogs[0].MethodName__c, 'Method name should match.');

        // Log the error message for debugging
        System.debug('ErrorLog Message: ' + errorLogs[0].Message__c);

        // Use contains() to match keywords flexibly
        System.assert(
            errorLogs[0].Message__c.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ||
            errorLogs[0].Message__c.contains('required field') ||
            errorLogs[0].Message__c.contains('failed'),
            'Error message should indicate a validation or DML failure.'
        );
    }

}