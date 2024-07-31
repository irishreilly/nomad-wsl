job "ms" {
  type = "service"

  group "app" {
    count = 1
    network {
      port "web" {
        static = 8080
      }
    }

    service {
      name     = "ms-svc"
      port     = "web"
      provider = "nomad"
    }

    task "ms-task" {
      driver = "docker"
      config {
        image = "microservice:1.0.1"
        ports = ["web"]
      }
      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
