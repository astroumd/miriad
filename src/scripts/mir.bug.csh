#! /bin/csh -f
#
#
#* mir.bug.csh - Send mail about bugs to appropriate person
#& bpw
#: user utility
#+
#Usage: mir.bug.csh [selection] [taskname or 'general'] [file]
#
#Mirbug allows the user to send bugreports to the appropriate persons.
#
#[selection] should be one of "bug" or "feedback". This influences
#the information prepended to a report file. "mirbug" is an alias
#for "mir.bug.csh bug"; " mirfeedback" is an alias for "mir.bug.csh
#feedback"
#
#[taskname] should be one of the miriad tasks/tools/scripts or the
#string 'general'. The taskname can be the name of any file on the
#MIRPDOC directory with "doc" in the extension. This parameter is used
#to find out who is responsible for the code and then the report is
#mailed to that person. If this argument is not given the report is
#sent to some miriad central addresses.
#
#[file] (optional) is the name of a previously created file containing
#the report. This must be the third argument.
#
#mir.bug.csh creates a template report or prepends it to the optional
#file and then starts an editor. The default editor is vi on unix and
#edt on VMS. However, by including 'setenv EDITOR mem' in your .cshrc
#file (unix) or 'editor:==mem' in the login.com file (VMS) it is
#possible to specify which editor to use.
#
#After exiting the editor the user is given the option of not mailing
#the report by using ^C. If this is not done within 5 seconds, the
#report is mailed to the person responsible, to a central address and
#to the sender. If ^C is used, the report is saved.
#--
#
#* mirbug - Send mail about bugs to appropriate person
#& bpw
#: user utility
#+
#Usage: mirbug [taskname or 'general'] [file]
#
#Mirbug allows the user to send bugreports to the appropriate persons.
#
#[taskname] should be one of the miriad tasks/tools/scripts or the
#string 'general'. This parameter is used to find out who is responsible
#for the code and then the report is mailed to that person. If this
#argument is not given the report is sent to some miriad central
#addresses.
#
#[file] (optional) is the name of a previously created file containing
#the report. This must be the second argument.
#
#mirbug creates a template report or prepends it to the optional file
#and then starts an editor. The default editor is vi on unix and edt on
#VMS. However, by including 'setenv EDITOR mem' in your .cshrc file
#(unix) or 'editor:==mem' in the login.com file (VMS) it is possible to
#specify which editor to use.
#
#After exiting the editor the user is given the option of not mailing
#the report by using ^C. If this is not done within 5 seconds, the
#report is mailed to the person responsible, to a central address and
#to the sender. If ^C is used, the report is saved.
#
#``mirbug'' is an alias for ``mir.bug.csh bug''.
#--
#
#
#* mirfeedback - Send feedback to the appropriate person
#& bpw
#: user utility
#+
#Usage: mirfeedback [taskname] [file]
#
#This is a way to send feedback to a programmer. For a description
#of how it works, see "mirbug". The difference between these two is
#in the prepended information.
#
#``mirfeedback'' is an alias for ``mir.bug.csh feedback''.
#-- 


#----- Initializations
set mirprg     = $MIRCAT/miriad.pgmrs
set ncentral   = 3
set nself      = 4
set nperson    = 5
set central    = ( "" "" "" );          set site_id    = ( "" "" "" )
set central[1] = "miriad@sirius.astro"; set site_id[1] = "uiuc.edu"
set central[2] = "mirth@astro";         set site_id[2] = "umd.edu"
set central[3] = "mirth@bkyast";        set site_id[3] = "berkeley.edu"
set self       = `whoami`
set address    = ( "" "" "" "" "" )
set address[1] = "$central[1].$site_id[1]"

#----- Transform input parameters
set bug      = "$1"; if ( "$1" == "" ) set bug = "bug"
set task     = "$2"
set usefile  = "$3"
set templ    = mir$bug.$task
set template = /tmp/$templ

#----- Checks
if ( ! -w /tmp ) then
   echo "### Fatal Error: Can't write to /tmp"; exit 1
endif
set exist=n; set general=n;
if (      "$task" == ""        ) then
   echo "### Fatal Error: You must specify a taskname or 'general'"
   echo "###       Usage: mirbug [taskname or 'general'] [file]"
   echo "###       Use 'setenv EDITOR 'editor'' to get preferred editor"
   exit 1
else if ( "$task" == "general" ) then
   set general=y;
else if ( -f $MIRPDOC/${task}.doc || -f $MIRPDOC/${task}.cdoc ) then
   set exist=y
else
   echo "### Fatal Error: No task or script with the name $task exists"; exit 1
endif

#----- Obtain initials of person responsible
if ( $exist == y ) then
   set person = `doc -r $task`
   if ( "$person" == "" ) then
    echo "### Warning: Insufficient information to determine who is responsible"
      set person = "CENTRAL"
   endif
else if ( $general == y ) then
   set person = "CENTRAL"
endif

#----- Figure out where to send mail to
if ( "$person" != "CENTRAL" ) then

   grep -i ^$person $mirprg > /dev/null
   if ( $status == 0 ) then
      set string = "`grep -i "$person" $mirprg`"
      set name   = `echo $string | awk '{print $2 $3}'`
      set addr   = `echo $string | awk '{print $4}'`
      set phone  = `echo $string | awk '{print $5}'`
      if ( "`echo $addr | grep @`" != "" ) then
         set k = 1
         while( $k <= $ncentral )
            echo $addr | grep -i $site_id[$k] > /dev/null
            if ( $status == 0 ) set address[$k] = "$central[$k].$site_id[$k]"
            @ k =$k + 1
         end
         set address[$nself]   = $self
         set address[$nperson] = $addr
      else
         set addr = "unknown"
         set person = "CENTRAL"
      endif
   else
      echo "### Warning: No person matching $person is found in the list"
      set person = "CENTRAL"
      set name   = "unknown"
      set addr   = "unknown"
      set phone  = "unknown"
   endif
endif

#----- Send mail to all central addresses
if ( "$person" == "CENTRAL" ) then
   echo "### Warning: Mail will be sent to all central addresses"
   set k = 1
   while( $k <= $ncentral )
      set address[$k] = "$central[$k].$site_id[$k]"; @ k =$k + 1
   end
   set address[$nself]   = $self
   set address[$nperson] = ""
endif

#----- Construct template
onintr quit
if ( $general == y ) then

   echo "General $bug report"                                      >! $template
   echo "Date:               `date +%D`; time written: `date +%T`" >> $template
   set first = y
   foreach addr ( $address )
      if ( "$addr" != "unknown" && "$addr" != "" ) \
      if ( $first == y ) echo "Message sent to:    $addr"           >> $template
      if ( $first == n ) echo "                    $addr"           >> $template
      set first = n
   end
   echo " "                                                        >> $template
   echo "--------------------------------------------------------" >> $template
   echo " "                                                        >> $template

else

   if (      $bug == bug      ) then
      echo "Bug report on task: $task"                             >! $template
   else if ( $bug == feedback ) then
      echo "Feedback on task: $task"                               >! $template
   endif
   echo "Person responsible: $name"                                >> $template
   echo "    e-mail address: $addr"                                >> $template
   echo "             phone: $phone"                               >> $template
   echo " "                                                        >> $template
   echo "Date:               `date +%D`; time written: `date +%T`" >> $template
   if ( "$person" == "CENTRAL" ) \
   echo "THIS MESSAGE WAS ONLY SENT TO THE CENTRAL ADDRESSES"      >> $template
   set first = y
   foreach addr ( $address )
      if ( "$addr" != "unknown" && "$addr" != "" ) \
      if ( $first == y ) echo "Message sent to:    $addr"           >> $template
      if ( $first == n ) echo "                    $addr"           >> $template
      set first = n
   end
   echo " "                                                        >> $template
   echo "--------------------------------------------------------" >> $template
   echo " "                                                        >> $template
   if ( $bug == bug ) then
      echo "Version and date of task:"                             >> $template
      echo " "                                                     >> $template
      echo "Datafile on which task was used:"                      >> $template
      echo " "                                                     >> $template
      echo "Keywords:"                                             >> $template
      if ( "$task" != "general " ) then
         set keys = `grep -i "%A" $MIRPDOC/$task.doc | awk '{print $2}'`
         foreach key ( $keys )
            echo "   ${key}="                                      >> $template
         end
      endif
      echo " "                                                     >> $template
      if (      $bug == bug ) then
         echo "Description:"                                       >> $template
         echo " "                                                  >> $template
      else if ( $bug == feedback ) then
         echo "Suggestion for improvement:"                        >> $template
         echo " "                                                  >> $template
      endif
   endif

endif

if ( "$usefile" != "" ) then
   cat $usefile                                                    >> $template
endif

#----- Edit template
if ( $?EDITOR ) then
   $EDITOR $template
else
   vi $template
endif

#----- Send mail
onintr save
echo "OK to send? Hit CTRL-C within 5 seconds if not"
sleep 5
foreach addr ( $address )
   if ( "$addr" != "unknown" && "$addr" != "" ) then
      echo "mail $addr"
      if ( $MIRHOST == "sun3"       || \
           $MIRHOST == "sun4sol"    || \
	   $MIRHOST == "sun4" ) then
         mail -s "$bug $task" $addr < $template
      else
         mail $addr < $template
      endif
   endif
end


#----- Normal quit or quit before finishing editing
quit:
rm -f $template
exit 0


#----- Quit by hitting ^C after editing
save:
echo " "
if ( -w `pwd` ) then
   echo "Report saved as $templ"
   mv $template `pwd`/$templ
else
   echo "No write permission on current directory"
   echo "Report saved as $templ on your home directory"
   mv $template $HOME/$templ
endif
exit 0
