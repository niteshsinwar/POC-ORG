public class ContractInput {
    public static Contract ContractWithMaxEndDate(List<Contract> ContractList) {
        Date maxEndDate = Date.newInstance(2001, 01, 01); 
        
        Contract maxEndDateContract = null; 
        
        for (Contract contr : ContractList) {
            Date contrEndDate;
            
            if (contr.Status == 'Active') {
             contrEndDate = (Date)contr.StartDate.addDays((Integer)contr.TermDays__c);
            } else if (contr.Status == 'Cancelled') {
                contrEndDate = contr.CancelledDate__c;
            }
            
            if (contrEndDate != null && contrEndDate > maxEndDate) {
                maxEndDate = contrEndDate;
                maxEndDateContract = contr;
            }
        }
        
        return maxEndDateContract;
    }
}