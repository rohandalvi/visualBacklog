=begin
	
Author: Rohan Dalvi
Version: 1.0
Organization: EMC Corporation
Date Created: 10/5/2013.

Description: This is a intro script to import only user stories (no features or iterations). Takes care 
of the 2 step process to import parent-child user stories. 
	
=end

require 'rally_api_emc_sso'
require '../justImport/connect.rb'
require 'csv'

def create_stories(row)
	if(row["Name"] == nil)
		puts "This story has no name, it will be ignored by the script"
	else
		create_story = {}
		create_story["Name"] = row["Name"]
		create_story["Description"] = row["Description"]
		create_story["ScheduleState"] = row["Schedule State"]

		@rally.create("hierarchicalrequirement", create_story)
	end
end

def link_parents(row)
	if(row["Name"]==nil)
		puts "There is no name to this row, this won't work"
	else
		#id = get_story_id(row["Name"])
		if(row["Parent"]!=nil)
			if(it_is_parent_ID(row["Parent"]))
					if(parent_id_exists(row["Parent"]))
						row["Parent"] = get_parent_from_id(row["Parent"])
						update_story(row)
					else
						puts "The ID entered is incorrect, please enter the name next time."
						exit
					end
			else
				if(parent_name_exists(row["Parent"])) #check if parent name exists in Rally.
					# get Parent ID of this parent whose name exists in the project.
					row["Parent"] = get_parent_from_name(row["Parent"])
					update_story(row)
				end
			end
		end
	end	
end

def parent_name_exists(parentName)
	result = build_query("hierarchicalrequirement","Name,FormattedID","(Name = \"#{parentName}\")")
	
	if(result.length > 0)
		return true
	else
		return false
	end
end

def get_parent_from_name(parentName)

	result = build_query("hierarchicalrequirement","Name,FormattedID","(Name = \"#{parentName}\")")
	
	pid = nil
	if(result.length == 1)
		story = result.first
		pid = story
		
	else
		puts "Result's length is #{result.length}"
		puts "There was some problem finding your parent story, please check in Rally."
		exit
	end
	pid

end

def it_is_parent_ID(looksLikeID)
	looksLikeID = looksLikeID.to_s
	if( (! looksLikeID.nil?) && (looksLikeID[0..1].eql?("US") ) && (looksLikeID[2..5]=~ /^[-+]?[0-9]+$/) )
		return true
	else
		return false
	end
end

def parent_id_exists(parentID)
	result = build_query("hierarchicalrequirement","Name,FormattedID","(FormattedID = \"#{parentID}\")")
	
	if(result.length > 0)
		return true
	else
		return false
	end

end

def get_parent_from_id(parentID)
	result = build_query("hierarchicalrequirement","Name,FormattedID","(FormattedID = \"#{parentID}\")")
	parent = nil
	if(result.length==1)
		story = result.first
		parent = story
	else
		puts "Result's length is #{result.length}"
		puts "There was some problem finding your parent story, please check in Rally."
		exit
	end
	parent

end





def update_story(story)
	storyID = get_story_id(story["Name"])
	update_array = {}
	update_array["Name"] = story["Name"]
	update_array["Description"] = story["Description"]
	update_array["ScheduleState"] = story["Schedule State"]
	if(story["Parent"]!=nil)

		update_array["Parent"] = story["Parent"]

	end

	@rally.update("hierarchicalrequirement","FormattedID|#{storyID}",update_array)

end

def get_story_id(storyName)

	result = build_query("hierarchicalrequirement","Name,FormattedID","(Name = \"#{storyName}\")")
	if(result.length == 1)
		story = result.first
		if(story["FormattedID"]!=nil)

			return story["FormattedID"]
		else
			puts "Could not get story ID, please check the query in get_story_id function"
			exit
		end
	else
		puts "The result.length is #{result.length} and so the story ID cannot be returned"

	end
end

def build_query(type,fetch,string)
	query = RallyAPI::RallyQuery.new()
	query.type=type
	query.fetch=fetch
	query.query_string=string
	query.project ={"_ref" => "https://rally1.rallydev.com/slm/webservice/v2.0/project/14357184706.js"}
	result = @rally.find(query)
	return result
end



def start
	puts "Connected"
	file_name = "rallyimport.csv"
	input = CSV.read(file_name)

	header = input.first
	rows = []
	(1...input.size).each { |i| rows << CSV::Row.new(header, input[i]) }

	@iCount = 1 #@iCount = 0 or rows.length-1
	puts "First creating stories..."
	while @iCount<rows.length #@iCount<rows.length or @iCount> 0
		if(input[@iCount]!= nil)

			#puts rows[@iCount]
			create_stories(rows[@iCount])
			
		end
		@iCount += 1 #@iCount += 1 or @iCount -= 1
		
	end
	@count = 1
	puts "Then linking parents..."
	while @count<rows.length
		if(input[@count]!=nil)
			link_parents(rows[@count])
			
		end
		@count += 1
	end
end
start