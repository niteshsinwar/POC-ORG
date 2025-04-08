trigger UpdateCustomerLastEndDate on Contract (after insert, after update) {
    // Initialize variables
    Id customerId;
    Date maxEndDate;

    // Get the Contract that triggered the trigger (assuming it's the first record in Trigger.new)
    Contract triggeringContract = Trigger.new[0];

    if (triggeringContract.Customer__c != null && triggeringContract.Status == 'Activated') {
        customerId = triggeringContract.Customer__c;
    }

    if (customerId != null) {
        // Query for the maximum End Date for this Customer's active Contracts
        AggregateResult aggregateResult = [
            SELECT MAX(EndDate) maxEndDate
            FROM Contract
            WHERE Customer__c = :customerId
              AND Status = 'Activated'
        ];
        
        Date maxEndDate = (Date)aggregateResult.get('maxEndDate');

        // Update the Customer record
        if (maxEndDate != null) {
            Customer customer = new Customer(Id = customerId, Last_End_Date__c = maxEndDate);
            update customer;
        }
    }
}