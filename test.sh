#!/bin/bash

TASK_NAME=$1
test_exist=0

if [ $# == 0 ]; then
	printf  "You shoud provide Task dir name -> ./submit TASK_dir_name\n"
	exit 1
fi

if [ ! -d $TASK_NAME ]; then
	printf "INVALID dir name\nMake sure task dirctory is exist\n"
	exit 1
fi

testing_task () {
	echo "in function test"
	cd $TASK_NAME
	sumbit=0
	if [ -f test.sh ]; then
		./test.sh 
		printf "\n"
		if ! [ $? == 0 ]; then
			echo "making submit false"
			sumbit=1
			printf "Error while running test file\n Do you want to submit? (y\n), default(n): "
			read ch
			if ! [ $ch == 'y' || $ch == 'Y' ]; then
				submit=0
			fi
		fi

	fi
	cd ..
	if [ $sumbit == 1 ]; then
		exit 1
	fi
}

pushing_task () {
	echo "in function publish"

	if ! [ $(git branch --show-current) == 'master' -o $(git symbolic-ref --short HEAD) == 'main' ]; then
		printf "Error: invalid branch, ensure you are in main or master branch"
		exit 1
	fi

	if [ -z $(git status -s | ln) ]; then
		git add . > /dev/null 2>&1
		git commit -m "commit changes" > /dev/null 2>&1
	fi

	git push > /dev/null 2>&1
	return 0
}

testing_task

pushing_task
