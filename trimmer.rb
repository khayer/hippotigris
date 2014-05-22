#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'zlib'

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
    opts.banner = "Usage: #{$0} [options] in.fq[.gz] out.fq"
    opts.separator ""
    opts.separator "Trim all reads to 75 bases"

    opts.separator ""
    opts.on("-n", "--number [NUMBER]",
      :REQUIRED,Integer,
      "How many bases to trim?, Default: 75 bases") do |n|
      options[:n] = n
    end

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
  fq = argv[0]
  out = argv[1]
  if fq =~ /\.gz$/
    fq_file = Zlib::GzipReader.new(File.open(fq))
  else
    fq_file = File.open(fq)
  end
  out_file = File.open(out,'w')
  i = 0
  while !fq_file.eof?
    line = fq_file.readline
    line.chomp!
    case i
    when 0
      if line =~ /^@/
        out_file.puts line
      else
        $logger.error("LINE: \"#{line}\" IS NOT AS EXPECTED, IT SHOULD BE THE HEADER LINE")
        raise RuntimeError, 'FOUND CORRUPTED LINE'
      end
    when 1
      if line =~ /(a|t|g|c|n)/i && line.length >= options[:n]
        out_file.puts line[0...options[:n]]
      else
        $logger.error("LINE: \"#{line}\" IS NOT AS EXPECTED, IT SHOULD BE THE SEQUENCE")
        raise RuntimeError, 'FOUND CORRUPTED LINE'
      end
    when 2
      if line =~ /^+/
        out_file.puts line
      else
        $logger.error("LINE: \"#{line}\" IS NOT AS EXPECTED, IT SHOULD BE THE + LINE")
        raise RuntimeError, 'FOUND CORRUPTED LINE'
      end
    when 3
      i = -1
      out_file.puts line[0...options[:n]]
    end
    i += 1
  end
end

if __FILE__ == $0
  run(ARGV)
end
