require 'net/http'
require 'uri'

##
# This script is used to trigger jenkins jobs remotely based on a 'shared' git reposiotry, to make it works you must put this file
# in the respository's root folder, there are 2 ways to create a shared git repository
#
#   1. Configure the workspaceDir in JENKINS_HOME/config.xml, set the value to the git repository folder 
#   2. Create soft links for all jobs, source ->  git repository folder, target -> job/workspace 
# 
# We may create a Jenkins plugin later but it works currently. 
# 
# @author James (james.wang.z81@gmail.com)
# @since Feb 22, 2012
#
##
class GitJenkinsRemoteTrigger
	
	def initialize(jenkins, module_job_mappings, running_options = { :only_once => true }, auth_options = { :required => false })	
		@jenkins = jenkins
		@module_job_mappings = module_job_mappings
		@running_options = running_options
		@auth_options = auth_options		
	end

	def run
		if @running_options[:only_once]
			run_once
		else	
			while true
				run_once
				sleep @running_options[:interval] 
			end
		end
	end

	def run_once
		pull_result = %x[git pull origin master]
		puts pull_result
		return if pull_result.include? 'Already up-to-date'
		@module_job_mappings.each do |module_name, job_name|
			result = %x[git log --quiet HEAD~..HEAD #{module_name}]
			if not result.empty?
				trigger job_name 
			end
		end
	end

	def trigger(job_name)
		puts "triggering job #{job_name}"
		uri = URI("#{@jenkins}/job/#{job_name}/build")			
		begin
			if @auth_options[:required] 
				req = Net::HTTP::Get.new(uri.request_uri)
				req.basic_auth @auth_options[:username], @auth_options[:api_token] 
				res = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
				puts res.body
			else
				Net::HTTP.get_print uri 
			end
		rescue => e
			puts "Trigger error!!! -> #{e}"
		end
	end

end
