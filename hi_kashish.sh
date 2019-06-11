#!/bin/bash
SNAPSHOT_BEFORE_FAILED=()
SNAPSHOT_AFTER_FAILED=()
#$version=$env.get('version_no')

# next function will be deleted , actual build function will be used here
create_build(){
	local version1=$1
	local CURRENT_DIR=$2
	cd $CURRENT_DIR
	mkdir -p cos/releases/domain_Cos$version1/release_"$version1".0.0_dummy
	ls -la cos/releases/domain_Cos$version1 | grep "current_release"
	if (( $? == 0 )) ;then
		echo "Link:current_release already exist"
	else
		echo "No link, creating a new one for current_release"
		cd cos/releases/domain_Cos$version1
		ln -s release_"$version1".0.0_dummy current_release
	fi
	echo "build release successfull"
	cd $CURRENT_DIR
	mkdir -p cos/config
	ls -la cos/config/ | grep "Cos${version1}"
	if (( $? == 0 ))
	then
		echo "Link:Cos${version1} already exist"
	else
		cd cos/config
		ln -s ../releases/domain_Cos${version1}/current_release Cos${version1}
		cd ..
		cd ..
	fi
	echo "mapped release successful"
	return 1
}

take_snapshot(){
	local TARGET_DIR=$1
	local update_status=$2
	local delta_counter=0;
	local scan_dir=$(find $TARGET_DIR)
	if [ $2 == 0 ]
	then
		if [ -d "$TARGET_DIR" ]
		then
			for T in $scan_dir
			do
				SNAPSHOT_BEFORE_FAILED[$delta_counter]="$T"
				delta_counter=$((delta_counter+1))
			done
		fi
	else
		if [ -d "$TARGET_DIR" ]
		then
			for T1 in $scan_dir
			do
				SNAPSHOT_AFTER_FAILED[$delta_counter]="$T1"
				delta_counter=$((delta_counter+1))
			done
		fi
	fi
}


array_diff(){
  awk 'BEGIN{RS=ORS=" "}
       {NR==FNR?a[$0]++:a[$0]--}
       END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
}

array_d(){
	Array3=()
	for i in "${$1[@]}"; do
		skip=
		for j in "${$2[@]}"; do
			[[ $i == $j ]] && { skip=1; break; }
		done
		[[ -n $skip ]] || Array3+=("$i")
	done
}

create_symlink(){
	local status=1
	# $1 this will be the path to go
	local PATH_TO_GO=$1
	# $ this will be the path to comaback
	local PATH_TO_COMEBACK=$2
	# $3 this will be your symlink path
	local SYMLINK_1=$3
	local SYMLINK_2=$4
	local dirTest=$5
	if [ -d "$dirTest" ] ; then
		echo "$dirTest" already exists skipping folder creation
	else
		echo "$dirTest" creating
		mkdir -p $dirTest
	fi
	# navigate
	cd "$PATH_TO_GO"
	# will create
	ln -s ${SYMLINK_1} ${SYMLINK_2}
	if [ $?===0 ] ; then
		status=0
	else
		status=1
	fi
	cd "$PATH_TO_COMEBACK"
	return $status
}

modify_symlinks(){
	echo "modifying symlink"
	local links=$(find . -type l -ls)
	local del_links=$(find . -type l -ls -exec rm {} \;)
	if [ $?==0 ]
	then
		echo "Link deleted successfully"
		echo "deleted symlynks are following -"
		echo "$links"
	fi
}

restore_state(){
	echo "restoring state"
	bad_working_tree=($(array_diff SNAPSHOT_AFTER_FAILED[@] SNAPSHOT_BEFORE_FAILED[@]))
	for REF_DEL in ${bad_working_tree[@]} 
	do
		if [ -d "$REF_DEL" ] && [ -e "$REF_DEL" ]
		then
			rm -rf $REF_DEL
		elif [ -f "$REF_DEL" ] && [ -e "$REF_DEL" ]
		then
			rm -f $REF_DEL
		elif [ -e "$REF_DEL" ]
		then
			echo "new files will be created: $REF_DEL"
		else
			echo "...."
		fi
	done
	echo "state restored"
}


kashish(){
	local TARGET_VER=$1
	unset SNAPSHOT_BEFORE_FAILED
	unset SNAPSHOT_AFTER_FAILED
	echo "taking folder and link snapshot"
	take_snapshot $PWD 0
	sleep 1
	echo "snapshot created"
	echo "now building the project"
	create_build $TARGET_VER $PWD
	local res=$?
	if [ $res -ne 0 ] 
	then
		echo "taking folder and link snapshot after build"
		take_snapshot $PWD 1
		sleep 1
		echo "output before build"
		for (( c=0; c<${#SNAPSHOT_BEFORE_FAILED[@]}; c++ ))
		do
	    		echo ${SNAPSHOT_BEFORE_FAILED[$c]}
		done
		echo "output after build"
		for (( c1=0; c1<${#SNAPSHOT_AFTER_FAILED[@]}; c1++ ))
		do
	    		echo ${SNAPSHOT_AFTER_FAILED[$c1]}
		done
		echo "modifying state"
		modify_symlinks
		sleep 1
		echo "applying backup of last successfull working state"
		restore_state
		sleep 1
		echo "now restoring symlink"
		local tempPwd=$PWD
		local tempReleaseD=cos/releases/domain_Cos${TARGET_VER}
		local tempLink=release_"$TARGET_VER".0.0_dummy
		local temp_release=current_release
		local tempDirTest=cos/releases/domain_Cos$TARGET_VER/release_"$TARGET_VER".0.0_dummy
		# ln -s release_"$version1".0.0_dummy current_release
		local tempConfigD="cos/config"
		# ln -s ../releases/domain_Cos${version1}/current_release Cos${TARGET_VER}
		#echo $tempLink
		create_symlink $tempReleaseD $PWD $tempLink $temp_release $tempDirTest
		#cd cos/releases/domain_Cos${TARGET_VER}
		#ln -s release_"$TARGET_VER".0.0_dummy current_release 
		#ln -s release_"$TARGET_VER".0.0_dummy current_release 
	else
		echo "create_build did not throw any error !! no need to restore anything"
	fi
	
}

kashish 71

#take_snapshot $PWD
#echo $SNAPSHOT

#create_build 71 $PWD
