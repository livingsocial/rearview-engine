define([
    'view/base'
], function(
    BaseView
){  

    var PrimaryNavView = BaseView.extend({

        subscriptions : {
            'view:dashboard:save'    : 'render',
            'view:adddashboard:save' : 'render',
            'view:addcategory:save'  : 'render'
        },

        initialize : function(options) {
            _.bindAll(this);
            this.templar = options.templar;
            this.user    = options.user;
            

            Backbone.history.bind("all", function (route, router) {
                this.setNav();
            }.bind(this));
        },

        render : function() {
            this.$el.empty();

            this.collection.fetch({
                success : function() {
                    this.collection.sort();

                    this.templar.render({
                        path : 'primarynav',
                        el   : this.$el,
                        data : {
                            'nav'  : this.collection.toJSON(),
                            'user' : this.user.toJSON()
                        }
                    });
                }.bind(this)
            });

            this.$el.find('.user').tooltip({
                placement : 'bottom'
            });
        },

        setNav : function() {
            var fragment = Backbone.history.fragment;

            this.$el.find('li').removeClass('active');

            switch (fragment) {
                case 'ecosystem':
                    this.$el.find('.nav > li:first-child').addClass('active');
                    break;
            }
        }
    });

    return PrimaryNavView;
});