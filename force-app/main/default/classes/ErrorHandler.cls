public with sharing class ErrorHandler {
    public static void logError(Exception e, String className, String methodName, String level) {
        try {
            ErrorLog__c errorLog = new ErrorLog__c();
            errorLog.ClassName__c = className;
            errorLog.MethodName__c = methodName;
            errorLog.Level__c = level;
            errorLog.Message__c = e.getMessage();
            errorLog.StackTrace__c = e.getStackTraceString();

            System.debug('Logging Error: ' + errorLog);
            insert errorLog;
        } catch (Exception logError) {
            System.debug('Failed to log error: ' + logError.getMessage());
        }
    }
}