var jade = require('jade/runtime');

module.exports = function template(locals) {
var buf = [];
var jade_mixins = {};
var locals_ = (locals || {}),webdav = locals_.webdav,standard = locals_.standard,tutorials = locals_.tutorials,contactsTutorial = locals_.contactsTutorial,calendarTutorial = locals_.calendarTutorial,server = locals_.server,further = locals_.further,log = locals_.log,login = locals_.login,show = locals_.show,hide = locals_.hide,domain = locals_.domain,calendar = locals_.calendar,client = locals_.client,serverField = locals_.serverField,android = locals_.android,select = locals_.select,calendars = locals_.calendars,url = locals_.url,contacts = locals_.contacts,thunderbird = locals_.thunderbird,files = locals_.files,file = locals_.file,troubleshouting = locals_.troubleshouting,problems = locals_.problems,github = locals_.github,token = locals_.token;
buf.push("<!DOCTYPE html><html lang=\"en\"><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"><title>Cozy - Sync</title><link rel=\"stylesheet\" href=\"/fonts/fonts.css\"><link rel=\"stylesheet\" href=\"stylesheets/app.css\"><link rel=\"icon\" type=\"image/x-icon\" href=\"favicon.ico\"><link rel=\"icon\" type=\"image/png\" href=\"favicon-96x96.png\" sizes=\"96x96\"><link rel=\"icon\" type=\"image/png\" href=\"favicon-16x16.png\" sizes=\"16x16\"><link rel=\"icon\" type=\"image/png\" href=\"favicon-32x32.png\" sizes=\"32x32\"></head><body><div id=\"content\"><div class=\"content-block\"><h1>" + (jade.escape((jade.interp = webdav) == null ? '' : jade.interp)) + "</h1><p>" + (jade.escape((jade.interp = standard) == null ? '' : jade.interp)) + "</p><p>" + (jade.escape((jade.interp = tutorials) == null ? '' : jade.interp)) + "<ul><li><a target=\"_blank\" href=\"https://docs.cozy.io/en/mobile/contacts.html\">" + (jade.escape((jade.interp = contactsTutorial) == null ? '' : jade.interp)) + "</a></li><li><a target=\"_blank\" href=\"https://docs.cozy.io/en/mobile/calendar.html\">" + (jade.escape((jade.interp = calendarTutorial) == null ? '' : jade.interp)) + "</a></li></ul></p></div><div class=\"content-block\"><h1>" + (jade.escape((jade.interp = server) == null ? '' : jade.interp)) + "</h1><p>" + (jade.escape((jade.interp = further) == null ? '' : jade.interp)) + "</p><div class=\"url credentials\"><p>" + (jade.escape((jade.interp = log) == null ? '' : jade.interp)) + ":&nbsp;<span id=\"login-span\">" + (jade.escape((jade.interp = login) == null ? '' : jade.interp)) + "</span></p><p>password:&nbsp;<span id=\"password-span\"></span><button id=\"show-password\">" + (jade.escape((jade.interp = show) == null ? '' : jade.interp)) + "</button><button id=\"hide-password\">" + (jade.escape((jade.interp = hide) == null ? '' : jade.interp)) + "</button></p><button id=\"generate-btn\">Reset password</button></div>");
var dDomain = (domain == '') ? 'your.cozy.url' : domain
buf.push("</div><div class=\"content-block\"><h1>" + (jade.escape((jade.interp = calendar) == null ? '' : jade.interp)) + "</h1><p>" + (jade.escape((jade.interp = client) == null ? '' : jade.interp)) + "</p><div class=\"content-tab\"><div class=\"menu-tab\"><h2 data-device=\"ios\" class=\"tab caldav selected\">iOS</h2><h2 data-device=\"android\" class=\"tab caldav\">Android</h2><h2 data-device=\"thunderbird\" class=\"tab caldav\">Thunderbird (Lightning)</h2></div><div data-device=\"ios\" class=\"caldavconf\"><p>" + (jade.escape((jade.interp = serverField) == null ? '' : jade.interp)) + " :</p><p id=\"iosuri\" class=\"url\">" + (jade.escape((jade.interp = dDomain) == null ? '' : jade.interp)) + "/public/sync/principals/me</p></div><div data-device=\"android\" class=\"caldavconf\"><p>" + (jade.escape((jade.interp = android) == null ? '' : jade.interp)) + "</p><p class=\"url\">https://" + (jade.escape((jade.interp = dDomain) == null ? '' : jade.interp)) + "/public/sync/principals/me/</p></div><div data-device=\"thunderbird\" class=\"caldavconf\"><p>" + (jade.escape((jade.interp = select) == null ? '' : jade.interp)) + "&nbsp;<select id=\"calendar\"><option id=\"placeholder\" value=\"\">-</option>");
// iterate calendars
;(function(){
  var $$obj = calendars;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var c = $$obj[$index];

buf.push("<option" + (jade.attr("value", encodeURIComponent(c), true, true)) + ">" + (jade.escape(null == (jade.interp = c) ? "" : jade.interp)) + "</option>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var c = $$obj[$index];

buf.push("<option" + (jade.attr("value", encodeURIComponent(c), true, true)) + ">" + (jade.escape(null == (jade.interp = c) ? "" : jade.interp)) + "</option>");
    }

  }
}).call(this);

buf.push("</select></p><p>" + (jade.escape((jade.interp = url) == null ? '' : jade.interp)) + "</p><p id=\"thunderbirduri\" class=\"url\"></p></div></div></div><div class=\"content-block\"><h1>" + (jade.escape((jade.interp = contacts) == null ? '' : jade.interp)) + "</h1><p>" + (jade.escape((jade.interp = client) == null ? '' : jade.interp)) + "</p><div class=\"content-tab\"><div class=\"menu-tab\"><h2 data-device=\"ios\" class=\"tab carddav selected\">iOS</h2><h2 data-device=\"android\" class=\"tab carddav\">Android</h2><h2 data-device=\"thunderbird\" class=\"tab carddav\">Thunderbird (SOGo)</h2></div><div data-device=\"ios\" class=\"carddavconf\"><p>" + (jade.escape((jade.interp = serverField) == null ? '' : jade.interp)) + " :</p><p class=\"url\">" + (jade.escape((jade.interp = dDomain) == null ? '' : jade.interp)) + "/public/sync</p></div><div data-device=\"android\" class=\"carddavconf\"><p>" + (jade.escape((jade.interp = android) == null ? '' : jade.interp)) + "</p><p class=\"url\">https://" + (jade.escape((jade.interp = dDomain) == null ? '' : jade.interp)) + "/public/sync/principals/me/</p></div><div data-device=\"thunderbird\" class=\"carddavconf\"><p>" + (jade.escape((jade.interp = thunderbird) == null ? '' : jade.interp)) + "</p><p class=\"url\">https://" + (jade.escape((jade.interp = dDomain) == null ? '' : jade.interp)) + "/public/sync/addressbooks/me/all-contacts/</p></div></div></div><div class=\"content-block\"><h1>" + (jade.escape((jade.interp = files) == null ? '' : jade.interp)) + "</h1><p>" + (jade.escape((jade.interp = file) == null ? '' : jade.interp)) + "</p></div><div class=\"content-block\"><h1>" + (jade.escape((jade.interp = troubleshouting) == null ? '' : jade.interp)) + "</h1><p>" + (jade.escape((jade.interp = problems) == null ? '' : jade.interp)) + "&nbsp;<a target=\"_blank\" href=\"https://github.com/mycozycloud/cozy-webdav/issues\">" + (jade.escape((jade.interp = github) == null ? '' : jade.interp)) + "!</a></p></div></div><script>window.password = \"" + (jade.escape((jade.interp = token) == null ? '' : jade.interp)) + "\";</script><script src=\"javascripts/vendor.js\"></script><script src=\"javascripts/app.js\" onload=\"require('initialize');\"></script></body></html>");;return buf.join("");
}