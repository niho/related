require 'base64'
require 'digest/md5'

module Related
  module Helpers

    # Generate a unique id
    def generate_id
      Base64.encode64(
        Digest::MD5.digest("#{Time.now}-#{rand}")
      ).gsub('/','x').gsub('+','y').gsub('=','').strip
    end

  end
end