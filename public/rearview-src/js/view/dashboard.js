define([
    'view/base',
    'model/monitor',
    'collection/monitor',
    'view/smallmonitor',
    'view/expandedmonitor',
    'view/addmonitor',
    'view/resetmonitor',
    'view/alerttimeline',
    'codemirror',
    'codemirror-ruby',
    'jquery-validate'
], function(
    BaseView,
    MonitorModel,
    MonitorCollection,
    SmallMonitorView,
    ExpandedMonitorView,
    AddMonitorView,
    ResetMonitorView,
    AlertTimelineView,
    CodeMirror
){  
    var DashboardView = BaseView.extend({
        rowMonitorLimit : 3,
        events : {
            'slid .carousel'  : 'advanceCarousel'
        },

        subscriptions : {
            'view:expandedmonitor:open'       : 'hideDash',
            'view:expandedmonitor:exit'       : 'updateDash',
            'view:addmonitor:close'           : 'showDash',
            'view:addmonitor:save'            : 'updateDash',
            'view:addmonitor:show'            : 'hideDash',
            'view:smallmonitor:edit'          : 'editMonitor',
            'view:alerttimeline:troubleshoot' : 'editMonitor',
            // 'view:dashboard:complete'         : 'advanceCarousel'
        },

        hidePrevCaption : function() {
            this.$el.find('.carousel-caption').parent().children('.carousel-caption p').hide();
        },

        initialize : function(options) {
            _.bindAll(this);

            this.templar            = options.templar;
            this.dashboardId        = ( options.dashboardId ) ? options.dashboardId : null;
            this.categoryId         = ( options.categoryId ) ? options.categoryId : null;
            this.user               = ( options.user ) ? options.user : null;
            this.router             = ( options.router ) ? options.router : null;
            this.categories         = [];
            this.monitors           = [];
            this.monitorCollections = [];
            this.currentOrder       = [];
            this.carouselIndex      = 0;

            this.expandedMonitorView = new ExpandedMonitorView({
                'el'      : $('.edit-monitor-wrap'),
                'user'    : this.user,
                'templar' : this.templar,
                'router'  : this.router
            });

            this.addMonitorView = new AddMonitorView({
                'model'       : new MonitorModel({
                    'dashboardId' : this.dashboardId
                }),
                'user'        : this.user,
                'dashboardId' : this.dashboardId,
                'templar'     : this.templar
            });

            this.alertTimelineView = new AlertTimelineView({
                'el'          : $('.timeline-wrap'),
                'collection'  : this.collection,
                'dashboardId' : this.dashboardId,
                'user'        : this.user,
                'status'      : this.checkDashboardAlertState(),
                'templar'     : this.templar
            });

            this.resetMonitorView = new ResetMonitorView({
                'el'      : $('.reset-monitor-wrap'),
                'templar' : this.templar
            });

            this.addHelpers();

            Backbone.Mediator.pub('view:dashboard:init');
        },

        render : function() {
            this.initMonitors();
            return this;
        },
        /**
         * DashboardView#initMonitors()
         *                  
         * 
         **/
        initMonitors : function() {
            this.getCategories();
            if(this.categories.length && this.categoryId==null) {
              Backbone.Mediator.pub('view:dashboard:category', this.setCategoryId(this.categories[this.carouselIndex].id));
            }
            // publish dashboard information for the header view
            this.getDashboardInfo(this.dashboardId, function(title) {
                Backbone.Mediator.pub('view:dashboard:render', {
                    'title'    : title,
                    'subtitle' : this.getDashboardSubtitle(this.getCategoryIndex()),
                    'nav'      : {
                        'ecosystem' : false,
                        'dashboard' : true
                    },
                    'dashboardId'    : this.dashboardId
                });
            }.bind(this));

            this.updateMonitorList();
            this.setupCarousel();
            this.setupDrop();
            this.goToCategory();

            Backbone.Mediator.pub('view:dashboard:complete');
        },

        setCategories : function(categories) {
            // we need to remove the parent if categories exist
            _.each(categories, function(category, index) {
                if ( category.children.length ) {
                    this.categories.splice(index,1);
                }
            }, this);
            
            this.categories = categories;
        },

        getCategories : function() {
            $.ajax({
                url : '/dashboards/' + this.dashboardId + '/children',
                async : false,
                success : function(result) {
                    var categories = result;
                    // NOTE : a decision was made once a category exists
                    //        to move all current monitors to that category
                    //        and never show the parent
                    this.setCategories(categories);
                }.bind(this)
            });
        },

        setupDrop : function() {
            this.$monitorDragWraps = $('.small-monitor-drag');
            this.$monitorWraps     = $('.small-monitor-wrap');

            this.$monitorWraps.droppable({ 
                accept : '.small-monitor',
                
                over : function(e, ui) {
                    $(e.target).addClass('active-drop');
                    ui.draggable.draggable( 'option', 'revert', false );
                },
                out : function(e, ui) {
                    $(e.target).removeClass('active-drop');
                    ui.draggable.draggable( 'option', 'revert', true );
                }, 
                drop : function(e, ui) {
                    $(e.target).removeClass('active-drop');
                    $(window).trigger('resize');
                }
            });
        },

        setupCarousel : function() {
            this.$carousel = $('#dashboardCarousel').carousel({
                interval : false
            });

            this.$el.find('.icon-chevron-sign-right').click(function() {
                this.$carousel.carousel('next');
            }.bind(this));

            this.$el.find('.icon-chevron-sign-left').click(function() {
                this.$carousel.carousel('prev');
            }.bind(this));
        },

        getDashboardSubtitle : function(carouselIndex) {
            this.getCategories();
            var subtitle = '';
            if ( ( this.categories.length >= 1 ) &&
                 ( this.parentDashboardInfo.id !== this.getCategoryId() ) ) {

                subtitle = _.str.capitalize( this.categories[carouselIndex].name ) + ' Dashboard';
            } else {
                subtitle = 'Monitor Dashboard';
            }

            return subtitle;
        },

        publishDashboardSubtitle : function(carouselIndex) {
            Backbone.Mediator.pub('view:dashboard:render', {
                'subtitle' : this.getDashboardSubtitle(carouselIndex)
            });
        },

        advanceCarousel : function(e) {
            if(e) e.stopPropagation();

            this.carouselIndex = this.$el.find('.item.active').index('.item');
            this.setCategoryId( ( this.categories.length ) 
                                ? this.categories[this.carouselIndex].id 
                                : this.getCategoryId() );

            
            this.router.navigate('dash/' + this.dashboardId + '/category/' + this.getCategoryId() );
            this.$el.find('.dashboard-' + this.getCategoryId()).css({
                'min-height' : this.$el.find('.dashboard-' + this.getCategoryId() + ' .monitor-grid').height() + 40
            });

            this.publishDashboardSubtitle(this.carouselIndex);
            Backbone.Mediator.pub('view:dashboard:category', this.getCategoryId());
            $(window).trigger('resize');
        },

        getCategoryIndex : function() {
            var currentIndex = 0;
            _.each(this.categories, function(category, index) {
                if ( this.getCategoryId() === category.id ) {
                    currentIndex = index;
                }
            }, this);

            return currentIndex;
        },

        goToCategory : function() {
            if ( this.getCategoryIndex() ) {
                // When we advance directly to a slide
                // animation is unnecessary
                this.$carousel.toggleClass('slide');
                this.$carousel.carousel(this.getCategoryIndex());
                this.$carousel.toggleClass('slide');
            }
            
            if ( this.categories.length <= 1 ) {
                this.$el.find('.carousel-indicators, .carousel-control').hide();
            }
        },

        // This should return an id no matter what
        // whether it's a category ( which is just a nested dashboard )
        // or dashboard id
        getCategoryId : function() {
            return this.categoryId;
        },

        setCategoryId : function(id) {
            this.categoryId = ( !_.isNull(id) ) ? id : this.categoryId;
            return this.getCategoryId();
        },

        getMonitorOrder : function() {
            var userPreferences = this.user.get('preferences');

            if ( this.categories.length ) {
                _.each(this.categories, function(category) {
                    var categoryMonitorOrder = ( userPreferences.dashboards 
                                                 && !_.isEmpty(userPreferences.dashboards[category.id]) )
                                             ? userPreferences.dashboards[category.id].order
                                             : [];
                    this.currentOrder[category.id] = categoryMonitorOrder;
                }, this);
            } else {
                var dashboardMonitorOrder = ( userPreferences.dashboards 
                                             && !_.isEmpty(userPreferences.dashboards[this.parentDashboardInfo.id]) )
                                         ? userPreferences.dashboards[this.parentDashboardInfo.id].order
                                         : [];
                this.currentOrder[this.parentDashboardInfo.id] = dashboardMonitorOrder;
            }

            return this.currentOrder;
        },

        getDashboardInfo : function(dashboardId, cb) {
            $.ajax({
                url : '/dashboards/' + dashboardId,
                async : false,
                success : function(dashboard) {
                    this.parentDashboardInfo = dashboard;
                    
                    if (typeof cb === 'function') {
                        cb(this.parentDashboardInfo.name);
                    }
                }.bind(this),
                error : function(result) {
                }.bind(this),
                complete : function(jxhr, status) {
                }.bind(this)
            });
        },

        editMonitor : function(id) {
            this.expandedMonitorView.render(id, this.categories, this.getCategoryId(), this.dashboardId);
        },

        updateDash : function(data) {
            if (data && data.status && data.status != 'error') {
                this.collection = new MonitorCollection(null, {
                    dashboardId : this.dashboardId
                });

                this.reinitializeDash(data);
            }
            this.showDash();
        },

        reinitializeDash : function(data) {
            var $parentSibling = this.$el.parent();

            this.router.navigate();
            if ( this.getCategoryId() ) {
                this.router.navigate("dash/" + this.dashboardId + '/category/' + this.getCategoryId(), {trigger: true});
            } else {
                this.router.navigate("dash/" + this.dashboardId, {trigger: true});
            }
        },

        hideDash : function() {
            this.$el.hide();
        },

        showDash : function() {
            this.$el.show();
            // highcharts gets stuck sometimes, firing a 
            // resize event keeps it from sticking
            $(window).trigger('resize');
        },

        updateSavedMonitorStatus : function(data) {
            var model = ( data ) ? data.model : null;

            if ( model ) {
                _.each(this.monitors, function(view) {
                    if(view.model.get('id') === model.get('id')) {
                        view.nextRun();
                    }
                });
            }
        },

        checkDashboardAlertState : function() {
            this.collection.each(function(model) {
                if ( model.get('status') !== 'success' && typeof model.get('status') != 'undefined' && model.get('active') ) {
                    this.dashboardAlert = true;
                }
            });

            if ( this.dashboardAlert ) {
                Backbone.Mediator.pub('view:dashboard:alert');
            }

            return this.dashboardAlert;
        },
        /**
         * SmallMonitorView#updateMonitorList()
         *  
         * This method is simply to place small monitors in bootstrap
         * rows and add them correctly for template render. 
         **/
        updateMonitorList : function() {
            // to store current list in current order
            var monitorCollection = [],
                renderCategories  = [];

            // get current monitor order from user prefs
            this.getMonitorOrder();

            // NOTE: utilize handlebars to determine how many monitors
            // per row are needed which is configurable by this view
            Handlebars.registerHelper('mod', function(indexCount, block) {
                if ( parseInt(indexCount, 10) % (this.rowMonitorLimit) === 0 ) {
                    return block.fn(this);
                }
            }.bind(this));
            // build json payload for template render in handlebars
            if ( this.categories.length ) {
                _.each(this.categories, function(category) {
                    var monitorCollection = new MonitorCollection(null, {
                        dashboardId : category.id
                    });

                    // sometimes there is a preexisting order that may lack
                    // newly added monitors, etc. here we are making sure they 
                    // get rendered at the end of the current user's ordering
                    // preferences array
                    var categoryMonitorOrder = this.currentOrder[category.id];
                    if (categoryMonitorOrder.length !== 0) {
                        // instantiate views that don't have order yet...
                        var unorderedMonitors = _.difference(monitorCollection.pluck('id'), categoryMonitorOrder);
                        // add them to the order array
                        categoryMonitorOrder = _.union(categoryMonitorOrder, unorderedMonitors); 
                        monitorCollection.filterById( categoryMonitorOrder );
                    }

                    this.monitorCollections.push(monitorCollection);
                    category.monitors = monitorCollection.toJSON();
                }, this);
                renderCategories = this.categories;
            } else {
                var monitorCollection = new MonitorCollection(null, {
                    dashboardId : this.parentDashboardInfo.id
                });
                
                var dashboardMonitorOrder = ( this.currentOrder.length ) 
                                          ? this.currentOrder[this.parentDashboardInfo.id]
                                          : [];
                if (dashboardMonitorOrder.length !== 0) {
                    // instantiate views that don't have order yet...
                    var unorderedMonitors = _.difference(monitorCollection.pluck('id'), dashboardMonitorOrder);
                    // add them to the order array
                    dashboardMonitorOrder = _.union(dashboardMonitorOrder, unorderedMonitors); 
                    monitorCollection.filterById( dashboardMonitorOrder );
                }

                this.monitorCollections.push(monitorCollection);
                this.parentDashboardInfo.monitors = monitorCollection.toJSON();

                renderCategories.push(this.parentDashboardInfo);
            }

            // render the dashboard template before we render our
            // small monitors
            this.templar.render({
                path : 'dashboard',
                el   : this.$el,
                data : {
                    'categories' : renderCategories
                }
            });

            _.each(this.monitorCollections, function(monitorCollection) {
                monitorCollection.each(function(monitor) {
                    this.monitors.push(new SmallMonitorView({
                        'el'          : this.$el.find('.small-monitor-' + monitor.get('id'))[0],
                        'model'       : monitor,
                        'dashboardId' : this.dashboardId,
                        'templar'     : this.templar,
                        'user'        : this.user
                    }).render()); 
                }.bind(this));
            }, this);
        },

        destroyMonitors : function() {
            for (viewName in this.monitors) {
                var view = this.monitors[viewName];
                view.destructor();
                delete this.monitors[viewName];
            }
        },

        destructor : function() {
            var $parentSibling = this.$el.parent();

            // start cleaning up monitor views
            this.destroyMonitors();
            // unbind collection
            this.collection.off('remove', this.reinitializeDash, this);
            // unsubscribe from mediator channels
            this.destroySubscriptions();
            // clean up edit/add monitor view
            this.expandedMonitorView.destructor();
            this.addMonitorView.destructor();
            this.alertTimelineView.destructor();
            this.resetMonitorView.destructor();
            
            //
            this.monitors = [];
            this.categories = [];

            this.$el.empty();
            this.$el.remove();
            this.off();

            // place the containing element back in the page for later
            $parentSibling.prepend("<div class='monitor-panel container clearfix'>");
        }
    });

    return DashboardView;
});
