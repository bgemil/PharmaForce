import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import fetchUrgentOpportunities from '@salesforce/apex/UrgentOpportunitiesController.fetchUrgentOpportunities';
import fetchTotalRecordCount from '@salesforce/apex/UrgentOpportunitiesController.fetchTotalRecordCount';
import saveNewOpportunity from '@salesforce/apex/UrgentOpportunitiesController.saveNewOpportunity';

export default class UrgentOpportunitiesTable extends LightningElement {
    @api recordId;
    opportunities = []; 
    totalRecords = 0; 
    searchKey = ''; 
    offset = 0;
    limitValue = 5;

    columns = [
        { label: 'Opportunity Name', fieldName: 'Name', type: 'text' },
        { label: 'Stage', fieldName: 'StageName', type: 'text' },
        { label: 'Amount', fieldName: 'Amount', type: 'currency' },
        { label: 'Close Date', fieldName: 'CloseDate', type: 'date' },
    ];

    @wire(fetchUrgentOpportunities, {
        searchKey: '$searchKey',
        accountId: '$recordId',
        offset: '$offset',
        limitValue: '$limitValue',
    })
    wiredOpportunitiesWithCount({ error, data }) {
        if (data) {
            this.opportunities = data.opportunities; // Populate the opportunities
            this.totalRecords = data.totalRecords;   // Populate the total record count
        } else if (error) {
            this.opportunities = [];
            this.totalRecords = 0;
            console.error('Error fetching opportunities:', error);
            this.showToast('Error', 'Failed to fetch opportunities.', 'error');
        }
    }

    // Handle search input
    handleSearch(event) {
        this.searchKey = event.target.value; // Update searchKey
        this.offset = 0; // Reset pagination
    }

    // Pagination
    handlePrevious() {
        if (this.offset > 0) {
            this.offset -= this.limitValue; 
        }
    }

    handleNext() {
        if (this.offset + this.limitValue < this.totalRecords) {
            this.offset += this.limitValue; 
        }
    }

    handlePageClick(event) {
        const selectedPage = parseInt(event.target.dataset.page, 10);
        if (!isNaN(selectedPage)) {
            this.offset = (selectedPage - 1) * this.limitValue; 
        }
    }

    get pageClassMap() {
        const totalPages = this.totalPages;
        const currentPage = this.currentPage;
    
        if (totalPages <= 0) {
            console.log('No pages to display.');
            return [];
        }
    
        const pages = Array.from({ length: totalPages }, (_, i) => {
            const pageNumber = i + 1;
            return {
                number: pageNumber,
                class: pageNumber === currentPage ? 'active-page' : '',
            };
        });
    
        console.log('Pagination Map:', pages);
        return pages;
    }    

    get currentPage() {
        return Math.floor(this.offset / this.limitValue) + 1;
    }

    get totalPages() {
        const totalPages = Math.ceil(this.totalRecords / this.limitValue);
        console.log('Total Pages:', totalPages);
        return totalPages;
    }

    get disablePrevious() {
        return this.offset === 0;
    }

    get disableNext() {
        return this.offset + this.limitValue >= this.totalRecords;
    }

    // Modal for creating new opportunity
    isModalOpen = false;

    handleNewOpportunity() {
        this.isModalOpen = true;
    }

    handleModalCancel() {
        this.isModalOpen = false;
    }

    handleModalSave(event) {
        const newOpportunity = event.detail;
        newOpportunity.AccountId = this.recordId;
        newOpportunity.Urgent__c = true;

        if (!newOpportunity.Name || !newOpportunity.StageName || !newOpportunity.Amount || !newOpportunity.CloseDate) {
            this.showToast('Error', 'All fields are required.', 'error');
            return;
        }

        saveNewOpportunity({ opportunity: newOpportunity })
            .then(() => {
                this.isModalOpen = false;
                if(result) {
                    this.showToast('Success', 'New urgent opportunity created!', 'success');
                } else {
                    this.showToast('False', 'Problem in creating urgent opportunity', 'error');
                }                
                return Promise.all([
                    refreshApex(this.wiredOpportunitiesResult),
                    refreshApex(this.wiredTotalCountResult),
                ]);
            })
            .catch((error) => {
                this.showToast('Error', 'Failed to create opportunity.', 'error');
                console.error('Error saving opportunity:', error);
            });
    }

    // Utility to show toast notifications
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(toastEvent);
    }
}