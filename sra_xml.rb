#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'xml'

$logger = Logger.new(STDOUT)
VERSION = "v.0.0.1"

original_formatter = Logger::Formatter.new

$logger.formatter = Proc.new do |severity,time,progname,msg|
  message = original_formatter.call(severity, time, progname, msg)
  if severity == "ERROR"
    STDERR.puts message
  end
  message
end

# Initialize logger
def setup_logger(loglevel)
  case loglevel
  when "debug"
    $logger.level = Logger::DEBUG
  when "warn"
    $logger.level = Logger::WARN
  when "info"
    $logger.level = Logger::INFO
  else
    $logger.level = Logger::ERROR
  end
end

def setup_options(args)
  options = {:n =>  75}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] sra.xml statistics"
    opts.separator ""
    opts.separator "Read xml file"

    opts.separator ""
    #opts.on("-n", "--number [NUMBER]",
    #  :REQUIRED,Integer,
    #  "How many bases to trim?, Default: 75 bases") do |n|
    #  options[:n] = n
    #end

    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-V","--version", "Print version") do |v|
      STDOUT.puts VERSION
      exit()
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify the input files!" if args.length != 2
  options
end

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  raw_xml = argv[0]
  out = argv[1]
  source = XML::Parser.file(raw_xml)
  content = source.parse
  experiment_packages = content.root.find('./EXPERIMENT_PACKAGE')
  out_file = File.open(out,'w')
  i = 0
  stats = {}
  experiment_packages.each do |package|
    srr_num = package.find_first("RUN_SET/RUN/IDENTIFIERS/PRIMARY_ID").content
    library_strategy = package.find_first("EXPERIMENT/DESIGN/LIBRARY_DESCRIPTOR/LIBRARY_STRATEGY").content
    library_selection = package.find_first("EXPERIMENT/DESIGN/LIBRARY_DESCRIPTOR/LIBRARY_SELECTION").content
    lib_contr = package.find_first("EXPERIMENT/DESIGN/LIBRARY_DESCRIPTOR/LIBRARY_CONSTRUCTION_PROTOCOL")
    description = package.find_first("SAMPLE/DESCRIPTION")
    protocol = "unknown"
    if lib_contr
      lib_contr = lib_contr.content
      if lib_contr =~ /ribo.?(-|minus)/i
        #puts Regexp.last_match(0)
        protocol = "Ribo-"
      elsif lib_contr =~ /ribo.?(zero|0)/i
        #puts Regexp.last_match(0)
        protocol = "Ribo0"
      elsif lib_contr =~ /(poly.?a?.?|purist|selection|\+|spin|Ttract)/i
        #puts Regexp.last_match(0)
        protocol = "PolyA"
      end
    end
    if description
      description = description.content
      if description =~ /ribo.?(-|minus)/i
        #puts Regexp.last_match(0)
        protocol = "Ribo-"
      elsif description =~ /ribo.?(zero|0)/i
        #puts Regexp.last_match(0)
        protocol = "Ribo0"
      elsif description =~ /(poly.?a?.?|purist|selection|\+|spin|Ttract)/i
        #puts Regexp.last_match(0)
        protocol = "PolyA"
      end
    end


    #puts lib_contr
    out_file.puts "#{srr_num}\t#{library_strategy}\t#{library_selection}\t#{protocol}"
    stats[protocol] ||= 0
    stats[protocol] += 1
  end
  $logger.info(stats)
end

if __FILE__ == $0
  run(ARGV)
end
