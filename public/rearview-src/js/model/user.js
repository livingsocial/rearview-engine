define(
[
    'model/base',
    'backbone-mediator'
],
function(
    Base
){

    /**
     * UserModel
     *
     * Generic model that represents a user in rearview.
     **/
    var UserModel = Base.extend({
        
        url : '/user.json',

        defaults : {
            id          : null,
            email       : '',
            firstName   : '',
            lastName    : '',
            lastLogin   : null,
            createdAt   : null,
            modifiedAt  : null,
            preferences : {}
        },

        parse : function(response, options) {
            if ( response.createdAt ) {
                response.createdAt = this.formatServerDateTime(response.createdAt);
            }
            if ( response.modifiedAt ) {
                response.modifiedAt = this.formatServerDateTime(response.modifiedAt);
            }
            if ( !response.preferences ) {
                response.preferences = {};

                if ( !response.preferences.dashboards ) {
                    response.preferences.dashboards = [];
                }
            }
            
            return response;
        },
        /* a temporary method for converting over
           application -> dashboard terminology switch */
        convertApplicationPrefs : function() {
            var preferences = this.get('preferences');

            if ( preferences.applications ) {
                preferences.dashboards = preferences.applications;
                this.set('preferences', preferences);
                delete preferences.applications;
                this.save();
            }
        },

        updatePrefs : function(preferences) {
            var existingPreferences = this.get('preferences');
            this.set('preferences', _.extend(existingPreferences, preferences));
            this.save();
        },

        // On fetch success, publish event that user model is set.
        initialize : function() {
            _.bindAll(this);

            this.fetch({
                async   : false,
                success : function() {
                    this.convertApplicationPrefs();
                    Backbone.Mediator.pub('model:user:init', this);
                }.bind(this)
            });
        }
    });

    return UserModel;
});