/**
 * @description Scheduled batch job for daily territory rebalancing
 * @author Smart Territory Manager Team
 * @date 2024
 */
global class TerritoryRebalanceBatch implements Database.Batchable<sObject>, Schedulable {
    
    /**
     * @description Start method for batch
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Active_Leads__c, Max_Capacity__c, 
                   Region__c, Industry_Focus__c, Owner__c
            FROM Territory__c
            WHERE Active__c = true
        ]);
    }
    
    /**
     * @description Execute method for batch processing
     */
    global void execute(Database.BatchableContext bc, List<Territory__c> scope) {
        // Rebalance territories
        TerritoryManager.rebalanceTerritories();
        
        // Recalculate metrics for each territory
        for (Territory__c territory : scope) {
            updateTerritoryMetrics(territory.Id);
        }
    }
    
    /**
     * @description Finish method for batch
     */
    global void finish(Database.BatchableContext bc) {
        // Send summary email to admin
        sendRebalanceSummary(bc.getJobId());
    }
    
    /**
     * @description Execute method for schedulable
     */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new TerritoryRebalanceBatch(), 200);
    }
    
    /**
     * @description Update territory metrics
     */
    private void updateTerritoryMetrics(Id territoryId) {
        AggregateResult[] results = [
            SELECT COUNT(Id) activeCount,
                   AVG(Amount) avgDeal,
                   SUM(Amount) totalRev
            FROM Opportunity
            WHERE Territory__c = :territoryId
            AND StageName = 'Closed Won'
            AND CloseDate = THIS_YEAR
        ];
        
        if (!results.isEmpty()) {
            Territory__c territory = new Territory__c(Id = territoryId);
            territory.Active_Leads__c = (Decimal)results[0].get('activeCount');
            territory.Avg_Deal_Size__c = (Decimal)results[0].get('avgDeal');
            territory.Total_Revenue__c = (Decimal)results[0].get('totalRev');
            update territory;
        }
    }
    
    /**
     * @description Send rebalance summary email
     */
    private void sendRebalanceSummary(Id jobId) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                   TotalJobItems, CreatedDate, CompletedDate
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{'admin@example.com'});
        email.setSubject('Territory Rebalance Complete - ' + System.today());
        
        String body = 'Territory rebalancing has completed.\n\n';
        body += 'Status: ' + job.Status + '\n';
        body += 'Items Processed: ' + job.JobItemsProcessed + '\n';
        body += 'Errors: ' + job.NumberOfErrors + '\n';
        body += 'Started: ' + job.CreatedDate + '\n';
        body += 'Completed: ' + job.CompletedDate + '\n';
        
        email.setPlainTextBody(body);
        
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            System.debug('Error sending summary email: ' + e.getMessage());
        }
    }
}