# Contributing to Smart Territory Manager

First off, thank you for considering contributing to Smart Territory Manager! It's people like you that make this project such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps to reproduce the problem**
* **Provide specific examples**
* **Describe the behavior you observed and what you expected**
* **Include screenshots if possible**
* **Include your Salesforce org edition and API version**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a detailed description of the suggested enhancement**
* **Explain why this enhancement would be useful**
* **List any similar features in other tools**

### Pull Requests

* Fill in the required template
* Follow the Salesforce coding standards
* Include appropriate test coverage (minimum 75%)
* Update documentation as needed
* End all files with a newline

## Development Process

### Setting Up Your Development Environment

1. **Fork the repository**
```bash
git clone https://github.com/YOUR_USERNAME/salesforce-smart-territory-manager.git
cd salesforce-smart-territory-manager
```

2. **Create a scratch org**
```bash
sfdx force:org:create -f config/project-scratch-def.json -a dev-scratch
sfdx force:source:push -u dev-scratch
```

3. **Create a branch**
```bash
git checkout -b feature/your-feature-name
```

### Coding Standards

#### Apex
* Use descriptive variable and method names
* Add JavaDoc comments for all public methods
* Follow Salesforce best practices for bulkification
* Avoid SOQL/DML in loops
* Use proper exception handling

**Example:**
```apex
/**
 * @description Calculate lead score with proper error handling
 * @param leadId The ID of the lead to score
 * @return Lead_Score__c The calculated score
 * @throws LeadScoringException if lead not found
 */
public static Lead_Score__c calculateScore(Id leadId) {
    // Implementation
}
```

#### Lightning Web Components
* Use semantic HTML
* Follow Lightning Design System guidelines
* Add JSDoc comments
* Use proper error handling
* Make components accessible (ARIA labels)

**Example:**
```javascript
/**
 * Load territory metrics from server
 * @returns {Promise} Promise resolving to territory data
 */
loadTerritoryMetrics() {
    return getTerritoryMetrics({ territoryId: this.recordId })
        .then(result => {
            this.territoryMetrics = result;
        })
        .catch(error => {
            this.handleError(error);
        });
}
```

### Testing

All contributions must include appropriate test coverage:

* **Apex Classes**: Minimum 75% coverage (aim for 90%+)
* **Triggers**: 100% coverage required
* **Lightning Components**: Unit tests using Jest

**Running Tests:**
```bash
# Apex tests
sfdx force:apex:test:run -l RunLocalTests -r human

# LWC tests
npm run test:unit
```

**Example Test Class:**
```apex
@isTest
private class LeadScoringEngineTest {
    
    @testSetup
    static void setup() {
        // Create test data
    }
    
    @isTest
    static void testCalculateScore() {
        // Test implementation
        Test.startTest();
        Lead_Score__c score = LeadScoringEngine.calculateScore(leadId);
        Test.stopTest();
        
        System.assertNotEquals(null, score);
        System.assert(score.Total_Score__c > 0);
    }
}
```

### Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters
* Reference issues and pull requests after the first line

**Example:**
```
Add lead scoring calculation for behavioral metrics

- Implement email engagement scoring
- Add website visit tracking
- Include content download metrics

Closes #123
```

### Documentation

* Update README.md if you change functionality
* Update API.md for any API changes
* Add inline comments for complex logic
* Update INSTALLATION.md if setup process changes

## Project Structure

```
salesforce-smart-territory-manager/
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/          # Apex classes
│           ├── triggers/         # Apex triggers
│           ├── lwc/             # Lightning Web Components
│           ├── objects/         # Custom objects
│           └── permissionsets/  # Permission sets
├── config/                      # Configuration files
├── data/                        # Sample data
├── docs/                        # Additional documentation
└── tests/                       # Test utilities
```

## Review Process

1. **Automated Checks**: All PRs must pass automated tests
2. **Code Review**: At least one maintainer must approve
3. **Documentation**: Ensure all docs are updated
4. **Testing**: Verify test coverage meets requirements

## Release Process

1. Version bump in `sfdx-project.json`
2. Update CHANGELOG.md
3. Create release notes
4. Tag release in Git
5. Deploy to package org

## Getting Help

* **Documentation**: Check README.md and docs/
* **Issues**: Search existing issues
* **Discussions**: Use GitHub Discussions for questions
* **Email**: contact@example.com

## Recognition

Contributors will be recognized in:
* README.md contributors section
* Release notes
* Project documentation

Thank you for contributing! 🎉