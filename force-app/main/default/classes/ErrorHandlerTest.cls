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
           
            Assert.isNotNull(loggedError, 'Error log should be created.');
            Assert.areEqual('ErrorHandlerTest', loggedError.ClassName__c, 'Class name should match.');
            Assert.areEqual('testLogError', loggedError.MethodName__c, 'Method name should match.');
            Assert.areEqual('ERROR', loggedError.Level__c, 'Error level should match.');
            Assert.isNotNull(loggedError.Message__c, 'Message should not be null.');
            Assert.isNotNull(loggedError.StackTrace__c, 'Stack trace should not be null.');
        }
    }
}
