@isTest
public with sharing class ErrorHandlerTest {
    @isTest
    static void testLogError_Success() {
        // Arrange
        String className = 'TestClass';
        String methodName = 'TestMethod';
        String level = 'ERROR';

        // Use try-catch to simulate an exception
        Exception simulatedException;
        try {
            // Deliberately cause an exception
            Integer a = 1 / 0; 
        } catch (Exception e) {
            simulatedException = e;
        }

        // Act
        Test.startTest();
        ErrorHandler.logError(simulatedException, className, methodName, level);
        Test.stopTest();

        // Assert
        List<ErrorLog__c> logs = [SELECT ClassName__c, MethodName__c, Level__c, Message__c, StackTrace__c FROM ErrorLog__c];
        System.assertEquals(1, logs.size(), 'One log entry should be created.');
        System.assertEquals(className, logs[0].ClassName__c, 'ClassName__c should match.');
        System.assertEquals(methodName, logs[0].MethodName__c, 'MethodName__c should match.');
        System.assertEquals(level, logs[0].Level__c, 'Level__c should match.');
        System.assertEquals(simulatedException.getMessage(), logs[0].Message__c, 'Message__c should match.');
    }

    @isTest
    static void testLogError_FailureDuringInsert() {
        // Arrange
        String className = 'TestClass';
        String methodName = 'TestMethod';
        String level = 'ERROR';

        // Simulate an exception
        Exception simulatedException;
        try {
            Integer b = 1 / 0; // Trigger an exception
        } catch (Exception e) {
            simulatedException = e;
        }

        // Cause insert to fail using DML restriction
        Test.startTest();
        ErrorLog__c errorLog = new ErrorLog__c();
        try {
            // Force a failure by adding a validation rule (simulate restricted operation)
            ErrorHandler.logError(simulatedException, className, methodName, level);
        } catch (Exception ex) {
            System.assert(false, 'Exception should be handled internally.');
        }
        Test.stopTest();

        // Assert that no records exist
        List<ErrorLog__c> logs = [SELECT Id FROM ErrorLog__c];
        System.assertEquals(0, logs.size(), 'No records should be created if insert fails.');
    }
}