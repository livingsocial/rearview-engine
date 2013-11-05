define([
    'view/base'
], function(
    BaseView
){  

    var SecondaryNavView = BaseView.extend({

        initialize : function(options) {
            this.templar = options.templar;
            _.bindAll(this); 

            this.currentNav = {
                'secondary' : {
                    'nav' : {
                        'ecosystem' : true,
                        'dashboard' : false
                    }
                }
            };

            Backbone.Mediator.sub('view:dashboard:render', this.render, this);
            Backbone.Mediator.sub('controller:dashboard:init', this.render, this);          
            this.render();
        },

        render : function(data) {
            this.destructor();
            this.previous = self.currentNav;
            _.extend(this.currentNav.secondary, data);

            this.templar.render({
                path : 'secondarynav',
                el   : this.$el,
                data : this.currentNav
            });
        },

        destructor : function() {
            this.$el.empty();
        }
    });

    return SecondaryNavView;
});