public class OpportunityResponse {
    @AuraEnabled
    public List<Opportunity> opportunities;
    @AuraEnabled
    public Integer totalRecords;

    public OpportunityResponse(List<Opportunity> opportunities, Integer totalRecords) {
        this.opportunities = opportunities;
        this.totalRecords = totalRecords;
    }
}

