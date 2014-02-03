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
            'view:smallmonitor:save'      : 'render',
            'view:dashboard:save'         : 'render',
            'view:resetmonitor:reset'     : 'render'
        },

        initialize : function(options) {
            _.bindAll(this, 'render', 'activate', 'deactivate');
            this.templar = options.templar;
        },

        render : function(data) {
            //Until we can make sure all responses are json with an errors
            //attribute, parse the data.message and try to extract them...
            try {
              if ( JSON.parse(data.message) ) {
                data.messages = JSON.parse(data.message).errors;
              }
            } catch(e) {
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
