define(
[
    'jquery',
    'underscore',
    'backbone',
    'model/dashboard'
],
function(
    $,
    _,
    Backbone,
    DashboardModel
) {

    /**
     * DashboardCollection
     *
     * Route that pulls back all available dashboards.
     **/
    var DashboardCollection = Backbone.Collection.extend({
        model : DashboardModel,
        url   : '/dashboards.json',

        comparator : function(dashboard) {
            return dashboard.get('name').toLowerCase();
        },
        initialize : function(models, options) {
            if (options) this.cb = options.cb;
            
            this.fetch({
                success : function() {
                    if ( this.cb ) this.cb();
                    Backbone.Mediator.pub('collection:dashboard:init', this);
                }.bind(this),
                async : false
            });
        }
    });

    return DashboardCollection;
});