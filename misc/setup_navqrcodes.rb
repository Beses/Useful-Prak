#!/usr/bin/env ruby

require 'rqrcode'

nav_buttons = ["abort", "back", "main"]

nav_buttons.each do |nav_button|
  qr = RQRCode::QRCode.new("https://lehre.bpm.in.tum.de/ports/9001/trigger_nav?action=#{nav_button}")

  svg = qr.as_svg(
    standalone: true,
    shape_rendering: "crispEdges",
    module_size: 2, # 45 × 2 = 90 px
    width: 90,
    height: 90
  )

  File.write("public/#{nav_button}.svg", svg)
end


