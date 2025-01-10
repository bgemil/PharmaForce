trigger NewUrgentOpportunityTrigger on Opportunity (after insert) {
    NotificationsAndEmailsSender.processOpportunities(Trigger.New);
}