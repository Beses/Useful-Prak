require 'sequel'

DB = Sequel.sqlite('data.db')

# tables
DB.create_table? :events do
  String :site
  String :time
  String :home_team
  String :away_team
  Date :start_date
  Date :end_date
  String :title
  String :subtitle
  Date :fetched_at
  primary_key [:site, :title, :fetched_at]
end

DB.create_table? :site_urls do
  String :site
  String :url
  primary_key [:site]
end

DB.create_table? :process_event_list do
  Integer :instance_id
  String :first_level
  String :second_level
  primary_key [:first_level, :second_level]
end

# Helper functions
module DatabaseHelper
  # adders for each database
  def self.add_event(site, time, start_date, end_date, title, subtitle)
    DB[:events].insert_conflict.insert(
      site: site,
      time: time,
      start_date: start_date,
      end_date: end_date,
      title: title,
      subtitle: subtitle,
      fetched_at: Date.today
    )
  end

  def self.add_site_url(site, url)
    DB[:site_urls].insert_conflict(target: :site, update: { url: url }).insert(
      site: site,
      url: url
    )
  end

  def self.add_process_event(instance_id, first_level, second_level)
    DB[:process_event_list].insert_conflict.insert(
      instance_id: instance_id,
      first_level: first_level,
      second_level: second_level
    )
  end

  # getters for each database
  def self.get_events_by_site(site)
    DB[:events].where(site: site, fetched_at: Date.today).all
  end

  def self.get_url_by_site(site)
    row = DB[:site_urls].where(site: site).first
    row[:url]
  end

  def self.get_parent_levels(instance_id, second_level)
    DB[:process_event_list]
      .where(instance_id: instance_id, second_level: second_level)
      .get(:first_level)
  end

  # miscellaneous methods for testing
  def self.print_db_outputs
    print "Site urls\n"
    DB[:site_urls].all.each do |row|
      p row
    end
    print "\n"
    print "Events\n"
    DB[:events].all.each do |row|
      p row
    end
    print "\n"
    print "Process event list\n"
    DB[:process_event_list].all.each do |row|
      p row
    end
    print "\n"
  end

  def self.show_schemas
    puts DB.schema(:process_event_list)
    print "\n"
    puts DB.schema(:events)
    print "\n"
    puts DB.schema(:site_urls)
    print "\n"
  end

  def self.drop_tables
    DB.drop_table(:process_event_list)
    DB.drop_table(:events)
    DB.drop_table(:site_urls)
  end

end
