#!/bin/bash
#author: Bruno Garbaccio. bruno.garbaccio@oracle.com

# for Optimized3.36
device=mlx5_2
# for HPC2.36
#device=mlx5_0

hosts=""
for i in `cat /etc/hosts | grep .local.vcn | awk '{print $1}'`; do hosts=$hosts:$i ;done
hosts=${hosts#?};
hosts=`tr ':' ' ' <<<"$hosts"`
hosts=($hosts)

#ibdev2netdev 
for (( i=0; i<${#hosts[@]}; i++ ));
do
    ibdev2netdev=(`ssh ${hosts[$i]} "/usr/sbin/ibdev2netdev" > /tmp/ibdev2netdev`)
    hostname=(`ssh ${hosts[$i]} hostname`)
    echo "ibdev2netdev ${hostname} ${hosts[$i]} "
    cat /tmp/ibdev2netdev
    rm /tmp/ibdev2netdev
done


#latency 
for (( i=0; i<${#hosts[@]}; i++ ));
do
    for (( j=$i; j<${#hosts[@]}; j++ ));
    do
        latency=""
        ssh ${hosts[$i]} 'pkill ib_send_lat'
        ssh -f ${hosts[$i]} "ib_send_lat -F -d $device  > /dev/null 2>&1" 
        latency=(`ssh ${hosts[$j]} "ib_send_lat -F -d $device ${hosts[$i]} | tail -n 2 | head -n -1 "`)
        echo "latency ${hosts[$i]} - ${hosts[$j]} : ${latency[5]} µs"
        ssh ${hosts[$i]} 'pkill ib_send_lat'
    done
done

#bandwidth 
for (( i=0; i<${#hosts[@]}; i++ ));
do
    for (( j=$i; j<${#hosts[@]}; j++ ));
    do
        bw=""
        ssh ${hosts[$i]} 'pkill ib_write_bw'
        ssh -f ${hosts[$i]} "ib_write_bw -s 8388608 -F -d $device --perform_warm_up > /dev/null 2>&1 " 
        bw=(`ssh ${hosts[$j]} "ib_write_bw -F -s 8388608 -d $device ${hosts[$i]} --report_gbits --perform_warm_up | tail -n 2 | head -n -1 "`)
        echo "bandwidth ${hosts[$i]} - ${hosts[$j]} : ${bw[3]} Gbps"
        ssh ${hosts[$i]} 'pkill ib_write_bw'
    done
done



