#!/usr/bin/env ruby

require 'test/unit'

require 'libtelemeter'

class MyTest < Test::Unit::TestCase
    def test_parse_unknown_status
        assert_equal("blah", TelemeterException.parse_status("blah"))
    end
    def test_parse_wrong_input_status
        assert_equal(StatusMessage::INVALID, TelemeterException.parse_status("adasdf ERRTLMTLS_00002sadfadsf"))
    end
    def test_parse_wait_status
        assert_equal(StatusMessage::WAIT, TelemeterException.parse_status("adasdf ERRTLMTLS_00003sadfadsf"))
    end
    def test_parse_wrong_user_pwd_status
        assert_equal(StatusMessage::WRONG, TelemeterException.parse_status("adasdf ERRTLMTLS_00004sadfadsf"))
    end
end