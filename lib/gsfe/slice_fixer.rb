
module Gsfe
	class SliceFixer
		def initialize doc
			@document = doc
			@removables = []
			@properties = {}
			return self
		end

		def to_xml
			return @document.to_xml(indent:1, indent_text:"\t")
		end

		def cleanup
			@removables.each do |file|
 				FileUtils.rm_f file
			end
		end

		def add_image_fix
			doc = @document.clone

			doc.css('img').each do |img|
				img['class'] = 'image_fix'
			end

			@document = doc 
			return self
		end

		def fix_link_target
			doc = @document.clone

			doc.css('a').each do |link|
				link['target'] = '_blank'
			end

			@document = doc
			return self
		end

		def fix_img_src
			doc = @document.clone

			doc.css('td img').each do |img|
				# get image width
				img_set_bgcolor = false
				img_src = img['src']

				# analyse image & get colors
				# if only one color, generate a single pixel image.
				# if many colors,  convert to high-quality jpg
				img_props = image_properties img_src

				if img_props[:colors] > 256 then
					img_dest = img_src.gsub(/.png$/,'.jpg')
					puts "Converting #{img_src} to JPEG (colors: #{img_props[:colors]})"
					system "convert -quality 99 \"#{img_src}\" \"#{img_dest}\""
					# append source to removables
					@removables << img_src
					img[:src] = img_dest
				end

				elsif img_props[:colors] == 1 then
					img_set_bgcolor = true
					img_dir = File.dirname img_src
					img_width = img_props[:geometry_width]
					img_height = img_props[:geometry_height]
					img_dest = File.join img_dir, "spacer-#{img_width}-#{img_height}.gif"
					puts "Remplacing #{img_src} with #{File.basename img_dest}"
					if not File.exist? img_dest then
						system "convert -size #{img_width}x#{img_height} xc:\"rgba(0,0,0,0)\" \"#{img_dest}\""
					end
					# append src removables 
					@removables << img_src

					img[:src] = img_dest
				end

				if img_set_bgcolor then
					td = img.xpath('./ancestor::td[1]').first
					td['bgcolor'] = img_props[:histogram_color]
				end
			end

			@document = doc
			return self
		end

		def add_td_size_from_img
			doc = @document.clone

			doc.css('td img').each do |img|
				# get image width
				img_src=img['src']

				# get image information & report into TD
				img_props = image_properties img_src

				td = img.xpath('./ancestor::td[1]').first
				td['width'] = img_props[:geometry_width]
				td['height'] = img_props[:geometry_height]
			end

			@document = doc
			return self
		end

		def image_properties img_src
			if @properties.include? img_src then
				return @properties[img_src]
			end
			props = {}
			img_ident = []
			IO.popen(%Q{identify -verbose -unique "#{img_src}"}) do |f|
				img_ident = f.readlines.map(&:strip)
			end
			histogram = false
			img_ident.each do |line|
				case line
				when /Colors:\s+(\d+)$/ then
					props[:colors] = $1.to_i
				when /Geometry:\s+(\d+)x(\d+)/ then
					props[:geometry_width] = $1
					props[:geometry_height] = $2
 				when /Histogram:/ then
					histogram = true
				when /Rendering intent:/ then
					histogram = false
				else 
					if histogram then
						props[:histogram_color] = line.gsub(
							/^.*(#[0-9a-fA-F]+).*$/,
								'\1'
						)
					end
				end
			end

			@properties[img_src] = props
			return @properties[img_src]
		end
	end
end
