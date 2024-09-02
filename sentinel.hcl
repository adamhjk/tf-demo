sentinel {
    features = {
        terraform = true
    }
}

import "plugin" "tfplan/v2" {
    config = {
        plan_path = "./plan.json"
    }
}

policy "vpcs" {
    source = "./policy.sentinel"
    enforcement_level = "hard-mandatory"
}