#!/usr/bin/env ruby

require_relative '../database.rb'

sites = {
  #Spports
  'Allianz Arena' => 'https://allianz-arena.com/en/events?filter=MATCH',
  'BMW Park' => 'https://fcbayern.com/basketball/en/season/schedule',
  'SAP Garden' => 'https://www.sapgarden.com/de/kalender/events',
  'Olympiastadion' => 'https://www.olympiapark.de/de/veranstaltungen/sport',
  'Grünwalder Stadion' => 'https://www.tsv1860.de/de/spielplan',
  #'Dantestadion' => 'https://plugin.vbotickets.com/plugin/loadplugin?siteid=C8FBBB23-7794-437A-B5F8-6BE3054C8487&s=c42e55ba-50fb-4762-a088-5ce703438bc9&page=ListEvents&w=1920&h=917&o=0&parent=www.munich-cowboys.de&parenturl=https%3A%2F%2Fwww.munich-cowboys.de%2Ftickets%2F&PluginType=',
  'Dantestadion' => 'https://plugin.vbotickets.com/Plugin/events?ViewType=list&o=8224&s=5e803663-fd00-40d2-9adc-8958002699b3',

  # Culture
  'Nationaltheater' => 'https://www.staatsoper.de/en/schedule',
  'Residenztheater' => 'https://www.residenztheater.de/en/schedule?production=&month=&activitytype=&englishsurtitles=&theatertag=&stage=2&filter-submit=',
  'Prinzregententheater' => 'https://theaterakademie.de/en/theater/programm',
  'Isarphilharmonie'=> 'https://www.gasteig.de/veranstaltungen/?room=isarphilharmonie',
  'Deutsches Theater'=> 'https://www.deutsches-theater.de/programm/',
  'Gärtnerplatztheater' => 'https://tickets.staatstheater.bayern/gpt.webshop/webticket/eventlist',
}

sites.each do |site, url|
  DatabaseHelper.add_site_url(site, url)
  puts "added site: #{site}"
end