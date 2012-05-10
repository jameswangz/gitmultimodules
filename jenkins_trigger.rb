#!/usr/bin/ruby

require './git_jenkins_remote_trigger'

if __FILE__ == $0
	#jenkins = 'http://localhost:8080/jenkins'
	jenkins = 'http://localhost:8081'
	module_job_mappings = { 'api' => 'api', 'impl' => 'impl' }
	running_options = { :only_once => true, :interval => 5 }
	auth_options = { :required => false, :username => 'james', :api_token => 'dcebe4f09bdc324d2d9567780f04a0c1' }
	other_options = { :branch => 'test5', :commit_id_param_name => 'BUILD_ID', :max_tracked_builds => 10 }
	GitJenkinsRemoteTrigger.new(jenkins, module_job_mappings, running_options, auth_options, other_options).run
end
