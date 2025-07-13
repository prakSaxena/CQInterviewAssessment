/*************************************************************************************************************************
Class Name - caseTriggerHandler
Class Description - This class contains trigger execution logiv for caseTrigger on Case Object.
Developer -  Prakhar Saxena (+91-9634522822, +91-7983507579) (prakharsaxena9650@rediffmail.com)
Developer for - Complaince Quest L1 Take Away Assessment
***************************************************************************************************************************/
public with sharing class caseTriggerHandler {
    
    private static Boolean isFirstTransactionRunComplete = false;
    
    public static void handleAfterInsertOrUpdate(List<Case> newList, Map<Id, Case> oldMap) {
        
        if (isFirstTransactionRunComplete) {
            return;
        }
        isFirstTransactionRunComplete = true;
        
        
        Set<Id> casesToProcess = new Set<Id>();
        Map<Id, Case> casesToCreateNC = new Map<Id, Case>();

        for (Case c : newList) {
            if (c.SQX_NC_Reference__c != null){
                System.debug('Nonconformance Record Alredy existing for :: '+ c.CaseNumber + ' Case');
                continue;
            }
           
            if (c.Type != 'Problem') 
            {
                System.debug('Type is not - problem');
                continue;
            }
            
            if (oldMap != null && oldMap.containsKey(c.Id) && oldMap.get(c.Id).Type == 'Problem') {
                System.debug('Type is not updated to problem from another value');
                continue;
            }

            casesToCreateNC.put(c.Id, c);
            System.debug('c.Id :: ' + c.Id);
            System.debug('c :: ' + c);
            System.debug('casesToCreateNC :: '+casesToCreateNC);
        }

        if (!casesToCreateNC.isEmpty()) {            
            Set<Id> userIds = new Set<Id>();
            for (Case c : casesToCreateNC.values()) {
                userIds.add(c.CreatedById);
            }

            Map<Id, Boolean> userHasPermission = getUsersWithCaseAdminPermission(userIds);

            List<SQX_Nonconformance__c> newNCs = new List<SQX_Nonconformance__c>();
            Map<Id, SQX_Nonconformance__c> caseIdToNC = new Map<Id, SQX_Nonconformance__c>();

            for (Case c : casesToCreateNC.values()) {
                if (!userHasPermission.containsKey(c.CreatedById) || !userHasPermission.get(c.CreatedById)) {
                    continue;
                }

                SQX_Nonconformance__c nc = new SQX_Nonconformance__c(
                    Priority__c = c.Priority,
                    Title__c = c.Subject,
                    Description__c = c.Description,
                    QMS_Reference_Number__c = c.CaseNumber
                );
                newNCs.add(nc);
                caseIdToNC.put(c.Id, nc);
            }

            if (!newNCs.isEmpty()) {
                insert newNCs;

                List<Case> casesToUpdate = new List<Case>();
                Integer index = 0;
                for (Id caseId : caseIdToNC.keySet()) {
                    Case cToUpdate = new Case(
                        Id = caseId,
                        SQX_NC_Reference__c = newNCs[index].Id
                    );
                    casesToUpdate.add(cToUpdate);
                    index++;
                }
                if (!casesToUpdate.isEmpty()) {
                    update casesToUpdate;
                }
            }
        }
    }

    private static Map<Id, Boolean> getUsersWithCaseAdminPermission(Set<Id> userIds) {
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (Id userId : userIds) {
            result.put(userId, false);
        }

        for (PermissionSetAssignment psa : [
            SELECT AssigneeId 
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = 'Case_Admin'
            AND AssigneeId IN :userIds
        ]) {
            result.put(psa.AssigneeId, true);
        }

        return result;
    }
}