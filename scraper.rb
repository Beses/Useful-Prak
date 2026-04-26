require 'ferrum'
require 'nokogiri'
require_relative 'database.rb'

module ScraperManager
  def self.get_todays_events_for_site(instance_id, site)
    return unless DatabaseHelper.get_events_by_site(site).empty?

    url = DatabaseHelper.get_url_by_site(site)
    parent_site = DatabaseHelper.get_parent_levels(instance_id, site)

    headers = {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Encoding" => "gzip, deflate, br, zstd",
      "Accept-Language" => "en-GB,en-US;q=0.9,en;q=0.8",
      "Cache-Control" => "no-cache",
      "Pragma" => "no-cache",
      "Priority" => "u=0, i",
      "Sec-Ch-Ua" => '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"macOS\"",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "cross-site",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    }

    opts = {
      headless: "new",
      timeout: 35,
      window_size: [1366, 768],
      browser_options: {
        "disable-blink-features" => "AutomationControlled"
      },
    }

    browser = Ferrum::Browser.new(opts)
    browser.headers.set(headers)
    browser.go_to(url)

    html = browser.body
    doc = Nokogiri::HTML(html)
    browser.quit

    puts "The site entered and scraped is #{site}\n"
    time = nil
    home_team = ""
    away_team = ""
    start_date = nil
    end_date = nil
    title = nil
    subtitle = nil

    if parent_site == "Sports"

      if site == "Allianz Arena"
        doc.css("li.CalendarDayListItem-sc-11z764v-3").each do |li|
          h3 = li.at_css("h3.sc-nx1lne-0")
          next unless h3

          day_month = h3.text.strip.split.last # "Saturday 24/01" → "24/01"
          parsed_date = Date.strptime(day_month, "%d/%m")
          next unless parsed_date.day == Date.today.day && parsed_date.month == Date.today.month

          time_tag = li.at_css("p.CompactDate-sc-1akhu3p-4")
          next unless time_tag
          time = Time.strptime(time_tag.text.strip.split(" | ").last, "%h:%m")

          li.css('script[type="application/ld+json"]').each do |script|
            json_text = script.text.strip
            begin
              data = JSON.parse(json_text)
              start_date = data['startDate']
              home_team = data.dig('homeTeam', 'name')
              away_team = data.dig('awayTeam', 'name')
            rescue JSON::ParserError
              puts "Invalid JSON in script tag"
            end
          end
          title = "#{home_team} vs #{away_team}" if title.nil?

          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "BMW PARK"
        doc.css("li.MatchplanListItemWrapper-sc-16gig0v-1").each do |li|
          div = li.at_css("div.MatchDate-sc-2549kd-3")
          next unless div

          day_month = div.text.strip.split(' | ')[1]
          parsed_date = Date.strptime(day_month, "%d/%m/%y")
          next unless parsed_date == Date.today

          time = div.text.strip.split(' | ')[2]

          arena = li.at_css("span.WhereToWatchWrapper-sc-2549kd-14")
          next unless arena
          next unless arena.text.include?(site)

          teams = []
          li.css('div.TeamNameMedium-sc-2549kd-10').each do |team_name|
            teams.push(team_name.text.strip)
          end

          home_team = teams[0]
          away_team = teams[1]
          title = "#{home_team} vs #{away_team}" if title.nil?

          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "SAP GARDEN"
        doc.css("section").each do |section|
          a = section.at_css("a")
          next unless a

          spans = a.css("span")
          next unless spans.length >= 6
          home_team = spans[1].text.strip
          day_month = spans[3].children[0].text.strip.split(", ")[1]
          parsed_date = Date.strptime(day_month, "%d.%m.%y")
          next unless parsed_date == Date.today

          time = spans[3].children[2].text.strip
          away_team = spans[6].text.strip

          if home_team.include?("Basketball")
            subtitle = "Basketball"
          else
            subtitle = "Ice Hockey"
          end
          title = "#{home_team} vs #{away_team}" if title.nil?

          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "Olympiastadion"
        doc.css("div.list-item").each do |section|
          date = section.at_css("p.dateRange")
          next unless date
          date_text = date.text

          title = section.at_css("div.title").text

          if date_text.include?(" - ")
            dates = date_text.split(" - ")
            start_date_str = dates[0].split(" ")[1]
            end_date_str = dates[1].split(" ")[1]
            start_date = start_date_str.length == 10 ? Date.strptime(start_date_str, "%d.%m.%Y") : Date.strptime(start_date_str, "%d.%m")
            end_date = end_date_str.length == 10 ? Date.strptime(end_date_str, "%d.%m.%Y") : Date.strptime(end_date_str, "%d.%m")

            next unless (start_date..end_date).cover?(Date.today)
          elsif date_text.include?(" | ")
            date_time = date_text.split(" | ")
            next unless date_time
            day_month = date_time[0].split(" ")[1].strip
            parsed_date = Date.strptime(day_month, "%d.%m.%y")
            next unless parsed_date == Date.today

            time = date_time[1].strip
          end
          title = "#{home_team} vs #{away_team}" if title.nil?

          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "Grünwalder Stadion"
        doc.css("a.contents").each do |section|
          tags = section.css("div.flex.w-full").xpath('.//text()').map { |t| t.text.strip }.reject(&:empty?)
          parsed_date = Date.strptime(tags[0].split(", ")[1], "%d.%m")
          next unless parsed_date.day == Date.today.day && parsed_date.month == Date.today.month

          stadion = tags[2]
          next unless stadion == site
          time = tags[1]
          home_team = tags[6]
          away_team = tags[8]
          title = "#{home_team} vs #{away_team}" if title.nil?

          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "Dantestadion"
        doc.css("div.EventListWrapper").each do |section|
          next unless section.at_css("div.TextEventDate")
          event_date = section.at_css("div.TextEventDate").text.strip.split(", ")[1].split(" @ ")
          parsed_date = Date.strptime(event_date[0], "%d.%m.%Y")
          next unless parsed_date == Date.today

          time = event_date[1].gsub(" Uhr", "").strip
          event_name = section.at_css("h2.HeaderEventName > a").text.strip.split(" - ")[1].split(" vs. ")
          home_team = event_name[0]
          away_team = event_name[1]

          next if home_team.nil?
          title = "#{home_team} vs #{away_team}"
          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end
      end



    elsif parent_site == "Culture"

      if site == "Nationaltheater"
        doc.css("div.activity-list__row").each do |section|
          parsed_date = Date.strptime(section["data-date"], "%Y-%m-%d")
          next unless parsed_date == Date.today

          time_place = section.at_css("div.activity-list__text > span")
          next unless time_place
          time_place_text = time_place.text.strip
          parts = time_place_text.split("|")
          place = parts[1]&.strip
          next unless place == site
          time = parts[0]&.strip

          play_tag = section.at_css("div.activity-list__text span.h3")
          next unless play_tag
          title = play_tag.text.strip

          artist_tag = section.at_css("div.activity-list--toggle__content > p")
          next unless artist_tag
          subtitle = artist_tag.text.strip
          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "Residenztheater"
        doc.css("section.schedule__day").each do |section|
          next unless section.at_css("div.schedule__today")

          place_time = section.at_css("div.schedule-act__details")
          next unless place_time
          #place = place_time.text.split(",")[0].strip
          time = place_time.text.split(",")[1].strip.split("–")[0].strip

          title_tag = section.at_css("h3.schedule-act__title.headline--1 > a")
          next unless title_tag
          title_tag.css("span.visuallyhidden").remove
          title = title_tag.text.gsub(/\s+/, ' ').strip
          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end


      elsif site == "Prinzregententheater"
        doc.css("li.datarecord.datarecord--large").each do |section|
          date_time = section.css("time")
          next unless date_time
          parsed_date = Date.strptime(date_time[0]["datetime"], "%Y-%m-%d")
          next unless parsed_date == Date.today

          time = date_time[1].text.strip

          location_tag = section.at_css("div.flex-3 span")
          next unless location_tag
          next unless location_tag.text.strip.include?(site)

          title_tag = section.at_css("div.flex-4 a")
          next unless title_tag
          title = title_tag.text.strip

          subtitle_tag = section.at_css("span.eventSubtitle")
          next unless subtitle_tag
          subtitle = subtitle_tag.text.strip
          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "Isarphilharmonie"
        doc.css("li.w-12.w-xs-6.w-md-4.w-lg-3").each do |section|
          date_time_tag = section.css("span.VyqDWX time").attr("datetime")&.value
          next unless date_time_tag
          date_time = DateTime.parse(date_time_tag)
          next unless date_time.to_date == Date.today

          time = date_time.strftime("%H:%M")

          titles = section.at_css("h3._0B0hhi.hjKKs5").children
          next unless titles
          title = titles[0].text.strip
          subtitle = titles[1].text.strip
          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "Deutsches Theater"
        doc.css("div.wpb_column").each do |section|
          zeitraum_tag = section.at_css('div.zeitraum-generisch')
          next unless zeitraum_tag
          zeitraum = zeitraum_tag.text.strip
          if zeitraum.include?(" bis ")
            dates = zeitraum.split(" bis ")
            end_date   = Date.strptime(dates[1].strip, "%d.%m.%y")
            start_date = Date.strptime(dates[0].strip + end_date.year.to_s, "%d.%m.%Y")

            if start_date > end_date
              start_date = Date.strptime(dates[0].strip + (end_date.year - 1).to_s, "%d.%m.%Y")
            end

            next unless (start_date..end_date).cover?(Date.today)
          else
            parsed_date = Date.strptime(zeitraum, "%d.%m.%y")
            next unless parsed_date == Date.today
          end
          link = section.at_css("a")
          title = link["href"].split("/").reject(&:empty?).last.gsub("-", " ").split.map(&:capitalize).join(" ") rescue nil

          subtitle_tag = section.at_css("div.weitere-informationen div")
          subtitle = subtitle_tag.text.strip
          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end

      elsif site == "Gärtnerplatztheater"
        doc.css("div.evt-event-list").each do |section|
          date_tag = section.at_css('span[class^="event-date"]')
          next unless date_tag
          parsed_date = Date.strptime(date_tag.text.strip, "%d.%m.%Y")
          next unless parsed_date == Date.today

          location_tag = section.at_css('span[id^="event-location"]')
          next unless location_tag
          next unless location_tag.text.strip == site

          title_tag = section.at_css('h2[id^="event-title"]')
          next unless title_tag
          title = title_tag.text.strip

          subtitle_tag = section.at_css("p.eventSubtitle1")
          next unless subtitle_tag
          subtitle = subtitle_tag.text.strip

          time_tag = section.at_css("span.evt-event-detail__time")
          next unless time_tag
          time = time_tag.text.strip
          DatabaseHelper.add_event(site, time, start_date, end_date, title, subtitle)
        end
      end


    end

  end

end