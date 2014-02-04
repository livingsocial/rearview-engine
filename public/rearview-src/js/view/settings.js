define([
    'view/base',
    'jquery-validate'
], function(
    BaseView
){
    var SettingsView = BaseView.extend({

        el: '.settings',

        events: {
            'click .saveSettings' : 'saveSettings',
            'click .saveCloseSettings' : 'saveCloseSettings'
        },

        initialize : function(options) {
            _.bindAll(this,'saveSettings','saveCloseSettings','render');
            this.user    = options.user;
            this.templar = options.templar;
        },

        render : function() {
            this.templar.render({
                path : 'settings',
                el   : this.$el,
                data : {
                  'user' : this.user.toJSON()
                }
            });
            this.$modal = this.$el.find('.settings');
            this.resizeModal($('#settings'), 'small', true);
            //this.setSettingsValidation();
        },

        saveSettings : function() {
          this.user.updatePrefs({
            'alertKeys' : this.parseAlertKeys(this.$el.find('.alert-settings textarea').val())
          });
        },

        saveCloseSettings : function() {
          this.saveSettings();
          this.$modal.modal('hide');
        },

        /**
         * SettingsView#setSettingsValidation()
         *
         * Sets up the front end form validation for the name field which is required.
         * If name is present, save the sceduling data to the job model and setup the
         * next view in the add dashboard workflow to set up the metrics data.
         **/
        setSettingsValidation : function() {
            // grab form data
            this.form = $('#addDashboardForm');

            // set up form validation
            this.validator = this.form.validate({
                rules : {
                    'dashboardName' : {
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
         * SettingsView#save()
         *
         * Save the current model.
         **/
        save : function() {
            this._saveDashboard(function() {
                this._cleanUp();
            }.bind(this));
        },
        /**
         * SettingsView#saveFinish()
         *
         * Save the current model and close the modal dialogue.
         **/
        saveFinish : function() {
            this._saveDashboard(function() {
                this._closeModal();
            }.bind(this));
        },

        destructor : function() {
            var $prevSibling = this.$el.prev();

            this.remove();
            this.off();

            // containing element in server side template is removed for garbage collection,
            // so we are currently putting a new one in it's place after this process
            this.$el = $("<section class='settings-wrap'></section>").insertAfter($prevSibling);
        },

        /*
         * PSEUDO-PRIVATE METHODS (internal)
         */

        /** internal
         * SettingsView#_saveDashboard(cb)
         * - cb (Function): method to be called after dashboard saved.
         *
         * Post new model to the POST service route.
         **/
        _saveDashboard : function(cb) {
            this.model.save({
                'userId'      : this.user.get('id'),
                'name'        : this.$el.find('#dashboardName').val(),
                'description' : this.$el.find('#dashboardDescription').val()
            },
            {
                success : function(model, response, options) {
                    this.collection.add(model);

                    Backbone.Mediator.pub('view:adddashboard:save', {
                        'model'     : model,
                        'message'   : "The dashboard '" + model.get('name') + "' was added.",
                        'attention' : 'Dashboard Saved!'
                    });

                    if ( typeof cb === 'function' ) cb();
                }.bind(this),
                error : function(model, xhr, options) {
                    this.validator.showErrors({'dashboardName' : 'That dashboard name already exists!'});
                }.bind(this)
            });
        },
        /** internal
         * SettingsView#_closeModal()
         *
         * Call hide on the modal initialized to a saved DOM element.
         **/
        _closeModal : function() {
            this._cleanUp();
            this.$modal.modal('hide');
        },

        _cleanUp : function() {
            this.$el.find('#dashboardName').val('');
            this.$el.find('#dashboardDescription').val('');
            this.$el.find('#dashboardName').parent().removeClass('error');
            this.validator.resetForm();
            this.model = new DashboardModel();
        }
    });

    return SettingsView;
});
