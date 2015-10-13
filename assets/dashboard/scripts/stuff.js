var ko_data = { query: ko.observable(''), results: ko.observable([]), status_msg: ko.observable('&nbsp;') };
var tr_token;

function split_last(string, delim) {
    var tokens = string.split(delim);
    return tokens[tokens.length-1];
}

function map_array(array, func) {
    var result = [];
    array.each(function() {
        result.push(func($(this)));
    });
    return result;
}

function search() {
    ko_data.status_msg('Searching...');

    $.ajax("/tz/feed?q="+encodeURIComponent($('#search-q').val()))
        .done(function(data) {
            var items = $(data).find("item");

            if (items.length == 0) {
                ko_data.status_msg('<i class="icon icon-warning-sign"></i> No search results! Try searching something else..');
                return;
            }

            ko_data.status_msg('&nbsp;');
            // knock it out!
            results = map_array(items, function(item) {
                return {
                    title: item.find("title").text(),
                    link: item.find("link").text(),
                    torrent_link: "http://torcache.net/torrent/"+split_last(item.find("link").text(), "/").toUpperCase()+".torrent",
                    date: (new Date(item.find("pubDate").text())).toISOString(),
                    info: item.find("description").text().replace(/ Hash: .*$/g, ''),
                };
            });
            ko_data.results(results);
            setup_result_events();

            ko_data.query($('#search-q').val());
            $('#results').modal('show');
        });

    return false;
}

function tr_ajaxError(request, error_string, exception, ajaxObject) {
    if (request.status === 409 && (tr_token = request.getResponseHeader('X-Transmission-Session-Id'))) {
        $.ajax(ajaxObject);
    }
}

function tr_request(data, callback) {
    ajaxSettings = {
        url: '/transmission/rpc',
        type: 'POST',
        contentType: 'json',
        dataType: 'json',
        cache: false,
        data: JSON.stringify(data),
        beforeSend: function(XHR){ if (tr_token) { XHR.setRequestHeader('X-Transmission-Session-Id', tr_token); } },
        error: function(request, error_string, exception){ tr_ajaxError(request, error_string, exception, ajaxSettings); },
        success: callback,
    };

    $.ajax(ajaxSettings);
}

function download() {
    var anchor = $(this);
    var url = anchor.prop('href');
    var o = { method: 'torrent-add', arguments: { filename: url } }
    tr_request(o, function() {
        anchor
            .unbind('click')
            .removeClass("btn-default")
            .addClass("btn-info")
            .html('<i class="icon icon-ok"></i>&nbsp;Added to download&nbsp;<i class="icon icon-chevron-right"></i>')
            .click(function() {
                $('#results').modal('hide');
                return false;
            })
        ;
    });
    return false;
}

$(document).ready(function() {
    $('#search-form').submit(search);
    $('#search-q').focus();
    ko.applyBindings(ko_data);
});

function setup_result_events() {
    // target=_blank
    $('a').prop('target','_blank');

    // download
    $('.download-btn').click(download);

    // time ago
    $('time.timeago').timeago();
}
