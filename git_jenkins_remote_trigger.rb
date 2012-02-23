#!/usr/bin/ruby

require 'net/http'
require 'uri'

class GitJenkinsRemoteTrigger
	
	@@jenkins = 'http://10.30.148.51:8080/jenkins'
	@@modules = ['api', 'impl']
	@@poll_internal = 5

	@@auth_required = true
	# following fileds only required if @@auth_required is true
	@@api_token = 'dcebe4f09bdc324d2d9567780f04a0c1' 
		
	def run
		while true
			pull_result = %x[git pull origin master]
			next if pull_result.strip == 'Already up-to-date.'
			@@modules.each do |m|
				result = %x[git log --quiet HEAD~..HEAD #{m}]
				if not result.empty?
					trigger_job m
				end
			end
			sleep @@poll_internal	
		end
	end

	def trigger_job(job_name)
		puts "triggering job #{job_name}"
		uri_string = "#{@@jenkins}/job/#{job_name}/build"			
		if @@auth_required
			uri = URI("#{uri_string}?token=#{@@api_token}")
			req = Net::HTTP::Get.new(uri.request_uri)
			req.basic_auth 'james', 'james'
			res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
			puts res.body
		else
			Net::HTTP.get_print URI(uri_string) 
		end
	end

end

if __FILE__ == $0
	GitJenkinsRemoteTrigger.new.run
end
