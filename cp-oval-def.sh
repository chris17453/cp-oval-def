#!/bin/bash 
#  ██████╗██████╗        ██████╗ ██╗   ██╗ █████╗ ██╗      ██████╗ ███████╗███████╗
# ██╔════╝██╔══██╗      ██╔═══██╗██║   ██║██╔══██╗██║      ██╔══██╗██╔════╝██╔════╝
# ██║     ██████╔╝█████╗██║   ██║██║   ██║███████║██║█████╗██║  ██║█████╗  █████╗  
# ██║     ██╔═══╝ ╚════╝██║   ██║╚██╗ ██╔╝██╔══██║██║╚════╝██║  ██║██╔══╝  ██╔══╝  
# ╚██████╗██║           ╚██████╔╝ ╚████╔╝ ██║  ██║███████╗ ██████╔╝███████╗██║     
#  ╚═════╝╚═╝            ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  
# Copy an SCAP OVAL Definition from one xml file to another
# author: Charles Watkins
# date  : 2018-08-23
#
#***********************************************************************
# Variables
# debug    = auto fill in variables for testing: true or nothing
# id       = OVAL definition to copy
# source   = file to copy from
# dest     = file to copy definition to
#***********************************************************************
id="$1"
source="$2"
dest="$3"

#***********************************************************************
# Format and display a message in the console  
# param1 = info/warn/msg
# param2 = message to display
# out    = formatted message or nothing
#***********************************************************************
msg(){ 
	msg=$2
  if [[ "msg" = "$1" ]]; then 
   echo -en '\033[00;32m' "[Msg ]"  '\033[0m' "$msg" "\n"
  fi
  if [[ "info" = "$1" ]]; then 
   echo -en '\033[00;36m' "[Info]"  '\033[0m' "$msg" "\n"
  fi
  if [[ "warn" = "$1" ]]; then 
   echo -en '\033[01;31m' "[Warn]"   '\033[00;31m' " $msg" "\n" 
   #'\033[0m'
  fi
  tput sgr0
}

#***********************************************************************
# Get an ID from an xml/html attribute ending matching param1 pattern
# param1 = attribute pattern _ref/_test/_state
# param2 = xml snipit to search
# out    = id from search
#***********************************************************************
get_ref() {
	ref="$1"
    echo "$2" |  sed -n 's/.*'"${ref}"'="\([^"]*\).*/\1/p' 
}

#***********************************************************************
# Get xml or html tag from formatted text
# param1 = xml or html snipit to parse
# out    = xml tag with optional namespace
#***********************************************************************
get_obj() {
	echo "$1" |  sed -n 's/.*<\([^[:space:]]*\).*/\1/p'
}

#***********************************************************************
# Get BASE xml tag (NO NAMESPACE)
# param1 = xml or html snipit to parse
# out    = xml tag with no namespace
#***********************************************************************
strip_namespace(){
	tag="$1"
	echo "$tag" | sed 's/^.*[:]//g'
}

#***********************************************************************
# Get the type of xml tag.. EX: file_state =state or nfs_test=test
# param1 = xml or html snipit to parse
# out    = xml tag base 
#***********************************************************************
get_obj_base() {
	echo "$1" |  sed -n 's/.*_\([^[:space:]]*\).*/\1/p'
}

#***********************************************************************
# Get thing of the i forget.. oh well.
# param1 = 
# out    = 
#***********************************************************************
get_object_type(){
	obj_tag="$(strip_namespace $1)"
	obj_base="$2"
	
	if [[ -z "$obj_base" ]]; then 
		expr1="${obj_tag}s" 
	else
		expr1="${obj_base}s" 
	fi 	
	echo "$expr1";
}

#***********************************************************************
# Get an xml object from a file based by attribute and/or value
# param1 = attribute name or pattern
# param2 = the file to extract the object from
# param3 = the optional xml tag
# out    = xml object including tags
#***********************************************************************
get_type() {
	id="$1"
	file="$2"
	type=""
	if [[ -z "$3" ]]; then  
	    expr1='[\\n]'	
		def="$(sed -n '/id="'${id}'"/,/'"${expr1}"'/p' "${file}")"
	    obj_tag="$(get_obj $def)"
	    obj_base="$(get_obj_base $obj_tag)"
	    if [[ -z "$obj_base" ]]; then 
			expr1="${obj_tag}>" 
		else
			expr1="${obj_base}>" 
		fi 
	else 
		type="$3"; 
		expr1='<\/'"${type}"'>'	
	fi
	sed -n '/id="'${id}'"/,/'"${expr1}"'/p' "${file}"
}

#***********************************************************************
# Determine if an xml ovject exists in a file
# param1 = attribute value
# param2 = the xml object type/tag
# param3 = the file to check 
# out    = true or false
#***********************************************************************
check_if_object_exists(){
 id="$1"
 file="$2"
 #res=$(grep "$id" "$file")
 res="$(get_type $id $file)"
 if [[ ! -z "$res" ]]; then
	echo "true";
 return;
 fi
 echo "false"
}

#***********************************************************************
# Insert an xml object into an file based on it's tag
# param1 = xml tag to match
# param2 = text to insert
# param3 = the file to insert into
# out    = nothing
#***********************************************************************
insert_obejct(){
     tag="$1"
    text="$2"
    file="$3"
    tmp_file="/tmp/xml.txt"
    echo "$text">"$tmp_file"
   regex='/<((!?oval_).)*'"$tag"'>/r'
   sed -i -r "${regex} $tmp_file" "$file" 
}

#***********************************************************************
# recursivly move a XML object and all sub objects from one file to another
# param1 = xml or html snipit to parse
# out    = xml tag with no namespace
#***********************************************************************
copy_definition(){
  echo $(msg "info" "Fetching \033[01;31m $1")
        id="$1"
	source="$2"
	  dest="$3"
	  mode="$4"
	  depth="$5"
       def="$(get_type $id $source)"
       if [[ -z  "$def" ]]; then 
			echo $(msg "warn" "Not found")
			return;
       fi
       
   obj_tag="$(get_obj $def)"
  obj_base="$(get_obj_base $obj_tag)"
  obj_type="$(get_object_type  $obj_tag $obj_base)"
  #echo "$obj_type"
  insert=$(insert_obejct "$obj_type" "$def" "$dest")
  
  all_ref="$(get_ref ref "$def")"
  if [[ -z "$depth" ]]; then 
   depth=0; 
  fi
  ((depth++))
  
  if [[  -z "$all_ref" ]]; then
	echo $(msg "warn" "No sub elements Found");
	return;
  fi
	
  for tr in $all_ref
    do
      obj="$(copy_definition $tr $source $dest $mode "$depth")"	
      if [[ ! -z "$obj" ]];
      then
		echo "$obj"
      fi 
    done
}

yes_no(){
   msg="$1"
   while true; do
       read -p "$msg" yn
       case $yn in
           [Yy]* ) echo "true"; return 0;;
           [Nn]* ) echo "false"; return 1;;
           * ) echo "Please answer yes or no.";;
       esac
   done
}

#***********************************************************************
# END OF FUNCTIONS
#***********************************************************************






#***********************************************************************
# Init do the thing
#***********************************************************************
debug=""

# for debugging
if [[ "$debug" = "true" ]]; then 
    msg "info" "**********************************************************************************"
	msg "msg" "Debug mode"
   id=oval:ssg-accounts_logon_fail_delay:def:1
   source=/home/nd/repos2/rhel7.xml
   dest=/home/nd/repos2/test.xml
fi 


msg "info" "**********************************************************************************"
msg "info" "  ██████╗██████╗        ██████╗ ██╗   ██╗ █████╗ ██╗      ██████╗ ███████╗███████╗"
msg "info" " ██╔════╝██╔══██╗      ██╔═══██╗██║   ██║██╔══██╗██║      ██╔══██╗██╔════╝██╔════╝"
msg "info" " ██║     ██████╔╝█████╗██║   ██║██║   ██║███████║██║█████╗██║  ██║█████╗  █████╗  "
msg "info" " ██║     ██╔═══╝ ╚════╝██║   ██║╚██╗ ██╔╝██╔══██║██║╚════╝██║  ██║██╔══╝  ██╔══╝  "
msg "info" " ╚██████╗██║           ╚██████╔╝ ╚████╔╝ ██║  ██║███████╗ ██████╔╝███████╗██║     "
msg "info" "  ╚═════╝╚═╝            ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝╚═╝     "
msg "info" "**********************************************************************************"
msg "info" "ID    : \033[01;31m $id'"
msg "info" "Source: \033[01;31m $source'"
msg "info" "Dest  : \033[01;31m $dest'"
msg "info" "**********************************************************************************"

msg "msg" "Begin moving OVAL Definition"

# Does it exist in the destination?
alerady_exists="$(check_if_object_exists $id $dest)"
if [[ "true" = "$alerady_exists" ]]; then
   msg "warn" "'$id' Already exists in destination"
else
   copy_definition "$id" "$source" "$dest"
fi

msg "msg" "End"
msg "info" "**********************************************************************************"




