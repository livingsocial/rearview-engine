define([
    'view/base',
    'model/dashboard',
    'collection/monitor',
    'jquery-validate'
], function(
    BaseView,
    DashboardModel,
    MonitorCollection
){
    /* NOTE: Category is simply another dashboard model, but displayed
             differently in the UI.  Currently there is no need to nest
             any dashboards more than a single parent-child relationship */
    var AddCategoryView = BaseView.extend({

        events: {
            'click .saveCloseCategory' : 'checkValidationClose',
            'click .saveCategory'      : 'checkValidation',
            'hidden #addCategory'      : '_cleanUp',
            'shown #addCategory'       : 'focusFirst'
        },

        subscriptions : {
            'view:dashboard:add' : '_openModal'
        },

        initialize : function(options) {
            _.bindAll(this);
            this.user    = options.user;
            this.templar = options.templar;

            Handlebars.registerHelper('toUpperCase', function(value) {
                return ( typeof value === 'string' ) ? value.toUpperCase() : value;
            });
        },

        render : function(data) {
            this.dashboard = ( data ) ? data.dashboard : null;

            this.templar.render({
                path : 'addcategory',
                el   : this.$el,
                data : ( data ) ? data : {}
            });

            this.setElement(this.$el);
            this.setAddCategoryValidation();
            this.$modal = this.$el.find('.add-category');

            // resize add applciation modal to fit screen size
            this.resizeModal($('#addCategory'), 'small', true);
        },
        /**
         * AddCategoryView#setAddCategoryValidation()
         *
         * Sets up the front end form validation for the name field which is required.
         * If name is present, save the sceduling data to the job model and setup the
         * next view in the add dashboard workflow to set up the metrics data.
         **/
        setAddCategoryValidation : function() {
            // grab form data
            this.form = $('#addCategoryForm');
            // set up form validation
            this.validator = this.form.validate({
                rules : {
                    'categoryName' : {
                        'required' : true
                    }
                },
                highlight : function(label) {
                    $(label).closest('.control-group').addClass('error');
                },
                success : function(label) {
                    label.closest('.control-group').removeClass('error');
                    $(label).remove();
                },
                submitHandler : function(form) {
                    if ( this.close ) {
                        this.saveFinish();
                    } else {
                        this.save();
                    }
                }.bind(this)
            });
        },
        checkValidation : function() {
            this.close = false;
            // validate form
            this.form.submit();
        },
        checkValidationClose : function() {
            this.close = true;
            // validate form
            this.form.submit();
        },
        /**
         * AddCategoryView#save()
         *
         * Save the current model.
         **/
        save : function() {
            this._saveCategory(function() {
                this._cleanUp();
            }.bind(this));
        },
        /**
         * AddCategoryView#saveFinish()
         *
         * Save the current model and close the modal dialogue.
         **/
        saveFinish : function() {
            this._saveCategory(function() {
                this._closeModal();
            }.bind(this));
        },

        updateMonitorOrder : function(model) {
            var preferences = this.user.get('preferences');
            if ( preferences.dashboards[this.dashboard.id] ) {
                preferences.dashboards[model.get('id')]   = preferences.dashboards[this.dashboard.id];
                preferences.dashboards[this.dashboard.id] = null;
                this.user.save();
            }
        },

        destructor : function() {
            var $prevSibling = this.$el.prev();

            this.remove();
            this.off();

            // containing element in server side template is removed for garbage collection,
            // so we are currently putting a new one in it's place after this process
            this.$el = $("<section class='add-category-wrap'></section>").insertAfter($prevSibling);
        },

        /*
         * PSEUDO-PRIVATE METHODS (internal)
         */

        _checkFirstCategoryCondition : function(cb) {
            var currentDashboardModel = new DashboardModel({
                    id : this.dashboard.id
                }).fetch({
                    success : function(model, response, options) {
                        if ( _.isFunction(cb) ) cb(model);
                    }.bind(this)
                }); 
        },

        _moveAllCurrentMonitorsToCategory : function() {
            this.model.save({
                userId      : this.user.get('id'),
                name        : this.$el.find('#categoryName').val(),
                description : this.$el.find('#categoryDescription').val()
            }, {
                success : function(model, response, options) {
                    Backbone.Mediator.pub('view:addcategory:save', {
                        'model'     : model,
                        'message'   : "The category '" + model.get('name') + "' was added.",
                        'attention' : 'Category Saved!'
                    });

                    if ( model.get('id') ) {
                        new MonitorCollection(null, {
                            dashboardId : this.dashboard.id,
                            cb          : function(monitors) {
                                monitors.each(function(monitor) {
                                    monitor.save({
                                        'dashboardId' : model.get('id')
                                    });
                                }, this);

                                // update ordering if any from drag & drop
                                this.updateMonitorOrder(model);
                                
                            }.bind(this)
                        });
                    }
                }.bind(this),
                error : function(model, xhr, options) {
                    this.validator.showErrors({'categoryName' : 'That category name already exists!'});
                }.bind(this)
            });
        },
        /** internal
         * AddCategoryView#_saveCategory(cb)
         * - cb (Function): method to be called after category saved.
         *
         * Post new model to the POST service route.
         **/
        _saveCategory : function(cb) {
            this._checkFirstCategoryCondition(function(currentDashboardModel) {
                this.model = new DashboardModel({
                    category    : true,
                    dashboardId : this.dashboard.id
                });

                if ( !currentDashboardModel.get('children').length ) {
                    this._moveAllCurrentMonitorsToCategory();
                    if ( _.isFunction(cb) ) cb();
                } else {
                    this.model.save({
                        userId      : this.user.get('id'),
                        name        : this.$el.find('#categoryName').val(),
                        description : this.$el.find('#categoryDescription').val()
                    }, {
                        success : function(model, response, options) {
                            Backbone.Mediator.pub('view:addcategory:save', {
                                'model'     : model,
                                'message'   : "The category '" + model.get('name') + "' was added.",
                                'attention' : 'Category Saved!'
                            });

                            if ( _.isFunction(cb) ) cb();
                        }.bind(this),
                        error : function(model, xhr, options) {
                            this.validator.showErrors({'categoryName' : 'That category name already exists!'});
                        }.bind(this)
                    });
                }
            }.bind(this));
        },
        /** internal
         * AddCategoryView#_closeModal()
         *
         * Call hide on the modal initialized to a saved DOM element.
         **/
        _closeModal : function() {
            this._cleanUp();
            this.$modal.modal('hide');
        },

        _cleanUp : function() {
            this.$el.find('#categoryName').val('');
            this.$el.find('#categoryDescription').val('');
            this.$el.find('#categoryName').parent().removeClass('error');
            this.validator.resetForm();
            this.model = new DashboardModel();
        },

        _openModal : function(data) {
            this.destructor();
            this.render(data);
            this.$modal.modal('show');
        }
    });

    return AddCategoryView;
});