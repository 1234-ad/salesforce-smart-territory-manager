import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTerritoryMetrics from '@salesforce/apex/AnalyticsDataService.getTerritoryMetrics';
import getDashboardData from '@salesforce/apex/AnalyticsDataService.getDashboardData';

export default class TerritoryDashboard extends LightningElement {
    @api recordId;
    @track dashboardData;
    @track territoryMetrics;
    @track isLoading = true;
    @track error;
    
    // Chart data
    @track leadsByStatusChart;
    @track leadsByGradeChart;
    @track monthlyTrendChart;
    @track conversionFunnelChart;
    
    connectedCallback() {
        this.loadDashboardData();
        if (this.recordId) {
            this.loadTerritoryMetrics();
        }
    }
    
    /**
     * Load overall dashboard data
     */
    loadDashboardData() {
        getDashboardData()
            .then(result => {
                this.dashboardData = result;
                this.prepareChartData();
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                this.showToast('Error', 'Failed to load dashboard data', 'error');
            });
    }
    
    /**
     * Load territory-specific metrics
     */
    loadTerritoryMetrics() {
        getTerritoryMetrics({ territoryId: this.recordId })
            .then(result => {
                this.territoryMetrics = result;
                this.prepareTerritoryCharts();
            })
            .catch(error => {
                this.error = error;
                this.showToast('Error', 'Failed to load territory metrics', 'error');
            });
    }
    
    /**
     * Prepare chart data for visualization
     */
    prepareChartData() {
        if (!this.dashboardData) return;
        
        // Score distribution pie chart
        const scoreData = this.dashboardData.scoreDistribution;
        this.leadsByGradeChart = {
            labels: Object.keys(scoreData),
            datasets: [{
                data: Object.values(scoreData),
                backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0']
            }]
        };
        
        // Conversion funnel
        const funnel = this.dashboardData.conversionFunnel;
        this.conversionFunnelChart = {
            labels: ['Total Leads', 'Qualified', 'Contacted', 'Converted'],
            datasets: [{
                label: 'Conversion Funnel',
                data: [funnel.totalLeads, funnel.qualified, funnel.contacted, funnel.converted],
                backgroundColor: '#36A2EB'
            }]
        };
    }
    
    /**
     * Prepare territory-specific charts
     */
    prepareTerritoryCharts() {
        if (!this.territoryMetrics) return;
        
        // Leads by status
        const statusData = this.territoryMetrics.leadsByStatus;
        this.leadsByStatusChart = {
            labels: Object.keys(statusData),
            datasets: [{
                data: Object.values(statusData),
                backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF']
            }]
        };
        
        // Monthly trends
        const trends = this.territoryMetrics.monthlyTrends;
        this.monthlyTrendChart = {
            labels: trends.map(t => `${t.month}/${t.year}`),
            datasets: [{
                label: 'Leads per Month',
                data: trends.map(t => t.leadCount),
                borderColor: '#36A2EB',
                fill: false
            }]
        };
    }
    
    /**
     * Refresh dashboard data
     */
    handleRefresh() {
        this.isLoading = true;
        this.loadDashboardData();
        if (this.recordId) {
            this.loadTerritoryMetrics();
        }
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
    get hasData() {
        return this.dashboardData !== undefined;
    }
    
    get hasTerritoryData() {
        return this.territoryMetrics !== undefined;
    }
    
    get totalLeadsFormatted() {
        return this.dashboardData?.totalLeads?.toLocaleString() || '0';
    }
    
    get totalTerritoriesFormatted() {
        return this.dashboardData?.totalTerritories?.toLocaleString() || '0';
    }
    
    get avgConversionRateFormatted() {
        return this.dashboardData?.avgConversionRate?.toFixed(2) + '%' || '0%';
    }
    
    get totalRevenueFormatted() {
        return '$' + (this.dashboardData?.totalRevenue?.toLocaleString() || '0');
    }
    
    get territoryName() {
        return this.territoryMetrics?.territoryName || 'Territory';
    }
    
    get activeLeadsCount() {
        return this.territoryMetrics?.activeLeads?.toLocaleString() || '0';
    }
    
    get territoryConversionRate() {
        return this.territoryMetrics?.conversionRate?.toFixed(2) + '%' || '0%';
    }
    
    get territoryRevenue() {
        return '$' + (this.territoryMetrics?.totalRevenue?.toLocaleString() || '0');
    }
}