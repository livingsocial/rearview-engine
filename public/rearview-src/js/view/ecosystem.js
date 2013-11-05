define([
    'view/base',
    'view/dashboardtile'
], function(
    BaseView,
    DashboardTileView
){

    var EcosystemView = BaseView.extend({
        dashboards : [],

        subscriptions : {
            'view:addcategory:save'  : 'update',
            'view:adddashboard:save' : 'update',
            'view:dashboard:render'  : 'destructor',
            'view:dashboard:save'    : 'update'
        },

        initialize : function(options) {
            _.bindAll(this);

            this.templar    = options.templar;
            this.dashboards = [];
        },

        render : function() {
            this.collection.each(function( dashboard ) {
                this.dashboards.push(new DashboardTileView({
                    'el'      : this.el,
                    'model'   : dashboard,
                    'templar' : this.templar
                }));
            }.bind(this));

            this.paddingFix();

            Backbone.Mediator.pub('view:ecosystem:render', {
                'title'    : 'Ecosystem',
                'subtitle' : 'Rearview Dashboards',
                'nav' : {
                    'ecosystem' : true,
                    'dashboard' : false
                }
            });
        },

        paddingFix : function() {
            this.$el.css('padding-bottom','40px');
        },

        update : function(data) {
            var dashboardModel = ( data && data.model )
                               ? data.model 
                               : null;

            this.$el.empty();
            this.collection.fetch({
                success : function() {
                    this.render();
                }.bind(this)
            });
            
        },

        destroyDashboards : function() {
            var self = this;

            for (viewName in self.dashboards) {
                var view = self.dashboards[viewName];
                view.destructor();
                delete self.dashboards[viewName];
            }
        },

        destructor : function() {
            var prevSiblingEl = this.$el.prev();

            this.destroySubscriptions();
            this.destroyDashboards();

            this.off();
            this.collection.off();
            this.remove();

            prevSiblingEl.after("<section class='ecosystem-dashboard-wrap'>");
        }
    });

    return EcosystemView;
});
