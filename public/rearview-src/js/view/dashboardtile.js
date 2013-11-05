define([
    'view/base'
], function(
    BaseView
){  
    var DashboardTileView = BaseView.extend({

        events : {
            'click .save.btn'     : 'save',
            'click .settings.btn' : 'settings',
            'click figure.front'  : 'loadDashboard',
            'click .cancel.btn'   : 'settings',
            'click .add.btn'      : 'addCategory'
        },

        initialize : function(options) {
            _.bindAll(this);

            this.templar        = options.templar;
            this.intervalLength = ( options.intervalLength ) ? options.intervalLength : 60; // seconds
            this.render();
        },

        render : function() {
            this.templar.render({
                path   : 'dashboardtile',
                el     : this.$el,
                append : true,
                data   : {
                    'dashboard' : this.model.toJSON()
                }
            });

            this.$dashboardTile = this.$el.find('.dashboard' + this.model.get('id'));
            this.setElement(this.$dashboardTile);
            
            this.startStatusCheck();
        },

        loadDashboard : function(e) {
            location.href = '#dash/' + this.model.get('id');
        },

        addCategory : function(e) {
            Backbone.Mediator.pub('view:dashboard:add', {
                dashboard : {
                    id       : this.model.get('id'),
                    name     : this.model.get('name'),
                    children : this.model.get('children')
                }
            });
        },

        startStatusCheck : function() {
            this.updateTile();

            this.interval = setInterval(function() {
                this.updateTile();
            }.bind(this), this.intervalLength * 1000);

            clearInterval(this.interval);
        },

        updateTile : function() {
            $.ajax({
                url      : '/dashboards/' + this.model.get('id') + '/jobs.json',
                success  : function(response) {
                    _.map(response, function(job) {
                        job.createdAt = ( job.createdAt ) 
                                      ? this.formatServerDateTime(job.createdAt, true) 
                                      : job.createdAt;
                            
                        job.modifiedAt = ( job.modifiedAt )
                                       ? this.formatServerDateTime(job.modifiedAt, true)
                                       : job.modifiedAt;
                    }, this);

                    this.checkErrorState(response);
                }.bind(this)
            });
        },

        checkErrorState : function(response) {
            var dashboardErrorState = false; 

            for (var i = response.length - 1; i >= 0; i--) {
                if ( response[i].status != 'success' && typeof response[i].status != 'undefined' && response[i].active ) {
                    dashboardErrorState = true;
                    break;
                }
            };

            if ( dashboardErrorState ) {
                this.$el.find('.dashboard' + this.model.get('id')).addClass('red');
            } else {
                this.$el.find('.dashboard' + this.model.get('id')).removeClass('red');
            }
        },

        settings : function(e) {
            e.stopPropagation();
            this.$dashboardTile.toggleClass('flipped');
            setTimeout(function() {
                this.$dashboardTile.find('.front .btn').toggle();
            }.bind(this), 600);
        },

        save : function(e) {
            e.stopPropagation();

            this.model.save({
                'name' : this.$dashboardTile.find('.dashboard-name').val()
            },{
                success : function(response) {
                    Backbone.Mediator.pub('view:dashboard:save', {
                        'model'     : this.model,
                        'message'   : "Your changes to '" + this.model.get('name') + "' dashboard were saved.",
                        'attention' : 'Dashboard Saved!'
                    });
                }.bind(this),
                error : function(model, xhr, options) {
                    Backbone.Mediator.pub('view:dashboard:save', {
                        'model'     : this.model,
                        'message'   : "The dashboard '" + model.get('name') + "' produced an error during the process of saving.",
                        'attention' : 'Dashboard Save Error!',
                        'status'    : 'error'
                    });
                }.bind(this)
            });
        },

        destructor : function() {
            // go ahead and clear out the graph updating interval
            clearInterval(this.interval);

            this.remove();
            this.$el.remove();
            this.off();

            // remove model bound events
            this.model.off();
        }
    });

    return DashboardTileView;
});