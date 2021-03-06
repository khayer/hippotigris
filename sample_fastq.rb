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

    opts.on("-r", "--randomize_n [NUMBER]",
      :REQUIRED,String,
      "Give range to randomize N, example: '10,20'") do |n|
      n = n.split(",").map { |e| e.to_i  }
      n = rand(n[0]..n[1])
      $logger.info("Your randomized n is #{n}.")
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
    num_reads = `zcat #{fqf} | wc -l`.to_i/4
    fqf_file = Zlib::GzipReader.new(File.open(fqf))
    fqr_file = Zlib::GzipReader.new(File.open(fqr))
  else
    num_reads = `wc -l #{fqf}`.to_i/4
    fqf_file = File.open(fqf)
    fqr_file = File.open(fqr)
  end
  $logger.info("I found #{num_reads} of reads.")
  cut_off = 1.0/(num_reads.to_f/options[:n])
  subf = File.open(out_prefix + "_fwd.fq",'w')
  subr = File.open(out_prefix + "_rev.fq",'w')
  rec_no = 0
  while !fqf_file.eof?
    if rand() > cut_off
      for i in (0..3)
        fqf_file.readline
        fqr_file.readline
      end
    else
      for i in (0..3)
        subf.puts fqf_file.readline
        subr.puts fqr_file.readline
      end
      rec_no += 1
    end
  end
  $logger.info("Total number of reads: #{rec_no}")
end

if __FILE__ == $0
  run(ARGV)
end
