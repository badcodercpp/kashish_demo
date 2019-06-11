Array1=( "key1" "key2" "key3" "key4" "key5" "key6" "key7" "key8" "key9" "key10" )
Array2=( "key1" "key2" "key3" "key4" "key5" "key6" )

Array3=()
for i in "${Array1[@]}"; do
    skip=
    for j in "${Array2[@]}"; do
        [[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || Array3+=("$i")
done
#for t in ${}
#echo ${Array3[@]}
#declare -p Array3

array_difference(){
    local one=("${!1}")
    local two=("${!2}")
    echo "one"
    echo ${one[@]}
    echo "two"
    echo $two
    diff=()
    for i in "${one[@]}"; do
        skip=
        for j in "${two[@]}"; do
            [[ $i == $j ]] && { skip=1; break; }
        done
        [[ -n $skip ]] || diff+=("$i")
    done
    echo ${diff[@]}
}

bad_working_tree=($(array_difference "Array1[@]" "Array2[@]"))
echo "hello"
echo ${bad_working_tree[@]}
echo "test"