#!/bin/bash
SNAPSHOT_BEFORE_FAILED=()
SNAPSHOT_AFTER_FAILED=()

# next line to be deleted
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
	return 0
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


restore_state(){
	
	: 'for (( i=0; i<${#SNAPSHOT_AFTER_FAILED[@]}; i++ ))
	do
		for (( j=0; j<${#SNAPSHOT_BEFORE_FAILED[@]}; j++ )) 
		do
			if [ $SNAPSHOT_AFTER_FAILED[$i] == $SNAPSHOT_BEFORE_FAILED[$j] ] 
			then
				echo "comes to delete"
				echo ${SNAPSHOT_AFTER_FAILED[$i]}
			fi
		done
	done '
	echo "difference"
	#echo ${SNAPSHOT_AFTER_FAILED[@]} ${SNAPSHOT_BEFORE_FAILED[@]} | tr ' ' '\n' | uniq -u
	bad_working_tree=($(array_diff SNAPSHOT_AFTER_FAILED[@] SNAPSHOT_BEFORE_FAILED[@]))
	for REF_DEL in ${bad_working_tree[@]} 
	do
		if [ -d "$REF_DEL" ] 
		then
			rm -rf $REF_DEL
		elif [ -f "$REF_DEL" ]
		then
			rm -f $REF_DEL
		fi
	done
}


kashish(){
	unset SNAPSHOT_BEFORE_FAILED
	unset SNAPSHOT_AFTER_FAILED
	echo "taking folder and link snapshot"
	take_snapshot $PWD 0
	sleep 1
	echo "snapshot created"
	echo "now building the project"
	create_build 71 $PWD
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
		echo "restoring state"
		restore_state
	else
		echo "create_build did throw any error !! no need to restore anything"
	fi
	
}

kashish

#take_snapshot $PWD
#echo $SNAPSHOT

#create_build 71 $PWD
