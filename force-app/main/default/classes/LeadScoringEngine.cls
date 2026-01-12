/**
 * @description Advanced Lead Scoring Engine with multi-factor analysis
 * @author Smart Territory Manager Team
 * @date 2024
 */
public with sharing class LeadScoringEngine {
    
    // Scoring weights from custom settings
    private static final Decimal DEMOGRAPHIC_WEIGHT = 0.25;
    private static final Decimal BEHAVIORAL_WEIGHT = 0.35;
    private static final Decimal FIRMOGRAPHIC_WEIGHT = 0.20;
    private static final Decimal ENGAGEMENT_WEIGHT = 0.20;
    
    // Score thresholds
    private static final Decimal HOT_THRESHOLD = 80;
    private static final Decimal WARM_THRESHOLD = 60;
    private static final Decimal COLD_THRESHOLD = 40;
    
    /**
     * @description Calculate comprehensive score for a lead
     * @param leadId The ID of the lead to score
     * @return Lead_Score__c The calculated score record
     */
    public static Lead_Score__c calculateScore(Id leadId) {
        Lead lead = getLeadWithDetails(leadId);
        
        if (lead == null) {
            throw new LeadScoringException('Lead not found: ' + leadId);
        }
        
        Lead_Score__c score = new Lead_Score__c();
        score.Lead__c = leadId;
        score.Demographic_Score__c = calculateDemographicScore(lead);
        score.Behavioral_Score__c = calculateBehavioralScore(lead);
        score.Firmographic_Score__c = calculateFirmographicScore(lead);
        score.Engagement_Score__c = calculateEngagementScore(lead);
        
        // Calculate weighted total
        score.Total_Score__c = 
            (score.Demographic_Score__c * DEMOGRAPHIC_WEIGHT) +
            (score.Behavioral_Score__c * BEHAVIORAL_WEIGHT) +
            (score.Firmographic_Score__c * FIRMOGRAPHIC_WEIGHT) +
            (score.Engagement_Score__c * ENGAGEMENT_WEIGHT);
        
        score.Score_Grade__c = determineGrade(score.Total_Score__c);
        score.Last_Calculated__c = System.now();
        score.Conversion_Probability__c = calculateConversionProbability(score.Total_Score__c);
        
        upsert score Lead__c;
        
        // Update lead rating based on score
        updateLeadRating(leadId, score.Score_Grade__c);
        
        return score;
    }
    
    /**
     * @description Bulk calculate scores for multiple leads
     * @param leadIds Set of lead IDs to score
     * @return Map<Id, Lead_Score__c> Map of lead IDs to their scores
     */
    public static Map<Id, Lead_Score__c> calculateBulkScores(Set<Id> leadIds) {
        Map<Id, Lead_Score__c> scoreMap = new Map<Id, Lead_Score__c>();
        List<Lead_Score__c> scoresToUpsert = new List<Lead_Score__c>();
        
        for (Id leadId : leadIds) {
            try {
                Lead_Score__c score = calculateScore(leadId);
                scoreMap.put(leadId, score);
                scoresToUpsert.add(score);
            } catch (Exception e) {
                System.debug('Error scoring lead ' + leadId + ': ' + e.getMessage());
            }
        }
        
        if (!scoresToUpsert.isEmpty()) {
            upsert scoresToUpsert Lead__c;
        }
        
        return scoreMap;
    }
    
    /**
     * @description Calculate demographic score based on location, industry, title
     * @param lead The lead record
     * @return Decimal The demographic score (0-100)
     */
    private static Decimal calculateDemographicScore(Lead lead) {
        Decimal score = 0;
        
        // Industry scoring
        if (lead.Industry != null) {
            Map<String, Decimal> industryScores = new Map<String, Decimal>{
                'Technology' => 25,
                'Finance' => 23,
                'Healthcare' => 20,
                'Manufacturing' => 18,
                'Retail' => 15,
                'Other' => 10
            };
            score += industryScores.containsKey(lead.Industry) ? 
                     industryScores.get(lead.Industry) : 10;
        }
        
        // Title/Role scoring
        if (lead.Title != null) {
            String title = lead.Title.toLowerCase();
            if (title.contains('ceo') || title.contains('president') || title.contains('owner')) {
                score += 30;
            } else if (title.contains('vp') || title.contains('director') || title.contains('head')) {
                score += 25;
            } else if (title.contains('manager')) {
                score += 20;
            } else {
                score += 10;
            }
        }
        
        // Geographic scoring
        if (lead.Country != null) {
            Map<String, Decimal> countryScores = new Map<String, Decimal>{
                'United States' => 25,
                'Canada' => 23,
                'United Kingdom' => 22,
                'Germany' => 20,
                'Australia' => 20
            };
            score += countryScores.containsKey(lead.Country) ? 
                     countryScores.get(lead.Country) : 15;
        }
        
        // Company size indicator
        if (lead.NumberOfEmployees != null) {
            if (lead.NumberOfEmployees > 1000) {
                score += 20;
            } else if (lead.NumberOfEmployees > 500) {
                score += 15;
            } else if (lead.NumberOfEmployees > 100) {
                score += 10;
            } else {
                score += 5;
            }
        }
        
        return Math.min(score, 100);
    }
    
    /**
     * @description Calculate behavioral score based on engagement activities
     * @param lead The lead record
     * @return Decimal The behavioral score (0-100)
     */
    private static Decimal calculateBehavioralScore(Lead lead) {
        Decimal score = 0;
        
        // Website visits (from custom field)
        if (lead.Website_Visits__c != null) {
            score += Math.min(lead.Website_Visits__c * 2, 25);
        }
        
        // Email engagement
        if (lead.Email_Opens__c != null) {
            score += Math.min(lead.Email_Opens__c * 1.5, 20);
        }
        
        if (lead.Email_Clicks__c != null) {
            score += Math.min(lead.Email_Clicks__c * 3, 25);
        }
        
        // Content downloads
        if (lead.Content_Downloads__c != null) {
            score += Math.min(lead.Content_Downloads__c * 5, 20);
        }
        
        // Webinar attendance
        if (lead.Webinar_Attended__c) {
            score += 10;
        }
        
        return Math.min(score, 100);
    }
    
    /**
     * @description Calculate firmographic score based on company attributes
     * @param lead The lead record
     * @return Decimal The firmographic score (0-100)
     */
    private static Decimal calculateFirmographicScore(Lead lead) {
        Decimal score = 0;
        
        // Annual revenue
        if (lead.AnnualRevenue != null) {
            if (lead.AnnualRevenue > 100000000) {
                score += 30;
            } else if (lead.AnnualRevenue > 50000000) {
                score += 25;
            } else if (lead.AnnualRevenue > 10000000) {
                score += 20;
            } else if (lead.AnnualRevenue > 1000000) {
                score += 15;
            } else {
                score += 10;
            }
        }
        
        // Company growth indicators
        if (lead.Company_Growth_Rate__c != null) {
            score += Math.min(lead.Company_Growth_Rate__c * 2, 25);
        }
        
        // Technology stack
        if (lead.Technologies_Used__c != null) {
            Integer techCount = lead.Technologies_Used__c.split(';').size();
            score += Math.min(techCount * 5, 20);
        }
        
        // Funding status
        if (lead.Funding_Status__c == 'Series C+' || lead.Funding_Status__c == 'IPO') {
            score += 25;
        } else if (lead.Funding_Status__c == 'Series B') {
            score += 20;
        } else if (lead.Funding_Status__c == 'Series A') {
            score += 15;
        }
        
        return Math.min(score, 100);
    }
    
    /**
     * @description Calculate engagement score based on interactions
     * @param lead The lead record
     * @return Decimal The engagement score (0-100)
     */
    private static Decimal calculateEngagementScore(Lead lead) {
        Decimal score = 0;
        
        // Response time to emails
        if (lead.Avg_Response_Time_Hours__c != null) {
            if (lead.Avg_Response_Time_Hours__c < 2) {
                score += 25;
            } else if (lead.Avg_Response_Time_Hours__c < 24) {
                score += 20;
            } else if (lead.Avg_Response_Time_Hours__c < 48) {
                score += 15;
            } else {
                score += 10;
            }
        }
        
        // Meeting attendance
        if (lead.Meetings_Attended__c != null) {
            score += Math.min(lead.Meetings_Attended__c * 10, 25);
        }
        
        // Proposal requests
        if (lead.Proposal_Requested__c) {
            score += 20;
        }
        
        // Demo requests
        if (lead.Demo_Requested__c) {
            score += 15;
        }
        
        // Social media engagement
        if (lead.Social_Engagement_Score__c != null) {
            score += Math.min(lead.Social_Engagement_Score__c, 15);
        }
        
        return Math.min(score, 100);
    }
    
    /**
     * @description Determine letter grade based on total score
     * @param totalScore The total calculated score
     * @return String The grade (Hot/Warm/Cold)
     */
    private static String determineGrade(Decimal totalScore) {
        if (totalScore >= HOT_THRESHOLD) {
            return 'Hot';
        } else if (totalScore >= WARM_THRESHOLD) {
            return 'Warm';
        } else if (totalScore >= COLD_THRESHOLD) {
            return 'Cold';
        } else {
            return 'Ice Cold';
        }
    }
    
    /**
     * @description Calculate probability of conversion based on score
     * @param totalScore The total calculated score
     * @return Decimal Conversion probability percentage
     */
    private static Decimal calculateConversionProbability(Decimal totalScore) {
        // Sigmoid function for probability calculation
        Decimal probability = 100 / (1 + Math.exp(-0.1 * (totalScore - 50)));
        return probability.setScale(2);
    }
    
    /**
     * @description Update lead rating field based on score grade
     * @param leadId The lead ID
     * @param grade The score grade
     */
    private static void updateLeadRating(Id leadId, String grade) {
        Lead leadToUpdate = new Lead(Id = leadId);
        leadToUpdate.Rating = grade;
        update leadToUpdate;
    }
    
    /**
     * @description Query lead with all necessary fields for scoring
     * @param leadId The lead ID
     * @return Lead The lead record with all fields
     */
    private static Lead getLeadWithDetails(Id leadId) {
        return [
            SELECT Id, Industry, Title, Country, NumberOfEmployees, AnnualRevenue,
                   Website_Visits__c, Email_Opens__c, Email_Clicks__c, 
                   Content_Downloads__c, Webinar_Attended__c,
                   Company_Growth_Rate__c, Technologies_Used__c, Funding_Status__c,
                   Avg_Response_Time_Hours__c, Meetings_Attended__c,
                   Proposal_Requested__c, Demo_Requested__c, Social_Engagement_Score__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
    }
    
    /**
     * @description Custom exception for lead scoring errors
     */
    public class LeadScoringException extends Exception {}
}