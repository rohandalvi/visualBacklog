=begin

  This script takes a file and uses regular expression to dig out ParentID's for all user stories. The parent ID can then be written into a csv.
  
  Author: Rohan Dalvi 
  Version: 1.0
  Date Created: 09/25/2013
    
=end 
 
  require 'nokogiri'
  require 'csv'
  require 'logger'
  
  if(ARGV.length!=1)
    puts "Usage: #{__FILE__} file_name"
    puts "where file_name is the name of html file. Also, please add double quotes if file_name contains spaces"
    exit
  end

  puts "Processing"
  
  $count = 0
  @parentInformation = []
  $iCount = 0
  $i=0
  $number = 0
  
  puts "Init Variables"
  def parse_For_Parent(text)
    
    if(text!=nil)
      
      match = text[/ParentID:(?<match>.*)$/,"match"]
      if(match!=nil)
          match = match.slice(0..(match.index(" <br")))
          @parentInformation[$count] = match.strip!
          
      end
      
    end
    $count += 1
  end
  
  
  log = Logger.new('logger.log','5')
  log.level = Logger::DEBUG
  log.debug "Log file created"

  
  file_name = ARGV[0].strip #"FastFailover1.html"
  text = File.read(file_name)
  output = text.gsub(/<meta .*>/,"")

  File.open(file_name,"w"){|file| file.puts output}

  puts "Fine-tuned the HTML"

  f = File.open(file_name)
  doc = Nokogiri::HTML(f,'utf-8')
  f.close
  count_noshade = doc.xpath('count(.//hr[@noshade])') #xpath to count number of <hr noshade> tags generated by Alfapad in the HTML file.
  
  puts "Processing HTML now..."
  #regex for selecting Name of the user story.
  ans = doc.css('a[href]').select{ |e| e['href'] =~ /\d/}
  topic = doc.css('p > span') 

  delim_array=[]
  
  h = Hash.new("Name Descripion")

  puts "Describing User Stories..."
  
  while $iCount < count_noshade do
    
    path = ".//hr[#{$iCount}][@noshade]/following-sibling::*[not(self::hr[@noshade])][count(preceding-sibling::hr[@noshade])=#{$iCount}]"  #xpath to parse information between consecutive <hr noshade> tags generated by Alfapad.
    xpath = doc.xpath(path)
    delim_array[$iCount] = xpath.text
    $iCount +=1

  end
  
  puts "Writing to CSV..."
  
  File.open("rallyimport.csv","w")
  CSV.open("rallyimport.csv","wb") do |csv|
    csv << ["Name","Description","Schedule State","Project","Parent"]
    
  while $i < ans.length do
    if(h[ans[$i]]!=nil && delim_array[$i]!=nil)
    h[ans[$i]] = delim_array[$i].tap{|s| s.slice!(ans[$i].text.to_s)}.tap{|x| x.slice!('TOP')}.gsub!(/[\r\n[,]]+/," <br /><br /> ") #replace h[ans[$i]] with description
    #h[ans[$i]] = description
    parse_For_Parent(h[ans[$i]])
    csv << ["#{h.keys[$i].text}","#{h.fetch(h.keys[$i])}","Defined","Yan-test","#{@parentInformation[$i]}"]
    end
    #puts "#{ans[$i].text}"
   # puts "#{h.keys[$i].text} => #{h.fetch(h.keys[$i])}"
    $i +=1
    
  end 
end #end for CSV.open


puts "Done! Your rallyimport.csv is now Import ready!"
#system('start /wait excel "test.csv"')
