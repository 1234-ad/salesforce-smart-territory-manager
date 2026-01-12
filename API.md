# API Documentation

## REST API Endpoints

### Lead Scoring API

#### Calculate Lead Score
```
POST /services/apexrest/LeadScoring/calculate
```

**Request Body:**
```json
{
  "leadId": "00Q5g00000XYZ123"
}
```

**Response:**
```json
{
  "success": true,
  "leadScore": {
    "totalScore": 85.5,
    "scoreGrade": "Hot",
    "demographicScore": 75.0,
    "behavioralScore": 90.0,
    "firmographicScore": 80.0,
    "engagementScore": 95.0,
    "conversionProbability": 78.5
  }
}
```

#### Bulk Calculate Scores
```
POST /services/apexrest/LeadScoring/bulk
```

**Request Body:**
```json
{
  "leadIds": ["00Q5g00000XYZ123", "00Q5g00000XYZ456"]
}
```

---

### Territory Management API

#### Assign Lead to Territory
```
POST /services/apexrest/Territory/assign
```

**Request Body:**
```json
{
  "leadId": "00Q5g00000XYZ123"
}
```

**Response:**
```json
{
  "success": true,
  "territoryId": "a005g00000ABC123",
  "territoryName": "East Coast Tech",
  "assignedTo": "John Smith"
}
```

#### Manual Assignment
```
POST /services/apexrest/Territory/manual
```

**Request Body:**
```json
{
  "leadId": "00Q5g00000XYZ123",
  "territoryId": "a005g00000ABC123",
  "reason": "Customer request"
}
```

#### Rebalance Territories
```
POST /services/apexrest/Territory/rebalance
```

**Response:**
```json
{
  "success": true,
  "reassignedCount": 15,
  "message": "Successfully rebalanced 15 leads across territories"
}
```

---

### Analytics API

#### Get Territory Metrics
```
GET /services/apexrest/Territory/analytics?territoryId=a005g00000ABC123
```

**Response:**
```json
{
  "territoryId": "a005g00000ABC123",
  "territoryName": "East Coast Tech",
  "activeLeads": 45,
  "conversionRate": 23.5,
  "totalRevenue": 1250000,
  "avgDealSize": 50000,
  "leadsByStatus": {
    "Open": 20,
    "Working": 15,
    "Qualified": 10
  }
}
```

#### Get Dashboard Data
```
GET /services/apexrest/Dashboard/metrics
```

**Response:**
```json
{
  "totalLeads": 500,
  "totalTerritories": 10,
  "avgConversionRate": 25.3,
  "totalRevenue": 5000000,
  "scoreDistribution": {
    "Hot": 150,
    "Warm": 200,
    "Cold": 150
  }
}
```

---

## Apex API Reference

### LeadScoringEngine Class

#### calculateScore(Id leadId)
Calculate comprehensive score for a single lead.

**Parameters:**
- `leadId` (Id): The ID of the lead to score

**Returns:**
- `Lead_Score__c`: The calculated score record

**Example:**
```apex
Lead_Score__c score = LeadScoringEngine.calculateScore(leadId);
System.debug('Total Score: ' + score.Total_Score__c);
```

#### calculateBulkScores(Set<Id> leadIds)
Calculate scores for multiple leads in bulk.

**Parameters:**
- `leadIds` (Set<Id>): Set of lead IDs to score

**Returns:**
- `Map<Id, Lead_Score__c>`: Map of lead IDs to their scores

**Example:**
```apex
Set<Id> leadIds = new Set<Id>{'00Q...', '00Q...'};
Map<Id, Lead_Score__c> scores = LeadScoringEngine.calculateBulkScores(leadIds);
```

---

### TerritoryManager Class

#### assignLead(Id leadId)
Assign lead to optimal territory based on multiple criteria.

**Parameters:**
- `leadId` (Id): The lead to assign

**Returns:**
- `Territory__c`: The assigned territory

**Example:**
```apex
Territory__c territory = TerritoryManager.assignLead(leadId);
System.debug('Assigned to: ' + territory.Name);
```

#### manualAssignment(Id leadId, Id territoryId, String reason)
Manually assign lead to specific territory.

**Parameters:**
- `leadId` (Id): The lead to assign
- `territoryId` (Id): The target territory
- `reason` (String): Reason for manual assignment

**Example:**
```apex
TerritoryManager.manualAssignment(leadId, territoryId, 'Customer request');
```

#### rebalanceTerritories()
Rebalance territories based on workload.

**Returns:**
- `Integer`: Number of leads reassigned

**Example:**
```apex
Integer reassigned = TerritoryManager.rebalanceTerritories();
System.debug('Reassigned ' + reassigned + ' leads');
```

---

### LeadAssignmentOrchestrator Class

#### processNewLead(Id leadId)
Process new lead through complete assignment workflow.

**Parameters:**
- `leadId` (Id): The lead to process

**Returns:**
- `AssignmentResult`: Result of the assignment process

**Example:**
```apex
LeadAssignmentOrchestrator.AssignmentResult result = 
    LeadAssignmentOrchestrator.processNewLead(leadId);
    
if (result.success) {
    System.debug('Lead assigned to: ' + result.territoryName);
}
```

#### bulkProcessLeads(Set<Id> leadIds)
Bulk process multiple leads.

**Parameters:**
- `leadIds` (Set<Id>): Set of lead IDs to process

**Returns:**
- `List<AssignmentResult>`: Results for each lead

---

### AnalyticsDataService Class

#### getTerritoryMetrics(Id territoryId)
Get comprehensive territory metrics.

**Parameters:**
- `territoryId` (Id): The territory ID

**Returns:**
- `TerritoryMetrics`: Territory performance data

**Example:**
```apex
AnalyticsDataService.TerritoryMetrics metrics = 
    AnalyticsDataService.getTerritoryMetrics(territoryId);
    
System.debug('Active Leads: ' + metrics.activeLeads);
System.debug('Conversion Rate: ' + metrics.conversionRate);
```

#### getDashboardData()
Get dashboard data for all territories.

**Returns:**
- `DashboardData`: Complete dashboard metrics

**Example:**
```apex
AnalyticsDataService.DashboardData dashboard = 
    AnalyticsDataService.getDashboardData();
    
System.debug('Total Leads: ' + dashboard.totalLeads);
```

#### getLeadMetrics(Id leadId)
Get lead performance metrics.

**Parameters:**
- `leadId` (Id): The lead ID

**Returns:**
- `LeadMetrics`: Lead performance data

---

## Batch Jobs

### TerritoryRebalanceBatch

Schedule daily territory rebalancing:

```apex
// Schedule at 2 AM daily
System.schedule('Daily Rebalance', '0 0 2 * * ?', new TerritoryRebalanceBatch());

// Execute immediately
Database.executeBatch(new TerritoryRebalanceBatch(), 200);
```

---

## Error Handling

All API methods throw custom exceptions:

- `LeadScoringEngine.LeadScoringException`
- `TerritoryManager.TerritoryException`

**Example:**
```apex
try {
    Lead_Score__c score = LeadScoringEngine.calculateScore(leadId);
} catch (LeadScoringEngine.LeadScoringException e) {
    System.debug('Scoring error: ' + e.getMessage());
}
```

---

## Rate Limits

- REST API: 100 requests per minute per user
- Bulk operations: Maximum 200 records per transaction
- Batch jobs: Maximum 50 million records per 24 hours

---

## Authentication

REST API endpoints require Salesforce OAuth 2.0 authentication:

```bash
curl -X POST https://login.salesforce.com/services/oauth2/token \
  -d "grant_type=password" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "username=YOUR_USERNAME" \
  -d "password=YOUR_PASSWORD"
```

Use the returned access token in API requests:

```bash
curl -X POST https://yourinstance.salesforce.com/services/apexrest/LeadScoring/calculate \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"leadId": "00Q5g00000XYZ123"}'
```