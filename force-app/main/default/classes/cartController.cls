public with sharing class cartController{
    public static Map<String,Schema.SObjectType> sObjInfo = Schema.getGlobalDescribe();
    @AuraEnabled
    public static CartWrapper getMetadataInfo(Id recordId){
        String sObjType = String.valueOf(recordId.getSobjectType());
        try{
            Product_Cart_Configuration__mdt metadata =[SELECT Id, Parent_Object__c,Child_Item_to_create__c,fields_to_populate__c FROM Product_Cart_Configuration__mdt WHERE Parent_Object__c=:sObjType];
            if(metadata != null){
                /*This part was added just in case quotelineItems or opportunity line Item or order Item needs a validation on the parent object
                But is not being used for the moment*/
                    utils.DynamicQueryStructure structure = new utils.DynamicQueryStructure();
                    structure.AdditionalFields = '';
                    structure.sObjectName = sObjType;
                    structure.whereClause = new map<String,List<object>>{'Id'=> new List<Object>{String.valueOf(recordId)}};
                    structure.orderByParent ='';
                    List<sObject> objs  = utils.getDynamicQuery(structure);
                /*END*/
                Boolean listNotEmpty = objs.size()>0;
                if(!listNotEmpty){
                    throw new AuraHandledException('The Object is not invalid');
                }
                Id oppPricebook2 =String.valueOf(objs[0].get('Pricebook2Id'));
                CartWrapper wrapper = new CartWrapper();
                wrapper.childObject = (List<SObject>)Type.forName('List<'+metadata.Child_Item_to_create__c+'>').newInstance();
                wrapper.parentInfo = objs[0];
                wrapper.priceBookEntryInfo = [SELECT Id,Product2Id, Product2.name,Name,UnitPrice FROM PricebookEntry WHERE Pricebook2.isActive = true AND Pricebook2Id =: oppPricebook2];
                return wrapper;
            }
            else{
                
                throw new AuraHandledException('We were unable to find a setting for this object please contact you system admin');
            }
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
    }

    public class CartWrapper {
        @AuraEnabled        
        public List<PricebookEntry> priceBookEntryInfo{get;set;}
        @AuraEnabled
        public sObject parentInfo{get;set;}
        @AuraEnabled
        public List<sObject> childObject{get;set;}
    }
}