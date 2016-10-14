var ko_data = { query: ko.observable(''), results: ko.observable([]), status_msg: ko.observable('&nbsp;'), free_space: ko.observable('') };

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
    $('#search-q').blur(); // get rid of the browser autocomplete by focusing out of the text input
    ko_data.status_msg('Searching...');

    var query = $('#search-q').val();

    if ((search_cache[query] || []).length > 0) {
        showResults(query);
    } else {
        $.ajax("/tz/feed?f="+encodeURIComponent(query))
            .done(function(data) {
                handleResults(query, data);
            })
            .fail(function(xhr, textStatus, err) {
                console.log('FAILED');
                xml = xhr.responseText.split('&').join('&amp;');
                data = $.parseXML(xml);
                handleResults(query, data);
            });
    }

    return false;
}

function handleResults(query, data) {
    var results = parseResults(data);
    search_cache[query] = results;
    showResults(query);
}

function parseResults(data) {
    var items = $(data).find("item");

    return mapArray(items, function(item) {
        var hash = splitLast(item.find("link").text(), "/");
        return {
            title: item.find("title").text(),
            link: item.find("link").text(),
            magnet_link: "magnet:?xt=urn:btih:"+hash,
            date: (new Date(item.find("pubDate").text())).toISOString(),
            info: item.find("description").text().replace(/ Hash: .*$/g, ''),
        };
    });
}

function showResults(query) {
    var results = search_cache[query];

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

function trFrame() {
    return $('#tr-frame')[0].contentWindow;
}

function transmission() {
    return trFrame().transmission;
}

function download() {
    var anchor = $(this);

    // ui feedback
    anchor.parent().css('display', 'inherit');
    anchor.button('loading');

    // backend rolling
    var magnet = anchor.attr('href');
    var paused = !transmission().shouldAddedTorrentsStart();
    var o = { method: 'torrent-add', arguments: { filename: magnet, paused: paused } }

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

    return false;
}

function refreshFreeSpace() {
    var btn = $(this).button('loading');
    downloads_dir = trFrame().$('#download-dir').val();
    transmission().remote.getFreeSpace(downloads_dir, function(path, bytes) {
        ko_data.free_space(trFrame().Transmission.fmt.size(bytes));
        $(this).button('reset');
    }, btn);
}

function triggerUriSearch() {
    var query = getUriParam('q');
    if (!query) return;

    $('#search-q').val(query);
    $('#search-btn').click();
}

$(document).ready(function() {
    $('#search-form').submit(search);
    $('#results').on('hide.bs.modal', function() {
        // modal stays at last search result's scroll position
        // reset to top before hiding modal so that next search results will be scolled to top
        $(this).find('.modal-body').scrollTop(0);
    });
    $('#results').on('hidden.bs.modal', function() {
        $('#search-q').focus();
    });

    $('.anchor-button').focus(function() { $(this).blur(); })
    $('#free-space-refresh').click(refreshFreeSpace);

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

function trLoaded() {
    // I prefer to sort torrents by age
    transmission().setSortMethod('age');

    // Load free space
    $('#free-space-refresh').click();
}
