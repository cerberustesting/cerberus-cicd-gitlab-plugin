#!/usr/local/bin/ruby

require 'optparse'
require 'net/http'
require 'uri'
require 'pp'
require 'json'

# function to perform http requests
# TODO: Add error controls
def call_uri(url, method)
  uri = URI(url)
  if method == 'POST'
    req = Net::HTTP::Post.new(uri)
  elsif method == 'GET'
    req = Net::HTTP::Get.new(uri)
  end
  puts "Executing #{method} to: #{url}"
  res = Net::HTTP.start(uri.hostname) do |http|
    http.request(req)
  end

  res
end

# list of environments (to be fed later)
qs_envs = ''
qs_countries = ''
qs_robots = ''

# parsed arguments with defaults
script_arguments = {
  executor: 'cerberus-gitlab-plugin',
  maxcampaignexecutiontime: 300
}

OptionParser.new do |opts|
  opts.banner = 'Usage: cerberus_gitlab_plugin [options]'

  # parse the cerberus host (mandatory)
  opts.on('-a [ARG]', '--cerberus_host [ARG]', 'MANDATORY : Cerberus url.') do |v|
    script_arguments[:cerberus_host] = v
  end

  # parse the campaign name (mandatory)
  opts.on('-c [ARG]', '--campaign [ARG]', 'MANDATORY : Cerberus campaign name.') do |v|
    script_arguments[:campaign] = v
  end

  # parse the tag (mandatory)
  opts.on('-t [ARG]', '--tag [ARG]', 'MANDATORY : Cerberus campaign tag execution.') do |v|
    script_arguments[:tag] = v
  end

  # parse the environments list
  opts.on('-e [ARG]', '--envs [ARG]', 'Optional : Cerberus environments list separated by comma (e.g. QA,UAT).') do |v|
    script_arguments[:envs] = v
    script_arguments[:envs].split(',').each { |env| qs_envs += "&environment=#{env}" }
  end

  # parse the country list
  opts.on('-n [ARG]', '--country [ARG]', 'Optional : Cerberus countries list separated by comma (e.g. FR,UK).') do |v|
    script_arguments[:country] = v
    script_arguments[:country].split(',').each { |country| qs_countries += "&country=#{country}" }
  end

  # parse the robots list
  opts.on('-b [ARG]', '--robots [ARG]', 'Optional : Cerberus robots list separated by comma (e.g. robot1,robot2).') do |v|
    script_arguments[:robots] = v
    script_arguments[:robots].split(',').each { |robot| qs_robots += "&robot=#{robot}" }
  end

  # parse the screenshot setting
  opts.on('-s [ARG]', '--screenshot [ARG]', 'Optional : Cerberus screenshot execution setting value (from 1 to 5).') do |v|
    script_arguments[:screenshot] = v
  end

  # parse the verbose setting
  opts.on('-v [ARG]', '--verbose [ARG]', 'Optional : Cerberus verbose execution setting value (0, 1 or 2).') do |v|
    script_arguments[:verbose] = v
  end

  # parse the pagesource setting
  opts.on('-p [ARG]', '--pagesource [ARG]', 'Optional : Cerberus page source execution setting value (0, 1 or 2).') do |v|
    script_arguments[:pagesource] = v
  end

  # parse the selenium log setting
  opts.on('-l [ARG]', '--seleniumlog [ARG]', 'Optional : Cerberus selenium log execution setting value (0, 1 or 2).') do |v|
    script_arguments[:seleniumlog] = v
  end

  # parse the timeout setting
  opts.on('-i [ARG]', '--timeout [ARG]', 'Optional : Cerberus timeout execution setting value (in ms).') do |v|
    script_arguments[:timeout] = v
  end

  # parse the retries setting
  opts.on('-r [ARG]', '--retries [ARG]', 'Optional : Cerberus retries execution setting value (from 0 to 3).') do |v|
    script_arguments[:retries] = v
  end

  # parse the priority setting
  opts.on('-o [ARG]', '--priority [ARG]', 'Optional : Cerberus priority execution setting value.') do |v|
    script_arguments[:priority] = v
  end

  # parse the manual execution setting
  opts.on('-m [ARG]', '--manualexecution [ARG]', 'Optional : Cerberus manual execution setting value (Y, N or A).') do |v|
    script_arguments[:manualexecution] = v
  end

  # Set executor value
  opts.on('-x [ARG]', '--executor [ARG]', 'Optional : Cerberus executor (who trigger the build)') do |v|
    script_arguments[:executor] = v
  end

  # Set plugin max timeout
  # this timeout refers to the gitlab job execuction: if the campaigns execution exceeds this duration, the job fails wih 
  opts.on('--maxcampaignexecutiontime [ARG]', 'Optional : Gitlab timeout allowed to wait for campaign completion, in seconds. (default: 300)') do |v|
    script_arguments[:maxcampaignexecutiontime] = v
  end

  # help
  opts.on('-h', '--help', 'Display this help') do 
    puts opts
    exit
  end

end.parse!

# mandatory parameters check
isCampaignDefined = !script_arguments[:campaign].nil?
isTagDefined = !script_arguments[:tag].nil?
isHostDefined = !script_arguments[:cerberus_host].nil?

if !isHostDefined
  puts 'ERROR: mandatory argument not found (cerberus host), exiting with code 1.'
  exit 1
elsif !isCampaignDefined
  puts 'ERROR: mandatory argument not found (campaign name), exiting with code 1.'
  exit 1
elsif !isTagDefined
  puts 'ERROR: mandatory argument not found (tag), exiting with code 1.'
  exit 1
end

# optional parameters check
isEnvsListDefined = !script_arguments[:envs].nil?
isCountriesListDefined = !script_arguments[:country].nil?
isRobotsListDefined = !script_arguments[:robots].nil?
isScreenshotSettingDefined = !script_arguments[:screenshot].nil?
isVerboseSettingDefined = !script_arguments[:verbose].nil?
isPageSourceSettingDefined = !script_arguments[:pagesource].nil?
isSeleniumLogSettingDefined = !script_arguments[:seleniumlog].nil?
isTimeoutSettingDefined = !script_arguments[:timeout].nil?
isRetriesSettingDefined = !script_arguments[:retries].nil?
isPrioritySettingDefined = !script_arguments[:priority].nil?
isManualExecutionSettingDefined = !script_arguments[:manualexecution].nil?

# log any overrides
if isEnvsListDefined then puts "INFO: environments list value has been set by the plugin with value #{script_arguments[:envs]}" end
if isCountriesListDefined then puts "INFO: countries list value has been set by the plugin with value #{script_arguments[:country]}" end
if isRobotsListDefined then puts "INFO: robots list value has been set by the plugin with value #{script_arguments[:robots]}" end
if isScreenshotSettingDefined then puts "INFO: screenshot setting value has been overridden by the plugin with value #{script_arguments[:screenshot]}" end
if isVerboseSettingDefined then puts "INFO: verbose setting value has been overridden by the plugin with value #{script_arguments[:verbose]}" end
if isPageSourceSettingDefined then puts "INFO: page source setting value has been overridden by the plugin with value #{script_arguments[:pagesource]}" end
if isSeleniumLogSettingDefined then puts "INFO: selenium log setting value has been overridden by the plugin with value #{script_arguments[:seleniumlog]}" end
if isTimeoutSettingDefined then puts "INFO: timeout setting value has been overridden by the plugin with value #{script_arguments[:timeout]}" end
if isRetriesSettingDefined then puts "INFO: retries setting value has been overridden by the plugin with value #{script_arguments[:retries]}" end
if isPrioritySettingDefined then puts "INFO: priority setting value has been overridden by the plugin with value #{script_arguments[:priority]}" end
if isManualExecutionSettingDefined then puts "INFO: manual execution setting value has been overridden by the plugin with value #{script_arguments[:manualexecution]}" end

# build query strings

# set the mandatory parameters
qs = "campaign=#{script_arguments[:campaign]}&tag=#{script_arguments[:tag]}&executor=#{script_arguments[:executor]}"

# set the optional parameters (if defined)

# set the environments list 
if isEnvsListDefined then qs += qs_envs end

# set the countries list 
if isCountriesListDefined then qs += qs_countries end

# set the robots list 
if isRobotsListDefined then qs += qs_robots end

# set the screenshot values
if isScreenshotSettingDefined then qs += "&screenshot=#{script_arguments[:screenshot]}" end

# set the verbose values
if isVerboseSettingDefined then qs += "&verbose=#{script_arguments[:verbose]}" end

# set the page source values
if isPageSourceSettingDefined then qs += "&pagesource=#{script_arguments[:pagesource]}" end

# set the selenium values
if isSeleniumLogSettingDefined then qs += "&seleniumlog=#{script_arguments[:seleniumlog]}" end

# set the timeout values
if isTimeoutSettingDefined then qs += "&timeout=#{script_arguments[:timeout]}" end

# set the retries values
if isRetriesSettingDefined then qs += "&retries=#{script_arguments[:retries]}" end

# set the priority values
if isPrioritySettingDefined then qs += "&priority=#{script_arguments[:priority]}" end

# set the manual execution values
if isManualExecutionSettingDefined then qs += "&manualexecution=#{script_arguments[:manualexecution]}" end

# log
puts "Launching campaign: #{script_arguments[:campaign]} on host: #{script_arguments[:cerberus_host]} with tag: #{script_arguments[:tag]}"
puts "Triggering Cerberus call : #{script_arguments[:cerberus_host]} with query strings #{qs}"

# post to /AddToExecutionQueueV003
url = "#{script_arguments[:cerberus_host]}/AddToExecutionQueueV003?#{qs}"
res = call_uri(url, 'POST')
case res
when Net::HTTPSuccess, Net::HTTPRedirection
  puts "--- Cerberus API return ---\n\n"
  puts res.body
  exit(1) unless res.body.include? 'succesfully inserted to queue'
else
  res.value
end

# TODO: control the http status
# TODO: returns an error if no campaign could be launched (if we pass no parameter and it itsn't defined)
# TODO: get the tag

# Result : OK (Score : 0.0), campaign executed in 4s.
# Details : OK 7 | KO 1 | FA 3 | NA 0 | NE 0 | WE 0 | PE 0 | QU 0 | QE 0 | CA 0
# ---------------------------------------------------------------------------------------------
# Progress : 100% (11/11) still 0 to go - Details : OK 7 | KO 1 | FA 3 | NA 0 | NE 0 | WE 0 | PE 0 | QU 0 | QE 0 | CA 0

def campaign_progress(json_res)
  s_qu = json_res['status_QU_nbOfExecution']
  s_fa = json_res['status_FA_nbOfExecution']
  s_we = json_res['status_WE_nbOfExecution']
  s_ko = json_res['status_KO_nbOfExecution']
  s_ne = json_res['status_NE_nbOfExecution']
  s_pe = json_res['status_PE_nbOfExecution']
  s_ca = json_res['status_CA_nbOfExecution']
  s_qe = json_res['status_QE_nbOfExecution']
  s_na = json_res['status_NA_nbOfExecution']
  s_ok = json_res['status_OK_nbOfExecution']
  total = json_res['TOTAL_nbOfExecution']
  s_executed = s_fa + s_we + s_ko + s_ne + s_ca + s_qe + s_na + s_ok
  puts "Details: OK #{s_ok} | KO #{s_ko} | FA #{s_fa} | NA #{s_na} | SE #{s_ne} | WE #{s_we} | PE #{s_pe} | QU #{s_qu} | QE #{s_qe} | CA #{s_ca}"
  puts "Progress: #{(s_executed * 100) / total}% (#{total}/#{s_executed}) - To be executed: #{s_pe + s_qu}"
  # TODO implement progress
end
url = "#{script_arguments[:cerberus_host]}/ResultCIV003?tag=#{script_arguments[:tag]}"
o = 0
# Check interval
interval = 5
# Max time for campaign execution completion
timeout = Integer(script_arguments[:maxcampaignexecutiontime])


# Control values
campaign_result = ''
error = 0
error_threshold = 5
hasTimeoutBeenExceeded = false

loop do
  sleep(interval)

  # call ResultCI
  res = call_uri(url, 'GET')

  case res
  when Net::HTTPSuccess, Net::HTTPRedirection
    res_parsed = JSON.parse(res.body)
    campaign_result = res_parsed['result']
    campaign_progress(res_parsed)
  else
    # TODO: parse errors when campaign isn't reacheable
    puts 'Error: Campaign not reacheable'
    error += 1
    # res.value
  end
  o += interval
  if o >= timeout then hasTimeoutBeenExceeded = true end
  break if o >= timeout || error > error_threshold
  break if campaign_result.include?('OK') || campaign_result.include?('KO')
end

if hasTimeoutBeenExceeded == true
  puts 'Campaign execution exceeded the gitlab timeout of ' + timeout.to_s + ' seconds, exiting with code 3'
  exit 3
end

# Parse the CI Score value (OK/KO and complete accordingly)
case campaign_result
when 'OK'
  puts 'The Cerberus campaign CI status is: OK, exiting with code 0'
  exit 0
when 'KO'
  puts 'The Cerberus campaign CI status is: KO, exiting with code 2'
  exit 2
else
  puts 'ERROR : no CI status has been found, exiting with code 1'
  exit 1
end
