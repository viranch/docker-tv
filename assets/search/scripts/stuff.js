var ko_data = { results: ko.observableArray() };
var ko_elem;
var tr_token;

function split_last(string, delim) {
    var tokens = string.split(delim);
    return tokens[tokens.length-1];
}

function search() {
    $('#search-status').html('Searching...');

    $.ajax("/tz/feed?q="+encodeURIComponent($('#search-q').val()))
        .done(function(data) {
            var items = $(data).find("item");
            ko_data.results.removeAll();

            if (items.length == 0) {
                $('#search-status').html('<i class="icon icon-warning-sign"></i> No search results! Try searching something else..');
                return;
            }

            $('#search-status').html('&nbsp;');
            // knock it out!
            items.each(function() {
                var item = $(this);
                ko_data.results.push({
                    title: item.find("title").text(),
                    link: item.find("link").text(),
                    torrent_link: "http://torcache.net/torrent/"+split_last(item.find("link").text(), "/").toUpperCase()+".torrent",
                    date: (new Date(item.find("pubDate").text())).toISOString(),
                    info: item.find("description").text().replace(/ Hash: .*$/g, ''),
                });
            });
            setup_result_events();
        });
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
    var url = anchor.attr('href');
    var o = { method: 'torrent-add', arguments: { filename: url } }
    tr_request(o, function() {
        anchor
            .unbind('click')
            .removeClass("btn-default")
            .addClass("btn-info")
            .attr('href', '/transmission')
            .html('<i class="icon icon-ok"></i>&nbsp;Added to download&nbsp;<i class="icon icon-chevron-right"></i>')
            .attr('title', 'Visit download page')
        ;
    });
    return false;
}

$(document).ready(function() {
    $('#search-btn').click(search);
    $('#search-q').keyup(function(e){ if(e.keyCode==13) $('#search-btn').click(); });
    $('#search-q').focus();
    ko.applyBindings(ko_data);
});

function setup_result_events() {
    // target=_blank
    $('a').attr('target','_blank');

    // download
    $('.download-btn').click(download);

    // time ago
    $('time.timeago').timeago();
}
