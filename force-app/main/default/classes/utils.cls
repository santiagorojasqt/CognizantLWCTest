public with sharing class utils {
    public utils() {

    }


    /*
        @Author : Santiago Rojas
        @BuiltDate : 30-01-2021
        @Description : Get's a dynamic Query Based on the params
        @params : DynamicQueryStructure data
    */

    public static List<sObject> getDynamicQuery(DynamicQueryStructure data){
        // This is the object for which we required data.
        SObjectType rType = ((SObject)(Type.forName('Schema.'+data.sObjectName).newInstance())).getSObjectType();
        List<Schema.ChildRelationship> directRelationShip = null;
        DescribeSObjectResult dRes = rType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = dRes.fields.getMap();
        if(data.subqueryObj != null){
            directRelationShip = new List<Schema.ChildRelationship>();
            String [] subqueries = data.subqueryObj.split(',');
            for(String subquery: subqueries){
                for(Schema.ChildRelationship child: dRes.getChildRelationships()){
                    if(child.getRelationshipName() == subquery){
                        directRelationShip.add(child);
                    }
                }
            }
        }
        
        String subqueries = '';
        if(directRelationShip!= null &&directRelationShip.size()>0){
            subqueries = ','+createSubqueries(directRelationShip,data);
        }
        // Get all of the fields on the object
        set<String> fieldNames = fieldMap.keySet();
        // Build a Dyn amic Query String.
        List<sObject> sObjs  = new List<Sobject>();
        String wherecls = createWhereClause(data,false);
        if(fieldNames.Size()>0){
            String query = 'SELECT '+ data.AdditionalFields+ string.join((Iterable<String>)fieldNames, ',') + subqueries+ ' FROM ';
            query+= String.escapeSingleQuotes(data.sObjectName)+' '+ wherecls +' '+ data.orderByParent;
            sObjs = Database.query(query);
        }
        return sObjs;
    }


    private static String createSubqueries(List<Schema.ChildRelationship> subQueries,DynamicQueryStructure data){
        set<String> fieldNames = null;
        Map<String, Schema.SObjectField> fieldMap = null;
        DescribeSObjectResult dRes = null;
        String returnedQuery = '';
        String crRelationShip = '';
        String crOrderBy = '';
        for(Schema.ChildRelationship child: subQueries){
            crRelationShip = child.getRelationshipName();
            dRes = child.getChildSObject().getDescribe();
            if(data.orderByChild != null){
                if(data.orderByChild.containsKey(crRelationShip)){
                    crOrderBy = data.orderByChild.get(crRelationShip);
                }
                else{
                    crOrderBy = '';
                }
            }
            String wherecls = createWhereClause(data,true);
            fieldMap = dRes.fields.getMap();
            fieldNames = fieldMap.keySet();
            ReturnedQuery += '( SELECT '+string.join((Iterable<String>)fieldNames, ',');
            ReturnedQuery += ' FROM '+child.getRelationshipName()+' '+ wherecls +' '+crOrderBy+'),';       
        }
        ReturnedQuery = ReturnedQuery.removeEnd(',');
        return ReturnedQuery;
    }

    private static String createWhereClause(DynamicQueryStructure data, Boolean isChildObj){
        String wherecls = '';
        if(isChildObj){
            if(!data.childsWhereClause.isEmpty()){
                wherecls='WHERE ';
                for(String key : data.childsWhereClause.keySet()){
                    wherecls+=key+' in(\''+String.escapeSingleQuotes(String.join((Iterable<String>)data.childsWhereClause.get(key),'\',\''))+'\') AND ';
                }
                wherecls = wherecls.Substring(0,wherecls.length()-4);
            }
        }
        else{
            if(!data.whereClause.isEmpty()){
                wherecls='WHERE ';
                for(String key : data.whereClause.keySet()){
                    wherecls+=key+' in(\''+String.escapeSingleQuotes(String.join((Iterable<String>)data.whereClause.get(key),'\',\''))+'\') AND ';
                }
                wherecls = wherecls.Substring(0,wherecls.length()-4);
                wherecls = wherecls.replace('\\', '');
            }
        }
        system.debug(wherecls);
        return wherecls;
    }

    public class DynamicQueryStructure{
        public String sObjectName{get;set;}
        public String subqueryObj{get;set;}
        public map<String,list<object>> whereClause{get;set;}
        public map<String,list<object>> childsWhereClause{get;set;}
        public String AdditionalFields{get;set;}
        public String orderByParent{get;set;}
        public Map<String,String> orderByChild{get;set;}
    }

}
