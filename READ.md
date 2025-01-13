
# Flavor tool 스크립트 
출력 예시
root@controller1:~/tools.d/openstack.d# ./flavor_tools.sh -c --vcpu 8 --mem 16 --disk 20 -p ~/adminrc
250113 14:53:34.578 | CMD     | openstack flavor create --vcpus 8 --ram 16384 --disk 20 --public -f json -c name -c id -c vcpus -c ram -c disk 8c16g20g >.flavor_out.json
250113 14:53:36.473 | OK      | command ok.
250113 14:53:36.545 | INFO    | NAME: 8c16g20g | UUID: d3fb53e8-07d4-4ca6-ac16-32f10bd7f9e4
