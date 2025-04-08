public class PayloadGenerator {
    public static PayloadWrapper generatePayload(String accountId, String accessToken) {
        PayloadWrapper payload = new PayloadWrapper();
        
        // Query Account
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
        
        if (acc != null) {
            // Set Account data
            payload.accountId = acc.Id;
            payload.accountName = acc.Name;
            
            // Query Contacts related to Account
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            for (Contact con : [SELECT Id, Name, AccountId FROM Contact WHERE AccountId = :accountId]) {
                contactMap.put(con.Id, con);
            }
            
            // Query Opportunities related to Contacts
            Map<Id, List<Opportunity>> oppMap = new Map<Id, List<Opportunity>>();
            for (Opportunity opp : [SELECT Id, Name, ContactId FROM Opportunity WHERE ContactId IN :contactMap.keySet()]) {
                if (!oppMap.containsKey(opp.ContactId)) {
                    oppMap.put(opp.ContactId, new List<Opportunity>());
                }
                oppMap.get(opp.ContactId).add(opp);
            }
            
            // Set Contact and Opportunity data
            for (Id contactId : contactMap.keySet()) {
                Contact con = contactMap.get(contactId);
                ContactData contactData = new ContactData();
                contactData.contactName = con.Name;
                
                if (oppMap.containsKey(contactId)) {
                    for (Opportunity opp : oppMap.get(contactId)) {
                        OpportunityData oppData = new OpportunityData();
                        oppData.opportunityId = opp.Id;
                        oppData.opportunityName = opp.Name;
                        contactData.opportunities.add(oppData);
                    }
                }
                
                payload.contacts.add(contactData);
            }
            
            return payload;
        } else {
            return null; // Account not found
        }
    }

    public class PayloadWrapper {
        public String accountId;
        public String accountName;
        public List<ContactData> contacts;

        public PayloadWrapper() {
            contacts = new List<ContactData>();
        }
    }

    public class ContactData {
        public String contactName;
        public List<OpportunityData> opportunities;

        public ContactData() {
            opportunities = new List<OpportunityData>();
        }
    }

    public class OpportunityData {
        public String opportunityId;
        public String opportunityName;

        public OpportunityData() {
        }
    }
}