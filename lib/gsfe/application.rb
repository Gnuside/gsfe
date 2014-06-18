

module Gsfe
	class Application
		def initialize

		end
		
		def import input_file, output_file
			doc = Nokogiri::XML(open(input_file))

			mail = Gsfe::SliceFixer.new(doc)
			mail.add_image_fix
			mail.fix_link_target
			mail.add_td_size_from_img
			mail.fix_img_src

			File.open('out','w') do |f|
				f.puts mail.to_xml
			end


			File.open('out','w') do |f|
				f.puts mail.to_xml
			end

			html2haml_opts = {
				erb: true,
				html_style_attributes: true
			}

			system %Q{html2haml --html-attributes < 'out' > "#{output_file}"}
			if not $?.success? then
				STDERR.puts "ERROR converting HTML to HAML. Aborting."
				exit 1
			end

			mail.cleanup
			FileUtils.rm_f input_file

		ensure
			FileUtils.rm_f "out"
		end
	end
end
