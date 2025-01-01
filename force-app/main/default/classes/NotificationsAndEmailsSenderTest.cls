@isTest
private class NotificationsAndEmailsSenderTest {
    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Amount = 1000,
            CloseDate = Date.today(),
            Urgent__c = true,
            AccountId = acc.Id
        );
        insert opp;

        User testUser = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];
        insert new AccountTeamMember(AccountId = acc.Id, UserId = testUser.Id);
    }

    @isTest
    static void testSendNotificationsAndEmails() {
        Opportunity testOpp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        Test.startTest();
        NotificationsAndEmailsSender.sendNotificationsAndEmails(testOpp, testUser.Id, true, 'notifTypeId', emailMessages);
        Test.stopTest();

        System.assertEquals(1, emailMessages.size(), 'One email should be added to the list.');
    }
}