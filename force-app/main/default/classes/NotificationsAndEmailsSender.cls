public with sharing class NotificationsAndEmailsSender {
    public static void sendNotificationsAndEmails(Opportunity opportunity, Id recipientId, Boolean isCreator, String notificationTypeId, List<Messaging.SingleEmailMessage> emailMessages) {
        try {
            User recipient = [SELECT Email FROM User WHERE Id = :recipientId LIMIT 1];
            if (recipient.Email != null) {
                String notificationTitle = isCreator
                    ? 'Urgent Opportunity Created!'
                    : 'New Urgent Opportunity Created';
                String notificationBody = isCreator
                    ? 'You’ve successfully created the ' +  opportunity.Name + ' urgent opportunity. '
                    : 'User ' + UserInfo.getName() + ' created a new urgent opportunity: ' + opportunity.Name;

                // pt notif Salesforce
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setBody(notificationBody);
                notification.setTitle(notificationTitle);
                notification.setNotificationTypeId(notificationTypeId);
                notification.setSenderId(UserInfo.getUserId());
                notification.setTargetId(recipientId);
                notification.send(new Set<String>{String.valueOf(recipientId)});


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
        } catch (Exception e) {
            ErrorHandler.logError(e, 'NotificationsAndEmailsSender', 'sendNotificationsAndEmails', 'ERROR');
            throw new AuraHandledException('Failed to send notifications or emails.');
        }
    }
}