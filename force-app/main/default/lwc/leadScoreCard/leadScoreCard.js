import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getLeadMetrics from '@salesforce/apex/AnalyticsDataService.getLeadMetrics';

const LEAD_FIELDS = [
    'Lead.Name',
    'Lead.Company',
    'Lead.Status',
    'Lead.Rating'
];

export default class LeadScoreCard extends LightningElement {
    @api recordId;
    @track leadMetrics;
    @track isLoading = true;
    @track error;
    
    @wire(getRecord, { recordId: '$recordId', fields: LEAD_FIELDS })
    lead;
    
    connectedCallback() {
        this.loadLeadMetrics();
    }
    
    /**
     * Load lead metrics and score data
     */
    loadLeadMetrics() {
        getLeadMetrics({ leadId: this.recordId })
            .then(result => {
                this.leadMetrics = result;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                this.showToast('Error', 'Failed to load lead metrics', 'error');
            });
    }
    
    /**
     * Refresh lead score
     */
    handleRefresh() {
        this.isLoading = true;
        this.loadLeadMetrics();
    }
    
    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
    /**
     * Getters for template
     */
    get hasMetrics() {
        return this.leadMetrics !== undefined;
    }
    
    get totalScore() {
        return this.leadMetrics?.totalScore?.toFixed(0) || '0';
    }
    
    get scoreGrade() {
        return this.leadMetrics?.scoreGrade || 'N/A';
    }
    
    get conversionProbability() {
        return this.leadMetrics?.conversionProbability?.toFixed(1) + '%' || '0%';
    }
    
    get demographicScore() {
        return this.leadMetrics?.demographicScore?.toFixed(0) || '0';
    }
    
    get behavioralScore() {
        return this.leadMetrics?.behavioralScore?.toFixed(0) || '0';
    }
    
    get firmographicScore() {
        return this.leadMetrics?.firmographicScore?.toFixed(0) || '0';
    }
    
    get engagementScore() {
        return this.leadMetrics?.engagementScore?.toFixed(0) || '0';
    }
    
    get scoreVariant() {
        const grade = this.scoreGrade;
        if (grade === 'Hot') return 'success';
        if (grade === 'Warm') return 'warning';
        return 'error';
    }
    
    get progressBarClass() {
        const score = parseInt(this.totalScore);
        if (score >= 80) return 'progress-bar progress-hot';
        if (score >= 60) return 'progress-bar progress-warm';
        return 'progress-bar progress-cold';
    }
    
    get progressWidth() {
        return `width: ${this.totalScore}%`;
    }
}