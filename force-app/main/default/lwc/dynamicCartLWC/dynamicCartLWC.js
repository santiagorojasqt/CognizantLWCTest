import { LightningElement,api, track } from 'lwc';
import getMetadataInfo from '@salesforce/apex/cartController.getMetadataInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const selectedRows =[];
export default class DynamicCartLWC extends LightningElement {
    @api recordId;
    @api wrapper;
    @api hasError;
    @api tableData;
    @api columns;
    @api actions;
    @api defaultSortDirection = 'asc';
    @api sortDirection = 'asc';
    @api sortedBy;
    @api items;
    @api selectedRows=[];

    @api
    get itemsFiltered() {
        return this.itemsFiltered;
    }
    set itemsFiltered(value) {
        this.itemsFiltered = value;
    }
    @track itemsFiltered;
    connectedCallback(){
        this.selectedRows =[];
        this.getMeadataInfoCaller();
        
    }
    async getMeadataInfoCaller(){
        this.wrapper = await getMetadataInfo({recordId:this.recordId});
        this.processInfo()
    }
    handleclick(){
        this.showItems =  false; 
        if(!this.itemsFiltered){
            this.itemsFiltered = [];
        }
        var el = this.template.querySelector('lightning-datatable');
        console.log(el);
        var selected = el.getSelectedRows();
        selected.forEach(element => {
            let result = this.itemsFiltered.filter(item => item.name == element.Id);
            if(result.length===0){
                this.itemsFiltered.push(
                    {
                        type: 'icon',
                        label: element.Name.replaceAll('-','/')+'-1',
                        name: element.Id,
                        iconName: 'standard:price_book_entries',
                        alternativeText: 'price book entry',
                    }
                );
            }
            else{
                let rs = result[0];
                let count = rs.label.split('-')[1];
                let crNumber = (parseInt(count)+1);
                this.indx = this.itemsFiltered.map(function(e) { return e.name; }).indexOf(rs.name);
                this.itemsFiltered.splice(this.indx, 1,{
                    type: 'icon',
                    label: element.Name.replaceAll('-','/').concat('-', crNumber.toString()),
                    name: element.Id,
                    iconName: 'standard:price_book_entries',
                    alternativeText: 'price book entry',
                })
            }
            let items =  this.itemsFiltered;
            this.itemsFiltered = [];
            this.itemsFiltered = items;
            this.uncheckAll();
        });
    }

    handleSave(){
        
    }

    uncheckAll() {
        this.selectedRows = [];
    }
    processInfo(){
        this.columns = [
            { label: 'Name', fieldName: 'Name', sortable: true },
            { label: 'Unit Price', fieldName: 'UnitPrice', sortable: true},
        ]
        let priceBookMap = new Map();
        this.tableData = this.wrapper.priceBookEntryInfo;
        this.tableData.forEach(element => {
            let id = element.Id;
            priceBookMap.set(id,element);
        });
    }
    handleRowAction(event){
        console.log(event);
    }
    showNotification() {
        const evt = new ShowToastEvent({
            title: this._title,
            message: this.message,
            variant: this.variant,
        });
        this.dispatchEvent(evt);
    }
    sortBy(field, reverse, primer) {
        const key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }
    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.tableData];
        cloneData.sort(this.sortBy(sortedBy, this.sortDirection === 'asc' ? 1 : -1));
        this.tableData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
    handleProductdeletion(event){
        const name = event.detail.item.name;
        const index = event.detail.index;
        this.items.splice(index, 1);
    }
}