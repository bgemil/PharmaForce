trigger NewUrgentOpportunityTrigger on Opportunity (after insert) {
    try {
        // preiau id-ul custom notification-ului pe care l-am creat
        CustomNotificationType oppNotificationType = [ 
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'new_urgent_opportunity_notification'
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        for (Opportunity opportunity : Trigger.New) {
            if (opportunity.Urgent__c == true) { 
                Boolean isCreatorInTeam = false;
                if (opportunity.AccountId != null) {
                    isCreatorInTeam = [
                        SELECT Id 
                        FROM AccountTeamMember 
                        WHERE AccountId = :opportunity.AccountId AND UserId = :opportunity.CreatedById
                        LIMIT 1
                    ] != null;
                }

                // pt creator
                if(isCreatorInTeam) {
                    NotificationsAndEmailsSender.sendNotificationsAndEmails(
                        opportunity,
                        opportunity.CreatedById,
                        true, // isCreator
                        oppNotificationType.Id,
                        emailMessages
                    );
                }

                // pt team members
                if (opportunity.AccountId != null) {
                    List<AccountTeamMember> teamMembers = [
                        SELECT UserId 
                        FROM AccountTeamMember 
                        WHERE AccountId = :opportunity.AccountId AND UserId != :opportunity.CreatedById
                    ];

                    for (AccountTeamMember member : teamMembers) {
                        NotificationsAndEmailsSender.sendNotificationsAndEmails(
                            opportunity,
                            member.UserId,
                            false, // isCreator
                            oppNotificationType.Id,
                            emailMessages
                        );
                    }
                }
            }
        }

        // Send all emails in bulk
        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }
    } catch (Exception e) {
        System.debug('Trigger caught exception: ' + e.getMessage());
        ErrorHandler.logError(e, 'NewUrgentOpportunityTrigger', 'afterInsert', 'ERROR');
    }
}