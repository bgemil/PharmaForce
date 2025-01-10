public with sharing class NotificationsAndEmailsSender {
    public static void processOpportunities(List<Opportunity> opportunities) {
        try {
            // Fetch the notification type ID once
            CustomNotificationType oppNotificationType = [
                SELECT Id 
                FROM CustomNotificationType 
                WHERE DeveloperName = 'new_urgent_opportunity_notification'
                LIMIT 1
            ];

            // Collect all Account IDs and Opportunity Creator IDs
            Set<Id> accountIds = new Set<Id>();
            Set<Id> creatorIds = new Set<Id>();
            for (Opportunity opportunity : opportunities) {
                if (opportunity.AccountId != null) {
                    accountIds.add(opportunity.AccountId);
                }
                if (opportunity.CreatedById != null) {
                    creatorIds.add(opportunity.CreatedById);
                }
            }

            // Query all AccountTeamMember records for the relevant Accounts
            Map<Id, List<AccountTeamMember>> accountTeamMembersMap = new Map<Id, List<AccountTeamMember>>();
            for (AccountTeamMember member : [
                SELECT AccountId, UserId
                FROM AccountTeamMember
                WHERE AccountId IN :accountIds
            ]) {
                if (!accountTeamMembersMap.containsKey(member.AccountId)) {
                    accountTeamMembersMap.put(member.AccountId, new List<AccountTeamMember>());
                }
                accountTeamMembersMap.get(member.AccountId).add(member);
            }

            // Query all relevant Users
            Map<Id, User> userMap = new Map<Id, User>([
                SELECT Id, Email
                FROM User
                WHERE Id IN :creatorIds
            ]);

            // Prepare email messages
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

            for (Opportunity opportunity : opportunities) {
                if (opportunity.Urgent__c == true) {
                    Boolean isCreatorInTeam = false;

                    // Check if the creator is in the account team using a loop
                    if (opportunity.AccountId != null && accountTeamMembersMap.containsKey(opportunity.AccountId)) {
                        for (AccountTeamMember member : accountTeamMembersMap.get(opportunity.AccountId)) {
                            if (member.UserId == opportunity.CreatedById) {
                                isCreatorInTeam = true;
                                break; // Exit the loop as soon as a match is found
                            }
                        }
                    }

                    // Notify creator
                    if (isCreatorInTeam) {
                        sendNotificationsAndEmails(
                            opportunity,
                            opportunity.CreatedById,
                            true, // isCreator
                            oppNotificationType.Id,
                            emailMessages,
                            userMap
                        );
                    }

                    // Notify team members
                    if (opportunity.AccountId != null && accountTeamMembersMap.containsKey(opportunity.AccountId)) {
                        for (AccountTeamMember member : accountTeamMembersMap.get(opportunity.AccountId)) {
                            if (member.UserId != opportunity.CreatedById) {
                                sendNotificationsAndEmails(
                                    opportunity,
                                    member.UserId,
                                    false, // isCreator
                                    oppNotificationType.Id,
                                    emailMessages,
                                    userMap
                                );
                            }
                        }
                    }
                }
            }

            // Send all emails in bulk
            if (!emailMessages.isEmpty()) {
                Messaging.sendEmail(emailMessages);
            }
        } catch (Exception e) {
            ErrorHandler.logError(e, 'NotificationsAndEmailsSender', 'processOpportunities', 'ERROR');
            throw new AuraHandledException('Failed to process opportunities.');
        }
    }

    public static void sendNotificationsAndEmails(Opportunity opportunity, Id recipientId, Boolean isCreator, String notificationTypeId, List<Messaging.SingleEmailMessage> emailMessages, Map<Id, User> userMap) {
        try {
            if (userMap.containsKey(recipientId)) {
                User recipient = userMap.get(recipientId);

                if (recipient.Email != null) {
                    String notificationTitle = isCreator
                        ? 'Urgent Opportunity Created!'
                        : 'New Urgent Opportunity Created';
                    String notificationBody = isCreator
                        ? 'You’ve successfully created the ' + opportunity.Name + ' urgent opportunity. '
                        : 'User ' + UserInfo.getName() + ' created a new urgent opportunity: ' + opportunity.Name;

                    // Send Salesforce notification
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setBody(notificationBody);
                    notification.setTitle(notificationTitle);
                    notification.setNotificationTypeId(notificationTypeId);
                    notification.setSenderId(UserInfo.getUserId());
                    notification.setTargetId(recipientId);
                    notification.send(new Set<String>{String.valueOf(recipientId)});

                    // Prepare email
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new List<String>{recipient.Email});
                    email.setSubject(notificationTitle);
                    email.setPlainTextBody(
                        'Hello,\n\n' +
                        notificationBody + '.\n\n' +
                        'Opportunity Details:\n' +
                        'Name: ' + opportunity.Name + '\n' +
                        'Amount: ' + (opportunity.Amount != null ? opportunity.Amount : null) + '\n' +
                        'Close Date: ' + (opportunity.CloseDate != null ? opportunity.CloseDate.format() : 'N/A') + '\n\n' +
                        'Thank you.'
                    );
                    email.setWhatId(opportunity.Id); 
                    email.setSaveAsActivity(false); 
                    emailMessages.add(email);
                }
            }
        } catch (Exception e) {
            ErrorHandler.logError(e, 'NotificationsAndEmailsSender', 'sendNotificationsAndEmails', 'ERROR');
            throw new AuraHandledException('Failed to send notifications or emails.');
        }
    }
}
