#
# Copyright 2011-2013, Dell
# Copyright 2013-2014, SUSE LINUX Products GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "kwalify"
require "uri"
require "ipaddr"

class CrowbarValidator < Kwalify::Validator
   def initialize(schema_filename)
      super(Kwalify::Yaml.load_file(schema_filename))
   end

   ## hook method called by Validator#validate()
   def validate_hook(value, rule, path, errors)
      case rule.name
      when "DiskURL"
         begin
           arr = URI.split(value)
           if arr[0] != "disk"
             msg = "Should have protocol disk: #{value}"
             errors << Kwalify::ValidationError.new(msg, path)
           end
           if arr[2] == ""
             msg = "Should have host specified: #{value}"
             errors << Kwalify::ValidationError.new(msg, path)
           end
           if arr[5] == ""
             msg = "Should have path specified: #{value}"
             errors << Kwalify::ValidationError.new(msg, path)
           end
         rescue URI::InvalidURIError
           msg = "Should be a valid URI: #{value}"
           errors << Kwalify::ValidationError.new(msg, path)
         end
      when "FQDN"
         subregex = /[a-zA-Z0-9\-]{1,63}/
         endregex = /[\-]\z/
         startregex = /\A[\-]/
         numberregex = /\A\d+\z/

         if value.length > 254
           msg = "Should be a shorter than 254 characters: #{value}"
           errors << Kwalify::ValidationError.new(msg, path)
         end

         arr = value.split(".")
         if arr.length < 2
           msg = "Must contain 2 or more subdomains: #{value}"
           errors << Kwalify::ValidationError.new(msg, path)
         end
         if arr.last.length < 2
           msg = "Last subdomain must be more than 1 character: #{value}"
           errors << Kwalify::ValidationError.new(msg, path)
         end
         arr.each do |dn|
           if dn[subregex].nil?
             msg = "Can only contain _-A-Za-z0-9: #{value}"
             errors << Kwalify::ValidationError.new(msg, path)
           end
           if !dn[endregex].nil?
             msg = "Last character can not be - or _: #{value}"
             errors << Kwalify::ValidationError.new(msg, path)
           end
           if !dn[startregex].nil?
             msg = "First character can not be - or _: #{value}"
             errors << Kwalify::ValidationError.new(msg, path)
           end
           if !dn[numberregex].nil?
             msg = "Subdomain can not be only numbers: #{value}"
             errors << Kwalify::ValidationError.new(msg, path)
           end
        end
      when "Email"
         regex = /\A([\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+\.)*[\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+@((((([a-z0-9]{1}[a-z0-9\-]{0,62}[a-z0-9]{1})|[a-z])\.)+[a-z]{2,6})|(\d{1,3}\.){3}\d{1,3}(\:\d{1,5})?)\z/
         if value[regex].nil?
           msg = "Should be an Email Address: #{value}"
           errors << Kwalify::ValidationError.new(msg, path)
         end
      when "DomainName"
         # http://tools.ietf.org/html/rfc1034#section-3.5
         # https://tools.ietf.org/html/rfc1123#page-13
         label = /[a-z0-9]([a-z0-9\-]{0,253}[a-z0-9])?/i
         regex = /\A#{label}(\.#{label})*\z/
         if value[regex].nil?
           msg = "Should be a Domain Name: #{value}"
           errors << Kwalify::ValidationError.new(msg, path)
         end
      when "IpAddress"
        cidr = (1..128).cover? Integer(value) rescue false
        blank_broadcast = path.is_a?(String) && path.include?("broadcast") \
          && value.empty?
        begin
          IPAddr.new(value) unless blank_broadcast || cidr
        rescue IPAddr::InvalidAddressError
          msg = "Should be an IP Address: #{value}"
          errors << Kwalify::ValidationError.new(msg, path)
        end
      when "IpAddressMap"
         value.each_key do |key|
           begin
             IPAddr.new(key)
           rescue IPAddr::InvalidAddressError
             msg = "Should be an IP Address: #{key}"
             errors << Kwalify::ValidationError.new(msg, path)
           end
         end
      end
   end
end
