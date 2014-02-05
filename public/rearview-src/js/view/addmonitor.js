define([
    'view/base',
    'model/monitor',
    'codemirror',
    'codemirror-ruby',
    'jquery-validate',
    'parsley'
], function(
    BaseView,
    MonitorModel,
    CodeMirror
){

    var AddMonitorView = BaseView.extend({
        scheduleViewInitialized : false,
        metricsViewInitialized  : false,
        scheduleView            : true,

        el : '.add-monitor-wrap',

        subscriptions : {
            'view:dashboard:category' : 'updateDashboardId'
        },

        events : {
            'click .setMetrics'   : 'advanceToMetrics',
            'click .testGraph'    : 'testMetrics',
            'click .nameSchedule' : 'backToSchedule',
            'click .saveFinish'   : 'saveFinish',
            'click .back'         : 'exitFullScreen',
            'hide #addMonitor'    : 'modalClose',
            'show #addMonitor'    : 'modalShow',
            'shown #addMonitor'   : 'focusFirst'
        },

        initialize : function(options) {
            _.bindAll(this);
            this.user        = options.user;
            this.dashboardId = options.dashboardId;
            this.templar     = options.templar;

            // use debounce to throttle resize events and set the height when
            // the viewport changes.
            var resize = _.debounce(this.adjustModalLayout, 500);

            // Add the event listener
            $(window).resize(resize);
            this.render();
        },

        render : function() {
            this.setElement( $('.add-monitor-wrap') );

            this.templar.render({
                path : 'addmonitor',
                el   : this.$el,
                data : {}
            });

            this.templar.render({
                path : 'schedulemonitor',
                el   : this.$el.find('.content-wrap'),
                data : {
                  'user' : this.user.toJSON()
                }
            });

            this.scheduleViewInitialized = true;

            // scheduling is the first step in add monitor workflow
            this.setScheduleValidation();

            // store reference to modal
            this.$modal = this.$el.find('.add-monitor');
            this.resizeModal($('#addMonitor'), 'large');
        },

        updateDashboardId : function(id) {
            this.dashboardId = id;
            this.model.set({
                'dashboardId' : this.dashboardId
            });
        },

        /** Non-Backbone methods **/

        /**
         * AddMonitorView#adjustModalLayout()
         *
         * Dynamic adjustment of elements within the modal interface
         **/
        adjustModalLayout : function() {
            var $modal             = $('#addMonitor'),
                sizes              = this.resizeModal($modal, 'large'),
                heroUnitMin        = 325,
                heroAdjust         = 80,    // hero unit height adjust
                testFieldsetAdjust = 150,
                graphOutputAdjust  = 80;

            // only adjust if not the scheduling view step
            if ( !this.scheduleView ) {
                var heroMinHeightCheck = ( sizes.body.height - heroAdjust ) > heroUnitMin
                                       ? sizes.body.height - heroAdjust
                                       : heroUnitMin;

                // make all the needed height, width calculation and DOM adjustments
                $modal.find('.hero-unit').css({
                    'height' : heroMinHeightCheck
                });

                var MirrorHeightCalculation = Math.floor((heroMinHeightCheck - testFieldsetAdjust ) / 2);

                this.expressionsMirror.setSize(null, MirrorHeightCalculation);
                this.metricsMirror.setSize(null, MirrorHeightCalculation);

                var graphOutputHeightCalculation = Math.floor(( heroMinHeightCheck - graphOutputAdjust ) / 2);

                $modal.find('.graph').css({
                    'height' : graphOutputHeightCalculation
                });

                // highcharts graph needs to be sized via highcharts api
                this.chart.setSize(null, graphOutputHeightCalculation);

                $modal.find('#outputView').css({
                    'height' : graphOutputHeightCalculation
                });
            }
        },
        /**
         * AddMonitorView#advanceToMetrics()
         *
         * Triggers form validation which on success advances to the metrics
         * view.
         **/
        advanceToMetrics : function() {
            // validate form
            this.scheduleForm.parsley('validate');
        },
        /**
         * AddMonitorView#backToSchedule()
         *
         * Sets the schedule view when going backwards through the add monitor
         * workflow.
         **/
        backToSchedule : function() {
            this._setupScheduleView();
        },
        /**
         * AddMonitorView#exitFullScreen(e)
         *
         * Method for changing styles on CodeMirror in question so the user
         * can work in a fullscreen setting.
         **/
        exitFullScreen : function(e) {
            var $closeButton       = this.$el.find('button.close'),
                $backButton        = this.$el.find('button.back'),
                $metricsEditor     = $('.add-monitor .metrics .CodeMirror'),
                $expressionsEditor = $('.add-monitor .expressions .CodeMirror');

            $closeButton.show();
            $backButton.hide();

            $metricsEditor.removeClass('fullscreen');
            if ( $metricsEditor.data('beforeFullscreen') ) {
                $metricsEditor.height($metricsEditor.data('beforeFullscreen').height);
                $metricsEditor.width($metricsEditor.data('beforeFullscreen').width);
            }
            this.metricsMirror.refresh();

            $expressionsEditor.removeClass('fullscreen');
            if ( $expressionsEditor.data('beforeFullscreen') ) {
                $expressionsEditor.height($expressionsEditor.data('beforeFullscreen').height);
                $expressionsEditor.width($expressionsEditor.data('beforeFullscreen').width);
            }
            this.expressionsMirror.refresh();
        },
        /**
         * AddMonitorView#setScheduleValidation()
         *
         * Sets up the front end form validation for the name field which is required.
         * If name is present, save the sceduling data to the monitor model and setup the
         * next view in the add monitor workflow to set up the metrics data.
         **/
        setScheduleValidation : function() {
            this.scheduleForm = $('#namePagerForm');

            var validator = this.scheduleForm.parsley({
                listeners: {
                    onFormSubmit : function ( isFormValid, event, ParsleyForm ) {
                        if (isFormValid) {
                            this._setSchedule();
                            this._setupMetricsView();
                        }
                    }.bind(this)
                }
            });
        },
        setMetricsValidation : function() {
            $.validator.addMethod('code', function(value, element) {
                var mirror  = $(element).data('CodeMirror'),
                    wrapper = $( mirror.getWrapperElement() );
                return this._validateMirror(mirror);
            }.bind(this), 'This field is required.');

            $.validator.addMethod('metric-ruby', function(value, element) {
                var valid = false;

                $.ajax({
                    url   : '/monitor.json',
                    type  : 'post',
                    data  : this.model.toJSON(),
                    async : false,
                    success : function( response ) {
                        if ( response.status == 'success' ) {
                            valid = true;
                        }
                    }
                });
                return valid;
            }, 'Your metrics code does not validate.');

            $.validator.addMethod('expression-ruby', function(value, element) {
                var valid = false;

                $.ajax({
                    url   : '/monitor.json',
                    type  : 'post',
                    data  : this.model.toJSON(),
                    async : false,
                    success : function( response ) {
                        if ( response.status == 'success' || value == '') {
                            valid = true;
                        }
                    }
                });
                return valid;
            }.bind(this), 'Your expression code does not validate.');

            this.metricsForm = $('#metricsExpressionsForm');

            // set up form validation
            this.metricsForm.validate({
                rules : {
                    'inputMetrics' : {
                        'code'        : true,
                        'expression-ruby' : true
                    },
                    'inputExpressions' : {
                        'expression-ruby' : true
                    }
                },
                errorPlacement: function(error, element) {
                    var mirror = $(element).data('CodeMirror');
                    if(mirror) {
                        var wrapper = $( mirror.getWrapperElement() );
                        this._validateMirror(mirror);
                        error.insertAfter(wrapper);
                    } else {
                        error.insertAfter(element);
                    }
                }.bind(this),
                highlight : function(label) {
                    $(label).closest('.control-group').addClass('error');
                    $(label).closest('fieldset').addClass('error');
                },
                success : function(label) {
                    $(label).closest('.control-group').removeClass('error');
                    $(label).closest('fieldset').removeClass('error');
                    $(label).remove();
                },
                submitHandler : function(form) {
                    this._saveMonitor(function() {
                        this._closeModal();
                    }.bind(this));
                }.bind(this)
            });
        },
        /**
         * AddMonitorView#testMetrics()
         *
         * Set scheduling data to the monitor model and post the data to
         * the /job route which will return the proper graphite data.
         * Finally, format the returned data for HighCharts to consume and
         * render.
         **/
        testMetrics : function() {
            this._setMetrics();

            $.post('/monitor.json', this.model.toJSON(), function(result) {
                if (result.graph_data) {
                    var formattedGraphData = this.formatGraphData( result.graph_data );
                    this.renderGraphData(this.chart, formattedGraphData);

                    // set the output field from the std out response
                    $('#outputView').val(result.output);
                }

                if(result.status === 'error') {
                    Backbone.Mediator.pub('view:addmonitor:test', {
                        'model'     : this.model,
                        'message'   : "The monitor '" + this.model.get('name') + "' produced an error after testing.",
                        'attention' : 'Monitor Test Error!',
                        'status'    : 'error'
                    });
                }
            }.bind(this))
            .error(function(result) {
                Backbone.Mediator.pub('view:addmonitor:test', {
                    'model'     : this.model,
                    'message'   : "The monitor '" + this.model.get('name') + "' produced an error after testing.",
                    'attention' : 'Monitor Test Error!',
                    'status'    : 'error'
                });
            }.bind(this));
        },
        /**
         * AddMonitorView#modalClose(e)
         *
         **/
        modalClose : function(e) {
            // NOTE : hack, figure out backbone events on hidden.
            // ie. there are 2 nested bootstrap ui elements and I'm
            // trying to bind to one hidden event and to another,
            // but ALL hidden events are firing all bound methods.
            if ( $(e.target).hasClass('add-monitor') ) {
                e.stopPropagation();

                // reset addMonitorView for when modal closes
                if (this.metricsViewInitialized) {
                    this.backToSchedule();
                    this.metricsViewInitialized = false;
                }

                Backbone.Mediator.pub('view:addmonitor:close');
            }
        },
        /**
         * AddMonitorView#modalShow()
         *
         **/
        modalShow : function() {
            Backbone.Mediator.pub('view:addmonitor:show');
        },
        /**
         * AddMonitorView#resize()
         */
        resize : function() {
            return _.debounce(this.adjustModalLayout, 500);
        },
        /**
         * AddMonitorView#saveFinish()
         *
         * Save the current model and close the modal dialogue.
         **/
        saveFinish : function() {
            this._setMetrics();

            $('#inputMetrics').css({
                'margin-left' : '-10000px',
                'left'        : '-10000px',
                'display'     : 'block',
                'position'    : 'absolute'
            });
            $('#inputExpressions').css({
                'margin-left' : '-10000px',
                'left'        : '-10000px',
                'display'     : 'block',
                'position'    : 'absolute'
            });

            this.metricsForm.submit();
        },
        setHelp : function() {
            var $content = '';

            $.ajax({
                url     : rearview.path + '/help/quick.html',
                async   : false,
                success : function( response ) {
                    $content = response;
                }
            });

            var $help = this.$el.find('.help');

            $help.tooltip({
                container : '.expressions-metrics',
                trigger   : 'manual',
                html      : true,
                placement : 'right',
                delay     : { show : 100, hide : 200 },
                title     : $content
            }).click(function(e) {
                e.stopPropagation();
                $(this).tooltip('toggle');
            });
        },
        /**
         * AddMonitorView#destructor()
         *
         * Try and keep memory leaks from happening by cleaning up DOM,
         * nulling out references, and unbinding events. Also since this
         * view sticks around, we need to reset things such as a new model
         * for saving next time.
         **/
        destructor : function() {
            this.metricsViewInitialized  = false;
            this.scheduleViewInitialized = false;
            this.metricsMonitorFooter    = null;
            this.scheduleMonitorBody     = null;
            this.scheduleMonitorFooter   = null;

            var prevSiblingEl = this.$el.prev();

            // cleanup events tied to template feature if init'd
            if ( this.$template ) {
                this.$template.off();
            }
            this.remove();
            this.off();

            // containing element in server side template is removed for garbage collection,
            // so we are currently putting a new one in it's place after this process
            $("<section class='add-monitor-wrap'></section>").insertAfter(prevSiblingEl);
        },


        /*
         * PSEUDO-PRIVATE METHODS (internal)
         */


        /** internal
         * AddMonitorView#_closeModal()
         *
         * Call hide on the modal initialized to a saved DOM element.
         **/
        _closeModal : function() {
            this.$modal.modal('hide');
        },
        /** internal
         * AddMonitorView#_getTemplateMetaData(cb)
         * - cb (Function): method to be called after response received
         *
         * Grab meta data for exisitng expression templates
         **/
        _getTemplateMetaData : function(cb) {
            $.ajax({
                url     : rearview.path + '/monitors/index.json',
                success : function( response ) {
                    if ( typeof cb === 'function' ) {
                        cb(response);
                    }
                }
            });
        },
        /** internal
         * AddMonitorView#_initCodeMirror()
         *
         * Setup code entry areas on the metrics view.
         **/
        _initCodeMirror : function() {
            var $expressions            = this.$el.find('#inputExpressions')[0],
                expressionsCodeSelector = '.add-monitor .expressions .CodeMirror',
                $metrics                = this.$el.find('#inputMetrics')[0],
                metricsCodeSelector     = '.add-monitor .metrics .CodeMirror',
                $closeButton            = this.$el.find('button.close'),
                $backButton             = this.$el.find('button.back');

            this.expressionsMirror = CodeMirror.fromTextArea( $expressions, {
                value        : '',
                lineNumbers  : true,
                lineWrapping : true,
                height       : '100',
                mode         : 'ruby',
                theme        : 'ambiance',
                onKeyEvent   : function(i, e) {
                    if (( e.keyCode == 70 && e.ctrlKey ) && e.type == 'keydown') {
                        e.stop();
                        return this._toggleFullscreen(expressionsCodeSelector, this.expressionsMirror, $closeButton, $backButton);
                    }
                }.bind(this)
            });

            $($expressions).data('CodeMirror', this.expressionsMirror);

            this.metricsMirror = CodeMirror.fromTextArea( $metrics, {
                value        : '',
                lineNumbers  : true,
                lineWrapping : true,
                mode         : 'ruby',
                theme        : 'ambiance',
                onKeyEvent   : function(i, e) {
                    if (( e.keyCode == 70 && e.ctrlKey ) && e.type == 'keydown') {
                        e.stop();
                        return this._toggleFullscreen(metricsCodeSelector, this.metricsMirror, $closeButton, $backButton);
                    }
                }.bind(this)
            });

            $($metrics).data('CodeMirror', this.metricsMirror);
        },
        /** internal
         * AddMonitorView#_initDatePicker()
         *
         * Set up date picker widget.
         **/
        _initDatePicker : function() {
            this.fromDatePicker = $('#fromDatePicker').datetimepicker();
        },
        /** internal
         * AddMonitorView#_setTemplateSelect(data)
         * - data (Object): data containing metrics/expressions route
         *
         * Bind selection event to populate expressions field
         **/
        _setTemplateSelect : function(data) {
            this.$template = this.$el.find('#selectTemplate');
            this.$template.data('template', data);

            this.$template.on('change', function() {
                var data = this.$template.data('template');

                // first option is nothing, just lets you know template is optional
                if ( this.selectedIndex > 0 ) {
                    var index        = this.selectedIndex - 1,
                        templateMeta = data[index];

                    if (templateMeta.path) {
                        $.ajax({
                            url     : templateMeta.path,
                            success : function( response ) {
                                if (templateMeta.metrics && templateMeta.metrics.length > 0) {
                                    this.metricsMirror.setValue(templateMeta.metrics.join('\n'));
                                }

                                this.expressionsMirror.setValue(response);
                            }.bind(this)
                        });
                    }
                }
            }.bind(this));
        },
        /** internal
         * AddMonitorView#_setSchedule()
         *
         * Save scheduling data to the monitor model.
         **/
        _setSchedule : function() {
            // grab form data & update model
            this.model.set({
                'userId'        : this.user.get('id'),
                'name'          : this.$el.find('#monitorName').val(),
                'description'   : this.$el.find('#description').val(),
                'alertKeys'     : this.parseAlertKeys( this.$el.find('#pagerDuty').val() ),
                'cronExpr'      : this._createCronExpr()
            });
        },
        /** internal
         * AddMonitorView#_setMetrics()
         *
         * Save metrics data to the monitor model.
         **/
        _setMetrics : function() {
            // grab form data & update model
            this.model.set({
                'userId'      : this.user.get('id'),
                'monitorExpr' : this.expressionsMirror.getValue(),
                'metrics'     : this.metricsMirror.getValue().split('\n'),
                'minutes'     : parseInt(this.$el.find('#minutesBack').val()),
                'toDate'      : this.$el.find('#fromDatePicker').val()
            });
        },
        /** internal
         * AddMonitorView#_setupScheduleView()
         *
         * Store reference to previous page and substitute in the scheduling form.
         **/
        _setupScheduleView : function() {
            // store metrics body & footer
            this.metricsMonitorBody   = $('.add-monitor .modal-body').detach();
            this.metricsMonitorFooter = $('.add-monitor .modal-footer').detach();

            $('.add-monitor').append( this.scheduleMonitorBody );
            $('.add-monitor').append( this.scheduleMonitorFooter );

            this.scheduleView = true;
            this.adjustModalLayout();
        },
        /** internal
         * AddMonitorView#_setupMetricsView()
         *
         * Handles transition between scheduling and metrics views
         * by checking to see if we already have initialized the view,
         * otherwise initializing code entry, date picker, and graph areas.
         **/
        _setupMetricsView : function() {
            var modalContainerEl = $('.add-monitor');

            if ( !this.metricsViewInitialized ) {
                this.scheduleMonitorBody   = $('.add-monitor .modal-body').detach();
                this.scheduleMonitorFooter = $('.add-monitor .modal-footer').detach();


                // get template meta data
                this._getTemplateMetaData(function(data) {

                    this.templar.render({
                        path   : 'setmetrics',
                        el     : modalContainerEl,
                        append : true,
                        data   : {
                            monitor : {
                                templates : data
                            }
                        }
                    });

                    this._setTemplateSelect(data);
                    this._initCodeMirror();
                    this._initDatePicker();
                    this.initGraph( modalContainerEl.find('.graph')[0] );
                    this.setHelp();
                    this.setMetricsValidation();

                    // set that metrics view has been initialized to
                    // prevent initialization again
                    this.metricsViewInitialized = true;
                    this.scheduleView = false;
                    this.adjustModalLayout();
                }.bind(this));
            } else {
                this.scheduleMonitorBody   = $('.add-monitor .modal-body').detach();
                this.scheduleMonitorFooter = $('.add-monitor .modal-footer').detach();

                $('.add-monitor').append( this.metricsMonitorBody );
                $('.add-monitor').append( this.metricsMonitorFooter );
            }
        },
        /** internal
         * AddMonitorView#_saveMonitor(cb)
         * - cb (Function): method to be called after monitor saved.
         *
         * Post new model to the /jobs service route.
         **/
        _saveMonitor : function(cb) {
            this._setMetrics();

            this.model.save({
                'id'          : null,
                'userId'      : this.user.get('id')
            },
            {
                success : function(model, response, options) {
                    if ( typeof cb === 'function' ) {
                        cb();
                    }
                    Backbone.Mediator.pub('view:addmonitor:save', {
                        'model'     : model,
                        'message'   : "The monitor '" + model.get('name') + "' was added.",
                        'attention' : 'Monitor Saved!',
                        'status'    : 'success'
                    });

                    this.model = new MonitorModel();
                }.bind(this),
                error : function(model, xhr, options) {
                    Backbone.Mediator.pub('view:addmonitor:save', {
                        'model'     : model,
                        'tryJSON'   : xhr.responseText,
                        'attention' : 'Monitor Save Error!',
                        'status'    : 'error'
                    });
                }
            });
        }
    });

    return AddMonitorView;
});
