define(
[
    'jquery',
    'underscore',
    'backbone',
    'model/monitor'
],
function(
    $,
    _,
    Backbone,
    MonitorModel
) {
    /**
     * MonitorCollection
     *
     * Route that pulls back all available monitors.
     * NOTE : jobs & monitors are synonymous in this web application
     *        context. Dash & dashboard are synonymous as well.
     **/
    var MonitorCollection = Backbone.Collection.extend({
        model : MonitorModel,
        url : function() {
            return ( this.dashboardId ) ? '/dashboards/' + this.dashboardId + '/jobs.json' : '/jobs.json';
        },
        initialize : function(models, options) {
            _.bindAll(this, 'url');

            this.dashboardId = options.dashboardId;
            this.cb          = options.cb;

            this.fetch({
                success : function(result) {
                    if ( this.cb ) this.cb(result);
                }.bind(this),
                async : false
            });
        },
        filterById: function(orderArray) {
            var filteredOrder = [];
            _.each(orderArray, function(monitorId) {
                if(!_.isUndefined(this.get(monitorId))) { 
                    filteredOrder.push(monitorId);
                }
            }, this);
            return this.reset(_.map(filteredOrder, function(monitorId) { 
                    return this.get(monitorId); 
            }, this));  
        }
    });

    return MonitorCollection;
});