define([
    'timeline',
    'view/base'
], function(
    Timeline,
    BaseView
){

    var AlertTimelineView = BaseView.extend({

        events : {
            'shown .accordion-body'  : 'publishTimelineHeight',
            'hidden .accordion-body' : 'publishTimelineHeight'
        },

        subscriptions : {
            'view:dashboard:complete' : 'render'
        },

        initialize : function(options) {
            _.bindAll(this);

            this.templar      = options.templar;
            this.dashboardId  = options.dashboardId;
            this.status       = options.status;
            this.popovers     = [];
            this.openPopovers = [];
            this.alertData    = [];
        },

        render : function() {
            this.templar.render({
                path   : 'alerttimeline',
                el     : this.$el,
                data   : {}
            });

            this.$timeline  = this.$el.find('.alert-timeline .accordion-inner');
            this.$accordion = this.$el.find('.alert-timeline .accordion-body');

            // this.setupAlertTimeline();

            // // notify user with red bell indicator
            // this.setAlertStatus();
        },

        addPopover : function() {
            var self = this;
            jobAlertIdList = _.uniq(self.jobAlertList);

            for (var i = jobAlertIdList.length - 1; i >= 0; i--) {

                var initPopover = function(jobId) {

                    var $content   = $("<div class='timeline-monitor'>"),
                        $closeBtn  = $('<button/>', {
                            'text'  : 'Troubleshoot Monitor',
                            'class' : 'btn'
                        });

                    var $group = $('.timeline-group-' + jobId);

                    var el = $group.popover({
                        trigger   : 'manual',
                        html      : true,
                        placement : 'bottom',
                        delay     : {
                            show : 100,
                            hide : 200
                        },
                        container : 'body',
                        content   : $content
                    }).click(function(e) {
                        e.stopPropagation();
                        var $this = $(this);

                        // remove other open popovers from view
                        _.each(self.openPopovers, function(openPopover) {
                            openPopover.data('popover').tip().removeClass('active');
                            openPopover.data('popover').hide();
                        });
                        // reset list of open popovers
                        self.openPopovers = [];

                        // check that popover is active
                        if ($this.toggleClass('active').hasClass('active')) {
                            $closeBtn.off('click');
                            $('body').off('click');
                            $this.popover('show');

                            // throw up the loading text till the data is retrieved about the incident
                            // Note : better overlay method overiding base.  Need to switch out base
                            self.showOverlay($content.parent(), 'Loading...', 'alert-data-overlay');

                            self.loadAlertIncidentData(jobId, $this, $content, function(incidentData) {
                                // create the table that will hold meta data about incident
                                var $metaTable = self.createMetaTable(incidentData);

                                if ( $this.data('popover').tip().find('.alert-meta-data').length > 0 ) {
                                    $this.data('popover').tip().find('.alert-meta-data').replaceWith($metaTable);
                                } else {
                                    $this.data('popover').tip().append($metaTable);
                                }
                                $this.data('popover').tip().append($closeBtn);

                                // add a popover hide trigger
                                $closeBtn.on('click', function(e) {
                                    e.stopPropagation();
                                    $this.popover('hide');
                                    $this.toggleClass('active');
                                    $closeBtn.off('click');
                                    self.openPopovers = [];
                                    Backbone.Mediator.pub('view:alerttimeline:troubleshoot', jobId);
                                });

                                // push the current element tied to a popover into an array
                                self.openPopovers.push($this);
                                // add a on body trigger to remove popovers as well
                                $('body').on('click', function() {
                                    self.openPopovers = [];
                                    $this.removeClass('active');
                                    $this.popover('hide');
                                });
                            });


                        } else {
                            self.openPopovers = [];
                            $this.popover('hide');
                        }
                    });
                }
                // initialize popovers with correct jobId reference
                initPopover(jobAlertIdList[i]);
            };
        },

        loadAlertIncidentData : function(jobId, $alertEvent, $content, cb) {
            var self = this;

            // load graph data for popover
            var job             = self.collection.get(jobId),
                incidentPattern = /timeline-event-(\d+)/g,
                incidentId      = parseInt(incidentPattern.exec($alertEvent.attr('class'))[1]),
                incidentData    = _.findWhere(self.alertData, {
                    'id' : incidentId
                });

            // get meta data for incident alert
            var name            = job.get('name'),
                startDate       = new XDate(incidentData.start),
                endDate         = new XDate(incidentData.end),
                jobData         = job.toJSON(),
                incidentMinDiff = startDate.diffMinutes(endDate),
                incidentHrsDiff = startDate.diffHours(endDate);

            jobData.toDate  = endDate.toString("MM/dd/yyyy HH:mm");
            // restricting to 500 minutes back to help keep HighCharts from choking
            jobData.minutes = ( incidentMinDiff < 500 ) ? incidentMinDiff : 500;

            var chart = self.initGraph($content[0]);

            $.ajax({
                url   : '/monitor.json',
                type  : 'post',
                data  : job.toJSON(),
                async : false,
                success : function( response ) {
                    if ( response.status == 'success' ) {
                        var formattedGraphData = self.formatGraphData( response.graph_data );
                        self.renderGraphData(chart, formattedGraphData);


                        if ( typeof cb === 'function' ) {
                            cb({
                                'name'  : name,
                                'start' : startDate.toString("MM/dd/yyyy HH:mm"),
                                'end'   : endDate.toString("MM/dd/yyyy HH:mm"),
                                'hrs'   : Math.floor(incidentHrsDiff),
                                'min'   : Math.floor(incidentMinDiff % 60)
                            });
                        }

                        // finally hide the loading text
                        self.hideOverlay($content.parent());
                    }
                }
            });
        },

        // NOTE : Need to abstract this out to a template
        createMetaTable : function(incidentData) {
            return $("<table class='alert-meta-data'><tr><th>Name</th><td>"
                   + incidentData.name
                   + "</td></tr><tr><th>Start</th><td>"
                   + incidentData.start
                   + "</td></tr><tr><th>End</th><td>"
                   + incidentData.end
                   + "</td></tr><tr><th>Duration</th><td>"
                   + incidentData.hrs + ' hr '
                   + incidentData.min + ' min'
                   + "</td></tr></table>");
        },

        publishTimelineHeight : function() {
            var self = this;

            // hide overflow at the beginning of transition
            // to keep a vertical scrollbar from appearing
            Backbone.Mediator.pub('view:alerttimeline:toggle', self.$accordion.height());
            $(document.body).css('overflow','auto');
        },

        setAlertStatus : function() {
            var self = this;
            if (this.status) self.$el.find('.icon-bell-alt').addClass('alert-status');
        },

        setupAlertTimeline : function() {
            var self            = this,
                jobAlertIdList  = [];

            $.ajax('/dashboards/' + self.dashboardId + '/errors', {
                success : function(result) {

                    // format data for timeline.js
                    _.each(result, function(alert) {
                        var startDate = null;

                        // NOTE: set the name for an alert, but this isn't currently
                        // being used for the UI, more for debugging purposes.
                        _.extend(alert, {
                            'name' : ( typeof self.collection.get(alert.jobId) != 'undefined' ) ? self.collection.get(alert.jobId).get('name') : ''
                        });

                        // limiting data range to 2 weeks worth
                        // NOTE : Need to probably have a better rendering system for the alert timeline
                        //        for issues lasting longer than 2 weeks.
                        if ( self.formatServerDateTime(alert.date, true) < new XDate(Date.now(), true).addWeeks(-2) ) {
                            startDate = new XDate(Date.now(), true).addWeeks(-2);
                        } else {
                            startDate = self.formatServerDateTime(alert.date, true);
                        }

                        self.alertData.push({
                            'id'      : alert.id,
                            'jobId'   : alert.jobId,
                            'start'   : startDate,
                            'end'     : ( alert.endDate ) ? self.formatServerDateTime(alert.endDate, true) : self.formatServerDateTime(Date.now(), true),
                            'status'  : alert.status,
                            'content' : alert.name
                        });

                        jobAlertIdList.push(alert.jobId);
                    });

                    // create our timeline
                    self.timeline  = new Timeline(self.$timeline[0]);

                    // default timeline view to current time spanning 1day back and 0.5day into the future
                    var start = new XDate(Date.now() - 2 * 24/2 * 60 * 60 * 1000, true),
                        end   = new XDate(Date.now() + 1 * 24/2 * 60 * 60 * 1000, true);

                    // render the timeline data
                    self.timeline.draw(self.alertData, {
                        'utc'         : true,
                        'start'       : start,
                        'end'         : end,
                        'width'       : '100%',
                        'editable'    : false,
                        'style'       : 'box',
                        'intervalMin' : 1000 * 60 * 10,          // 10 seconds
                        'intervalMax' : 1000 * 60 * 60 * 24 * 3, // 3 day max zoom out
                    });

                    self.$timeline.on('mouseenter', function() {
                        $(window).on('scroll', self.stopBrowserScroll);
                    });
                    self.$timeline.on('mouseleave', function() {
                        $(window).off('scroll', self.stopBrowserScroll);
                    });

                    self.jobAlertList = jobAlertIdList;
                    self.addPopover();
                }
            });
        },

        stopBrowserScroll : function() {
            window.scrollTo(0,0);
        },

        /** internal
         * BaseView#showOverlay(el, text, class) -> Element
         *
         *
         **/
        showOverlay : function(el, text, className) {
            var self = this;
            el = $(el);

            if ( !self.overlay ) {
                var className = ( className ) ? className : '';
                el.data('overlay', $("<div class='overlay " + className + "'><h1></h1></div>"));
                el.append(el.data('overlay'));
            }

            el.data('overlay').find('h1').html(text);
            el.data('overlay').show();
        },
        /** internal
         * BaseView#hideOverlay() -> Element
         *
         *
         **/
        hideOverlay : function(el) {
            var self = this;
            el.data('overlay').hide();
        },

        destructor : function() {
            var self     = this,
                parentEl = self.$el.prev();

            // unsubscribe from mediator channels
            self.destroySubscriptions();

            self.remove();
            self.unbind();
            self.off();

            self.$el.empty();

            // place the containing element back in the page for later
            $("<section class='timeline-wrap clearfix'></section>").insertAfter(parentEl);
        }
    });

    return AlertTimelineView;
});
