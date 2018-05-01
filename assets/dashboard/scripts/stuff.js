var ko_data = { query: ko.observable(''), results: ko.observable([]), status_msg: ko.observable('&nbsp;'), free_space: ko.observable('') };

var tr_token;
var search_cache = {};
var search_providers = 1;
var search_counter = 0;

function splitN(string, delim, pos) {
    pos = pos || -1;
    var tokens = string.split(delim);
    if (pos < 0) {
        pos = tokens.length + pos;
    }
    return tokens[pos];
}

function mapArray(array, func) {
    var result = [];
    array.each(function() {
        result.push(func($(this)));
    });
    return result;
}

function uniq(array, func) {
    var result = [];
    var map = [];
    $.each(array, function(idx, value) {
        var mapVal = func(value);
        if (map.indexOf(mapVal) < 0) {
            map.push(mapVal);
            result.push(value);
        }
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

// from https://gist.github.com/lanqy/5193417
// from http://scratch99.com/web-development/javascript/convert-bytes-to-mb-kb/
function bytesToSize(bytes) {
    var sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes == 0) return '0 B';
    var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
    if (i == 0) return bytes + ' ' + sizes[i];
    return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + sizes[i];
}

function search() {
    $('#search-q').blur(); // get rid of the browser autocomplete by focusing out of the text input
    ko_data.status_msg('Searching...');

    var query = $('#search-q').val();

    if ((search_cache[query] || []).length > 0) {
        showResults(query);
    } else {
        /*
        $.ajax("/tz/feed?f="+encodeURIComponent(query))
            .done(function(data) {
                var results = parseTzResults(data);
                handleResults(query, results);
            })
            .fail(function(xhr, textStatus, err) {
                xml = xhr.responseText.split('&').join('&amp;');
                data = $.parseXML(xml);
                var results = parseTzResults(data);
                handleResults(query, results);
            });
        */
        $.ajax("/st/rss?query="+encodeURIComponent(query))
            .done(function(data) {
                var results = parseStResults(data);
                handleResults(query, results);
            })
            .fail(function(xhr, textStatus, err) {
                handleResults(query, []);
            });
    }

    return false;
}

function handleResults(query, results) {
    results = (search_cache[query] || []).concat(results)
        .sort(function(a, b) {
            return (b.seeds*2+b.peers)-(a.seeds*2+a.peers);
        });
    search_cache[query] = uniq(results, function(r) { return r.magnet_link; });
    if (++search_counter == search_providers) {
        showResults(query);
        search_counter = 0;
    }
}

function parseTzResults(data) {
    var items = $(data).find("item");

    return mapArray(items, function(item) {
        var hash = splitN(item.find("link").text(), "/");
        var desc = item.find("description").text();
        var people = desc.match(/Seeds: (\d+) Peers: (\d+)/);
        return {
            title: item.find("title").text(),
            link: item.find("link").text(),
            magnet_link: "magnet:?xt=urn:btih:"+hash,
            date: (new Date(item.find("pubDate").text())).toISOString(),
            info: desc.replace(/ Hash: .*$/g, ''),
            seeds: Number(people[1]),
            peers: Number(people[2]),
        };
    });
}

function parseStResults(data) {
    var items = $(data).find("item");

    return mapArray(items, function(item) {
        var size = bytesToSize(Number(item.find("size").text()));
        var seeds = Number(item.find('torznab\\:attr[name="seeders"]')[0].getAttribute('value'));
        var peers = Number(item.find('torznab\\:attr[name="peers"]')[0].getAttribute('value'));
        return {
            title: item.find("title").text(),
            link: item.find("guid").text(),
            magnet_link: item.find("magneturl").text(),
            date: (new Date(item.find("pubDate").text())).toISOString(),
            info: "Size: " + size + " Seeds: " + seeds + " Peers: " + peers,
            seeds: seeds,
            peers: peers,
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
