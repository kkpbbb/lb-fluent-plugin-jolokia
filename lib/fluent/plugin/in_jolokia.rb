#
#  Copyright 2013 the original author or authors.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require 'json'
require 'net/http'
require 'uri'

module Fluent
  
  class JolokiaInput < Input
    Plugin.register_input('jolokia',self)

    config_param :tag, :string, :default => nil
    config_param :jolokia_url, :string
    config_param :jmx_bean, :string
    config_param :jmx_attribute, :string, :default => nil
    config_param :jmx_path, :string, :default => nil
    config_param :run_interval, :time
    config_param :add_jolokia_url, :bool, :default => false
    config_param :user, :string, :default => nil
    config_param :password, :string, :default => nil

    def initialize
      super
    end
    
    def configure(conf)
      super
      @uri = URI.parse(@jolokia_url)
    end
      
    def start
      @finished = false
      @thread = Thread.new(&method(:run_periodic))
    end

    def shutdown
      if @run_interval
        @finished = true
        @thread.join
      else
        Process.kill(:TERM, @pid)
        if @thread.join(60)
          return
        end
        Process.kill(:KILL, @pid)
        @thread.join
      end
    end

    # 
    # Main loop 
    #
    def run_periodic
      until @finished
        sleep @run_interval

        tag         = @tag
        value       = get_attribute(@jmx_bean, @jmx_attribute, @jmx_path)
        value[:url] = @jolokia_url if @add_jolokia_url

        Engine.emit(
          tag, 
          Engine.now.to_i,
          value
        )
        
      end
    end  

    def get_attribute(mbean, attribute = nil, path = nil)
      opt             = { :type => 'read', :mbean => mbean }
      opt[:attribute] = attribute if attribute
      opt[:path]      = path if path

      resp = HTTParty.post(@jolokia_url, :body => JSON.generate(opt))

      return nil

      http = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.path)
      request.basic_auth(@user, @password) if @user
      request.body = JSON.generate(opt)
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        $log.warn "Failed to get data from #{@uri}. #{response.code} #{response.message}"
        return nil
      end 
      data = JSON.parse(resp.body)
      if data.nil?
        $log.warn "Failed to parse a response from #{@uri}. data is nil." 
        return nil
      end
      return data

    end
  end    
end
