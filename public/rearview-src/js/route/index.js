define([
    'backbone',
    'backbone-mediator'
],
function(
    Backbone
){

    var IndexRouter = Backbone.Router.extend({

        initialize : function(options) {
            this.app = options.app;
        },

        routes : {
            ''                       : 'ecosystem',
            'ecosystem'              : 'ecosystem',
            'dash/:id'               : 'dashboard', // dashboard id
            'dash/:id/expand/:mid'   : 'dashboard', // dashboard id & monitor id
            'dash/:id/category/:cid' : 'category'  // dashboard id & child dashboard id
        },

        category : function(id, cid) {
            // make sure we capture an integer value
            id  = ( id ) ? parseInt(id) : id;
            cid = ( cid ) ? parseInt(cid) : cid;

            if (id) this.app.category(id, cid);
        },

        dashboard : function(id, mid) {
            // make sure we capture an integer value
            id  = ( id ) ? parseInt(id) : id;
            mid = ( mid ) ? parseInt(mid) : mid;

            if (id) this.app.dashboard(id, mid);
        },

        ecosystem : function() {
            this.navigate('ecosystem', { replace : true });

            this.app.ecosystem();
        }
    });

    return IndexRouter;
});