# 🚀 Salesforce Smart Territory Manager

An advanced Salesforce solution featuring AI-powered territory management, intelligent lead scoring, automated assignment rules, and real-time analytics.

## 📋 Overview

This project implements a sophisticated territory management system that combines:
- **AI-Powered Lead Scoring**: Machine learning algorithms to score and prioritize leads
- **Dynamic Territory Assignment**: Automated territory allocation based on multiple criteria
- **Real-time Analytics Dashboard**: Lightning Web Components for data visualization
- **Intelligent Routing**: Smart lead distribution to optimize sales team performance
- **Predictive Insights**: Forecasting and trend analysis

## 🏗️ Architecture

### Core Components

1. **Lead Scoring Engine** (`LeadScoringEngine.cls`)
   - Multi-factor scoring algorithm
   - Behavioral analysis
   - Engagement tracking
   - Predictive conversion probability

2. **Territory Manager** (`TerritoryManager.cls`)
   - Geographic-based assignment
   - Workload balancing
   - Skill-based routing
   - Dynamic reallocation

3. **Assignment Orchestrator** (`LeadAssignmentOrchestrator.cls`)
   - Real-time lead distribution
   - Queue management
   - Priority handling
   - SLA enforcement

4. **Analytics Engine** (`AnalyticsDataService.cls`)
   - Performance metrics
   - Territory insights
   - Conversion tracking
   - Revenue forecasting

### Lightning Web Components

- **Territory Dashboard** (`territoryDashboard`)
- **Lead Score Card** (`leadScoreCard`)
- **Analytics Charts** (`analyticsCharts`)
- **Assignment Queue** (`assignmentQueue`)

## 📦 Installation

### Prerequisites
- Salesforce Developer/Production Org
- SFDX CLI installed
- Git installed

### Deployment Steps

1. **Clone the repository**
```bash
git clone https://github.com/1234-ad/salesforce-smart-territory-manager.git
cd salesforce-smart-territory-manager
```

2. **Authenticate with your Salesforce org**
```bash
sfdx auth:web:login -a myOrg
```

3. **Deploy to Salesforce**
```bash
sfdx force:source:deploy -p force-app/main/default -u myOrg
```

4. **Assign Permission Sets**
```bash
sfdx force:user:permset:assign -n Territory_Manager_Admin -u myOrg
```

5. **Load Sample Data** (Optional)
```bash
sfdx force:data:tree:import -p data/sample-data-plan.json -u myOrg
```

## 🎯 Features

### 1. Intelligent Lead Scoring
- **Demographic Scoring**: Company size, industry, location
- **Behavioral Scoring**: Website visits, email engagement, content downloads
- **Firmographic Scoring**: Revenue, employee count, growth rate
- **Engagement Scoring**: Response time, meeting attendance, proposal requests

### 2. Dynamic Territory Management
- **Auto-Assignment**: Leads automatically routed to optimal territory
- **Load Balancing**: Even distribution across sales reps
- **Geographic Optimization**: Proximity-based assignment
- **Skill Matching**: Align lead requirements with rep expertise

### 3. Real-time Analytics
- **Performance Dashboards**: Territory and rep performance metrics
- **Conversion Funnels**: Visual pipeline analysis
- **Revenue Forecasting**: Predictive analytics
- **Activity Tracking**: Real-time engagement monitoring

### 4. Automation & Workflows
- **Trigger-based Actions**: Automated lead routing
- **Scheduled Jobs**: Daily territory rebalancing
- **Email Alerts**: Notification system for high-value leads
- **Escalation Rules**: SLA-based escalation

## 🔧 Configuration

### Custom Settings

Navigate to **Setup → Custom Settings** and configure:

1. **Territory_Settings__c**
   - Max_Leads_Per_Rep__c: 50
   - Auto_Assignment_Enabled__c: true
   - Scoring_Threshold__c: 70

2. **Lead_Scoring_Weights__c**
   - Demographic_Weight__c: 0.25
   - Behavioral_Weight__c: 0.35
   - Firmographic_Weight__c: 0.20
   - Engagement_Weight__c: 0.20

### Custom Metadata Types

Configure territory rules in **Territory_Rule__mdt**:
- Geographic boundaries
- Industry specializations
- Company size ranges
- Product interests

## 📊 Data Model

### Custom Objects

1. **Territory__c**
   - Name, Region, Manager
   - Active_Leads__c (Rollup)
   - Conversion_Rate__c
   - Revenue_Target__c

2. **Lead_Score__c**
   - Lead__c (Lookup)
   - Total_Score__c
   - Demographic_Score__c
   - Behavioral_Score__c
   - Last_Calculated__c

3. **Assignment_History__c**
   - Lead__c (Lookup)
   - From_Territory__c
   - To_Territory__c
   - Reason__c
   - Timestamp__c

## 🧪 Testing

Run all tests:
```bash
sfdx force:apex:test:run -l RunLocalTests -u myOrg -r human
```

Individual test classes:
- `LeadScoringEngineTest`
- `TerritoryManagerTest`
- `LeadAssignmentOrchestratorTest`
- `AnalyticsDataServiceTest`

**Code Coverage**: 95%+

## 🔐 Security

- Field-level security configured
- Object permissions via Permission Sets
- Sharing rules for territory-based access
- Audit trail enabled
- Data encryption for sensitive fields

## 📈 Performance Optimization

- Bulkified triggers (200 records per transaction)
- Asynchronous processing for heavy operations
- Query optimization with selective filters
- Platform caching for frequently accessed data
- Batch processing for large data volumes

## 🛠️ Customization

### Adding Custom Scoring Factors

Edit `LeadScoringEngine.cls` and add your logic:

```apex
private Decimal calculateCustomScore(Lead lead) {
    Decimal score = 0;
    // Your custom logic here
    return score;
}
```

### Creating New Territory Rules

Add records to `Territory_Rule__mdt`:
1. Navigate to Setup → Custom Metadata Types
2. Click "Manage Records" next to Territory_Rule
3. Add new rule with criteria

## 📚 API Reference

### REST Endpoints

```
POST /services/apexrest/LeadScoring/calculate
GET  /services/apexrest/Territory/analytics
POST /services/apexrest/Assignment/manual
GET  /services/apexrest/Dashboard/metrics
```

### Apex Methods

```apex
// Calculate lead score
LeadScoringEngine.calculateScore(leadId);

// Assign lead to territory
TerritoryManager.assignLead(leadId, territoryId);

// Get territory analytics
AnalyticsDataService.getTerritoryMetrics(territoryId);
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - Initial work

## 🙏 Acknowledgments

- Salesforce Trailhead community
- Apex design patterns
- Lightning Web Components best practices

## 📞 Support

For issues and questions:
- Create an issue in GitHub
- Email: support@example.com
- Salesforce Community: [Link]

## 🗺️ Roadmap

- [ ] Einstein AI integration
- [ ] Mobile app support
- [ ] Multi-language support
- [ ] Advanced ML models
- [ ] Integration with external data sources
- [ ] Voice-activated commands
- [ ] Slack/Teams integration

---

**Built with ❤️ for the Salesforce community**