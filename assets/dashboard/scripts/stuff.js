var ko_data = { query: ko.observable(''), results: ko.observable([]), status_msg: ko.observable('&nbsp;') };
var tr_token;
var search_cache = {};

function splitLast(string, delim) {
    var tokens = string.split(delim);
    return tokens[tokens.length-1];
}

function mapArray(array, func) {
    var result = [];
    array.each(function() {
        result.push(func($(this)));
    });
    return result;
}

function getUriParam(param) {
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
        showResults(query, search_cache[query]);
    } else {
        $.ajax("/tz/feed?q="+encodeURIComponent(query))
            .done(function(data) {
                var items = $(data).find("item");

                results = mapArray(items, function(item) {
                    var hash = splitLast(item.find("link").text(), "/").toUpperCase();
                    return {
                        title: item.find("title").text(),
                        link: item.find("link").text(),
                        torrent_link: "https://torcache.net/torrent/"+hash+".torrent",
                        magnet_link: "magnet:?xt=urn:btih:"+hash,
                        date: (new Date(item.find("pubDate").text())).toISOString(),
                        info: item.find("description").text().replace(/ Hash: .*$/g, ''),
                    };
                });
                search_cache[query] = results;

                showResults(query, results);
            });
    }

    return false;
}

function showResults(query, results) {
    $('#search-q').select();
    if (results.length == 0) {
        ko_data.status_msg('<i class="icon icon-warning-sign"></i> No search results! Try searching something else..');
        return;
    }

    ko_data.status_msg('&nbsp;');
    // knock it out!
    ko_data.query(query);
    ko_data.results(results);
    setupResultEvents();

    $('#results').modal('show');
}

function transmission() {
    return $('#tr-frame')[0].contentWindow.transmission;
}

function download() {
    var anchor = $(this);

    // ui feedback
    anchor.parent().css('display', 'inherit');
    anchor.button('loading');

    // backend rolling
    var url = anchor.attr('href');
    addDownload(url, anchor, {
        error: function() {
            var magnet = anchor.attr('data-magnet');
            addDownload(magnet, anchor);
        }
    });

    return false;
}

function addDownload(url, anchor, opts) {
    var paused = !transmission().shouldAddedTorrentsStart();
    var o = { method: 'torrent-add', arguments: { filename: url, paused: paused } }
    transmission().remote.sendRequest(o, function(data) {
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
            transmission().remote._controller.refreshTorrents();
        } else {
            if (typeof(opts) != 'undefined' && typeof(opts.error) == 'function') {
                opts.error();
                return false;
            }
            var error = data.result;
            if (error.indexOf(":") > -1) {
                toks = error.split(":");
                toks.shift();
                error = toks.join(":");
            }
            anchor
                .removeClass("btn-default")
                .addClass("btn-danger")
                .html('<i class="icon icon-exclamation-sign"></i>&nbsp;' + error)
            ;
        }
    });
}

function triggerUriSearch() {
    var query = getUriParam('q');
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

    triggerUriSearch();
});

function setupResultEvents() {
    // target=_blank
    $('a').attr('target','_blank');

    // download
    $('.download-btn').click(download);

    // time ago
    $('time.timeago').timeago();
}
