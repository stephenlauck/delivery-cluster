name "delivery_builders"
description "Delivery builder node role"
run_list "recipe[push-jobs]", "recipe[delivery_build]"
