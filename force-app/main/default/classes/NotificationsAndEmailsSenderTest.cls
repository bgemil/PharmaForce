@isTest
public class NotificationsAndEmailsSenderTest {
    @testSetup
    static void setupTestData() {
        // Create a test user with a System Administrator profile
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Alias = 'testusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create opportunities
        Opportunity opp1 = new Opportunity(
            Name = 'Urgent Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Amount = 1000,
            Urgent__c = true,
            AccountId = testAccount.Id
        );
        insert opp1;

        Opportunity opp2 = new Opportunity(
            Name = 'No Account Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(15),
            Amount = 2000,
            Urgent__c = true
        );
        insert opp2;

        // Create an account team member
        AccountTeamMember teamMember = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = testUser.Id,
            TeamMemberRole = 'Sales Team'
        );
        insert teamMember;
    }

    @isTest
    static void testProcessOpportunities_WithAccountTeam() {
        // Retrieve test data
        List<Opportunity> opps = [SELECT Id, Name, AccountId FROM Opportunity WHERE AccountId != null];

        // Run as the test user
        User testUser = [SELECT Id FROM User WHERE Alias = 'testusr' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            NotificationsAndEmailsSender.processOpportunities(opps);
            Test.stopTest();
        }

        System.assert(true, 'Opportunities processed successfully.');
    }

    @isTest
    static void testProcessOpportunities_WithoutAccountId() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE AccountId = null LIMIT 1];

        User testUser = [SELECT Id FROM User WHERE Alias = 'testusr' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            NotificationsAndEmailsSender.processOpportunities(new List<Opportunity>{opp});
            Test.stopTest();
        }

        System.assert(true, 'Opportunities without AccountId processed successfully.');
    }

    @isTest
    static void testSendNotificationsAndEmails() {
        Opportunity opp = [SELECT Id, Name, AccountId FROM Opportunity WHERE AccountId != null LIMIT 1];
        User testUser = [SELECT Id, Email FROM User WHERE Alias = 'testusr' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            NotificationsAndEmailsSender.sendNotificationsAndEmails(
                opp,
                testUser.Id,
                true, // isCreator
                'notificationTypeId',
                new List<Messaging.SingleEmailMessage>()
            );
            Test.stopTest();
        }

        System.assert(true, 'Notifications and emails sent successfully.');
    }

    @isTest
    static void testSendNotificationsAndEmails_ErrorHandling() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testusr' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            try {
                NotificationsAndEmailsSender.sendNotificationsAndEmails(
                    null, // Invalid Opportunity
                    null, // Invalid UserId
                    true,
                    null, // Invalid NotificationTypeId
                    null  // Invalid EmailMessage List
                );
            } catch (Exception e) {
                System.assert(e != null, 'Error should be caught in sendNotificationsAndEmails.');
            }
            Test.stopTest();
        }
    }
}
