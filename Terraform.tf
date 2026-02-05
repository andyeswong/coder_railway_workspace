terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    railway = {
      source  = "registry.terraform.io/terraform-community-providers/railway"
      version = "~> 0.6"
    }
  }
}

provider "railway" {
  token = "4d648626-88b2-43e1-909d-7da6bea41510"
}

provider "coder" {}

data "coder_provisioner" "me" {}
data "coder_workspace" "me"  {}
data "coder_workspace_owner" "me" {}


resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }
}

resource "railway_service" "codeserver" {
  name         = "coder-${lower(data.coder_workspace.me.name)}-${lower(data.coder_workspace_owner.me.name)}"
  project_id   = "64211a28-8a9b-4f5b-a740-deabe67017e1"
  source_image = "andyeswong/coder-workspace:stable"
  env_vars = {
    "CODER_AGENT_INIT_SCRIPT" = coder_agent.main.init_script
  }
}

