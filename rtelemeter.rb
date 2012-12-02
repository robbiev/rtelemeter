#!/usr/bin/env ruby
# == Synopsis 
#   Consult your Telenet subscription's
#   current volume usage.
#
# == Usage 
#   rtelemeter.rb [options]
#   For help use: rtelemeter.rb -h
#
# == Options
#   TODO add options
#
# == Author
#   Robbie Vanbrabant
#
# == Copyright
#   Copyright (c) 2008 Robbie Vanbrabant.

# TODO Use highline to show daily stats? See its examples.

require 'optparse' 
require 'rdoc/usage'
require 'ostruct'
require 'date'
require 'libtelemeter'

# reading passwords from command line
# gem install highline
require 'rubygems'
require 'highline/import'

# configuration file
# gem install crypt
require 'yaml'
require 'crypt/blowfish'

# Simple client example
class SimpleTelemeterClient
    def initialize(config_file)
        @config_file = config_file
    end
    
    def run(user, pwd)
        #$VERBOSE = $DEBUG = true
        $VERBOSE = nil # TODO Deal with ugly warnings
        telemeter = Telemeter.new
        extractor = TelemeterDataExtractor.new
        data = telemeter.get_usage(extractor, user, pwd)
        puts "Usage: #{data.usage} of #{data.max_usage}" 
        if data.max_usage.to_i != 0
            puts "[#{('='*(data.usage/(data.max_usage/20.0)).to_i).ljust(20)}]"
        end
    end
end

class CommandLineApp
  VERSION = '0.1'
  @@message = "Unable to get usage, please try again later.\n"
    
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    # TO DO - add additional defaults
  end

  # Parse options, check arguments, then process the command
  def run
    if options_valid? && option_combinations_valid? 
      process_arguments            
      process_command
    else
      output_usage
    end
  end
  
  protected
    def options_valid?
      # Specify options
      opts = OptionParser.new 
      opts.on('-v', '--version')    { output_version ; exit 0 }
      opts.on('-h', '--help')       { output_help }
      opts.on('-V', '--verbose')    { @options.verbose = true }
      # TO DO - add additional options
            
      opts.parse!(@arguments) rescue return false

      true      
    end
    
    # True if required arguments were provided
    def option_combinations_valid?
      # TO DO - implement your real logic here
      true 
    end
    
    # Setup the arguments
    def process_arguments
      # TO DO - place in local vars, etc
    end
    
    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def output_usage
      RDoc::usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
        begin
            config = TelemeterConfig.new
            run = true
            if config.write_config
                choose do |menu|
                    menu.layout = :one_line
                    menu.prompt = "Retrieve your volume statistics now? "
                    menu.choice :yes
                    menu.choice :no do run = false end
                end
            end
            if (run)
                config_data = config.read_config
                SimpleTelemeterClient.new(config.config_location).run(config_data['user'], config.decrypt(config_data['pwd']))
            end
        rescue TelemeterException => ex
	    puts ex
            if ex.status
                # let's be smart and help the user.
                $stderr << StatusMessage.to_english(ex.status) 
                if [StatusMessage::INVALID,StatusMessage::WRONG].include?(ex.status)
                    try_again = false
                    choose do |menu|
                        menu.layout = :one_line
                        menu.prompt = "Remove configuration file and enter different credentials? "
                        menu.choice :yes do  
                            File.delete(config.config_location)
                            puts "Removed #{config.config_location}"
                            try_again = true
                        end
                        menu.choice :no
                    end
                    retry if try_again
                end
            else
                $stderr << @@message
            end
        rescue Exception => ex
            $stderr << ex 
            $stderr << "\n"
        end
    end
end

class TelemeterConfig
    @@blowfish = Crypt::Blowfish.new("At least we'll have some security, right?")
    
    def write_config()
        if !File.exist?(config_location)
            puts "Creating #{config_location}..."
            puts "Please provide your Telenet credentials."
            user = ask("User: ") { |q| q.echo = true }
            pwd = ask("Password: ") { |q| q.echo = "*" }
            File.open(config_location, "w") do |f| 
                begin
                    f.write( {"user"=>user,"pwd"=>encrypt(pwd)}.to_yaml )
                    f.chmod(0600)
                ensure
                    f.close()
                end
            end
            return true
        elsif File.directory?(config_location)
            puts "Warning: #{config_location} is a directory."
            return false
        end
        return false
    end
    
    def read_config
        begin
            file = File.open(config_location())
            return YAML::load(file)
        ensure
            file.close()
        end
    end
   
    def encrypt(pwd) 
        @@blowfish.encrypt_block(pwd)
    end
    
    def decrypt(pwd)
        @@blowfish.decrypt_block(pwd)
    end
    
    def config_location
        if RUBY_PLATFORM =~ /win32/
            home = ENV['USERPROFILE']
        else
            home = ENV['HOME']
        end
        if home[home.length-1,home.length] =~ /[^\/\\]/
            home = home + File::SEPARATOR
        end
        home + ".rtelemeter.yaml"
    end
end

# Create and run the application
app = CommandLineApp.new(ARGV, STDIN)
app.run
