@isTest
public class ErrorHandlerTest {
 
    @isTest
    static void testLogError() {
        try {
            Integer result = 10 / 0;
        } catch (Exception e) {
            String stackTrace = e.getStackTraceString();
           
            Test.startTest();
            ErrorHandler.logError(
                e,                  // Exception
                'ErrorHandlerTest', // Class name
                'testLogError',     // Method name
                'ERROR'             // Error level
            );
            Test.stopTest();
           
            ErrorLog__c loggedError = [SELECT ClassName__c, MethodName__c, Level__c, Message__c, StackTrace__c
                                       FROM ErrorLog__c
                                       WHERE ClassName__c = 'ErrorHandlerTest'
                                       AND MethodName__c = 'testLogError'
                                       LIMIT 1];
           
            System.assert(loggedError != null, 'Error log should be created.');
            System.assert(loggedError.ClassName__c == 'ErrorHandlerTest', 'Class name should match.');
            System.assert(loggedError.MethodName__c == 'testLogError', 'Method name should match.');
            System.assert(loggedError.Level__c == 'ERROR', 'Error level should match.');
            System.assert(loggedError.Message__c != null, 'Message should not be null.');
            System.assert(loggedError.StackTrace__c != null, 'Stack trace should not be null.');
        }
    }
}