/**
 * @description Dynamic Territory Management with intelligent assignment
 * @author Smart Territory Manager Team
 * @date 2024
 */
public with sharing class TerritoryManager {
    
    private static final Integer MAX_LEADS_PER_REP = 50;
    private static final Decimal WORKLOAD_BALANCE_THRESHOLD = 0.8;
    
    /**
     * @description Assign lead to optimal territory based on multiple criteria
     * @param leadId The lead to assign
     * @return Territory__c The assigned territory
     */
    public static Territory__c assignLead(Id leadId) {
        Lead lead = getLeadDetails(leadId);
        List<Territory__c> eligibleTerritories = findEligibleTerritories(lead);
        
        if (eligibleTerritories.isEmpty()) {
            throw new TerritoryException('No eligible territories found for lead: ' + leadId);
        }
        
        Territory__c optimalTerritory = selectOptimalTerritory(lead, eligibleTerritories);
        
        // Create assignment record
        createAssignmentHistory(leadId, null, optimalTerritory.Id, 'Auto-Assignment');
        
        // Update lead owner
        updateLeadOwner(leadId, optimalTerritory.Owner__c);
        
        // Update territory metrics
        updateTerritoryMetrics(optimalTerritory.Id);
        
        return optimalTerritory;
    }
    
    /**
     * @description Bulk assign multiple leads to territories
     * @param leadIds Set of lead IDs to assign
     * @return Map<Id, Territory__c> Map of lead IDs to assigned territories
     */
    public static Map<Id, Territory__c> bulkAssignLeads(Set<Id> leadIds) {
        Map<Id, Territory__c> assignmentMap = new Map<Id, Territory__c>();
        
        for (Id leadId : leadIds) {
            try {
                Territory__c territory = assignLead(leadId);
                assignmentMap.put(leadId, territory);
            } catch (Exception e) {
                System.debug('Error assigning lead ' + leadId + ': ' + e.getMessage());
            }
        }
        
        return assignmentMap;
    }
    
    /**
     * @description Manually assign lead to specific territory
     * @param leadId The lead to assign
     * @param territoryId The target territory
     * @param reason Reason for manual assignment
     */
    public static void manualAssignment(Id leadId, Id territoryId, String reason) {
        Territory__c territory = [SELECT Id, Owner__c FROM Territory__c WHERE Id = :territoryId LIMIT 1];
        
        // Get current territory if exists
        Id currentTerritoryId = getCurrentTerritory(leadId);
        
        // Create assignment history
        createAssignmentHistory(leadId, currentTerritoryId, territoryId, reason);
        
        // Update lead owner
        updateLeadOwner(leadId, territory.Owner__c);
        
        // Update metrics for both territories
        if (currentTerritoryId != null) {
            updateTerritoryMetrics(currentTerritoryId);
        }
        updateTerritoryMetrics(territoryId);
    }
    
    /**
     * @description Rebalance territories based on workload
     * @return Integer Number of leads reassigned
     */
    public static Integer rebalanceTerritories() {
        Integer reassignedCount = 0;
        
        List<Territory__c> territories = [
            SELECT Id, Name, Active_Leads__c, Owner__c, Max_Capacity__c,
                   Region__c, Industry_Focus__c
            FROM Territory__c
            WHERE Active__c = true
            ORDER BY Active_Leads__c DESC
        ];
        
        // Find overloaded and underloaded territories
        List<Territory__c> overloaded = new List<Territory__c>();
        List<Territory__c> underloaded = new List<Territory__c>();
        
        for (Territory__c territory : territories) {
            Decimal loadPercentage = (territory.Active_Leads__c / territory.Max_Capacity__c) * 100;
            
            if (loadPercentage > 90) {
                overloaded.add(territory);
            } else if (loadPercentage < 60) {
                underloaded.add(territory);
            }
        }
        
        // Rebalance from overloaded to underloaded
        for (Territory__c overloadedTerritory : overloaded) {
            List<Lead> leadsToReassign = getReassignableLeads(overloadedTerritory.Id, 10);
            
            for (Lead lead : leadsToReassign) {
                for (Territory__c underloadedTerritory : underloaded) {
                    if (isCompatibleTerritory(lead, underloadedTerritory)) {
                        manualAssignment(lead.Id, underloadedTerritory.Id, 'Workload Rebalancing');
                        reassignedCount++;
                        break;
                    }
                }
            }
        }
        
        return reassignedCount;
    }
    
    /**
     * @description Find eligible territories for a lead
     * @param lead The lead record
     * @return List<Territory__c> List of eligible territories
     */
    private static List<Territory__c> findEligibleTerritories(Lead lead) {
        String query = 'SELECT Id, Name, Region__c, Industry_Focus__c, Owner__c, ' +
                       'Active_Leads__c, Max_Capacity__c, Conversion_Rate__c ' +
                       'FROM Territory__c ' +
                       'WHERE Active__c = true ' +
                       'AND Active_Leads__c < Max_Capacity__c';
        
        // Add geographic filter
        if (String.isNotBlank(lead.State)) {
            query += ' AND (Region__c = \'' + lead.State + '\' OR Region__c = \'National\')';
        }
        
        // Add industry filter
        if (String.isNotBlank(lead.Industry)) {
            query += ' AND (Industry_Focus__c INCLUDES (\'' + lead.Industry + '\') OR Industry_Focus__c = null)';
        }
        
        query += ' ORDER BY Conversion_Rate__c DESC, Active_Leads__c ASC LIMIT 10';
        
        return Database.query(query);
    }
    
    /**
     * @description Select optimal territory from eligible list
     * @param lead The lead record
     * @param territories List of eligible territories
     * @return Territory__c The optimal territory
     */
    private static Territory__c selectOptimalTerritory(Lead lead, List<Territory__c> territories) {
        Map<Id, Decimal> territoryScores = new Map<Id, Decimal>();
        
        for (Territory__c territory : territories) {
            Decimal score = 0;
            
            // Geographic proximity score (30%)
            if (territory.Region__c == lead.State) {
                score += 30;
            } else if (territory.Region__c == 'National') {
                score += 15;
            }
            
            // Industry match score (25%)
            if (territory.Industry_Focus__c != null && 
                territory.Industry_Focus__c.contains(lead.Industry)) {
                score += 25;
            }
            
            // Workload balance score (25%)
            Decimal loadPercentage = (territory.Active_Leads__c / territory.Max_Capacity__c) * 100;
            score += (100 - loadPercentage) * 0.25;
            
            // Historical performance score (20%)
            if (territory.Conversion_Rate__c != null) {
                score += territory.Conversion_Rate__c * 0.2;
            }
            
            territoryScores.put(territory.Id, score);
        }
        
        // Find territory with highest score
        Id optimalTerritoryId;
        Decimal maxScore = 0;
        
        for (Id territoryId : territoryScores.keySet()) {
            if (territoryScores.get(territoryId) > maxScore) {
                maxScore = territoryScores.get(territoryId);
                optimalTerritoryId = territoryId;
            }
        }
        
        return [SELECT Id, Name, Owner__c FROM Territory__c WHERE Id = :optimalTerritoryId];
    }
    
    /**
     * @description Create assignment history record
     */
    private static void createAssignmentHistory(Id leadId, Id fromTerritory, Id toTerritory, String reason) {
        Assignment_History__c history = new Assignment_History__c(
            Lead__c = leadId,
            From_Territory__c = fromTerritory,
            To_Territory__c = toTerritory,
            Reason__c = reason,
            Assigned_Date__c = System.now()
        );
        insert history;
    }
    
    /**
     * @description Update lead owner based on territory
     */
    private static void updateLeadOwner(Id leadId, Id newOwnerId) {
        Lead leadToUpdate = new Lead(
            Id = leadId,
            OwnerId = newOwnerId,
            Territory_Assigned__c = true,
            Territory_Assignment_Date__c = System.now()
        );
        update leadToUpdate;
    }
    
    /**
     * @description Update territory metrics
     */
    private static void updateTerritoryMetrics(Id territoryId) {
        Territory__c territory = [
            SELECT Id, 
                   (SELECT Id FROM Leads__r WHERE IsConverted = false),
                   (SELECT Id FROM Leads__r WHERE IsConverted = true)
            FROM Territory__c
            WHERE Id = :territoryId
        ];
        
        Integer activeLeads = territory.Leads__r.size();
        Integer convertedLeads = territory.Leads__r.size();
        
        territory.Active_Leads__c = activeLeads;
        territory.Conversion_Rate__c = activeLeads > 0 ? 
            (Decimal.valueOf(convertedLeads) / activeLeads) * 100 : 0;
        
        update territory;
    }
    
    /**
     * @description Get current territory for a lead
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
     * @description Get leads that can be reassigned from a territory
     */
    private static List<Lead> getReassignableLeads(Id territoryId, Integer limitCount) {
        return [
            SELECT Id, State, Industry, Rating
            FROM Lead
            WHERE Territory__c = :territoryId
            AND IsConverted = false
            AND Status != 'Working - Contacted'
            ORDER BY CreatedDate DESC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Check if lead is compatible with territory
     */
    private static Boolean isCompatibleTerritory(Lead lead, Territory__c territory) {
        // Check geographic compatibility
        if (territory.Region__c != 'National' && territory.Region__c != lead.State) {
            return false;
        }
        
        // Check industry compatibility
        if (territory.Industry_Focus__c != null && 
            !territory.Industry_Focus__c.contains(lead.Industry)) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @description Get lead details for assignment
     */
    private static Lead getLeadDetails(Id leadId) {
        return [
            SELECT Id, State, Industry, Rating, Company, AnnualRevenue
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
    }
    
    /**
     * @description Custom exception for territory operations
     */
    public class TerritoryException extends Exception {}
}