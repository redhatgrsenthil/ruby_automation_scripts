
#define the task to be performed by jenkins and tracking status of the task
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

#Getting name of the release branch as a param from jenkins
@releaseBranchName = "#{ARGV[0]}"

@date = Time.now.strftime("%Y%m%d")

#Generating temporary branch name
# Ex: BR_RELESE_TEST_20160501_12_30_12
@time=Time.new
@tempBranchName="#{@releaseBranchName}_#{@time.year}#{@time.month}#{@time.day}_#{@time.hour}_#{@time.min}_#{@time.sec}"

# Displaying over all status
def displayStatus()
  @counter=1
  puts "\n\n\n"
  puts "                     ****   Tasks  ****                                       "
  puts "__________________________________________________________________________\n\n"
  @Tasks.each  do | task |
    printf "%d - %-50s %s",@counter,task[:Task],task[:status]
    puts "\n"
    @counter=@counter+1
  end
  puts "\n\n__________________________________________________________________________\n"
end

# function - cleaning up the work space
def gitCleanUp()
    puts "[INFO] Clean up git context"
    system("git clean -df")
    $result=`git ls-files --others --exclude-standard`
    if($result=="")
        puts "\n\n[INFO] No UnTracked files"
        return true
    else
        puts "\n\n[ERROR] gitCleanup Failed-Directory has Untracked files"
        return false
    end

end

# function - checking out the branch
def checkoutBranch(branch)
    puts "[INFO] checking out the branch :#{branch}"
    system("git fetch")
    system("git checkout #{branch}")
    $currentBranchName=`git rev-parse --abbrev-ref HEAD`
    system("git pull")
    system("git reset --hard #{branch}")

    if($currentBranchName.strip.eql?(branch.strip))
      puts "\n\n[INFO] The branch name #{branch} is sccessfully checkout "
      return true
     else
      puts "\n\n[ERROR] Got issue while checking out the branch:#{branch}"
      return false
    end
end

#function - creating new branch
def createBranch(newBranch)
    system("git checkout -b #{newBranch}")
    $newBranchName=`git rev-parse --abbrev-ref HEAD`
    if($newBranchName.strip.eql?(newBranch.strip))
      puts "\n\n[INFO] The branch name #{newBranch} has been sccessfully Created "
      return true
    else
      puts "\n\n[ERROR] Got issue while createing new branch:#{newBranch}"
      return false
    end
end

#function - validataing branch context
def validateGitContext(branch)
    # prove that it's validated, because this is how you test your function!
      $result=`git log master^..origin/master  --pretty=format:"'%h %d'"`
    if($result.include?("origin/master" && "master"))
        puts "\n\n[INFO] you are on the latest version of #{branch}"
        return true
    else
        puts "\n\n[ERROR] something went wrong you are not up to date on #{branch}"
        return false
    end
end

#function - merging the branch
def mergeBrach(from,to)
    # prove that it's validated, because this is how you test your function!
    system("git tag -a TAG_BEFORE_MERGE_FROM_#{from}_TO_#{to}_#{@date} -m before_merge_from_#{from}_to_#{to}")
    system("git merge  #{from} --no-commit --no-ff")
    system("git tag -a TAG_AFTER_MERGE_FROM_#{from}_TO_#{to}_#{@date} -m before_merge_from_#{from}_to_#{to}")
    ###### Condition to check merge conflict
   merge_status=`git diff --name-only --diff-filter=U`

   if(merge_status.strip != "")
       puts "\n\n[ERROR] merge conflict occured, Please do it through manual merge\n\n"
       return false
   else
       puts "\n\n[INFO] The branch has been merged successfully"
       return true
   end


    # need to validate confilict files
end

#function - validating the head of branch
def validateHeadofBranch(branch)
    puts "[INFO] validating head of master: #{branch}"
    $result=`git branch -a --contains origin/master | grep origin/$branch`
    if( $result.include? branch )
      puts "\n\n[INFO] validating head of master: #{branch}"
      return true
    else
      puts "\n\n[ERROR] something went wrong on validateHeadofBranch: #{branch}"
      return false
    end
end

#function - updating the pom version
def updatePomSnapshot()
  $pomversion=`grep -m 1 "<version>" pom.xml`

  #grabing the version from xml tag
  $pomVersionArray=$pomversion.sub!(/<version>/,"").sub!(/<\/version>/,"").strip.split /\./
  $newPomversion="#{$pomVersionArray[0]}.#{$pomVersionArray[1].to_i+1}.0"
  puts "[INFO] Updating to Release Version"
  #Changing pom version
  system("mvn -DnewVersion=#{$newPomversion} versions:set")
    #constructing xml tag with version Ex:<version>1.25.3-SNAPSHOT</version>
  $newPomXml="<version>#{$newPomversion}</version>"
  $validVersionFound=`grep -m 1 "#{$newPomXml}" pom.xml`

  if( $validVersionFound =="")
    puts "\n\n [ERROR] Pom snapshot is not updated properly"
    return false
  else
    puts "\n\n [INFO] Pom snapshot is updated properly"
    return true
  end
end

# function - excuting the maven profiles
def deployProfile
    system("mvn clean install")
    #system("mvn clean -P buildCore,deployCore")

    if ( $?.exitstatus > 0 )
      puts "\n\n[INFO] Maven profile succssfully deployed"
      return true
    else
      puts "\n\n[ERROR] Maven profile not deployed"
      return false
    end
end

def failfn(index)
  #puts "failed and Aborted"
  @Tasks[index][:status] = "Failed"
  displayStatus()
  exit
end

def successfn(index)
  @Tasks[index][:status] = "Success"
  @Tasks[index+1][:status]="Started and Running...."
  displayStatus()
end



## invoking the functio will start here
##
##############################################

displayStatus()

gitCleanUp() ? successfn(0):failfn(0)

# 1. Checking out the release branch
checkoutBranch(@releaseBranchName) ? successfn(1):failfn(1)

validateHeadofBranch(@releaseBranchName) ? successfn(2):failfn(2)

# 3.checking out the master branch to create a temp branch
checkoutBranch("master") ? successfn(3):failfn(3)

# 4.Creating temparory branch
# name should be data/time based , need to modify it later, for now i used dummy text
createBranch(@tempBranchName) ? successfn(4):failfn(4)

# 5.Merging relasebranch code to temporary branch
mergeBrach(@releaseBranchName,@tempBranchName) ? successfn(5):failfn(5)

#6.Updating pom version
updatePomSnapshot() ? successfn(6):failfn(6)

#7. Deploy some profile
deployProfile()? successfn(7):failfn(7)

displayStatus()
