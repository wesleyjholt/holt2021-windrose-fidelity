ndirs=$1

for i in {1..10}
do
    julia run_opt_9turb.sh ${ndirs} ${i}
    sleep 5
done