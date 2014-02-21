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
          this.user.applyPrefs({
            'alertKeys' : this.parseAlertKeys(this.$el.find('.alert-settings textarea').val())
          });
          this.user.save({},
          {
              success : function(model, response, options) {
                Backbone.Mediator.pub('view:settings:save', {
                  'model'     : this.user,
                  'message'   : "message",
                  'attention' : "attention" 
                });
              }.bind(this),
              error : function(model, xhr, options) {
              }.bind(this)
          });

        },

        saveCloseSettings : function() {
          this.saveSettings();
          this.$modal.modal('hide');
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

        _closeModal : function() {
            this._cleanUp();
            this.$modal.modal('hide');
        },

        _cleanUp : function() {
        }
    });

    return SettingsView;
});
