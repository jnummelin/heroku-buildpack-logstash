require 'yaml'
require 'json'
require 'erb'

module LogstashPack

  OUTPUT_PATH = ARGV[0]

  def self.detect
    if File.exists?("#{OUTPUT_PATH}/logstash.conf") || File.exists?("#{OUTPUT_PATH}/logstash.conf.erb")
      "Logstash"
    else
      raise "logstash.conf is missing!"
    end
  end

  def self.compile
    install_logstash
    compile_config
  end

  def self.release
    {
      "addons" => default_addons,
      "default_process_types" => default_process_types
    }.to_yaml
  end

  def self.default_process_types
    {
      "worker"  => "./lib/sockets-connect/rs-conn logstash/bin/logstash agent -f logstash.conf #{'--debug' if config[:debug]}"
    }
  end

  def self.default_addons
    ["searchbox", "ruppells-sockets"]
  end

  def self.log(message)
    puts "-----> #{message}"
  end

  def self.run(command)
    %x{ #{command} 2>&1 }
  end

  # run a shell command and stream the ouput
  # @param [String] command to be run
  def self.pipe(command)
    output = ""
    IO.popen(command) do |io|
      until io.eof?
        buffer = io.gets
        output << buffer
        puts buffer
      end
    end

    output
  end

  def self.install_logstash
    log('Installing logstash')
    log "Downloading Logstash #{config[:version]} from #{config[:url]}..."
    pipe("curl #{config[:url]} -L -o - | tar xzf -")
    run("mv #{Dir["logstash-*"][0]} #{OUTPUT_PATH}/logstash")
    run("cp #{OUTPUT_PATH}/patterns/* #{OUTPUT_PATH}/logstash/patterns")
    run("#{OUTPUT_PATH}/logstash/bin/plugin install contrib")
  end

  def self.compile_config
    if File.exists? "#{OUTPUT_PATH}/logstash.conf.erb"
      log("COMPILING ERB")
      content = File.read("#{OUTPUT_PATH}/logstash.conf.erb")
      template = ERB.new(content)
      File.open("#{OUTPUT_PATH}/logstash.conf", 'w') { |f| f.puts(template.result) }
    end
  end

  def self.config
    output = {}
    # get variables from config.json if it exists
    if File.exists? "#{OUTPUT_PATH}/config.json"
      config = JSON.parse File.read "#{OUTPUT_PATH}/config.json"
      output[:version] = config['logstash']['version'] if config['logstash']['version']
      output[:url] = config['logstash']['url'] if config['logstash']['url']
      output[:debug] = config['logstash']['debug'] if config['logstash']['debug']
    end

    output[:version] ||= "1.4.2"
    output[:url] ||= "https://download.elasticsearch.org/logstash/logstash/logstash-#{output[:version]}.tar.gz"
    output[:debug] ||= false

    output
  end
end
