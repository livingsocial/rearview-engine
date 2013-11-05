define(
[
    'model/base'
],
function(
    Base
){
    /**
     * DashboardModel
     *
     * Generic model that represents a dashboard in rearview.
     **/
    var DashboardModel = Base.extend({
        initialize : function(options) {
            this.category    = ( options ) ? options.category : false;
            this.dashboardId = ( options ) ? options.dashboardId : null;
        },
        url : function() {
            if ( this.category ) {
                return ( this.dashboardId ) ? '/dashboards/' + this.dashboardId + '/children.json' : '/dashboards.json';
            } else {
                return ( this.get('id') ) ? '/dashboards/' + this.get('id') : '/dashboards.json';
            }
        },
        parse : function(response, options) {
            response.createdAt = ( response.createdAt ) 
                               ? this.formatServerDateTime(response.createdAt)
                               : response.createdAt;
            
            response.modifiedAt = ( response.modifiedAt ) 
                                ? this.formatServerDateTime(response.modifiedAt) 
                                : response.modifiedAt;
            return response;
        },
        defaults : {
            'id'         : null,
            'userId'     : null,
            'name'       : 'Default',
            'createdAt'  : null,
            'modifiedAt' : null,
            'description': null,
            'children'   : []
        }
    });

    return DashboardModel;
});