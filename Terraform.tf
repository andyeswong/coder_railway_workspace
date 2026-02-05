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
  source_repo = "andyeswong/coder_railway_workspace"
  source_repo_branch = "main"
}

resource "railway_variable_collection" "codeserver_agent_token" {
  environment_id = "c7b6f1b3-bfcc-4e21-ab76-fe900a62d432"
  service_id     = railway_service.codeserver.id
  variables = [
    {
      name  = "CODER_AGENT_TOKEN"
      value = coder_agent.main.token
    },
    {
      name  = "CODER_INIT_SCRIPT"
      value = coder_agent.main.init_script
    }
  ]
  
  depends_on = [railway_service.codeserver]
}

resource "railway_tcp_proxy" "codeserver_proxy" {
  environment_id = "c7b6f1b3-bfcc-4e21-ab76-fe900a62d432"
  service_id     = railway_service.codeserver.id
  application_port           = 13337

  depends_on = [railway_service.codeserver]
}

# code-server
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = "https://${railway_tcp_proxy.codeserver_proxy.domain}:${railway_tcp_proxy.codeserver_proxy.proxy_port}/?folder=/home/coder"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "https://${railway_tcp_proxy.codeserver_proxy.domain}:${railway_tcp_proxy.codeserver_proxy.proxy_port}/healthz"
    interval  = 3
    threshold = 10
  }
}

resource "coder_metadata" "railway_url" {
  resource_id = railway_service.codeserver.id
  
  item {
    key   = "Railway URL"
    value = "${railway_tcp_proxy.codeserver_proxy.domain}:${railway_tcp_proxy.codeserver_proxy.proxy_port}"
  }

  item{
    key   = "Init Script"
    value = "run => eval $ {CODER_INIT_SCRIPT} > coder_init.log 2>&1 &"
  }
}
