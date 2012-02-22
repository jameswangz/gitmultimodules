#!/usr/bin/ruby

require 'net/http'
require 'uri'

class JenkinsRemoteTrigger
	
	@@jenkins = 'http://localhost:8080/jenkins'
	@@modules = ['api', 'impl']
	@@poll_internal = 5

	def run
		while true
			pull_result = %x[git pull origin master]
			next if pull_result.strip == 'Already up-to-date.'
			@@modules.each do |m|
				result = %x[git log --quiet HEAD~..HEAD #{m}]
				if not result.empty?
					puts "triggering job #{m}"
					Net::HTTP.get_print URI("#{@@jenkins}/job/#{m}/build/")			
				end
			end
			sleep @@poll_internal	
		end
	end

end

JenkinsRemoteTrigger.new.run
