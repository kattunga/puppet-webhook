require 'sinatra'
require 'json'

# User customization
repo_puppetfile = "<%= @repo_puppetfile %>"
<% if @repo_hieradata -%>
repo_hierdata   = "<%= @repo_hieradata %>"
<% end -%>

webhook_config_obj = JSON.parse(File.read((Dir.pwd) + "/webhook_config.json"))

post '/payload' do

  content = request.body.read
  logger.info("#{content}")

  push = JSON.parse(request.body.read)
  logger.info("json payload: #{push.inspect}")

  repo_name   = push['repository']['name']
  repo_ref    = push['ref']
  ref_array   = repo_ref.split("/")
  ref_type    = ref_array[1]
  branchName  = ref_array[2]
  logger.info("repo name = #{repo_name}")
  logger.info("repo ref = #{repo_ref}")
  logger.info("branch = #{branchName}")

  # Check if repo_name is 'puppetfile'
  if repo_name == repo_puppetfile <% if @repo_hieradata %>|| repo_name == repo_hieradata <% end %>
    logger.info("Deploy r10k for this environment #{branchName}")
    deployEnv(branchName,webhook_config_obj)
  else
    module_name = repo_name.split('-').pop
    logger.info("Deploy puppet module #{module_name}")
    logger.info("Running for branch #{branchName}")
    deployModule(module_name,webhook_config_obj)
  end
end

# Some defines.
def deployEnv(branchname,cmd_obj)
  deployCmd = "#{cmd_obj['r10k_cmd']} deploy environment #{branchname} -pv"
  logger.info("Now running #{deployCmd}")
  `#{deployCmd}`
end

def deployModule(modulename,cmd_obj)
  deployCmd = "#{cmd_obj['r10k_cmd']} deploy module #{modulename} -v"
  logger.info("Now running #{deployCmd}")
  `#{deployCmd}`
end
