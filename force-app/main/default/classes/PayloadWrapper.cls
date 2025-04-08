public class PayloadWrapper {
    public String accountId;
    public String accountName;
    public List<OpportunityData> opportunities;

    public PayloadWrapper() {
        opportunities = new List<OpportunityData>();
    }


public class OpportunityData {
    public String opportunityId;
    public String opportunityName;
    public List<QuoteData> quotes;

    public OpportunityData() {
        quotes = new List<QuoteData>();
    }
}

public class QuoteData {
    public String quoteId;
    public String quoteName;
    // Add more fields as needed
}
}