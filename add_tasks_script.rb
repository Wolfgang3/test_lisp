token = '0/af8d04325c718270be55efe98be24869'
workspaceid = '113202625720682'
projectid = '113203241574212'
assigneeid= '113202598650509'
sectionid='114095552966171'


tasks = ['task 1','task 2','task 3'];
  
#use this line if you want your tasks to be displayed in Asana in the order of the array
#$tasks = array_reverse($tasks); 
  

tasks.each do |task|
  task=task+" "+Time.now.strftime("%d/%m/%Y %I:%M %p")
  system( 'curl -H "Authorization: Bearer '+token+'" https://app.asana.com/api/1.0/tasks -d "name='+task+'" -d "projects[0]='+projectid+'" -d "workspace='+workspaceid+'" -d "assignee='+assigneeid+'"')
  #puts "curl -H \"Authorization: Bearer #{token}\" https://app.asana.com/api/1.0/tasks -d \"name=#{task}\" -d \"projects[0]=#{projectid}\" -d \"workspace=#{workspaceid}\" -d \"assignee=#{assigneeid}\""
end



