trigger UpdateEvaluationDate on Student_Result__c (after update) {
    // Create a set to store the unique Student IDs whose grades have been updated.
    Set<Id> updatedStudentIds = new Set<Id>();

    // Create a map to store the most recent Evaluation Date for each Student.
    Map<Id, Date> recentEvaluationDates = new Map<Id, Date>();

    // Iterate through the updated Student Result records.
    for (Student_Result__c result : Trigger.new) {
        // Check if the Grade field has been changed.
        if (Trigger.oldMap.get(result.Id).Grades__c != result.Grades__c) {
            // Add the Student's ID to the set of updated Student IDs.
            updatedStudentIds.add(result.Student__c);

            // Update the recentEvaluationDates map with the current Evaluation Date.
            recentEvaluationDates.put(result.Student__c, result.LastModifiedDate.date());
        }
    }

    // Query for the Student records associated with the updated Student Results.
    List<Student__c> studentsToUpdate = [
        SELECT Id, Evaluation_Date__c
        FROM Student__c
        WHERE Id IN :updatedStudentIds
    ];

    // Update the Evaluation Date on the Student records.
    List<Student__c> studentsToUpdateWithNewDate = new List<Student__c>();

    for (Student__c student : studentsToUpdate) {
        Date recentDate = recentEvaluationDates.get(student.Id);

        if (recentDate != null && recentDate!=student.Evaluation_Date__c) {
            student.Evaluation_Date__c = recentDate;
            studentsToUpdateWithNewDate.add(student);
        }
    }

    // Perform bulk update of Student records with updated Evaluation Dates.
    if (!studentsToUpdateWithNewDate.isEmpty()) {
        update studentsToUpdateWithNewDate;
    }
}