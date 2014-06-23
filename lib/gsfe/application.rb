
require 'yaml'

module Gsfe
	class Application
		def initialize
			@config = {}
			if File.exist? ".gsfe" then
				@config = YAML.load_file('.gsfe')
			end
		end

		def import input_file, output_file, options
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


		def publish options
			if not File.exist? "config.rb" then
				fail "ERROR: please run the script from project root"
			end

			sed = %x{which gsed ||which sed}.strip
			zip = %x{which zip}.strip

			# FIXME: Use configuration file
			project_dir = Dir.pwd
			project_name = File.basename Dir.pwd
			if options['suffix'] then
				project_name += "-%s" % options['suffix']
			end
			if File.exist? ".rename-from-data" then
				project_shortname = project_name.gsub(/^(.*?-){3}/,'')
				project_date = %x{readlink data}.strip.gsub(/^((.*?-){3}).*$/,'\1')
				project_name = project_date + project_shortname
			end
			STDERR.puts "Project name: #{project_name}"


			# build files
			system "middleman build"

			puts options.inspect
			# REWRITE URLS
			if options['absolute'] then
				STDERR.puts "Rewriting urls with #{options['url']}"
				fail "No URL defined for rewrite" if (not options.include? 'url')
				system '%s -i -e "s|\([\"\'(]\)images/|\1%s/images/|" build/*.html' % [
 			   		sed, options['url'].gsub(/\/$/,'')
				]
			end
			system '%s -i -e "s|{{PROJECT_NAME}}|%s|" build/*.html' % [
				sed, project_name
 			]

			#REMOVE DOCTYPE
  		# system "#{sed} -i -e \"/DOCTYPE/d\" build/*.html"

  			# Rewrite HEIGHT to MAX-HEIGHT
  			system '%s -i -e "s/\([^-]\)height: *\([0-9]*\)px/\1height: \2px; max-height: \2px/g" build/*.html' % sed

  			FileUtils.rm_rf "public/#{project_name}"
			FileUtils.mkdir_p "public"
  			FileUtils.mv "build", "public/#{project_name}"

			done = false
			version = 0

			while !done do

				archive_name =
					if version > 1 then
					   	"#{project_name}-v#{version}.zip"
      			   	else
					   	"#{project_name}.zip"
				   	end

				if not File.exist? "public/#{archive_name}" then
          			Dir.chdir "public/#{project_name}"
					system "#{zip} -r \"../#{archive_name}\" ."
          			done = true
      			end
	  			version += 1
			end
			Dir.chdir project_dir
  	  	  	STDERR.puts "Generated file public/#{archive_name}"
		end

		def load prefix, options
			opts = options.dup
			opts.delete("save")
			if @config.include? prefix.to_s then
				STDERR.puts "merging config :)"
				@config[prefix.to_s].merge! opts
			else
				STDERR.puts "replacing config :("
				@config[prefix.to_s] = opts
			end
			return @config[prefix.to_s]
		end

		def save prefix
			File.open('.gsfe', 'w') do |f|
 			  	f.write @config.to_yaml
			end
		end
	end # class
end # module
