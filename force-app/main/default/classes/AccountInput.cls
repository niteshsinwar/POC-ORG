public class AccountInput {
    public static List<Account> accountWithUniqueNames(List<Account> AccountList) {
        Map<String, Account> accNames = new Map<String, Account>();
        List<Account> AccListWithUniqueName = new List<Account>();

        for (Account acc : AccountList) {
            if (accNames.containsKey(acc.Name)) {
                if (acc.CreatedDate > accNames.get(acc.Name).CreatedDate) {
                    accNames.put(acc.Name, acc);
                }
            } else {
                accNames.put(acc.Name, acc);
            }
        }

        AccListWithUniqueName=accNames.values();
        return AccListWithUniqueName;
    }
}