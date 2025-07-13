/*************************************************************************************************************************
Class/Trigger Name - caseTrigger
Class/Trigger Description - This is the trigger class for CASE Object.
Developer -  Prakhar Saxena (+91-9634522822, +91-7983507579) (prakharsaxena9650@rediffmail.com)
Developer for - Complaince Quest L1 Take Away Assessment
***************************************************************************************************************************/
trigger caseTrigger on Case (after insert, after update) {
    caseTriggerHandler.handleAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
}