# == Synopsis
#   Library that helps developers consult a Telenet subscription's
#   current volume usage.
#
# == Author
#   Robbie Vanbrabant
#
# == Copyright
#   Copyright (c) 2008 Robbie Vanbrabant.

require 'soap/wsdlDriver'
require 'rexml/document'

class Telemeter

  @@wsdl = 'https://t4t.services.telenet.be/TelemeterService.wsdl'
  def initialize
    @telemeter = SOAP::WSDLDriverFactory.new(@@wsdl).create_rpc_driver
  end

  def get_usage(user, pwd)
    puts "User: #{user}"
    usage = @telemeter.retrieveUsage(:UserId => user,:Password => pwd)
    puts "Measured at: #{usage.ticket.timestamp}"
    puts "Next update: #{usage.ticket.expiryTimestamp}"
    TelemeterData.new(usage.volume.totalUsage.to_i, usage.volume.limit.to_i)
  end
end

class TelemeterData
  attr_reader :max_usage, :usage

  def initialize(usage, max_usage)
    @max_usage = max_usage
    @usage = usage
  end
end
