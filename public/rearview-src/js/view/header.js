define([
    'view/base'
], function(
    BaseView
){  

    var HeaderView = BaseView.extend({
      
        initialize : function(options) {
            _.bindAll(this, 'render'); 
            this.templar = options.templar;

            this.currentNav = {
                'header' : {
                    'title'    : 'Ecosystem',
                    'subtitle' : '',
                    'date'     : new XDate(Date.now()).toUTCString("MMM dd, yyyy"),
                    'nav'      : {
                        'back' : false
                    }
                }
            };

            Backbone.Mediator.sub('view:ecosystem:render', this.render, this);
            Backbone.Mediator.sub('view:dashboard:render', this.render, this);

            this.render();
        },

        render : function(data) {
            this.previous = this.currentNav;
            _.extend(this.currentNav.header, data);

            this.templar.render({
                path : 'header',
                el   : this.$el,
                data : this.currentNav
            });
        }
    });

    return HeaderView;
});