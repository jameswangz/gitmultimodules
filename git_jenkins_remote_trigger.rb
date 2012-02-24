#!/usr/bin/ruby

require 'net/http'
require 'uri'

class GitJenkinsRemoteTrigger
	
	@@jenkins = 'http://localhost:8080/jenkins'
	@@modules2jobs = { 'api' => 'api', 'impl' => 'impl' }
	@@poll_internal = 5

	@@auth_required = true
	# following fileds only required if @@auth_required is true
	@@user_name = 'james'
	@@api_token = 'dcebe4f09bdc324d2d9567780f04a0c1' 
		
	def run
		while true
			pull_result = %x[git pull origin master]
			puts pull_result
			next if pull_result.include? 'Already up-to-date'
			@@modules2jobs.each do |module_name, job_name|
				result = %x[git log --quiet HEAD~..HEAD #{module_name}]
				if not result.empty?
					trigger job_name 
				end
			end
			sleep @@poll_internal	
		end
	end

	def trigger(job_name)
		puts "triggering job #{job_name}"
		uri = URI("#{@@jenkins}/job/#{job_name}/build")			
		if @@auth_required
			req = Net::HTTP::Get.new(uri.request_uri)
			req.basic_auth @@user_name, @@api_token
			res = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
			puts res.body
		else
			Net::HTTP.get_print uri 
		end
	end

end

if __FILE__ == $0
	GitJenkinsRemoteTrigger.new.run
end
