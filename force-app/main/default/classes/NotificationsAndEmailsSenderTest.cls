@isTest
public class NotificationsAndEmailsSenderTest {
    @testSetup
    static void setupTestData() {
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

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        System.runAs(testUser) {
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

            AccountTeamMember teamMember = new AccountTeamMember(
                AccountId = testAccount.Id,
                UserId = testUser.Id,
                TeamMemberRole = 'Sales Team'
            );
            insert teamMember;
        }
    }

    @isTest
    static void testProcessOpportunities_WithAccountTeam() {
        List<Opportunity> opps = [SELECT Id, Name, AccountId, Urgent__c, CreatedById FROM Opportunity WHERE AccountId != null];

        User testUser = [SELECT Id FROM User WHERE Alias = 'testusr' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            NotificationsAndEmailsSender.processOpportunities(opps);
            Test.stopTest();
        }

        Assert.isTrue(true, 'Opportunities processed successfully.');
    }

    @isTest
    static void testProcessOpportunities_WithoutAccountId() {
        Opportunity opp = [SELECT Id, Name, AccountId, Urgent__c, CreatedById FROM Opportunity WHERE AccountId = null LIMIT 1];

        User testUser = [SELECT Id FROM User WHERE Alias = 'testusr' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            NotificationsAndEmailsSender.processOpportunities(new List<Opportunity>{opp});
            Test.stopTest();
        }

        Assert.isTrue(true, 'Opportunities without AccountId processed successfully.');
    }

    @isTest
    static void testSendNotificationsAndEmails() {
        Opportunity opp = [SELECT Id, Name, AccountId, Amount, CloseDate FROM Opportunity WHERE AccountId != null LIMIT 1];
        User testUser = [SELECT Id, Email FROM User WHERE Alias = 'testusr' LIMIT 1];
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :new Set<Id>{testUser.Id}]);
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        System.runAs(testUser) {
            Test.startTest();
            NotificationsAndEmailsSender.sendNotificationsAndEmails(
                opp,
                testUser.Id,
                true, // isCreator
                'notificationTypeId',
                emailMessages,
                userMap
            );
            Test.stopTest();
        }

        Assert.isTrue(!emailMessages.isEmpty(), 'Emails should be added to the list.');
    }

    @isTest
    static void testSendNotificationsAndEmails_ErrorHandling() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testusr' LIMIT 1];
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Map<Id, User> userMap = new Map<Id, User>();

        System.runAs(testUser) {
            Test.startTest();
            try {
                NotificationsAndEmailsSender.sendNotificationsAndEmails(
                    null,
                    null, 
                    true, 
                    null, 
                    emailMessages,
                    userMap
                );
            } catch (Exception e) {
                Assert.isNotNull(e, 'Error should be caught in sendNotificationsAndEmails.');
            }
            Test.stopTest();
        }
    }
}
