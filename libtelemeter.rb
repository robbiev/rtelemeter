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
    @@wsdl = 'https://telemeter4tools.services.telenet.be/TelemeterService?wsdl'
    def initialize
        @telemeter = SOAP::WSDLDriverFactory.new(@@wsdl).create_rpc_driver
    end
    
    def get_usage(extractor, user, pwd)
        extractor.extract(@telemeter.getUsage(user, pwd))
    end
end

class TelemeterException < RuntimeError
    attr_reader :status
    def initialize(status)
        @status = TelemeterException.parse_status(status)
    end

    def self.parse_status(stat)
        # ERRTLMTLS_00001 means unknown error,
        # which is the default anyway so we don't care
        if stat =~ /ERRTLMTLS_00002/
            return StatusMessage::INVALID
        elsif stat =~ /ERRTLMTLS_00003/
            return StatusMessage::WAIT
        elsif stat =~ /ERRTLMTLS_00004/
            return StatusMessage::WRONG
        end
        
        return stat
    end
end

class StatusMessage
    INVALID="ERRTLMTLS_00002"
    WAIT="ERRTLMTLS_00003"
    WRONG="ERRTLMTLS_00004"
    
    def self.to_english(msg)
        if msg == INVALID
            return "An empty user name or password is not allowed."
        elsif msg == WAIT
            return "Telenet does not accept your request at this time:\n" +
                   "    This happens when you made too many requests in a short period of time.\n" +
                   "    Try to avoid this; the service does not update that often anyway.\n" +
                   "    Wait for about half an hour and try again."
        elsif msg == WRONG
            return "Wrong user name or password."
        end
        
        return msg
    end
end

class TelemeterData
    attr_reader :max_usage, :usage
    
    def initialize(usage, max_usage)
        @max_usage = max_usage
        @usage = usage
    end
end

class TelemeterDataExtractor
    def initialize()
        @doc = nil
    end
    
    def extract(xml_response)
        @doc = REXML::Document.new(xml_response)
        
        check_status()        
        
        max_total = @doc.find_first_recursive() { |node| node.name == 'max-up'}.text.to_i
        total = @doc.find_first_recursive() { |node| node.name == 'up'}.text.to_i
        TelemeterData.new(total, max_total)
    end
    
    private 
        # Checks the return code and raises an exception if something is wrong
        def check_status
            status = @doc.find_first_recursive() { |node| node.name == 'status'}.text
            # Sometimes this is a message that occupies multiple lines
            raise TelemeterException.new(status) if status != 'OK'
        end
end