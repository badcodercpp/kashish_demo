#!/bin/bash
ar=("test_1","test_2")
#SNAPSHOT=()
SNAPSHOT_BEFORE_FAILED=()
SNAPSHOT_AFTER_FAILED=()
#declare -A SNAPSHOT_BEFORE_FAILED
#declare -A SNAPSHOT_AFTER_FAILED
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
	fi
	echo "mapped release successful"
}

split_bad() {
    ret=()
    local string="$1"
    local delimiter="$2"
    if [ -n "$string" ]; then
        local part
        while read -d "$delimiter" part; do
            ret+="$part"
        done <<< "$string"
        #echo $part
	ret+="$part"
    fi
    echo $ret
}

take_snapshot(){
	local TARGET_DIR=$1
	local update_status=$2
	delta_counter=0;
	local scan_dir=$(find $TARGET_DIR/*)
	if [ $2 == 0 ]
	then
	echo "0 hi"
		if [ -d "$TARGET_DIR" ]
		then
			#SNAPSHOT_BEFORE_FAILED["dir"_$delta_counter]="$TARGET_DIR"
			#delta_counter=$((delta_counter+1))
			#cd $TARGET_DIR
			for T in $scan_dir
			do
				SNAPSHOT_BEFORE_FAILED[$delta_counter]="$T"
				echo $delta_counter
				echo $SNAPSHOT_BEFORE_FAILED[$delta_counter]
				: 'if [ -d "$T" ] 
				then
					SNAPSHOT_BEFORE_FAILED["dir"_$delta_counter]="$T"
				else
					SNAPSHOT_BEFORE_FAILED["file"_$delta_counter]="$T"
				fi '
				delta_counter=$((delta_counter+1))
			done
			#local lnk=$(find . -type l -ls | grep "\->")
			#unlink current_release
			local lnk=$(ls -lR $TARGET_DIR | grep ^l)
			#SNAPSHOT_BEFORE_FAILED["link"]="$lnk";
		fi
	else
		echo "1 hi"
		if [ -d "$TARGET_DIR" ]
		then
			#SNAPSHOT_AFTER_FAILED["dir"_$delta_counter]="$TARGET_DIR"
			#delta_counter=$((delta_counter+1))
			#cd $TARGET_DIR
			for T1 in $scan_dir
			do
				SNAPSHOT_AFTER_FAILED[$delta_counter]="$T1"
				echo $delta_counter
				echo $SNAPSHOT_AFTER_FAILED[$delta_counter]
				: 'if [ -d "$T1" ] 
				then
					SNAPSHOT_AFTER_FAILED["dir"_$delta_counter]="$T1"
					delta_counter=$((delta_counter+1))
				else
					SNAPSHOT_AFTER_FAILED["file"_$delta_counter]="$T1"
					delta_counter=$((delta_counter+1))
				fi '
				delta_counter=$((delta_counter+1))
			done
			#local lnk=$(find . -type l -ls | grep "\->")
			#unlink current_release
			local lnk=$(ls -lR $TARGET_DIR | grep ^l)
			#SNAPSHOT_AFTER_FAILED["link"]="$lnk";
		fi
	fi

	
}

take_snapshot_before_building(){
	: 'local TARGET_DIR=$1
	local delta_counter=0;
	if [ -d "$TARGET_DIR" ]
	then
		SNAPSHOT["dir"_$delta_counter]="$TARGET_DIR"
		delta_counter=$((delta_counter+1))
		cd $TARGET_DIR
		local scan_dir=$(find $TARGET_DIR)
		for T in $scan_dir
		do
			if [ -d "$T" ] 
			then
				SNAPSHOT["dir"_$delta_counter]="$T"
			else
				SNAPSHOT["file"_$delta_counter]="$T"
			fi
			delta_counter=$((delta_counter+1))
		done
		#local lnk=$(find . -type l -ls | grep "\->")
		#unlink current_release
		local lnk=$(ls -lR $TARGET_DIR | grep ^l)
		SNAPSHOT["link"]="$lnk";
		echo "ajay jha"
		m=$(split_bad "$lnk" "\->")
		echo $m
		echo $lnk
		for i in $(split_bad $lnk "->")
		do
			echo "ajay"
			echo $i
 			# process
		done
		for l in $lnk
		do
			SNAPSHOT["link"_$delta_counter]='$l'
			delta_counter=$((delta_counter+1))
			echo $l
		done 
	fi'
}

kashish(){
	#unset SNAPSHOT_BEFORE_FAILED
	#unset SNAPSHOT_AFTER_FAILED
	echo "taking folder and link snapshot"
	take_snapshot $PWD 0
	sleep 1
	echo "snapshot created"
	echo "now building the project"
	create_build 71 $PWD
	sleep 1
	echo "taking folder and link snapshot after build"
	take_snapshot $PWD 1
	sleep 1
	echo "output before build"
	echo ${#SNAPSHOT_BEFORE_FAILED[@]}
	for (( c=0; c<${#SNAPSHOT_BEFORE_FAILED[@]}; c++ ))
	do
    		echo ${SNAPSHOT_BEFORE_FAILED[$c]}
	done
	echo "output after build"
	for (( c1=0; c1<${#SNAPSHOT_AFTER_FAILED[@]}; c1++ ))
	do
    		echo ${SNAPSHOT_AFTER_FAILED[$c1]}
	done
}

kashish

#take_snapshot $PWD
#echo $SNAPSHOT

#create_build 71 $PWD
