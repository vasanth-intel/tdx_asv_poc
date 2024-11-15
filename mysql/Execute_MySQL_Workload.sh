#! /bin/bash

iter=$4
SCRIPT_DIR=`pwd`
RESULTS_DIR="$SCRIPT_DIR/mysql_results"

if [ -d "$RESULTS_DIR" ]
then
	echo -e "\nDeleting results dir: " $RESULTS_DIR
	rm -rf $RESULTS_DIR
fi

echo -e "\nCreating results dir: " $RESULTS_DIR
mkdir -p $RESULTS_DIR

sleep 5

echo -e "\nDisabling INNODB REDO_LOG.."
disable_redo_log="mysql -P 3306 --protocol=tcp -u root -e \"ALTER INSTANCE DISABLE INNODB REDO_LOG;\""
echo $disable_redo_log
eval $disable_redo_log 2>&1

sleep 10

echo -e "\nCreating Test Database.."
create_test_db="sudo mysqladmin -h 127.0.0.1 -P 3306 create test_db"
echo $create_test_db
eval $create_test_db 2>&1

sleep 10

cmd1="sysbench --db-driver=mysql --mysql-host=127.0.0.1 --mysql-port=3306 --mysql-user=root --mysql-db=test_db /usr/share/sysbench/oltp_common.lua --tables=8 --table_size=100000 prepare"
cmd3="sysbench --db-driver=mysql --mysql-host=127.0.0.1 --mysql-port=3306 --mysql-user=root --mysql-db=test_db /usr/share/sysbench/oltp_common.lua --tables=8 --table_size=100000 cleanup"

#threads=(1 8 16 32 64)
threads=$3
#operations=("read_only" "write_only" "read_write")
operations=$2
for opn in ${operations[@]}
do
	for i in ${threads[@]}
	do
		TEST_DIR_NAME=$1
		mkdir -p $RESULTS_DIR/$TEST_DIR_NAME
		echo $cmd1
		eval $cmd1 2>&1
		sleep 20

		for ((j=1; j<=$iter; j++))
		do
			case $opn in
				"read_only")
					cmd2="sysbench --db-driver=mysql --mysql-host=127.0.0.1 --mysql-port=3306 --mysql-user=root --mysql-db=test_db --threads=$i --time=90 --report-interval=5 oltp_read_only --tables=8 --table_size=100000 run"
					;;
				"write_only")
					cmd2="sysbench --db-driver=mysql --mysql-host=127.0.0.1 --mysql-port=3306 --mysql-user=root --mysql-db=test_db --threads=$i --time=90 --report-interval=5 oltp_write_only --tables=8 --table_size=100000 run"
					;;
				"read_write")
					cmd2="sysbench --db-driver=mysql --mysql-host=127.0.0.1 --mysql-port=3306 --mysql-user=root --mysql-db=test_db --threads=$i --time=90 --report-interval=5 oltp_read_write --tables=8 --table_size=100000 run"
					;;
			esac
			echo $cmd2
			eval $cmd2 2>&1 | tee -a $RESULTS_DIR/$TEST_DIR_NAME/${TEST_DIR_NAME}_native_${j}.log
			sleep 20
		done

		echo $cmd3
		eval $cmd3 2>&1
		sleep 20
	done
done

echo -e "\nDropping Test Database.."
drop_test_db="sudo mysqladmin -h 127.0.0.1 -P 3306 drop -f test_db"
echo $drop_test_db
eval $drop_test_db 2>&1

sleep 10

echo -e "\nRe-enabling INNODB REDO_LOG.."
enable_redo_log="mysql -P 3306 --protocol=tcp -u root -e \"ALTER INSTANCE ENABLE INNODB REDO_LOG;\""
echo $enable_redo_log
eval $enable_redo_log 2>&1
