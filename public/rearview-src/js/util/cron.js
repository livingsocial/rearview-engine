define([
    'underscore'
],
function(_){
    var CronUtil = function() {};

    _.extend(CronUtil, {

      //TODO this just checks that the characters are in the valid
      //set but does not assert the syntax of cron
      minuteRegex : RegExp(/^[0-9\*\-,\/]+$/),
      hourRegex : RegExp(/^[0-9\*\-,\/]+$/),
      dayRegex : RegExp(/^[\?0-9\*\-,\/,LW]+$/i),

      isFieldValid : function(field,value) {
        var valid = null;
        switch(field) {
          case 'day':
            valid = value.match(this.dayRegex);
          break;
          case 'hour':
            valid = value.match(this.hourRegex);
          break;
          case 'minute':
            valid = value.match(this.minuteRegex);
          break;
        }
        return valid!=null;
      },

      registerParsleyValidator : function() {
        window.ParsleyValidator.addValidator('cronfield',function(value,field) {
          return this.isFieldValid(field,value);
        }.bind(this),32)
        .addMessage('en', 'cronfield', 'This value is incorrect for cronfield: %s');
      }
      
    }); 
    
    return CronUtil;
});

