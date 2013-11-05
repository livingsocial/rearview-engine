define(
[
    'underscore',
    'backbone'
],
function(
    _,
    Backbone
){

    /**
     * BaseModel
     *
     * Generic model that holds common model methods.
     **/

    var BaseModel = Backbone.Model.extend({
        url : '',
        /**
         * BaseView#formatServerDateTime(value) -> 13 digit timestamp
         * - value (String|Int): Can't rely always rely on date format being given to the front end
         *
         * This is a centralized method simply for detecting the date format from the service architecture,
         * where some systems may use a 13 digit timestamp and others a 10, etc.  This method should make 
         * things easier to change wholesale in the future if needed.
         **/
        formatServerDateTime : function(value) { 
            var serverDateLength = value.toString().length;
            return ( serverDateLength == 10 ) ? ( parseInt(value, 10) * 1000 ) : parseInt(value, 10);
        }
    });

    return BaseModel;
});
