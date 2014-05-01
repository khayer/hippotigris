#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'zlib'

$logger = Logger.new(STDOUT)

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
  options = {:n =>  1000000}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] fwd.fq[.gz] rev.fq[.gz] out_prefix"
    opts.separator ""
    opts.separator "Samples N=1Mio reads from paired end fastq files."

    opts.separator ""
    opts.on("-n", "--number [NUMBER]",
      :REQUIRED,Integer,
      "How many reads to sample?, Default: 1Mio") do |n|
      options[:n] = n
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify the input files!" if args.length != 3
  options
end

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  fqf = argv[0]
  fqr = argv[1]
  out_prefix = argv[2]
  if fqf =~ /\.gz$/
    num_reads = `zcat #{fqf} | wc -l`.to_i
    fqf_file = Zlib::GzipReader.new(File.open(fqf))
    fqr_file = Zlib::GzipReader.new(File.open(fqr))
  else
    num_reads = `wc -l #{fqf}`.to_i
    fqf_file = File.open(fqf)
    fqr_file = File.open(fqr)
  end
  $logger.info("I found #{num_reads} of reads.")
  rand_array = (0...num_reads).to_a.sort { rand() - 0.5}[0..options[:n]].sort
  subf = File.open(out_prefix + "_fwd.fq",'w')
  subr = File.open(out_prefix + "_rev.fq",'w')
  rec_no = 0
  rand_array.each do |ele|
    while rec_no < ele
      for i in (0..3)
        fqf_file.readline
        fqr_file.readline
        rec_no += 1
      end
    end
    for i in (0..3)
      subf.puts fqf_file.readline
      subr.puts fqr_file.readline
      rec_no += 1
    end
  end
end

if __FILE__ == $0
  run(ARGV)
end
