define([
    'jquery',
    'underscore',
    'backbone',
    'util/templar',
    'util/cron',
    'route/index',
    'view/alert',
    'view/primarynav',
    'view/header',
    'view/addmonitor',
    'view/dashboard',
    'view/adddashboard',
    'view/addcategory',
    'view/ecosystem',
    'view/secondarynav',
    'view/settings',
    'model/user',
    'model/dashboard',
    'collection/monitor',
    'collection/dashboard',
    'backbone-mediator',
    'jquery-timepicker',
    'bootstrap'
], function(
    $,
    _,
    Backbone,
    Templar,
    CronUtil,
    IndexRouter,
    AlertView,
    PrimaryNavView,
    HeaderView,
    AddMonitorView,
    DashboardView,
    AddDashboardView,
    AddCategoryView,
    EcosystemView,
    SecondaryNavView,
    SettingsView,
    UserModel,
    DashboardModel,
    MonitorCollection,
    DashboardCollection
){
    /**
     * App
     *
     * This is the central location that sets up, modifies data, and decides
     * the next view state.  It also initializes and authenticates for the entire
     * application currently.  Kind of a pseudo controller.
     **/
    var App = function() {};

    _.extend(App, {

        initialize : function() {
            _.bindAll(this);
            // check authorization
            this.auth();
            console.log(CronUtil.dayRegex);

            // these views are evergreen, so on initialize of the app this is alright
            this.alert();
            this.primaryNav();
            this.header();
            this.secondaryNav();
            this.addCategory();

            // indicate initialized application
            // and start history object
            Backbone.Mediator.pub('controller:app:init');
            this.controllerInit = true;
            Backbone.history.start();
        },

        /* Initialize Driven */

        addCategory : function() {
            new AddCategoryView({
                'el'         : $('.add-category-wrap'),
                'templar'    : this.templar,
                'user'       : this.user
            });
        },

        alert : function() {
            this.auth();
            this.alertView = new AlertView({
                'el'      : $('.alert-wrap'),
                'templar' : this.templar
            });
        },

        header : function() {
            this.auth();
            new HeaderView({
                'el'      : $('.header-wrap'),
                'templar' : this.templar
            }).render();
        },

        primaryNav : function() {
            this.auth();
            new PrimaryNavView({
                'el'         : $('.primary-nav-wrap'),
                'collection' : this.dashboardCollection,
                'user'       : this.user,
                'templar'    : this.templar
            }).render();
            new SettingsView({
                'el'         : $('.settings-wrap'),
                'user'       : this.user,
                'templar'    : this.templar
            }).render();
        },

        secondaryNav : function() {
            this.auth();
            new SecondaryNavView({
                'el'      : $('.secondary-nav-wrap'),
                'templar' : this.templar
            }).render();
        },

        /* Router Driven */

        category : function(dashboardId, categoryId, monitorId) {
            var views = [];

            this.auth();
            this.destroyViews();

            var monitorCollection = new MonitorCollection(null, {
                dashboardId : dashboardId
            });

            views.push(new DashboardView({
                'el'         : $('.monitor-panel'),
                'collection' : monitorCollection,
                'dashboardId': dashboardId,
                'user'       : this.user,
                'templar'    : this.templar,
                'router'     : this.indexRouter,
                'categoryId' : categoryId
            }));

            this.renderViews(views);

            Backbone.Mediator.pub('controller:dashboard:init', {
                'nav' : {
                    'dashboard' : true
                },
                'monitorId'   : monitorId,
                'dashboardId' : dashboardId
            });
        },

        dashboard : function(dashboardId, monitorId) {
            var views = [];

            this.auth();
            this.destroyViews();

            var monitorCollection = new MonitorCollection(null, {
                dashboardId : dashboardId
            });

            views.push(new DashboardView({
                'el'         : $('.monitor-panel'),
                'collection' : monitorCollection,
                'dashboardId': dashboardId,
                'user'       : this.user,
                'templar'    : this.templar,
                'router'     : this.indexRouter
            }));

            this.renderViews(views);

            Backbone.Mediator.pub('controller:dashboard:init', {
                'nav' : {
                    'dashboard' : true
                },
                'monitorId'   : monitorId,
                'dashboardId' : dashboardId
            });
        },

        ecosystem : function() {
            var views = [];

            this.auth();
            this.destroyViews();

            views.push(new EcosystemView({
                'el'         : $('.ecosystem-dashboard-wrap'),
                'collection' : this.dashboardCollection,
                'templar'    : this.templar
            }));

            var dashboardModel = new DashboardModel();

            views.push(new AddDashboardView({
                'el'         : $('.add-dashboard-wrap'),
                'templar'    : this.templar,
                'model'      : dashboardModel,
                'collection' : this.dashboardCollection,
                'user'       : this.user
            }));

            this.renderViews(views);

            Backbone.Mediator.pub('controller:dashboard:init', {
                'nav' : {
                    'dashboard' : false
                }
            });
        },
        /* Helper Methods */

        /**
         * Controller#destroyViews()
         *
         * Breaks down existing views from the previous route by calling their
         * destructor methods.  Each view is in charge of it's own memory
         * management and it is up to a new route to effectively clean up existing
         * views
         **/
        destroyViews : function() {
            if (this.currentView) {
                while (this.currentView.length > 0) {
                    this.currentView.pop().destructor();
                }
            }
        },
        /**
         * Controller#renderViews(views)
         * - views (Array): list of view references
         *
         * This method handles rendering all views that were initialized in
         * the current route/controller
         **/
        renderViews : function(views) {
            // set current views, so we can properly clean up our previous views
            // on the next destroyViews() execution
            this.currentView = views;

            for (var i = this.currentView.length - 1; i >= 0; i--) {
                this.currentView[i].render();
            }
        },
        /**
         * Controller#auth()
         *
         * Handles initial dashboard load by checking that neccesary items
         * are addressed before anything else liek their is a user, router is
         * set up, etc.
         **/
        auth : function() {
            // set reference to router in our dashboard
            this.indexRouter = ( !this.indexRouter )
                             ? new IndexRouter({
                                 'app' : this
                               })
                             : this.indexRouter;

            this.user = ( !this.user )
                      ? new UserModel()
                      : this.user;

            this.dashboardCollection = ( !this.dashboardCollection )
                                       ? new DashboardCollection()
                                       : this.dashboardCollection;

            // using a front end handlebars template manager
            // which can handle caching in production and template
            // invalidation through versioning
            this.templar = ( !this.templar )
                         ? new Templar([
                               'addcategory',
                               'adddashboard',
                               'addmonitor',
                               'alert',
                               'dashboard',
                               'dashboardtile',
                               'deletemonitor',
                               'expandedmonitor',
                               'header',
                               'primarynav',
                               'schedulemonitor',
                               'secondarynav',
                               'setmetrics',
                               'settings',
                               'smallmonitor'
                           ], {
                             url     : rearview.path + '/templates/',
                             version : ( _.isUndefined(rearview.version) ? '0.0.1' : rearview.version ),
                               cache : ( _.isUndefined(rearview.cache) ? true : false )
                           })
                         : this.templar;
        }
    });

    return App;
});
