#!/usr/bin/env ruby

require 'sinatra'
require 'rqrcode'
require 'net/http'
require 'uri'
require 'json'
require_relative 'database'
require_relative 'scraper'
require_relative 'escalation'

$title = ""
$current_state = nil
$children_of_current_state = nil
$cols = 1
$callback_addr = ""
$show_data = false
$instance_id = 0

$PORT = 9001
$BASE = "/ports/#{$PORT}"

# Layout automatisch nutzen
set :erb, layout: :layout
set :static, true
set :public_folder, File.join(__dir__, 'public')
set :port, $PORT
set :protection, :origin_whitelist => ['https://cpee.org/']
set :protection, :except => :frame_options

def calc_columns(count)
  return 0 if count.zero?
  return count if count <= 3
  (count / 2.0).ceil
end

# ----- Routen -----
get '/' do

  @title = $title
  @cols = $cols
  @callback_addr = $callback_addr
  @base = $BASE
  @nav_buttons = []
  @nav_buttons.push({ id: :abort, label: "Home", action: "abort" })
  @nav_buttons.push({ id: :main,  label: "Main", action: "main"  })
  @nav_buttons.push({ id: :back,  label: "Back", action: "back"  })

  headers 'CPEE-CALLBACK' => 'true'
  status 200

  if $show_data
    @todays_events = DatabaseHelper.get_events_by_site($current_state)
    erb :data
  else
    @events = $children_of_current_state
	
    erb :navigation
  end
end

put '/update' do
  $callback_addr = request.env['HTTP_CPEE_CALLBACK']
  EscalationManager.schedule_abort($callback_addr)
  # The hierachy of all events as put in in cpee
  categories = JSON.parse(params['categories'])
  $instance_id = request.env['HTTP_CPEE_INSTANCE'].to_i

  Thread.new do
    categories.each do |first_level, second_levels|
      next if first_level == "main"
      second_levels.each do |second_level|
        DatabaseHelper.add_process_event(
          $instance_id,
          first_level,
          second_level
        )
      end
    end

    DB[:process_event_list].where(instance_id: $instance_id).each do |row|
      ScraperManager.get_todays_events_for_site($instance_id, row[:second_level])
    end
  end

  # The state needed for the title
  state = params["state"] == "main" ? "" : params["state"]
  $title = "Today's #{state} Events"

  $current_state = params["state"]

  $children_of_current_state = categories[params["state"]]
  #pp $children_of_current_state

  #if no children exist, it is a leaf and the data.erb will be displayed
  $show_data = $children_of_current_state == nil ? true : false

  if $show_data
    $cols = 1
    #ScraperManager.get_todays_events_for_site($instance_id, $current_state)
    # Set the back button action to redirect to the direct parent of the current state
  else
    $cols = calc_columns($children_of_current_state.size)
  end

  headers 'CPEE-CALLBACK' => 'true'
  status 200
end

get '/trigger' do
  site = params[:site]

  uri = URI($callback_addr)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")

  req = Net::HTTP::Put.new(uri)
  req["Content-Type"] = "application/json"
  req.body = { site: site }.to_json

  res = http.request(req)

  "You selected #{site}. BPM notified!"
end

get '/trigger_nav' do
  action = params[:action]
  
  #puts "action: #{action}"
  #puts "$back: #{$back}"
  nav_addr = action == "back" ? DatabaseHelper.get_parent_levels($instance_id, $current_state) : action
  if nav_addr == nil
    nav_addr = "main"
  end
  #puts "nav_addr: #{nav_addr}"
  uri = URI($callback_addr)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")

  req = Net::HTTP::Put.new(uri)
  req["Content-Type"] = "application/json"
  req.body = { site: nav_addr }.to_json
  #puts "nav_address: #{nav_addr}"
  res = http.request(req)
  pp res

  "You selected #{nav_addr}. BPM notified!"
end
