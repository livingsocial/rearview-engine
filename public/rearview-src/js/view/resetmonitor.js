define([
    'view/base'
], function(
    BaseView
){

    var ResetMonitorView = BaseView.extend({

        subscriptions : {
            'view:smallmonitor:reset' : 'setCurrentMonitor'
        },

        events: {
            'click button.cancel' : 'closeModal',
            'click button.reset'  : 'resetMonitor'
        },

        initialize : function(options) {
            _.bindAll(this, 'setCurrentMonitor', 'resetMonitor', 'closeModal');
            this.templar = options.templar;
            this.render();
        },

        render : function() {
            this.templar.render({
                path : 'resetmonitor',
                el   : this.$el,
                data : {}
            });

            this.$modal = this.$el.find('.reset-monitor');
            // resize add applciation modal to fit screen size
            this.resizeModal($('#resetMonitor'), 'small', true);
        },
        /**
         * ResetMonitorView#setCurrentMonitor()
         *
         **/
        setCurrentMonitor : function(data) {
            this.model = data.model;
        },

        /**
         * ResetMonitorView#resetMonitor()
         *
         **/
        resetMonitor : function(e) {
            this.closeModal();

            $.ajax({
                url   : '/jobs/' + this.model.get('id') + '/reset.json',
                type  : 'post',
                data  : { _method : 'PUT' },
                success : function(result) {
                    Backbone.Mediator.pub('view:resetmonitor:reset', {
                        'model'     : this.model,
                        'message'   : "The '" + this.model.get('name') + "' monitor's history and data were reset.",
                        'attention' : 'Monitor Reset Successful!'
                    });
                }.bind(this),
                error : function() {
                    Backbone.Mediator.pub('view:resetmonitor:reset', {
                        'model'     : this.model,
                        'message'   : "The monitor '" + this.model.get('name') + "' caused an error on reset, please check your monitor code.",
                        'attention' : 'Monitor Activate Error!',
                        'status'    : 'error'
                    });
                }.bind(this)
            });
        },
        /**
         * ResetMonitorView#closeModal
         *
         **/
        closeModal : function() {
            this.$modal.modal('hide');
        },
        /**
         * ResetMonitorView#destructor
         *
         **/
        destructor : function() {
            var prevSiblingEl = this.$el.prev();

            // remember to clean up subscriptions
            this.destroySubscriptions();

            this.remove();
            this.unbind();
            if (this.onDestruct) {
                this.onDestruct();
            }

            // containing element in server side template is removed for garbage collection,
            // so we are currently putting a new one in it's place after this process
            this.$el = $("<section class='reset-monitor-wrap'></section>").insertAfter(prevSiblingEl);
        }
    });

    return ResetMonitorView;
});