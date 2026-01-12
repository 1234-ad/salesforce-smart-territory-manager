/**
 * @description Trigger for Lead object to handle scoring and assignment
 * @author Smart Territory Manager Team
 * @date 2024
 */
trigger LeadTrigger on Lead (after insert, after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handleNewLeads(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            handleLeadUpdates(Trigger.new, Trigger.oldMap);
        }
    }
    
    /**
     * @description Handle new lead insertions
     */
    private static void handleNewLeads(List<Lead> newLeads) {
        Set<Id> leadsToProcess = new Set<Id>();
        
        for (Lead lead : newLeads) {
            // Only process leads that meet criteria
            if (shouldProcessLead(lead)) {
                leadsToProcess.add(lead.Id);
            }
        }
        
        if (!leadsToProcess.isEmpty()) {
            // Process asynchronously to avoid governor limits
            System.enqueueJob(new LeadProcessingQueueable(leadsToProcess));
        }
    }
    
    /**
     * @description Handle lead updates
     */
    private static void handleLeadUpdates(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        Set<Id> leadsToRescore = new Set<Id>();
        Set<Id> leadsToReassign = new Set<Id>();
        
        for (Lead lead : newLeads) {
            Lead oldLead = oldMap.get(lead.Id);
            
            // Check if significant fields changed
            if (hasSignificantChanges(lead, oldLead)) {
                leadsToRescore.add(lead.Id);
            }
            
            // Check if status changed
            if (lead.Status != oldLead.Status) {
                LeadAssignmentOrchestrator.handleStatusChange(lead.Id, lead.Status);
            }
            
            // Check if territory reassignment needed
            if (shouldReassign(lead, oldLead)) {
                leadsToReassign.add(lead.Id);
            }
        }
        
        if (!leadsToRescore.isEmpty()) {
            System.enqueueJob(new LeadRescoringQueueable(leadsToRescore));
        }
    }
    
    /**
     * @description Check if lead should be processed
     */
    private static Boolean shouldProcessLead(Lead lead) {
        return lead.Email != null && 
               lead.Company != null && 
               !lead.IsConverted;
    }
    
    /**
     * @description Check if lead has significant changes
     */
    private static Boolean hasSignificantChanges(Lead newLead, Lead oldLead) {
        return newLead.Industry != oldLead.Industry ||
               newLead.Title != oldLead.Title ||
               newLead.NumberOfEmployees != oldLead.NumberOfEmployees ||
               newLead.AnnualRevenue != oldLead.AnnualRevenue ||
               newLead.Country != oldLead.Country;
    }
    
    /**
     * @description Check if lead should be reassigned
     */
    private static Boolean shouldReassign(Lead newLead, Lead oldLead) {
        return newLead.State != oldLead.State ||
               newLead.Industry != oldLead.Industry;
    }
    
    /**
     * @description Queueable class for processing new leads
     */
    public class LeadProcessingQueueable implements Queueable {
        private Set<Id> leadIds;
        
        public LeadProcessingQueueable(Set<Id> leadIds) {
            this.leadIds = leadIds;
        }
        
        public void execute(QueueableContext context) {
            LeadAssignmentOrchestrator.bulkProcessLeads(leadIds);
        }
    }
    
    /**
     * @description Queueable class for rescoring leads
     */
    public class LeadRescoringQueueable implements Queueable {
        private Set<Id> leadIds;
        
        public LeadRescoringQueueable(Set<Id> leadIds) {
            this.leadIds = leadIds;
        }
        
        public void execute(QueueableContext context) {
            LeadScoringEngine.calculateBulkScores(leadIds);
        }
    }
}