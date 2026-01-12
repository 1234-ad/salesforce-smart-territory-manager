## Installation Guide

### Prerequisites
- Salesforce Developer Edition or higher
- SFDX CLI installed
- Git installed
- VS Code with Salesforce Extensions (recommended)

### Step-by-Step Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/1234-ad/salesforce-smart-territory-manager.git
cd salesforce-smart-territory-manager
```

#### 2. Authenticate with Salesforce
```bash
# For production/developer org
sfdx auth:web:login -a myOrg

# For scratch org
sfdx auth:web:login -d -a DevHub
sfdx force:org:create -f config/project-scratch-def.json -a scratchOrg
```

#### 3. Deploy the Code
```bash
# Deploy to your org
sfdx force:source:deploy -p force-app/main/default -u myOrg

# Or push to scratch org
sfdx force:source:push -u scratchOrg
```

#### 4. Assign Permission Sets
```bash
sfdx force:user:permset:assign -n Territory_Manager_Admin -u myOrg
```

#### 5. Create Custom Objects
The following custom objects will be created:
- Territory__c
- Lead_Score__c
- Assignment_History__c

#### 6. Configure Custom Settings
Navigate to **Setup → Custom Settings** and configure:

**Territory_Settings__c**
- Max_Leads_Per_Rep__c: 50
- Auto_Assignment_Enabled__c: true
- Scoring_Threshold__c: 70
- Rebalance_Frequency__c: Daily

**Lead_Scoring_Weights__c**
- Demographic_Weight__c: 0.25
- Behavioral_Weight__c: 0.35
- Firmographic_Weight__c: 0.20
- Engagement_Weight__c: 0.20

#### 7. Schedule Batch Jobs
```apex
// Schedule daily territory rebalancing at 2 AM
System.schedule('Daily Territory Rebalance', '0 0 2 * * ?', new TerritoryRebalanceBatch());
```

#### 8. Add Lightning Components to Pages
1. Navigate to any Lead record page
2. Click **Setup → Edit Page**
3. Drag **Lead Score Card** component to the page
4. Save and activate

For Territory Dashboard:
1. Create a new Lightning App Page
2. Add **Territory Dashboard** component
3. Activate for desired profiles

#### 9. Load Sample Data (Optional)
```bash
sfdx force:data:tree:import -p data/sample-data-plan.json -u myOrg
```

### Verification

#### Test the Installation
1. Create a new Lead with complete information
2. Check if Lead Score is automatically calculated
3. Verify territory assignment
4. View the Lead Score Card on the Lead record page
5. Check Territory Dashboard for analytics

#### Run Tests
```bash
sfdx force:apex:test:run -l RunLocalTests -u myOrg -r human
```

Expected code coverage: 95%+

### Troubleshooting

#### Issue: Deployment Fails
**Solution**: Check API version compatibility. Update `sfdx-project.json` if needed.

#### Issue: Permission Errors
**Solution**: Ensure you've assigned the Territory_Manager_Admin permission set.

#### Issue: Triggers Not Firing
**Solution**: Check if triggers are active in Setup → Apex Triggers.

#### Issue: Components Not Visible
**Solution**: Verify Lightning Experience is enabled and components are activated on page layouts.

### Post-Installation Configuration

#### 1. Create Territories
Navigate to **Territories** tab and create your territories:
- Name: East Coast
- Region: NY, NJ, PA
- Industry Focus: Technology, Finance
- Max Capacity: 50

#### 2. Configure Assignment Rules
Set up territory rules in **Territory_Rule__mdt**:
- Geographic boundaries
- Industry specializations
- Company size ranges

#### 3. Set Up Email Templates
Create email templates for:
- New lead assignment notifications
- High-priority lead alerts
- Territory rebalance summaries

#### 4. Configure Dashboards
Create custom dashboards using:
- Territory performance reports
- Lead score distribution
- Conversion funnel analysis

### Maintenance

#### Regular Tasks
- Review territory assignments weekly
- Monitor lead score accuracy
- Adjust scoring weights based on conversion data
- Update territory capacities as team grows

#### Monthly Tasks
- Analyze territory performance
- Rebalance territories if needed
- Review and update assignment rules
- Check system health and logs

### Support
For issues or questions:
- GitHub Issues: [Create an issue](https://github.com/1234-ad/salesforce-smart-territory-manager/issues)
- Email: support@example.com
- Documentation: [Wiki](https://github.com/1234-ad/salesforce-smart-territory-manager/wiki)