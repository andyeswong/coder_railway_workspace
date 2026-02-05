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
}


resource "railway_variable" "codeserver_agent_token" {
  environment_id = "c7b6f1b3-bfcc-4e21-ab76-fe900a62d432"
  service_id     = railway_service.codeserver.id
  name           = "CODER_AGENT_TOKEN"
  value          = coder_agent.main.token
  
  depends_on = [railway_service.codeserver]
}

resource "railway_variable" "codeserver_derp_force" {
  environment_id = "c7b6f1b3-bfcc-4e21-ab76-fe900a62d432"
  service_id     = railway_service.codeserver.id
  name           = "CODER_DERP_FORCE_WEBSOCKETS"
  value          = "1"
  
  depends_on = [railway_variable.codeserver_agent_token]
}

resource "railway_variable" "codeserver_draining_seconds" {
  environment_id = "c7b6f1b3-bfcc-4e21-ab76-fe900a62d432"
  service_id     = railway_service.codeserver.id
  name           = "RAILWAY_DEPLOYMENT_DRAINING_SECONDS"
  value          = "30"
  
  depends_on = [railway_variable.codeserver_derp_force]
}

resource "railway_variable" "codeserver_init_script" {
  environment_id = "c7b6f1b3-bfcc-4e21-ab76-fe900a62d432"
  service_id     = railway_service.codeserver.id
  name           = "CODER_AGENT_INIT_SCRIPT"
  value          = coder_agent.main.init_script
  
  depends_on = [railway_variable.codeserver_draining_seconds]
}
