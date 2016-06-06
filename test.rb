@Tasks = [
                { :Task => "Clean Up work space", :status => "Not started"},
                { :Task => "Checkout Release branch",:status => "Not started"},
                { :Task => "Validate Head of Release Branch", :status => "Not started"},
                { :Task => "Check out master branch", :status => "Not started"},
                { :Task => "Create temporaray branch", :status => "Not started"},
                { :Task => "Merge Relase branch -> Temporary Branch", :status => "Not started"},
                { :Task => "Update Version in Pom.xml", :status => "Not started"},
                { :Task => "Deploy Profile", :status => "Not started"}
              ]


def successfn(index)
  @Tasks[index][:status] = "Success"
  puts @Tasks.length
  if (index+1 < @Tasks.length)
      @Tasks[index+1][:status]="Started and Running...."
  end
  #displayStatus()
end

successfn(7)
