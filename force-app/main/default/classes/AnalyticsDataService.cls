/**
 * @description Analytics data service for territory and lead metrics
 * @author Smart Territory Manager Team
 * @date 2024
 */
public with sharing class AnalyticsDataService {
    
    /**
     * @description Get comprehensive territory metrics
     * @param territoryId The territory ID
     * @return TerritoryMetrics Territory performance data
     */
    @AuraEnabled(cacheable=true)
    public static TerritoryMetrics getTerritoryMetrics(Id territoryId) {
        TerritoryMetrics metrics = new TerritoryMetrics();
        
        Territory__c territory = [
            SELECT Id, Name, Region__c, Active_Leads__c, Conversion_Rate__c,
                   Total_Revenue__c, Avg_Deal_Size__c
            FROM Territory__c
            WHERE Id = :territoryId
            LIMIT 1
        ];
        
        metrics.territoryId = territory.Id;
        metrics.territoryName = territory.Name;
        metrics.region = territory.Region__c;
        metrics.activeLeads = Integer.valueOf(territory.Active_Leads__c);
        metrics.conversionRate = territory.Conversion_Rate__c;
        metrics.totalRevenue = territory.Total_Revenue__c;
        metrics.avgDealSize = territory.Avg_Deal_Size__c;
        
        // Get lead distribution by status
        metrics.leadsByStatus = getLeadsByStatus(territoryId);
        
        // Get lead distribution by score grade
        metrics.leadsByGrade = getLeadsByGrade(territoryId);
        
        // Get monthly trend data
        metrics.monthlyTrends = getMonthlyTrends(territoryId);
        
        // Get top performing reps
        metrics.topReps = getTopReps(territoryId);
        
        return metrics;
    }
    
    /**
     * @description Get dashboard data for all territories
     * @return DashboardData Complete dashboard metrics
     */
    @AuraEnabled(cacheable=true)
    public static DashboardData getDashboardData() {
        DashboardData dashboard = new DashboardData();
        
        // Overall statistics
        dashboard.totalLeads = [SELECT COUNT() FROM Lead WHERE IsConverted = false];
        dashboard.totalTerritories = [SELECT COUNT() FROM Territory__c WHERE Active__c = true];
        dashboard.avgConversionRate = calculateAvgConversionRate();
        dashboard.totalRevenue = calculateTotalRevenue();
        
        // Territory performance comparison
        dashboard.territoryComparison = getTerritoryComparison();
        
        // Lead score distribution
        dashboard.scoreDistribution = getScoreDistribution();
        
        // Recent assignments
        dashboard.recentAssignments = getRecentAssignments(10);
        
        // Conversion funnel
        dashboard.conversionFunnel = getConversionFunnel();
        
        return dashboard;
    }
    
    /**
     * @description Get lead performance metrics
     * @param leadId The lead ID
     * @return LeadMetrics Lead performance data
     */
    @AuraEnabled(cacheable=true)
    public static LeadMetrics getLeadMetrics(Id leadId) {
        LeadMetrics metrics = new LeadMetrics();
        
        Lead lead = [
            SELECT Id, Name, Company, Status, Rating, CreatedDate,
                   LastActivityDate, LastModifiedDate
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
        
        metrics.leadId = lead.Id;
        metrics.leadName = lead.Name;
        metrics.company = lead.Company;
        metrics.status = lead.Status;
        metrics.rating = lead.Rating;
        metrics.createdDate = lead.CreatedDate;
        metrics.lastActivity = lead.LastActivityDate;
        
        // Get lead score
        List<Lead_Score__c> scores = [
            SELECT Total_Score__c, Score_Grade__c, Conversion_Probability__c,
                   Demographic_Score__c, Behavioral_Score__c, 
                   Firmographic_Score__c, Engagement_Score__c
            FROM Lead_Score__c
            WHERE Lead__c = :leadId
            ORDER BY Last_Calculated__c DESC
            LIMIT 1
        ];
        
        if (!scores.isEmpty()) {
            metrics.totalScore = scores[0].Total_Score__c;
            metrics.scoreGrade = scores[0].Score_Grade__c;
            metrics.conversionProbability = scores[0].Conversion_Probability__c;
            metrics.demographicScore = scores[0].Demographic_Score__c;
            metrics.behavioralScore = scores[0].Behavioral_Score__c;
            metrics.firmographicScore = scores[0].Firmographic_Score__c;
            metrics.engagementScore = scores[0].Engagement_Score__c;
        }
        
        // Get activity timeline
        metrics.activityTimeline = getActivityTimeline(leadId);
        
        // Get assignment history
        metrics.assignmentHistory = getAssignmentHistory(leadId);
        
        return metrics;
    }
    
    /**
     * @description Get leads by status for a territory
     */
    private static Map<String, Integer> getLeadsByStatus(Id territoryId) {
        Map<String, Integer> statusMap = new Map<String, Integer>();
        
        for (AggregateResult ar : [
            SELECT Status, COUNT(Id) cnt
            FROM Lead
            WHERE Territory__c = :territoryId
            AND IsConverted = false
            GROUP BY Status
        ]) {
            statusMap.put((String)ar.get('Status'), (Integer)ar.get('cnt'));
        }
        
        return statusMap;
    }
    
    /**
     * @description Get leads by score grade for a territory
     */
    private static Map<String, Integer> getLeadsByGrade(Id territoryId) {
        Map<String, Integer> gradeMap = new Map<String, Integer>();
        
        for (AggregateResult ar : [
            SELECT Rating, COUNT(Id) cnt
            FROM Lead
            WHERE Territory__c = :territoryId
            AND IsConverted = false
            GROUP BY Rating
        ]) {
            gradeMap.put((String)ar.get('Rating'), (Integer)ar.get('cnt'));
        }
        
        return gradeMap;
    }
    
    /**
     * @description Get monthly trend data
     */
    private static List<MonthlyTrend> getMonthlyTrends(Id territoryId) {
        List<MonthlyTrend> trends = new List<MonthlyTrend>();
        
        for (AggregateResult ar : [
            SELECT CALENDAR_MONTH(CreatedDate) month, 
                   CALENDAR_YEAR(CreatedDate) year,
                   COUNT(Id) leadCount
            FROM Lead
            WHERE Territory__c = :territoryId
            AND CreatedDate = LAST_N_MONTHS:12
            GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_YEAR(CreatedDate)
            ORDER BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
        ]) {
            MonthlyTrend trend = new MonthlyTrend();
            trend.month = (Integer)ar.get('month');
            trend.year = (Integer)ar.get('year');
            trend.leadCount = (Integer)ar.get('leadCount');
            trends.add(trend);
        }
        
        return trends;
    }
    
    /**
     * @description Get top performing reps
     */
    private static List<RepPerformance> getTopReps(Id territoryId) {
        List<RepPerformance> reps = new List<RepPerformance>();
        
        for (AggregateResult ar : [
            SELECT Owner.Name, COUNT(Id) leadCount, 
                   SUM(Amount) totalRevenue
            FROM Opportunity
            WHERE Territory__c = :territoryId
            AND StageName = 'Closed Won'
            AND CloseDate = THIS_YEAR
            GROUP BY Owner.Name
            ORDER BY SUM(Amount) DESC
            LIMIT 5
        ]) {
            RepPerformance rep = new RepPerformance();
            rep.repName = (String)ar.get('Name');
            rep.leadCount = (Integer)ar.get('leadCount');
            rep.totalRevenue = (Decimal)ar.get('totalRevenue');
            reps.add(rep);
        }
        
        return reps;
    }
    
    /**
     * @description Calculate average conversion rate
     */
    private static Decimal calculateAvgConversionRate() {
        AggregateResult ar = [
            SELECT AVG(Conversion_Rate__c) avgRate
            FROM Territory__c
            WHERE Active__c = true
        ];
        
        return (Decimal)ar.get('avgRate');
    }
    
    /**
     * @description Calculate total revenue
     */
    private static Decimal calculateTotalRevenue() {
        AggregateResult ar = [
            SELECT SUM(Total_Revenue__c) totalRev
            FROM Territory__c
            WHERE Active__c = true
        ];
        
        return (Decimal)ar.get('totalRev');
    }
    
    /**
     * @description Get territory comparison data
     */
    private static List<TerritoryComparison> getTerritoryComparison() {
        List<TerritoryComparison> comparisons = new List<TerritoryComparison>();
        
        for (Territory__c territory : [
            SELECT Name, Active_Leads__c, Conversion_Rate__c, Total_Revenue__c
            FROM Territory__c
            WHERE Active__c = true
            ORDER BY Total_Revenue__c DESC
            LIMIT 10
        ]) {
            TerritoryComparison comp = new TerritoryComparison();
            comp.territoryName = territory.Name;
            comp.activeLeads = Integer.valueOf(territory.Active_Leads__c);
            comp.conversionRate = territory.Conversion_Rate__c;
            comp.totalRevenue = territory.Total_Revenue__c;
            comparisons.add(comp);
        }
        
        return comparisons;
    }
    
    /**
     * @description Get score distribution
     */
    private static Map<String, Integer> getScoreDistribution() {
        Map<String, Integer> distribution = new Map<String, Integer>();
        
        for (AggregateResult ar : [
            SELECT Score_Grade__c grade, COUNT(Id) cnt
            FROM Lead_Score__c
            WHERE CreatedDate = THIS_MONTH
            GROUP BY Score_Grade__c
        ]) {
            distribution.put((String)ar.get('grade'), (Integer)ar.get('cnt'));
        }
        
        return distribution;
    }
    
    /**
     * @description Get recent assignments
     */
    private static List<RecentAssignment> getRecentAssignments(Integer limitCount) {
        List<RecentAssignment> assignments = new List<RecentAssignment>();
        
        for (Assignment_History__c history : [
            SELECT Lead__r.Name, To_Territory__r.Name, Reason__c, Assigned_Date__c
            FROM Assignment_History__c
            ORDER BY Assigned_Date__c DESC
            LIMIT :limitCount
        ]) {
            RecentAssignment assignment = new RecentAssignment();
            assignment.leadName = history.Lead__r.Name;
            assignment.territoryName = history.To_Territory__r.Name;
            assignment.reason = history.Reason__c;
            assignment.assignedDate = history.Assigned_Date__c;
            assignments.add(assignment);
        }
        
        return assignments;
    }
    
    /**
     * @description Get conversion funnel data
     */
    private static ConversionFunnel getConversionFunnel() {
        ConversionFunnel funnel = new ConversionFunnel();
        
        funnel.totalLeads = [SELECT COUNT() FROM Lead WHERE CreatedDate = THIS_YEAR];
        funnel.qualified = [SELECT COUNT() FROM Lead WHERE Status = 'Qualified' AND CreatedDate = THIS_YEAR];
        funnel.contacted = [SELECT COUNT() FROM Lead WHERE Status LIKE 'Working%' AND CreatedDate = THIS_YEAR];
        funnel.converted = [SELECT COUNT() FROM Lead WHERE IsConverted = true AND ConvertedDate = THIS_YEAR];
        
        return funnel;
    }
    
    /**
     * @description Get activity timeline for a lead
     */
    private static List<ActivityRecord> getActivityTimeline(Id leadId) {
        List<ActivityRecord> timeline = new List<ActivityRecord>();
        
        for (Task task : [
            SELECT Subject, Status, ActivityDate, CreatedDate
            FROM Task
            WHERE WhoId = :leadId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ]) {
            ActivityRecord activity = new ActivityRecord();
            activity.subject = task.Subject;
            activity.status = task.Status;
            activity.activityDate = task.ActivityDate;
            timeline.add(activity);
        }
        
        return timeline;
    }
    
    /**
     * @description Get assignment history for a lead
     */
    private static List<AssignmentRecord> getAssignmentHistory(Id leadId) {
        List<AssignmentRecord> history = new List<AssignmentRecord>();
        
        for (Assignment_History__c ah : [
            SELECT From_Territory__r.Name, To_Territory__r.Name, 
                   Reason__c, Assigned_Date__c
            FROM Assignment_History__c
            WHERE Lead__c = :leadId
            ORDER BY Assigned_Date__c DESC
        ]) {
            AssignmentRecord record = new AssignmentRecord();
            record.fromTerritory = ah.From_Territory__r.Name;
            record.toTerritory = ah.To_Territory__r.Name;
            record.reason = ah.Reason__c;
            record.assignedDate = ah.Assigned_Date__c;
            history.add(record);
        }
        
        return history;
    }
    
    // Wrapper classes for data structures
    
    public class TerritoryMetrics {
        @AuraEnabled public Id territoryId { get; set; }
        @AuraEnabled public String territoryName { get; set; }
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public Integer activeLeads { get; set; }
        @AuraEnabled public Decimal conversionRate { get; set; }
        @AuraEnabled public Decimal totalRevenue { get; set; }
        @AuraEnabled public Decimal avgDealSize { get; set; }
        @AuraEnabled public Map<String, Integer> leadsByStatus { get; set; }
        @AuraEnabled public Map<String, Integer> leadsByGrade { get; set; }
        @AuraEnabled public List<MonthlyTrend> monthlyTrends { get; set; }
        @AuraEnabled public List<RepPerformance> topReps { get; set; }
    }
    
    public class DashboardData {
        @AuraEnabled public Integer totalLeads { get; set; }
        @AuraEnabled public Integer totalTerritories { get; set; }
        @AuraEnabled public Decimal avgConversionRate { get; set; }
        @AuraEnabled public Decimal totalRevenue { get; set; }
        @AuraEnabled public List<TerritoryComparison> territoryComparison { get; set; }
        @AuraEnabled public Map<String, Integer> scoreDistribution { get; set; }
        @AuraEnabled public List<RecentAssignment> recentAssignments { get; set; }
        @AuraEnabled public ConversionFunnel conversionFunnel { get; set; }
    }
    
    public class LeadMetrics {
        @AuraEnabled public Id leadId { get; set; }
        @AuraEnabled public String leadName { get; set; }
        @AuraEnabled public String company { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String rating { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public Date lastActivity { get; set; }
        @AuraEnabled public Decimal totalScore { get; set; }
        @AuraEnabled public String scoreGrade { get; set; }
        @AuraEnabled public Decimal conversionProbability { get; set; }
        @AuraEnabled public Decimal demographicScore { get; set; }
        @AuraEnabled public Decimal behavioralScore { get; set; }
        @AuraEnabled public Decimal firmographicScore { get; set; }
        @AuraEnabled public Decimal engagementScore { get; set; }
        @AuraEnabled public List<ActivityRecord> activityTimeline { get; set; }
        @AuraEnabled public List<AssignmentRecord> assignmentHistory { get; set; }
    }
    
    public class MonthlyTrend {
        @AuraEnabled public Integer month { get; set; }
        @AuraEnabled public Integer year { get; set; }
        @AuraEnabled public Integer leadCount { get; set; }
    }
    
    public class RepPerformance {
        @AuraEnabled public String repName { get; set; }
        @AuraEnabled public Integer leadCount { get; set; }
        @AuraEnabled public Decimal totalRevenue { get; set; }
    }
    
    public class TerritoryComparison {
        @AuraEnabled public String territoryName { get; set; }
        @AuraEnabled public Integer activeLeads { get; set; }
        @AuraEnabled public Decimal conversionRate { get; set; }
        @AuraEnabled public Decimal totalRevenue { get; set; }
    }
    
    public class RecentAssignment {
        @AuraEnabled public String leadName { get; set; }
        @AuraEnabled public String territoryName { get; set; }
        @AuraEnabled public String reason { get; set; }
        @AuraEnabled public DateTime assignedDate { get; set; }
    }
    
    public class ConversionFunnel {
        @AuraEnabled public Integer totalLeads { get; set; }
        @AuraEnabled public Integer qualified { get; set; }
        @AuraEnabled public Integer contacted { get; set; }
        @AuraEnabled public Integer converted { get; set; }
    }
    
    public class ActivityRecord {
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date activityDate { get; set; }
    }
    
    public class AssignmentRecord {
        @AuraEnabled public String fromTerritory { get; set; }
        @AuraEnabled public String toTerritory { get; set; }
        @AuraEnabled public String reason { get; set; }
        @AuraEnabled public DateTime assignedDate { get; set; }
    }
}