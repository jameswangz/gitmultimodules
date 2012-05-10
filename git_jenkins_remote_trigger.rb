require 'uri'
require 'net/http'
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

module LogAnalyzer
	def analyze_multiple_commit_logs(raw_data)
		array = raw_data.scan(/commit\s+(.*?)\n+Author:\s+(.*?)\n+Date:\s+(.*?)\n+\s+(.*)/)
		hashs = array.collect { |elements| { 'commit_id' => elements[0], 'author' => elements[1], 'date' => elements[2], 'message' => elements[3] }  }
	end	
end

class GitJenkinsRemoteTrigger

	include LogAnalyzer

	def initialize(
		jenkins, 
		module_job_mappings, 
		running_options = { :only_once => true }, 
		auth_options = { :required => false },
		other_options = { :commit_id_param_name => 'GIT_COMMIT_ID'	}
	)	
		@jenkins = jenkins
		@module_job_mappings = module_job_mappings
		@running_options = running_options
		@auth_options = auth_options		
		@other_options = other_options
		@branch = @other_options[:branch]
		@working_dir = File.expand_path('.github_shared_repository', '~')
		create_working_dir_if_required
	end

	def create_working_dir_if_required
		if !File.exists? @working_dir
			puts "Creating working dir #{@working_dir}"
			FileUtils.mkdir(@working_dir)
		end
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
		create_or_switch_branch
		return
		pull_cmd = "git pull origin #{@branch}"
		puts pull_cmd
		pull_result = %x[#{pull_cmd}]
		puts pull_result
		return if pull_result.include? 'Already up-to-date'
		if pull_result.empty?
			puts 'Error! Couldn\'t pull from git repository, please check your network setting and SSH key.'
			return
		end
		@module_job_mappings.each do |module_name, job_name|
			working_file = initialize_working_file(job_name)
			build_data = YAML.load_file(working_file)
			changes_since_last_build = get_changes_since_last_build(build_data, module_name)
			if not changes_since_last_build.empty?
				commit_id = last_commit_id_of(changes_since_last_build) 
				unshift_this_build(build_data, working_file, changes_since_last_build)
				trigger(job_name, commit_id)
			end
		end
	end

	def create_or_switch_branch
		branches_output = %x[git branch]
		branches = {}
		branches_output.lines.each do |e| 
			e.strip =~ /(\*\s*)?(.+)/
			branches[$2] = !$1.nil?
		end
		puts branches
		return
		if branches.has_key? @branch
			current = branches[@branch]
			cmd = "git checkout #{@branch}" unless current
		else
			# The branch doesn't exist, we need to update the remote branch info and create it
			%x[git pull origin]
			cmd = "git checkout -b #{@branch} origin/#{@branch}"
		end	
		puts cmd
		%x[#{cmd}] if cmd
	end

	def initialize_working_file(job_name)
		working_file = File.expand_path("#{job_name}.yml", @working_dir)
		if !File.exists? working_file
			puts "Creating working file #{working_file}"
			initial_build_data = { 
				'recent_builds' => [
					{ 'build_id' => 'NONE', 'changes_since_last_build' => [] }
				] 
			}	
			File.open(working_file, 'w') { |f| f.write(initial_build_data.to_yaml) }
		end	
		working_file
	end

	def get_changes_since_last_build(build_data, module_name)
		last_build_id = build_data['recent_builds'][0]['build_id']
		if last_build_id == 'NONE'
			command = "git log --quiet #{module_name}"
		else
			command = "git log --quiet #{last_build_id}..HEAD #{module_name}"
		end
		puts command
		logs_raw_data = %x[#{command}]
		changes_since_last_build = analyze_multiple_commit_logs(logs_raw_data)
		puts "changes since last build of #{module_name} #{changes_since_last_build}"
		changes_since_last_build
	end

	def last_commit_id_of(changes_since_last_build)
		commit_id = changes_since_last_build.first['commit_id'] 
	end

	def unshift_this_build(build_data, working_file, changes_since_last_build)
		build_data['recent_builds'].unshift({ 'build_id' => last_commit_id_of(changes_since_last_build), 'changes_since_last_build' => changes_since_last_build })
		if (build_data['recent_builds'].length > @other_options[:max_tracked_builds]) 
			build_data['recent_builds'] = build_data['recent_builds'].take(@other_options[:max_tracked_builds])
		end	
		File.open(working_file, 'w') { |f| f.write(build_data.to_yaml) }
	end	

	def trigger(job_name, commit_id)
		puts "triggering job #{job_name}"
		uri = URI("#{@jenkins}/job/#{job_name}/buildWithParameters?#{@other_options[:commit_id_param_name]}=#{commit_id}")			
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

