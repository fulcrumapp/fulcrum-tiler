require 'thor'
require 'json'
require 'securerandom'
require 'fileutils'

PROPERTIES = [
  :line_width,
  :line_color,
  :polygon_fill,
  :polygon_opacity,
  :text_name,
  :text_face_name
]

class CLI < Thor
  desc "export file", "export data as MBTiles"
  option :input, type: :string
  option :file, type: :string
  option :max_zoom, type: :numeric, default: 12
  option :min_zoom, type: :numeric, default: 2
  option :line_width, type: :numeric, default: 0.5
  option :line_color, type: :string, default: '#594'
  option :polygon_fill, type: :string, default: '#ae8'
  option :polygon_opacity, type: :numeric, default: 0.8
  option :text_name, type: :string, default: nil
  option :text_face_name, type: :string, default: "DejaVu Sans Condensed"
  option :template_teaser, type: :string, default: nil
  option :template_full, type: :string, default: nil
  option :output, type: :string, default: "output"
  def export
    mbtiles = MBTiles.new(options)
    mbtiles.run!
  end

  class MBTiles
    attr_accessor :options

    def initialize(options)
      self.options = options
    end

    def print_header(header)
      puts ""
      puts "==========================="
      puts header
      puts "==========================="
      puts ""
    end

    def run!
      project_file = JSON.parse(File.read('./project.json'))
      mss_file = File.read('./style.mss')

      input = File.join('/input', options[:file])

      puts "OPTIONS: #{options.inspect}"

      text_name = options[:text_name]
      template_teaser = options[:template_teaser]
      template_full = options[:template_full] || template_teaser

      if text_name
        template_teaser ||= "{{{#{options[:text_name]}}}}"
        template_full ||= "{{{#{options[:text_name]}}}}"
      end

      print_header "Loading source layer info"

      source_info = layer_info(input)

      print_header "Transforming layer"

      transform!(input, source_info)

      input = '/input/input-transformed.db'

      print_header "Loading transformed layer info"

      info = layer_info(input)

      project_file['Layer'][0]['Datasource']['file'] = input
      project_file['Layer'][0]['Datasource']['layer'] = info[:name]
      project_file['Layer'][0]['Datasource']['type'] = 'sqlite'
      project_file['Layer'][0]['Datasource']['table'] = info[:name]
      project_file['Layer'][0]['geometry'] = geometry_type(info[:type])
      project_file['Layer'][0]['extent'] = info[:extents]

      if template_teaser
        template_full ||= template_teaser

        project_file['interactivity'] = {
          layer: "data",
          template_teaser: template_teaser,
          template_full: template_full
        }
      end

      print_header "Creating project and stylesheet"

      mss = stylesheet(mss_file, info)

      puts "Stylesheet:\n\n#{mss}"

      project_name = create_files!(info, project_file, mss)

      print_header "Exporting"

      export!(project_name, project_file)

      print_header "Complete"
    end

    def transform!(input, info)
      command = "ogr2ogr -f SQLite -t_srs 'EPSG:4326' /input/input-transformed.db #{input} #{info[:name]}"

      puts command

      system(command)
    end

    def create_files!(layer_info, project_json, mss)
      project_id = SecureRandom.uuid

      project_name = "mbtiles-#{project_id}"

      projects_root = '/root/Documents/MapBox/project'
      project_root = File.join(projects_root, project_name)

      FileUtils.mkdir_p(projects_root)
      FileUtils.mkdir_p(project_root)

      project_file = File.join(project_root, 'project.mml')
      style_file = File.join(project_root, 'style.mss')

      File.open(project_file, 'wb') {|f| f.write(project_json.to_json) }
      File.open(style_file, 'wb') {|f| f.write(mss) }

      project_name
    end

    def export!(project_name, project_file)
      args = [
        "--format=mbtiles",
        "--bbox=#{project_file['Layer'][0]['extent'].join(',')}",
        "--minzoom=#{options[:min_zoom]}",
        "--maxzoom=#{options[:max_zoom]}"
      ].join(" ")

      output_root = File.join("/output", project_name)

      FileUtils.mkdir_p(output_root)

      output_path = File.join(output_root, "output.mbtiles")

      command = "node index.js export #{project_name} #{output_path} #{args}"

      puts command

      system("cd /tileoven && #{command}")

      output_filename = options[:output]

      if !(output_filename =~ /\.mbtiles/)
        output_filename = "#{output_filename}.mbtiles"
      end

      final_path = File.join("/output", output_filename)

      FileUtils.mv(output_path, final_path)
      FileUtils.rm_rf(output_root)

      puts "Finished writing MBTiles file to #{final_path}"
    end

    def layer_info(layer_path)
      info = `ogrinfo #{layer_path}`.strip.split("\n")

      puts "Info:\n\n#{info.join("\n")}"

      layer_line = info.find {|line| line =~ /^1:/}

      layer_name = layer_line.split(' ')[1]

      summary = `ogrinfo -so #{layer_path} #{layer_name}`.strip.split("\n")

      puts "Layer:\n\n#{summary.join("\n")}"

      extents_line = summary.find {|line| line =~ /^Extent:/}

      extents = extents_line.gsub('Extent: ', '')
                            .gsub('(', '')
                            .gsub(')', '')
                            .gsub(' - ', ',')
                            .gsub(',', ' ')
                            .split(' ')
                            .map(&:to_f)

      geometry_line = summary.find {|line| line =~ /^Geometry:/}

      geometry_type = geometry_line.split(':')[1].strip

      { name: layer_name,
        type: geometry_type,
        extents: extents }
    end

    def stylesheet(mss, info)
      declarations = []

      geom_type = geometry_type(info[:type])

      PROPERTIES.each do |prop|
        next if geom_type != 'polygon' && prop.to_s =~ /polygon/

        if options[prop]
          brackets = [:text_name].include?(prop)
          quotes = [:text_face_name].include?(prop)

          text_attribute = prop =~ /^text/

          next if text_attribute && !options[:text_name]

          value = options[prop]
          value = "[#{value}]" if brackets
          value = "'#{value}'" if quotes

          declarations << "  #{prop.to_s.gsub('_', '-')}: #{value};"
        end
      end

      mss.gsub!(/__STYLES__/, declarations.join("\n"))

      mss
    end

    def geometry_type(type)
      {
        'Polygon' => 'polygon',
        '3D Polygon' => 'polygon',
        'Line String' => 'linestring',
        '3D Line String' => 'linestring',
        'Point' => 'point',
        '3D Point' => 'point'
      }[type] || 'polygon'
    end
  end
end

CLI.start(ARGV)
