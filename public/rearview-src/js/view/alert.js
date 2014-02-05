define([
    'view/base'
], function(
    BaseView
){

    var AlertView = BaseView.extend({

        subscriptions : {
            'view:adddashboard:save'      : 'render',
            'view:addcategory:save'       : 'render',
            'view:addmonitor:save'        : 'render',
            'view:addmonitor:test'        : 'render',
            'view:expandedmonitor:delete' : 'render',
            'view:expandedmonitor:save'   : 'render',
            'view:expandedmonitor:test'   : 'render',
            'view:smallmonitor:save'      : 'render',
            'view:dashboard:save'         : 'render',
            'view:resetmonitor:reset'     : 'render'
        },

        initialize : function(options) {
            _.bindAll(this, 'render', 'activate', 'deactivate');
            this.templar = options.templar;
        },

        render : function(data) {
            if( data.tryJSON ) {
              try {
                data.errors = JSON.parse(data.tryJSON).errors;
              } catch(e) {
                data.raw = data.tryJSON;
              }
            }
            this.templar.render({
                path   : 'alert',
                el     : this.$el,
                data   : data
            });
            this.activate();
        },

        activate : function() {
            this.$el.addClass('active');
            _.delay(this.deactivate, 20000);
        },

        deactivate : function() {
            this.$el.removeClass('active');
        }
    });

    return AlertView;
});
