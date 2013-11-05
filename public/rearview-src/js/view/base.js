define([
    'jquery',     
    'underscore', 
    'backbone',
    'handlebars',
    'highcharts',
    'underscore-string',
    'highcharts-theme',
    'xdate',
    'backbone-mediator'
], function(
    $, 
    _, 
    Backbone,
    Handlebars,
    HighChart
){  
    var BaseView = Backbone.View.extend({

        assetRoot        : 'public/',    // just a reference for asset url config
        intervalDiviser  : 4,            // used for dynamically reducing x-axis label markers
        infiniteTimes    : [],           // save infinite data in our graphData object
        infiniteLabels   : [],
        infiniteTimesInt : [],
        /**
         * BaseView#addHelpers()
         **/
        addHelpers : function() {
            Handlebars.registerHelper('nl2br', function(text) {
                var nl2br = (text + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + '<br>' + '$2');
                return new Handlebars.SafeString(nl2br);
            });
        },
        /**
         * BaseView#destroySubscriptions()
         **/
        destroySubscriptions : function () {
            for (sub in this.subscriptions) {
                Backbone.Mediator.unsubscribe(sub, this[this.subscriptions[sub]], this);
            }            
        },
        /**
         * BaseView#drawAsInfinite(key) -> Boolean|Null
         **/
        drawAsInfinite : function (key) {
            var match = key.match(/^drawAsInfinite\((.*)\)$/);
            if (match) {
                return _.last(match);
            } else {
                return null;
            }
        },
        /**
         * BaseView#formatGraphData(graphData) -> Object
         * - graphData (Object): payload containing graph data, output, status
         *                       from the /monitors route
         *
         * This method splits out coordinate data into 2 linear arrays keyed to
         * the specific metrics. This makes it easier for high charts to consume
         * the data and graph it. The old data key/value pairs are stored in the 
         * graphite key under the metrics queue created by the metrics field in 
         * the setmetrics.hbs template. 
         **/
        formatGraphData : function( graphData ) {
            var formattedGraphData = _.reduce(_.keys(graphData), (function(accum, key) {
                var graphiteDataRaw     = graphData[key];
                graphData[key]          = {};
                graphData[key].graphite = graphiteDataRaw;
                graphData[key].xInt     = [];
                graphData[key].x        = [];
                graphData[key].y        = [];

                _.each(graphData[key].graphite, function(dataPair) {
                    // NOTE : non standardized date data coming from database, sometimes 13 digits sometimes 10
                    //        in this case 10
                    graphData[key].x.push( new XDate(dataPair[0] * 1000).toUTCString("HH:mm") );
                    graphData[key].y.push( dataPair[1] );
                    graphData[key].xInt.push( dataPair[0] );
                });

                return graphData;

            }), []);

            return formattedGraphData;
        },
        focusFirst : function() {
            this.$el.find('input[type=text]:first').focus();
        },
        /**
         * BaseView#initGraph(el) -> Object
         * - el (Element): container element for graph
         *
         * Just sets up a high chart for any given element container.
         **/
        initGraph : function(el) {
            var self = this;

            self.chart = new Highcharts.Chart({
                exporting : {
                    buttons : { 
                        exportButton : {
                            enabled : false
                        },
                        printButton : {
                            enabled : false
                        }

                    }
                },
                credits: {
                    enabled : false
                },
                chart: {
                    zoomType        : 'x',
                    spacingRight    : 24,
                    animation       : true,
                    renderTo        : el,
                    type            : 'line',
                    borderRadius    : 3,
                    backgroundColor : {
                        stops: [
                            [0, 'rgb(16, 16, 16)'],
                            [1, 'rgb(16, 16, 16)']
                        ]
                    },
                },
                title : {
                    text  : null
                },
                xAxis : {
                    minTickInterval : this,
                    title : {
                        text : null
                    }
                },
                yAxis : {
                    title : {
                        text : null
                    }
                },
                plotOptions: {
                    column: { 
                        animation: true
                    },
                    series: {
                        animation : false,
                        marker: {
                            enabled: false
                        }
                    }
                },
                tooltip : {
                    animation : true
                }
            });

            return self.chart;
        },
        /**
         * BaseView#keyOrder(hash) -> Array
         * - hash : a hash of values
         *
         * Just getting a list of alphabetically sorted hash keys.
         **/
        keyOrder : function(hash) {
            var self = this,
                keys = [];

                keys = _.keys(hash);
                keys = _.sortBy(keys, function (key) {
                    return key.toLowerCase();
                });

            return keys;
        },
        /**
         * BaseView#_renderGraphData(chart, graphData)
         * - chart (Object): HighChart object
         * - graphData (Object): formatted graph data object
         *
         * Adds the right data sets to the given chart.
         **/
        renderGraphData : function(chart, graphData) {
            var self       = this,
                renderData = graphData,
                times      = [],
                colors     = [      // creating an array to a series color scheme to stay consistant between updates from the server
                    '#4572A7', 
                    '#AA4643', 
                    '#89A54E', 
                    '#80699B', 
                    '#3D96AE', 
                    '#DB843D', 
                    '#92A8CD', 
                    '#A47D7C', 
                    '#B5CA92'
                ];

            // clear out previous data series
            while (chart.series.length > 0) {
                chart.series[0].remove(true);
            }
            // remove all existing plot lines
            chart.xAxis[0].removePlotLine('plotLine');

            self.infiniteTimes    = [];
            self.infiniteTimesInt = [];
            self.infiniteLabels   = [];

            _.each(graphData, function(dataSet, key) {
                if ( self.drawAsInfinite(key) ) {
                    var drawAsInfiniteTimes    = [],
                        drawAsInfiniteIntTimes = [];

                    // check for time plots where defineAsInfinite is enabled
                    for (var i = 0; i < dataSet.xInt.length; i++) {
                        if (dataSet.y[i]) {
                            drawAsInfiniteTimes.push(dataSet.x[i]);
                            drawAsInfiniteIntTimes.push(dataSet.xInt[i]);
                        }
                    }

                    self.infiniteTimes.push(drawAsInfiniteTimes);
                    self.infiniteTimesInt.push(drawAsInfiniteIntTimes);
                    self.infiniteLabels.push(self.drawAsInfinite(key));
                    delete graphData[key];
                }
            });

            // go by alpha sorted key order for graph rendering color/label consistancy
            var sortedGraphDataKeys = self.keyOrder(graphData);
            
            // index of array for position placement for drawAsInfinite method
            for (var i = 0; i < sortedGraphDataKeys.length; i++) {
                var dataSet = graphData[sortedGraphDataKeys[i]];

                chart.xAxis[0].setCategories( dataSet.x );
                chart.xAxis[0].options.tickInterval = parseInt((dataSet.x.length / self.intervalDiviser), 10);
                chart.xAxis[0].setExtremes(null, null);

                chart.addSeries({
                    name      : sortedGraphDataKeys[i],
                    data      : dataSet.y,
                    animation : false,
                    color     : colors[i]
                });

                // keep track of x time intervals for each group combined
                // in order to have a complete list of x data points
                times = _.union(times, dataSet.xInt);
            }

            // check to see that there are any infinite lines to plot
            if ( self.infiniteTimes.length ) {
                var infinitesLength = self.infiniteTimes.length - 1;
                for (var i = infinitesLength; i >= 0; i--) {
                    var infiniteTimesPlots = self.infiniteTimesInt[i];

                    if ( infiniteTimesPlots.length ) {
                        for (var j = 0; j < infiniteTimesPlots.length; j++) {

                            // check the position in the time array to place the plot
                            var timeIndex = _.sortedIndex(times, infiniteTimesPlots[j]);

                            if (!_.isNull(timeIndex)) { 
                                chart.xAxis[0].addPlotLine({
                                    id        : 'plotLine',
                                    value     : timeIndex,
                                    color     : 'green',
                                    dashStyle : 'shortdash',
                                    width     : 2,
                                    label     : {
                                        text  : self.infiniteLabels[i],
                                        style : {
                                            color : '#ccc'
                                        } 
                                    }
                                });
                            }   
                        }
                    }
                }
            }
        },
        /**
         * BaseView#formatServerDateTime(value) -> Date Obj
         * - value (String|Int): Can't rely always rely on date format being given to the front end
         * - utc      (Boolean): UTC time format flag
         *
         * This is a centralized method simply for detecting the date format from the service architecture,
         * where some systems may use a 13 digit timestamp and others a 10, etc.  This method should make 
         * things easier to change wholesale in the future if needed.
         **/
        formatServerDateTime : function(value, utc) { 
            var serverDateLength = value.toString().length;
            return ( serverDateLength == 10 ) ? new XDate( parseInt(value, 10) * 1000, utc ) : new XDate( parseInt(value, 10), utc );
        },

        /**
         * BaseView#parseAlertKeys(value) -> Array
         * - value (String): INput string to parse
         *
         * This method is used to parse a string delimited by spaces, commas, or newlines
         **/
        parseAlertKeys : function(value) {
            var parsed = [];
            var fragments = value.split('\n');

            _.each(fragments, function(frag) {
                parsed.push(_.str.words(frag, /([ \,])/));
            });

            // assure a one dimensional array
            parsed = _.flatten(parsed);
            // filter out non valid alert keys
            parsed = _.filter(parsed, function(str) {
                // no blank values and no commas
                return !_.str.isBlank(str) && ( str !== ',' );
            });
            
            return parsed;
        },
        resizeModal : function($modal, size, ignoreHeight) {
            var width            = $(window).width(),
                height           = $(window).height(),
                widthMultiplier  = 0.6,
                heightMultiplier = 0.8;
            
            switch(size) {
                case 'small' :
                    widthMultipler = 0.3; break;
                case 'medium' :
                    widthMultipler = 0.6; break;
                case 'large' :
                    widthMultipler = 0.9; break;
                default : 
                    widthMultipler = 0.6;
            }

            $modal.css({
                width      : width * widthMultipler,
                marginLeft : -(width * (widthMultipler / 2))
            });

            if (!ignoreHeight) {
                $modal.css({
                    height     : height * heightMultiplier
                });
                $modal.find('.modal-body').css({
                    maxHeight : (height * heightMultiplier) - 140,
                    height    : (height * heightMultiplier) - 149
                });
            }

            $modal.each(function () {
                $(this).css({
                    marginTop: -($(this).height() / 2),
                });
            });

            // add a class to add other styling to
            $modal.addClass('modal-' + size);

            return {
                height : $modal.height(),
                width  : $modal.width(),
                body : {
                    height : $modal.find('.modal-body').height(),
                    width  : $modal.find('.modal-body').width()
                }
            };
        },

        
        /** internal
         * BaseView#_processRadioControl(collection[, defaults]) -> String
         * - collection (Object): Element collection
         * - defaults (String): if empty collection, return defaulted string
         *
         * Simply used to process bootstrap button groups and find what is 
         * currently selected. Buttons require data-value attributes to set
         * selected value.
         **/
        _processRadioControl : function(collection, defaults) {
            var activeValues = _.map(collection, function(el) {
                return $(el).attr('data-value');
            });

            if ( activeValues.length > 0 ) {
                return activeValues.join(',');
            } else if ( !defaults ) {
                return '';
            } else {
                return defaults;
            }
        },
        /** internal
         * BaseView#_createCronExpr() -> String
         *
         * Used to set up cron expression from the schedulemonitor.hbs view
         **/
        _createCronExpr : function() {
            var self = this;

            // cron syntax eg. 0 * * * * ?
            return [
                0, // self.$el.find('#inputSeconds').val()
                self.$el.find('#inputMinutes').val(),
                self.$el.find('#inputHours').val(),
                self.$el.find('#inputDays').val(),
                self._processRadioControl(self.$el.find('.month-picker button.active'), '*'),
                self._processRadioControl(self.$el.find('.day-picker button.active'), '?')
            ].join(' ');
        },
        /**
         * BaseView#showOverlay(el, text, class) -> Element
         *
         * 
         **/
        showOverlay : function(el, text, className) {
            var self = this;
            el = $(el);

            if ( !self.overlay ) {
                var className = ( className ) ? className : ''; 
                self.overlay  = $("<div class='overlay " + className + "'><h1></h1></div>");
                el.append(self.overlay);
            }

            self.overlay.find('h1').html(text);
            self.overlay.show();
        },
        /**
         * BaseView#hideOverlay() -> Element
         *
         * 
         **/
        hideOverlay : function() {
            var self = this;
            self.overlay.hide();
        },
        /** internal
         * AddMonitorView#_toggleFullscreen(selector, mirrorRef)
         * - selector (String|DOM Object): Code mirror selector
         * - mirrorRef (Object): Code mirror object reference
         *
         * Set code mirror styles to expand to their container.
         **/
        _toggleFullscreen : function(selector, mirrorRef, closeButton, backButton) {
            var self     = this,
                editorEl = $(selector);

            if (!editorEl.hasClass('fullscreen')) {
                if ( closeButton && backButton ) {
                    closeButton.hide();
                    backButton.show();
                }

                editorEl.data('beforeFullscreen', { 
                    height : editorEl.height(), 
                    width  : editorEl.width() 
                });
                editorEl.addClass('fullscreen');
                editorEl.width('100%');
                editorEl.height('100%');
                mirrorRef.setSize('100%', '100%');
                mirrorRef.refresh();
            } else {
                if ( closeButton && backButton ) {
                    closeButton.show();
                    backButton.hide();
                }

                editorEl.removeClass('fullscreen');
                editorEl.height(editorEl.data('beforeFullscreen').height);
                editorEl.width(editorEl.data('beforeFullscreen').width);
                mirrorRef.refresh();
            }
        },
        _validateMirror : function(mirror) {
            var self    = this,
                wrapper = $( mirror.getWrapperElement() );
            if(self._isNonblank(mirror.getValue())) {
                wrapper.removeClass('error');  
                return true;        
            } else {
                wrapper.addClass('error');
                return false;
            }
        },
        _isNonblank : function(string) {
            var isNonblankRegex = /\S/;
            return String (string).search(isNonblankRegex) != -1;
        },

        getPositions : function(el) {
            var self   = this,
                pos    = $(el).offset(),
                width  = $(el).width(),
                height = $(el).height();
            
            return [ [ pos.left, pos.left + width ], [ pos.top, pos.top + height ] ];
        },

        comparePositions : function( p1, p2 ) {
            var self = this,
                r1   = p1[0] < p2[0] ? p1 : p2,
                r2   = p1[0] < p2[0] ? p2 : p1;
            return ( r1[1] > r2[0] || r1[0] === r2[0] );
        },

        overlaps : function( el1, el2 ) {
            var self = this,
                pos1 = self.getPositions( el1 ),
                pos2 = self.getPositions( el2 );
        
            return self.comparePositions(pos1[0], pos2[0]) && self.comparePositions(pos1[1], pos2[1]);
        }
    });

    BaseView.prototype.destructor = function() {
        this.destroySubscriptions();

        if (this.onDestruct) {
            this.onDestruct();
        }

        this.off();
        this.remove();
        this.$el.empty();
    }

    return BaseView;
});