var ko_data = { query: ko.observable(''), results: ko.observable([]), status_msg: ko.observable('&nbsp;') };
var tr_token;
var search_cache = {};

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

function get_uri_param(param) {
    var query = window.location.search.substring(1).split('&');
    for (i in query) {
        var kv = query[i].split('=');
        if (kv[0] == param) {
            return decodeURIComponent(kv[1]);
        }
    }
    return null;
}

function search() {
    ko_data.status_msg('Searching...');

    var query = $('#search-q').val();

    if (search_cache[query]) {
        show_results(query, search_cache[query]);
    } else {
        $.ajax("/tz/feed?q="+encodeURIComponent(query))
            .done(function(data) {
                var items = $(data).find("item");

                results = map_array(items, function(item) {
                    return {
                        title: item.find("title").text(),
                        link: item.find("link").text(),
                        torrent_link: "https://torcache.net/torrent/"+split_last(item.find("link").text(), "/").toUpperCase()+".torrent",
                        date: (new Date(item.find("pubDate").text())).toISOString(),
                        info: item.find("description").text().replace(/ Hash: .*$/g, ''),
                    };
                });
                search_cache[query] = results;

                show_results(query, results);
            });
    }

    return false;
}

function show_results(query, results) {
    $('#search-q').select();
    if (results.length == 0) {
        ko_data.status_msg('<i class="icon icon-warning-sign"></i> No search results! Try searching something else..');
        return;
    }

    ko_data.status_msg('&nbsp;');
    // knock it out!
    ko_data.query(query);
    ko_data.results(results);
    setup_result_events();

    $('#results').modal('show');
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

    // ui feedback
    anchor.parent().css('display', 'inherit');
    anchor.button('loading');

    // backend rolling
    var url = anchor.prop('href');
    var o = { method: 'torrent-add', arguments: { filename: url } }
    tr_request(o, function(data) {
        anchor.button('reset');
        if (data.result == "success") {
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
        } else {
            var toks = data.result.split(":");
            toks.shift();
            var error = toks.join(":");
            anchor
                .removeClass("btn-default")
                .addClass("btn-danger")
                .html('<i class="icon icon-exclamation-sign"></i>&nbsp;' + error)
            ;
        }
    });

    return false;
}

function trigger_uri_search() {
    var query = get_uri_param('q');
    if (!query) return;

    $('#search-q').val(query);
    $('#search-btn').click();
}

$(document).ready(function() {
    $('#search-form').submit(search);
    $('#results').on('hidden.bs.modal', function() {
        $('#search-q').focus();
    });

    $('#search-q').focus();
    ko.applyBindings(ko_data);

    trigger_uri_search();
});

function setup_result_events() {
    // target=_blank
    $('a').prop('target','_blank');

    // download
    $('.download-btn').click(download);

    // time ago
    $('time.timeago').timeago();
}
