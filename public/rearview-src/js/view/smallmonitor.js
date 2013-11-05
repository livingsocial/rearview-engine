define([
    'view/base'
], function(
    BaseView
){
    var SmallMonitorView = BaseView.extend({

        el : '.small-monitor',

        events : {
            'click .header-name'      : 'editMonitor',
            'click .settings .btn'    : 'monitorSettings',
            'click .save'             : 'monitorSettings',
            'click .monitor-inactive' : 'deactivateMonitor',
            'click .monitor-active'   : 'activateMonitor',
            'click button.reset'      : 'resetMonitor' 
        },

        initialize : function(options) {
            _.bindAll(this, 'editMonitor', 
                            'expandMonitor', 
                            'monitorTitle',
                            'monitorSettings', 
                            'deactivateMonitor', 
                            'activateMonitor', 
                            'resetMonitor',
                            'setupDrag');
            
            this.templar = options.templar;
            this.user    = ( options.user ) ? options.user : null;
            // this is the parent dashboard Id, category ( subdashboardId ) can
            // be found from the monitor's model
            this.dashboardId = ( options.dashboardId ) ? options.dashboardId : null;
           
            this.addHelpers();
            this.intervalLength = ( options.intervalLength ) ? options.intervalLength : 60; // seconds
            Backbone.Mediator.sub('controller:dashboard:init', this.expandMonitor, this);

            // use debounce to throttle resize events and set the height when
            // the viewport changes.
            var resize = _.debounce(this.monitorTitle, 500);

            // Add the event listener
            $(window).resize(resize);
        },

        render : function() {
            this.templar.render({
                path   : 'smallmonitor',
                el     : this.$el,
                append : true,
                data   : {
                    'monitor' : this.model.toJSON()
                }
            });

            this.initMonitor();

            return this;
        },
        /**
         * SmallMonitorView#initMonitor()
         *
         * Set up the small monitor with job (monitor) model, append to
         * monitor list area, then finally get monitor data to create graph.
         **/
        initMonitor : function() {
            // store view object reference in dom storage
            this.$el.data('view', this);

            this.$monitor = this.$el.find('#smallMonitor' + this.model.get('id'));
            this.$wrap    = this.$monitor.parent();
            this.$graph   = this.$monitor.find('.graph')[0];

            // add tooltip to long header names
            this.$monitor.find('h1').tooltip();

            this.chart = this.initGraph( this.$graph );
            // update the graph on load
            this.updateGraph();
            // update the graph every interval
            this.interval = setInterval(function() {
                this.updateGraph(true);
            }.bind(this), this.intervalLength * 1000);

            this.setupDrag();
        },

        setupDrag : function() {
            // drag-n-drop
            this.$monitor.draggable({
                handle        : this.$el.find('.drag-handle'),
                containment   : 'body',
                snap          : '.small-monitor-drag', 
                snapMode      : 'inner',
                snapTolerance : 30,
                appendTo      : '.monitor-wrap',
                scroll        : true,
                revert        : 'invalid',
                //revert      : 'invalid',
                start : function( e, ui ) {
                    var $el    = ui.helper,
                        offset = ui.offset;

                    $el.draggable( "option", "revert", true );

                    // body must not have any styling in order
                    // for draggable to scroll the viewport
                    $('body').removeAttr('style');
                    // making sure that container's z-index is
                    // greater than the rest so the monitor will
                    // float over all other monitors
                    $el.parent().css({
                        'z-index' : '9999'
                    });

                    // get current order
                    this.currentOrder = this.getMonitorOrder();
                }.bind(this),
                stop : function( e, ui ) {
                    var $el    = ui.helper,
                        offset = ui.offset,
                        match  = [],
                        thisId = $el.attr('id'),
                        noOverlap = true;

                    $el.parent().css({
                        'z-index' : '1'
                    });
                        
                    $('.small-monitor').each(function(idx, monitor) {
                        var monitorId = $(monitor).attr('id');

                        if ( thisId !== monitorId ) {
                            if ( this.overlaps( $el, monitor ) ) {
                                this.setorder( $el.parent(), $(monitor).parent(), true );
                                $el.css({
                                    left : 0,
                                    top  : 0
                                });

                                noOverlap = false;
                            }  
                        }
                    }.bind(this));

                    // NOTE : doing this until I can figure out how to tweak tolerance
                    if ( noOverlap )  {
                        $el.css({
                            left : 0,
                            top  : 0
                        });
                    }

                }.bind(this),
                drag : function( event, ui ) {
                    var $el    = ui.helper,
                        offset = ui.offset,
                        match  = [];
                }.bind(this)
            });
        },

        setorder : function( el1, el2, persist ) {
            el1     = $(el1);
            el2     = $(el2);
            persist = !!persist;

            var drag1          = el1.parent(),
                drag2          = el2.parent(),
                newIdxPos      = drag2.attr('data-order'),
                currentOrder   = ( this.currentOrder ) ? this.currentOrder : this.getMonitorOrder(),
                monitorView    = el1.data('view'),
                monitorId      = monitorView.model.get('id'),
                existingIdxPos = _.indexOf(currentOrder, monitorId);

            // calculate new order
            currentOrder.splice(existingIdxPos, 1);
            currentOrder.splice(newIdxPos, 0, monitorId);
            this.currentOrder = currentOrder;

            // now reorder the monitors
            this.reorder();

            // set the user dashboard preferences
            if ( persist ) this.setDashboardPreferences();
        },

        updateGraph : function(period) {
            var runUpdate = false;

            if ( !period ) {
                runUpdate = true;
            } else if ( period && this.model.get('active') ) {
                runUpdate = true;
            }
            
            if (runUpdate) {
                // should be in an error state till proven otherwise
                this.errorState = true;

                this.showOverlay(this.$graph, 'Loading...', 'small-monitor-overlay');

                $.ajax({
                    url : '/jobs/' + this.model.get('id') + '/data',
                    success : function(result) {
                        if (result.status === 'error') {
                            this.hideOverlay();
                            if(_.isEmpty(result.graph_data)) {
                                this.showOverlay(this.$graph, 'Monitor Error - No Data', 'small-monitor-error-overlay');
                            } else {
                                this.showOverlay(this.$graph, 'Monitor Error', 'small-monitor-error-overlay');
                            }
                            this._setErrorState();
                        } else if (result.status === 'failed') {
                            this.hideOverlay();
                            this.formattedGraphData = this.formatGraphData( result.graph_data );
                            this.renderGraphData(this.chart, this.formattedGraphData);
                            this._setErrorState();
                            // set the output data so when we pass the model to the expanded view
                            // we already have it
                            this.model.set('output', result.output);
                        } else if (result.status === 'graphite_error') {
                            this.hideOverlay();
                            this.showOverlay(this.$graph, 'Graphite Error', 'small-monitor-error-overlay');
                            this._setErrorState();
                        } else if (result.status === 'graphite_metric_error') {
                            this.hideOverlay();
                            this.showOverlay(this.$graph, 'Graphite Metrics Error', 'small-monitor-error-overlay');
                            this._setErrorState();
                        } else if ( result.graph_data ) {
                            this.hideOverlay();
                            this.errorState = false;
                            this.formattedGraphData = this.formatGraphData( result.graph_data );
                            this.renderGraphData(this.chart, this.formattedGraphData);
                            // set the output data so when we pass the model to the expanded view
                            // we already have it
                            this.model.set('output', result.output);
                            this._setErrorState(true); // clear out error states if any on previous update
                        } else {
                            this.hideOverlay();
                            this.showOverlay(this.$graph, 'Unexpected Error', 'small-monitor-error-overlay');
                            this._setErrorState();
                        }
                    }.bind(this),
                    error : function() {
                        this.hideOverlay();
                        this.showOverlay(this.$graph, 'Waiting For Next Run', 'small-monitor-error-overlay');
                    }.bind(this)
                });

            }
        },
        /**
         * SmallMonitorView#deactivateMonitor(e)
         * - e (Object): event object
         *
         * After checking if the inactive button is not already set,
         * simply setting the model to reflect the active state and saving to db.
         **/
        deactivateMonitor : function(e) {
            if( !$(e.target).hasClass('active') ) {
                this.model.save({
                    'active' : false
                },
                {
                    error : function(model, xhr, options) {
                        Backbone.Mediator.pub('view:smallmonitor:save', {
                            'model'     : this.model,
                            'message'   : "The monitor '" + model.get('name') + "' caused an error on deactivation, please check your monitor code.",
                            'attention' : 'Monitor Deactivate Error!',
                            'status'    : 'error'
                        });
                    }
                });
            }
        },
        /**
         * SmallMonitorView#activateMonitor(e)
         * - e (Object): event object
         *
         * After checking if the active button is not already set,
         * simply setting the model to reflect the active state and saving to db.
         **/
        activateMonitor : function(e) {
            if( !$(e.target).hasClass('active') ) {
                this.model.save({
                    'active' : true
                },
                {
                    error : function(model, xhr, options) {
                        Backbone.Mediator.pub('view:smallmonitor:save', {
                            'model'     : this.model,
                            'message'   : "The monitor '" + this.model.get('name') + "' caused an error on activation, please check your monitor code.",
                            'attention' : 'Monitor Activate Error!',
                            'status'    : 'error'
                        });
                    }.bind(this)
                });
            }
        },
        /**
         * SmallMonitorView#resetMonitor(e)
         * - e (Object): event object
         *
         * Makes a call to /jobs/:id/reset.json to clear out data, alerts, and resets status
         **/
        resetMonitor: function(e) {
            this.$monitor.find('#resetMonitor').toggle('show');

            Backbone.Mediator.pub('view:smallmonitor:reset', {
                'model' : this.model
            });
        },

        expandMonitor : function(data) {
            if( data.monitorId == this.model.get('id') ) {
                this.editMonitor();
            }
        },
        /**
         * SmallMonitorView#editMonitor(e)
         * - e (Object): event object
         *
         * Publish an view:edit channel publish event and pass the model
         * for the ExpandedMonitorView for example.
         **/
        editMonitor : function() {
            Backbone.Mediator.pub('view:smallmonitor:edit', this.model.get('id'), this);
        },
        monitorSettings : function(e) {
            this.$monitor.toggleClass('flipped');
        },

        monitorTitle : function() {
            var buttonOffset = 140,
                monitorWidth = this.$monitor.width();

            this.$header    = this.$monitor.find('.header-name');
            this.$titleText = this.$monitor.find('.header-name p');

            // calculate maximum fluid width minus the current header control buttons
            this.$header.css('width', monitorWidth - buttonOffset);

            if ( this.$titleText.width() > this.$header.width() ) {
                this.$header.addClass('truncated');
            } else {
                this.$header.removeClass('truncated');
            }
        },

        nextRun : function() {
            this.hideOverlay();
            this.showOverlay(this.$graph, 'Waiting For Next Run', 'small-monitor-error-overlay');
        },

        reorder : function() {
            var dragWrappers = $('.dashboard-' + this.model.get('dashboardId') + ' .small-monitor-drag');

            dragWrappers.each(function(idx, dragWrap) {
                    $(dragWrap).prepend($('#smallMonitor' + this.currentOrder[idx]).parent());
            }.bind(this));
        },

        setDashboardPreferences : function() {
            var userPreferences      = ( this.user.get('preferences') ) ? this.user.get('preferences') : {},
                dashboardPreferences = ( userPreferences && userPreferences.dashboards ) ? userPreferences.dashboards : {};

            dashboardPreferences[this.model.get('dashboardId')] = {
                'order' : this.currentOrder
            }

            userPreferences.dashboards = dashboardPreferences;
            this.user.updatePrefs(userPreferences);
        },

        getMonitorOrder : function() {
            var $monitors = $('.dashboard-' + this.model.get('dashboardId') + ' .small-monitor-wrap'),
                order     = [];

            $monitors.each(function(idx, monitorWrap) {
                var smallMonitorView = $(monitorWrap).data('view');
                order.push( smallMonitorView.model.get('id') );
            });

            return order;
        },

        destructor : function() {
            // go ahead and clear out the graph updating interval
            clearInterval(this.interval);

            this.model.unbind();
            this.unbind();
            this.off();
            this.undelegateEvents();

            Backbone.Mediator.unsubscribe('view:smallmonitor:edit', this.editMonitor);
            Backbone.Mediator.unsubscribe('controller:dashboard:init', this.expandMonitor, this);

            this.remove();
            this.$el.remove();
        },

        _setErrorState : function(state) {
            if(!state) {
                this.$el.children(":first").addClass('red');
            } else {
                this.$el.children(":first").removeClass('red');
            }
        }

    });

    return SmallMonitorView;
});
