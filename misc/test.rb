require_relative '../scraper'

module ScraperManager
  def self.get_todays_events_for_site(instance_id, site)
    #site = "SAP Garden"
    #parent_site = "Sports"
    url = DatabaseHelper.get_url_by_site(site)
    parent_site = DatabaseHelper.get_parent_levels(instance_id, site)
    puts "url: #{url}"

    #url = DatabaseHelper.get_url_by_site(site)
    # Set "normal" looking browser headers
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

    # Hide automation flag and adjust default window size to be less common
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
    #sleep 1

    html = browser.body
    doc = Nokogiri::HTML(html)
    browser.quit

    puts "The site entered and scraped is #{site}\n"

	today_str = Date.today.strftime("%d/%m/%y")
	today_str = Date.new(2026, 3, 19).strftime("%d.%m.%y")
	puts "Today Str ist: #{today_str}"

        doc.css("li.MatchplanListItemWrapper-sc-16gig0v-1").each do |li|
          div = li.at_css("div.MatchDate-sc-2549kd-3")
          next unless div

          # Extract just the day/month part
          day_month = div.text.strip.split(' | ')[1]  # "Saturday 24/01" → "24/01"
	  puts "Der extrahierte Monat ist: #{day_month}\n"
          next unless day_month == today_str
	  puts "Monat und today str haben uebereingestimmt\n"
          time = div.text.strip.split(' | ')[2]
	  puts "Gefundene Uhrzeit: #{time}\n"

          arena = li.at_css("span.WhereToWatchWrapper-sc-2549kd-14")
	  puts "Gefundene Arena: #{arena}\n"
          next unless arena

          #next unless arena.text.include?(site)

          # Extract JSON metadata
          teams = []
          li.css('div.TeamNameMedium-sc-2549kd-10').each do |team_name|
            teams.push(team_name.text.strip)
          end

          date = day_month
          time = time
          home_team = teams[0]
          away_team = teams[1]
        end
  end
end
