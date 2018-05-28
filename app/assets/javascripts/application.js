// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require turbolinks
//= require jquery3
//= require popper
//= require bootstrap-table
//= require bootstrap-sprockets
//= require select2
//= require cocoon
//= require Chart.bundle
//= require chartkick
//= require_tree .

$(document).on('ready page:load', function() {
  $(function() {
      function init_select2(selector){
        $(selector).select2({
          placeholder: "country"
        });
      };

      init_select2(".country-select")

      $("form").on("cocoon:after-insert", function(_, row){
        field = $(row).find(".country-select")
        init_select2(field);
      });
   });
});

$(document).ready(function() {
  $('body').tooltip({ selector: '[data-toggle=tooltip]' });
});

/**
 * @author zhixin wen <wenzhixin2010@gmail.com>
 * extensions: https://github.com/kayalshri/tableExport.jquery.plugin
 */
(function ($) {
    'use strict';

    var sprintf = $.fn.bootstrapTable.utils.sprintf;

    var TYPE_NAME = {
        json: 'JSON',
        xml: 'XML',
        png: 'PNG',
        csv: 'CSV',
        txt: 'TXT',
        sql: 'SQL',
        doc: 'MS-Word',
        excel: 'MS-Excel',
        xlsx: 'MS-Excel (OpenXML)',
        powerpoint: 'MS-Powerpoint',
        pdf: 'PDF'
    };

    $.extend($.fn.bootstrapTable.defaults, {
        showExport: false,
        exportDataType: 'basic', // basic, all, selected
        // 'json', 'xml', 'png', 'csv', 'txt', 'sql', 'doc', 'excel', 'powerpoint', 'pdf'
        exportTypes: ['json', 'xml', 'csv', 'txt', 'sql', 'excel'],
        exportOptions: {}
    });

    $.extend($.fn.bootstrapTable.defaults.icons, {
        export: 'glyphicon-export icon-share'
    });

    $.extend($.fn.bootstrapTable.locales, {
        formatExport: function () {
            return 'Export data';
        }
    });
    $.extend($.fn.bootstrapTable.defaults, $.fn.bootstrapTable.locales);

    var BootstrapTable = $.fn.bootstrapTable.Constructor,
        _initToolbar = BootstrapTable.prototype.initToolbar;

    BootstrapTable.prototype.initToolbar = function () {
        this.showToolbar = this.options.showExport;

        _initToolbar.apply(this, Array.prototype.slice.apply(arguments));

        if (this.options.showExport) {
            var that = this,
                $btnGroup = this.$toolbar.find('>.btn-group'),
                $export = $btnGroup.find('div.export');

            if (!$export.length) {
                $export = $([
                    '<div class="export btn-group">',
                        '<button class="btn' +
                            sprintf(' btn-%s', this.options.buttonsClass) +
                            sprintf(' btn-%s', this.options.iconSize) +
                            ' dropdown-toggle" aria-label="export type" ' +
                            'title="' + this.options.formatExport() + '" ' +
                            'data-toggle="dropdown" type="button">',
                            sprintf('<i class="%s %s"></i> ', this.options.iconsPrefix, this.options.icons.export),
                            '<span class="caret"></span>',
                        '</button>',
                        '<ul class="dropdown-menu" role="menu">',
                        '</ul>',
                    '</div>'].join('')).appendTo($btnGroup);

                var $menu = $export.find('.dropdown-menu'),
                    exportTypes = this.options.exportTypes;

                if (typeof this.options.exportTypes === 'string') {
                    var types = this.options.exportTypes.slice(1, -1).replace(/ /g, '').split(',');

                    exportTypes = [];
                    $.each(types, function (i, value) {
                        exportTypes.push(value.slice(1, -1));
                    });
                }
                $.each(exportTypes, function (i, type) {
                    if (TYPE_NAME.hasOwnProperty(type)) {
                        $menu.append(['<li role="menuitem" data-type="' + type + '">',
                                '<a href="javascript:void(0)">',
                                    TYPE_NAME[type],
                                '</a>',
                            '</li>'].join(''));
                    }
                });

                $menu.find('li').click(function () {
                    var type = $(this).data('type'),
                        doExport = function () {

                            if (!!that.options.exportFooter) {
                                var data = that.getData();
                                var $footerRow = that.$tableFooter.find("tr").first();

                                var footerData = { };
                                var footerHtml = [];

                                $.each($footerRow.children(), function (index, footerCell) {

                                    var footerCellHtml = $(footerCell).children(".th-inner").first().html();
                                    footerData[that.columns[index].field] = footerCellHtml == '&nbsp;' ? null : footerCellHtml;

                                    // grab footer cell text into cell index-based array
                                    footerHtml.push(footerCellHtml);
                                });

                                that.append(footerData);

                                var $lastTableRow = that.$body.children().last();

                                $.each($lastTableRow.children(), function (index, lastTableRowCell) {

                                    $(lastTableRowCell).html(footerHtml[index]);
                                });
                            }

                            that.$el.tableExport($.extend({}, that.options.exportOptions, {
                                type: type,
                                escape: false
                            }));

                            if (!!that.options.exportFooter) {
                                that.load(data);
                            }
                        };

                    if (that.options.exportDataType === 'all' && that.options.pagination) {
                        that.$el.one(that.options.sidePagination === 'server' ? 'post-body.bs.table' : 'page-change.bs.table', function () {
                            doExport();
                            that.togglePagination();
                        });
                        that.togglePagination();
                    } else if (that.options.exportDataType === 'selected') {
                        var data = that.getData(),
                            selectedData = that.getAllSelections();

                        // Quick fix #2220
                        if (that.options.sidePagination === 'server') {
                            data = {total: that.options.totalRows};
                            data[that.options.dataField] = that.getData();

                            selectedData = {total: that.options.totalRows};
                            selectedData[that.options.dataField] = that.getAllSelections();
                        }

                        that.load(selectedData);
                        doExport();
                        that.load(data);
                    } else {
                        doExport();
                    }
                });
            }
        }
    };
})(jQuery);


(function($) {
    $(function() {
        function init_select2(selector){
          $(selector).select2({
            placeholder: "country"
          });
        };

        init_select2(".country-select")

        $("form").on("cocoon:after-insert", function(_, row){
          field = $(row).find(".country-select")
          init_select2(field);
        });
    });
})(jQuery);

function htmlSorter(a, b) {
  var a = $(a).text();
  var b = $(b).text();
  if (a < b) return -1;
  if (a > b) return 1;
  return 0;
}

function priceSorter(a, b) {
  a = a.replace('$', '');
  a = a.replace('.', '');
  a = a.replace(',', '');
  a = parseInt(a);
  b = b.replace('$', '');
  b = b.replace('.', '');
  b = b.replace(',', '');
  b = parseInt(b);
  if (a < b) {
    return 1;
  }
  if (a > b) {
    return -1;
  }
  return 0;
}

$(document).on('change', '#country', function(e) {
    var country = $('#country :selected').text();
    var url = '/cities?country='+country;
    window.open(url, '_self');
});
