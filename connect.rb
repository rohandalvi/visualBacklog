require 'rally_api_emc_sso'
#Setting custom headers
headers = RallyAPI::CustomHttpHeader.new()
headers.name = "My Utility"
headers.vendor = "MyCompany"
headers.version = "1.0"

#or one line custom header

workspace = "" #enter workspace name here
project = "" #enter project name here

config = {:base_url => "https://rally1.rallydev.com/slm"}
config[:workspace]  = "#{workspace}"
config[:project]    = "#{project}"
config[:headers]    = headers #from RallyAPI::CustomHttpHeader.new()

@rally = RallyAPI::RallyRestJson.new(config)
