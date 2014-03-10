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

      parsleyValidator : function(cb) {
        var validator = function() {};
        _.extend(validator, {
          validationMinlength: 1,
          validators : {
            cronfield : function (val,param) {
              var valid = null;
              switch(param) {
                case 'day':
                  valid = val.match(this.dayRegex);
                break;
                case 'hour':
                  valid = val.match(this.hourRegex);
                break;
                case 'minute':
                  valid = val.match(this.minuteRegex);
                break;
              }
              if(_.isFunction(cb)) {
                valid = cb(val,param,valid);
              }
              return valid!=null;
            }.bind(this)
          },
          messages : {
            cronfield : "Not a valid value for cron field '%s'" 
          }
        });
        return validator;
      }

    }); 
    
    return CronUtil;
});

