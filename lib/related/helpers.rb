require 'base64'
require 'digest/sha2'

module Related
  module Helpers

    # Generate a unique id
    def generate_id
      Base64.encode64(
        Digest::SHA256.digest("#{Time.now}-#{rand}")
      ).gsub('/','x').gsub('+','y').gsub('=','').strip[0..21]
    end

  end
end