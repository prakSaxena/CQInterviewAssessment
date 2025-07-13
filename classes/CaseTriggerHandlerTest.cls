/*************************************************************************************************************************
Class/Trigger Name - CaseTriggerHandlerTest
Class/Trigger Description - This is the Test Class for unit testing the trigger Handler logic.
Developer -  Prakhar Saxena (+91-9634522822, +91-7983507579) (prakharsaxena9650@rediffmail.com)
Developer for - Complaince Quest L1 Take Away Assessment
***************************************************************************************************************************/
@isTest
private class CaseTriggerHandlerTest {

    @testSetup
    static void setupData() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Case_Admin' LIMIT 1];
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User adminUser = new User(
            Alias='caseAd',
            Email='caseAdminUser@test.com',
            EmailEncodingKey='UTF-8',
            LastName='Admin12345',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            TimeZoneSidKey='America/New_York',
            UserName='caseAdminUser@test.com'
        );
        insert adminUser;

        User normalUser = new User(
            Alias='nonCseAd',
            Email='nonCaseAdminUser@test.com',
            EmailEncodingKey='UTF-8',
            LastName='NonAdmin',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            TimeZoneSidKey='America/New_York',
            UserName='nonCaseAdmin@test.com'
        );
        insert normalUser;

        insert new PermissionSetAssignment(AssigneeId=adminUser.Id, PermissionSetId=ps.Id);
    }

    @isTest
    static void testCaseAdminCreatesNonconformance() {
        User adminUser = [SELECT Id FROM User WHERE Alias='caseAd' LIMIT 1];
        System.runAs(adminUser) {
            Case c = new Case(
                Subject='Case from admin user',
                Type='Problem',
                Priority='High',
                Description='Test description'
            );
            insert c;

            Case createdCase = [SELECT Id, SQX_NC_Reference__c FROM Case WHERE Id=:c.Id];
            System.assertNotEquals(null, createdCase.SQX_NC_Reference__c, 'Case should be linked to NC');

            SQX_Nonconformance__c nc = [SELECT Id, Title__c, Priority__c, Description__c, QMS_Reference_Number__c 
                                        FROM SQX_Nonconformance__c WHERE Id=:createdCase.SQX_NC_Reference__c];
            System.assertEquals('Case from admin user', nc.Title__c);
            System.assertEquals('High', nc.Priority__c);
        }
    }

    @isTest
    static void testNormalUserDoesNotCreateNonconformance() {
        User normalUser = [SELECT Id FROM User WHERE Alias='nonCseAd' LIMIT 1];
        System.runAs(normalUser) {
            Case c = new Case(
                Subject='Case by normal user',
                Type='Problem',
                Priority='Low',
                Description='Should not create NC'
            );
            insert c;

            Case createdCase = [SELECT Id, SQX_NC_Reference__c FROM Case WHERE Id=:c.Id];
            System.assertEquals(null, createdCase.SQX_NC_Reference__c, 'Normal user should not create NC');
        }
    }

    @isTest
    static void testNoDuplicateNonconformance() {
        User adminUser = [SELECT Id FROM User WHERE Alias='caseAd' LIMIT 1];
        System.runAs(adminUser) {
            // Insert case
            Case c = new Case(
                Subject='Duplicate test case',
                Type='Problem',
                Priority='Medium',
                Description='Initial insert'
            );
            insert c;

            Case createdCase = [SELECT Id, SQX_NC_Reference__c FROM Case WHERE Id=:c.Id];
            Id firstNcId = createdCase.SQX_NC_Reference__c;

            c.Description = 'Second Time Update';
            update c;

            Case updatedCase = [SELECT SQX_NC_Reference__c FROM Case WHERE Id=:c.Id];
            System.assertEquals(firstNcId, updatedCase.SQX_NC_Reference__c, 'Should not create duplicate NC');

            Integer countNc = [SELECT COUNT() FROM SQX_Nonconformance__c WHERE QMS_Reference_Number__c != null];
            System.assertEquals(1, countNc, 'Only one NC should exist');
        }
    }
}