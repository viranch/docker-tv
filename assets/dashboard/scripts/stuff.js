function getFlag() {
    return ko_data.geo_country().toUpperCase().split('').map(x => String.fromCodePoint(127397 + x.charCodeAt(0))).join('');
}

var ko_data = {
    query: ko.observable(''),
    results: ko.observable([]),
    status_msg: ko.observable('&nbsp;'),
    free_space: ko.observable(''),
    jk_api: ko.observable(''),
    geo_ip: ko.observable(''),
    geo_city: ko.observable(''),
    geo_country: ko.observable(''),
    geo_flag: getFlag
};

var tr_token;
var jk_api = "";
var search_cache = {};

function splitN(string, delim, pos) {
    pos = pos || -1;
    var tokens = string.split(delim);
    if (pos < 0) {
        pos = tokens.length + pos;
    }
    return tokens[pos];
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
        $.ajax("/jk/api/v2.0/indexers/all/results?apikey=" + jk_api + "&Query=" + encodeURIComponent(query))
            .done(function(data) {
                var results = parseJkResults(data);
                handleResults(query, results);
            })
            .fail(function(xhr, textStatus, err) {
                handleResults(query, []);
            });
    }

    return false;
}

function handleResults(query, results) {
    search_cache[query] = results.sort(function(a, b) {
        return (b.seeds*2+b.peers)-(a.seeds*2+a.peers);
    });
    showResults(query);
}

function parseJkResults(data) {
    return data.Results.filter((x) => x.MagnetUri != null).map((item) => Object({
        title: item.Title,
        link: item.Guid,
        magnet_link: item.MagnetUri,
        date: (new Date(item.PublishDate)).toISOString(),
        size: bytesToSize(Number(item.Size)),
        seeds: item.Seeders,
        peers: item.Peers,
    }));
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

function initKO() {
    ko_data.jk_api(jk_api);

    $.ajax('/ip/').done(function(data) {
        ko_data.geo_ip(data.ip);
        ko_data.geo_city(data.city);
        ko_data.geo_country(data.country);
    });
}

$(document).ready(function() {
    if (jk_api != "") {
        $('#search-form').submit(search);
        $('#search-q').focus();
    }

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

    initKO();

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

    // Setup delete action so that free space status and download iframe are refreshed
    var f = trFrame().TransmissionRemote.prototype.removeTorrentsAndData;
    trFrame().TransmissionRemote.prototype.removeTorrentsAndData = function() {
        f.apply(this, arguments);
        $('#free-space-refresh').click();
        $('#idx-frame').contentWindow.location.reload();
    };

    // Setup download finish to refresh free space and download iframe
    var g = trFrame().Transmission.prototype.onTorrentChanged;
    trFrame().Transmission.prototype.onTorrentChanged = function(ev, t) {
        g.apply(this, arguments);
        if (t.fields.percentDone == 1) {
            $('#free-space-refresh').click();
            $('#idx-frame').contentWindow.location.reload();
        }
    }
}
