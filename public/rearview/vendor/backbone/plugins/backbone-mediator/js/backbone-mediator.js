/**
 * |-------------------|
 * | Backbone-Mediator |
 * |-------------------|
 *  Backbone-Mediator is freely distributable under the MIT license.
 *
 *  <a href="https://github.com/chalbert/Backbone-Mediator">More details & documentation</a>
 *
 * @author Nicolas Gilbert
 *
 * @requires _
 * @requires Backbone
 */

!function(t){"function"==typeof define&&define.amd?define(["underscore","backbone"],t):t(_,Backbone)}(function(t,e){var i,n={},s=e.View.prototype.delegateEvents,o=e.View.prototype.undelegateEvents;return e.Mediator={subscribe:function(t,e,i,s){n[t]||(n[t]=[]),n[t].push({fn:e,context:i||this,once:s})},publish:function(t){if(n[t])for(var i,s=[].slice.call(arguments,1),o=0,c=n[t].length;c>o;o++)i=n[t][o],i.fn.apply(i.context,s),i.once&&(e.Mediator.unsubscribe(t,i.fn,i.context),o--)},unsubscribe:function(t,e,i){if(n[t])for(var s,o=0;o<n[t].length;o++)s=n[t][o],s.fn===e&&s.context===i&&(n[t].splice(o,1),o--)},unsubscribeChannel:function(t){if(n[t])for(var e,i=0;i<n[t].length;i++)e=n[t][i],n[t].splice(i,1),i--},subscribeOnce:function(t,i,n){e.Mediator.subscribe(t,i,n,!0)}},i={delegateEvents:function(){s.apply(this,arguments),this.setSubscriptions()},undelegateEvents:function(){o.apply(this,arguments),this.unsetSubscriptions()},subscriptions:{},setSubscriptions:function(i){i&&t.extend(this.subscriptions||{},i),i=i||this.subscriptions,i&&!t.isEmpty(i)&&(this.unsetSubscriptions(i),t.each(i,function(i,n){var s;i.$once&&(i=i.$once,s=!0),t.isString(i)&&(i=this[i]),e.Mediator.subscribe(n,i,this,s)},this))},unsetSubscriptions:function(i){i=i||this.subscriptions,i&&!t.isEmpty(i)&&t.each(i,function(i,n){t.isString(i)&&(i=this[i]),e.Mediator.unsubscribe(n,i.$once||i,this)},this)}},t.extend(e.View.prototype,i),t.extend(e.Mediator,{pub:e.Mediator.publish,sub:e.Mediator.subscribe}),e});