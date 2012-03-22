#!/usr/bin/ruby

require './git_jenkins_remote_trigger'

if __FILE__ == $0
	jenkins = 'http://localhost:8080/jenkins'
	module_job_mappings = { 'api' => 'api', 'impl' => 'impl', 'impl/src' => 'impl-src' }
	running_options = { :only_once => false, :interval => 5 }
	auth_options = { :required => false, :username => 'james', :api_token => 'dcebe4f09bdc324d2d9567780f04a0c1' }
	other_options = { :COMMIT_ID_PARAM_NAME => 'BUILD_ID' }
	GitJenkinsRemoteTrigger.new(jenkins, module_job_mappings, running_options, auth_options, other_options).run
end
