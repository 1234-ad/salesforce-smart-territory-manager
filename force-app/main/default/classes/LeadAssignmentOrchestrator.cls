/**
 * @description Orchestrates lead assignment workflow with priority handling
 * @author Smart Territory Manager Team
 * @date 2024
 */
public with sharing class LeadAssignmentOrchestrator {
    
    private static final Integer HIGH_PRIORITY_THRESHOLD = 80;
    private static final Integer MEDIUM_PRIORITY_THRESHOLD = 60;
    
    /**
     * @description Process new lead through complete assignment workflow
     * @param leadId The lead to process
     * @return AssignmentResult Result of the assignment process
     */
    public static AssignmentResult processNewLead(Id leadId) {
        AssignmentResult result = new AssignmentResult();
        result.leadId = leadId;
        result.success = false;
        
        try {
            // Step 1: Calculate lead score
            Lead_Score__c score = LeadScoringEngine.calculateScore(leadId);
            result.leadScore = score.Total_Score__c;
            result.scoreGrade = score.Score_Grade__c;
            
            // Step 2: Determine priority
            String priority = determinePriority(score.Total_Score__c);
            result.priority = priority;
            
            // Step 3: Assign to territory
            Territory__c territory = TerritoryManager.assignLead(leadId);
            result.territoryId = territory.Id;
            result.territoryName = territory.Name;
            
            // Step 4: Create tasks based on priority
            createFollowUpTasks(leadId, territory.Owner__c, priority, score.Total_Score__c);
            
            // Step 5: Send notifications
            sendAssignmentNotifications(leadId, territory.Owner__c, priority);
            
            // Step 6: Update lead status
            updateLeadStatus(leadId, priority);
            
            result.success = true;
            result.message = 'Lead successfully processed and assigned';
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error processing lead: ' + e.getMessage();
            System.debug('Lead assignment error: ' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * @description Bulk process multiple leads
     * @param leadIds Set of lead IDs to process
     * @return List<AssignmentResult> Results for each lead
     */
    public static List<AssignmentResult> bulkProcessLeads(Set<Id> leadIds) {
        List<AssignmentResult> results = new List<AssignmentResult>();
        
        for (Id leadId : leadIds) {
            AssignmentResult result = processNewLead(leadId);
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * @description Reassign lead with new scoring
     * @param leadId The lead to reassign
     * @param reason Reason for reassignment
     * @return AssignmentResult Result of reassignment
     */
    public static AssignmentResult reassignLead(Id leadId, String reason) {
        AssignmentResult result = new AssignmentResult();
        result.leadId = leadId;
        
        try {
            // Recalculate score
            Lead_Score__c score = LeadScoringEngine.calculateScore(leadId);
            result.leadScore = score.Total_Score__c;
            result.scoreGrade = score.Score_Grade__c;
            
            // Get current territory
            Id currentTerritoryId = getCurrentTerritory(leadId);
            
            // Find new optimal territory
            Territory__c newTerritory = TerritoryManager.assignLead(leadId);
            
            // Only reassign if territory changed
            if (currentTerritoryId != newTerritory.Id) {
                result.territoryId = newTerritory.Id;
                result.territoryName = newTerritory.Name;
                result.message = 'Lead reassigned to new territory';
                
                // Notify both old and new owners
                notifyReassignment(leadId, currentTerritoryId, newTerritory.Id, reason);
            } else {
                result.message = 'Lead remains in current territory';
            }
            
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error reassigning lead: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Handle lead status change and trigger reassignment if needed
     * @param leadId The lead ID
     * @param newStatus The new status
     */
    public static void handleStatusChange(Id leadId, String newStatus) {
        // Recalculate score on status change
        Lead_Score__c score = LeadScoringEngine.calculateScore(leadId);
        
        // Check if reassignment is needed based on new score
        if (score.Total_Score__c >= HIGH_PRIORITY_THRESHOLD) {
            // High priority leads might need specialist assignment
            reassignLead(leadId, 'Status changed to high priority');
        }
    }
    
    /**
     * @description Process leads in queue based on priority
     * @param queueName The queue name
     * @param batchSize Number of leads to process
     * @return Integer Number of leads processed
     */
    public static Integer processQueue(String queueName, Integer batchSize) {
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = :queueName LIMIT 1];
        
        List<Lead> queuedLeads = [
            SELECT Id, CreatedDate
            FROM Lead
            WHERE OwnerId = :queue.Id
            AND IsConverted = false
            ORDER BY CreatedDate ASC
            LIMIT :batchSize
        ];
        
        Integer processedCount = 0;
        
        for (Lead lead : queuedLeads) {
            AssignmentResult result = processNewLead(lead.Id);
            if (result.success) {
                processedCount++;
            }
        }
        
        return processedCount;
    }
    
    /**
     * @description Determine priority based on lead score
     * @param score The lead score
     * @return String Priority level
     */
    private static String determinePriority(Decimal score) {
        if (score >= HIGH_PRIORITY_THRESHOLD) {
            return 'High';
        } else if (score >= MEDIUM_PRIORITY_THRESHOLD) {
            return 'Medium';
        } else {
            return 'Low';
        }
    }
    
    /**
     * @description Create follow-up tasks based on priority
     * @param leadId The lead ID
     * @param ownerId The owner ID
     * @param priority Priority level
     * @param score Lead score
     */
    private static void createFollowUpTasks(Id leadId, Id ownerId, String priority, Decimal score) {
        List<Task> tasks = new List<Task>();
        
        // Immediate contact task for high priority
        if (priority == 'High') {
            tasks.add(new Task(
                WhoId = leadId,
                OwnerId = ownerId,
                Subject = 'URGENT: Contact High-Value Lead (Score: ' + score.intValue() + ')',
                Priority = 'High',
                Status = 'Not Started',
                ActivityDate = Date.today(),
                Description = 'This is a high-priority lead with excellent conversion potential. ' +
                             'Contact within 2 hours for best results.'
            ));
            
            // Follow-up task
            tasks.add(new Task(
                WhoId = leadId,
                OwnerId = ownerId,
                Subject = 'Follow-up on High-Priority Lead',
                Priority = 'High',
                Status = 'Not Started',
                ActivityDate = Date.today().addDays(1),
                Description = 'Follow up if no response to initial contact.'
            ));
        } 
        // Standard contact for medium priority
        else if (priority == 'Medium') {
            tasks.add(new Task(
                WhoId = leadId,
                OwnerId = ownerId,
                Subject = 'Contact Qualified Lead (Score: ' + score.intValue() + ')',
                Priority = 'Normal',
                Status = 'Not Started',
                ActivityDate = Date.today().addDays(1),
                Description = 'This lead shows good potential. Contact within 24 hours.'
            ));
        }
        // Nurture task for low priority
        else {
            tasks.add(new Task(
                WhoId = leadId,
                OwnerId = ownerId,
                Subject = 'Nurture Lead (Score: ' + score.intValue() + ')',
                Priority = 'Low',
                Status = 'Not Started',
                ActivityDate = Date.today().addDays(3),
                Description = 'Add to nurture campaign and follow up in 3 days.'
            ));
        }
        
        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }
    
    /**
     * @description Send assignment notifications
     * @param leadId The lead ID
     * @param ownerId The new owner ID
     * @param priority Priority level
     */
    private static void sendAssignmentNotifications(Id leadId, Id ownerId, String priority) {
        Lead lead = [SELECT Name, Company, Email, Phone FROM Lead WHERE Id = :leadId LIMIT 1];
        
        // Create email notification
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(ownerId);
        email.setSaveAsActivity(false);
        email.setSubject('New ' + priority + ' Priority Lead Assigned: ' + lead.Name);
        
        String body = 'A new lead has been assigned to you:\n\n';
        body += 'Lead Name: ' + lead.Name + '\n';
        body += 'Company: ' + lead.Company + '\n';
        body += 'Priority: ' + priority + '\n';
        body += 'Email: ' + lead.Email + '\n';
        body += 'Phone: ' + lead.Phone + '\n\n';
        body += 'View Lead: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + leadId;
        
        email.setPlainTextBody(body);
        
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            System.debug('Error sending notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Update lead status based on priority
     * @param leadId The lead ID
     * @param priority Priority level
     */
    private static void updateLeadStatus(Id leadId, String priority) {
        Lead leadToUpdate = new Lead(Id = leadId);
        
        if (priority == 'High') {
            leadToUpdate.Status = 'Working - Contacted';
        } else {
            leadToUpdate.Status = 'Open - Not Contacted';
        }
        
        update leadToUpdate;
    }
    
    /**
     * @description Get current territory for a lead
     * @param leadId The lead ID
     * @return Id Current territory ID
     */
    private static Id getCurrentTerritory(Id leadId) {
        List<Assignment_History__c> history = [
            SELECT To_Territory__c
            FROM Assignment_History__c
            WHERE Lead__c = :leadId
            ORDER BY Assigned_Date__c DESC
            LIMIT 1
        ];
        
        return history.isEmpty() ? null : history[0].To_Territory__c;
    }
    
    /**
     * @description Notify about reassignment
     * @param leadId The lead ID
     * @param oldTerritoryId Old territory ID
     * @param newTerritoryId New territory ID
     * @param reason Reason for reassignment
     */
    private static void notifyReassignment(Id leadId, Id oldTerritoryId, Id newTerritoryId, String reason) {
        // Implementation for reassignment notifications
        System.debug('Lead ' + leadId + ' reassigned from ' + oldTerritoryId + ' to ' + newTerritoryId);
    }
    
    /**
     * @description Wrapper class for assignment results
     */
    public class AssignmentResult {
        @AuraEnabled public Id leadId { get; set; }
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Decimal leadScore { get; set; }
        @AuraEnabled public String scoreGrade { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public Id territoryId { get; set; }
        @AuraEnabled public String territoryName { get; set; }
    }
}