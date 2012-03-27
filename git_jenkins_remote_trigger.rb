require 'net/http'
require 'uri'
require 'fileutils'
require 'yaml'

##
# This script is used to trigger jenkins jobs remotely based on a 'shared' git reposiotry, to make it works you must put this file
# in the respository's root folder, as far as we know, there are 2 ways to create a shared git repository
#
#   1. Configure the workspaceDir in JENKINS_HOME/config.xml, set the value to the git repository folder, this solution
#      only works for the situation that the Jenkins server is dedicated for only 1 project. 
#   2. Create soft links for all jobs, source ->  git repository folder, target -> job/workspace 
# 
# We may create a Jenkins plugin later but it works currently. 
# 
# @author James Wang (james.wang.z81@gmail.com)
# @since Feb 22, 2012
#
##
class GitJenkinsRemoteTrigger
	
	def initialize(
		jenkins, 
		module_job_mappings, 
		running_options = { :only_once => true }, 
		auth_options = { :required => false },
		other_options = { :COMMIT_ID_PARAM_NAME => 'GIT_COMMIT_ID'	}
	)	
		@jenkins = jenkins
		@module_job_mappings = module_job_mappings
		@running_options = running_options
		@auth_options = auth_options		
		@other_options = other_options
		@working_dir = File.expand_path('.github_shared_repository', '~')
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
		create_working_dir_if_required
		pull_result = %x[git pull origin master]
		puts pull_result
		return if pull_result.include? 'Already up-to-date'
		if pull_result.empty?
			puts 'Error! Couldn\'t pull from git repository,  please check your network setting and SSH key.'
			return
		end
		@module_job_mappings.each do |module_name, job_name|
			working_file = File.expand_path("#{job_name}.yml", @working_dir)
			if !File.exists? working_file
				puts "Creating working file #{working_file}"
				intial_build_data = { 
					'current_build' => 'HEAD',
					'changes_since_last_build' => []
				}	
				File.open(working_file, 'w') { |f| f.write(intial_build_data.to_yaml) }
			end	
			result = %x[git log --quiet HEAD~..HEAD #{module_name}]
			puts "Result of #{module_name} [#{result}]"
			if not result.empty?
				result =~ /commit\s+(.+)/
				commit_id = $1

				build_data = YAML.load_file(working_file)
				last_build = build_data['current_build']
				changes_since_last_build_raw_data = %x[git log --quiet #{last_build}..HEAD #{module_name}]
				#puts "changes_since_last_build [#{changes_since_last_build_raw_data}]"
				changes_since_last_build = changes_since_last_build_raw_data.scan(/(commit.*)*/m) 
				puts changes_since_last_build

				build_data['current_build'] = commit_id
				File.open(working_file, 'w') { |f| YAML.dump(build_data, f) }		
				
				#trigger job_name, commit_id
			end
		end
	end

	def create_working_dir_if_required
		if !File.exists? @working_dir
			puts "Creating working dir #{@working_dir}"
			FileUtils.mkdir(@working_dir)
		end
	end

	def trigger(job_name, commit_id)
		puts "triggering job #{job_name}"
		uri = URI("#{@jenkins}/job/#{job_name}/buildWithParameters?#{@other_options[:COMMIT_ID_PARAM_NAME]}=#{commit_id}")			
		puts uri
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
