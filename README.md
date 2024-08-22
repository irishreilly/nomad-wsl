# Nomad Overview & WSL Example

This guide provides an overview of Nomad, which is a workload scheduler and orchestrator from Hashicorp, along with a sample dev installation for WSL2. Nomad is similar to Kubernetes, the popular container orchestration system originally created by Google, however Nomad can run both containerized and non-containerized applications on-prem or in the cloud. In addition to Docker, other Nomad task drivers include Java, exec, raw_exec, and QEMU for VMs. Additional benefits are that it's a relatively simple installation, it makes efficient use of hardware resources through bin packing, it's API-driven, and it can run both batch jobs and long-lived services.

This example highlights a local, single-node server using an Ubuntu distribution for WSL2 on Windows 11. It includes a simple job definition that you can deploy through the CLI or Web UI, and that references the containerized Python microservice provided. Note, a similar Nomad installation can be done using native Windows, MacOS, or Linux. For more extensive detail on Nomad, refer to the [Hashicorp Nomad Documentation](https://developer.hashicorp.com/nomad/docs).

## Prerequisites

* Ensure you have a Windows 11 machine with ample memory and multiple CPUs.  
* Install [WSL2 for Windows](https://learn.microsoft.com/en-us/windows/wsl/install) and configure a recent Ubuntu distribution as the default.
* Install [Docker Desktop for Windows](https://docs.docker.com/desktop/wsl/) and configure it to use WSL2 as opposed to Hyper-V.
* In Docker Desktop's settings set WSL integration under 'General' and 'Ubuntu' integration under Resources.
* Ensure the Docker install added your Windows wsluser to the 'docker' group for Ubuntu (/etc/group).

## Getting Started

### Nomad Infrastructure

* Launch a CMD window as admin (right click it) then execute wsl, assuming you set Ubuntu as your default distro.
* The infra/nomad-install.sh script in this repo can then be executed from within the Ubuntu distribution.
* If problems arise, review the logs that show up in the console window. Use another window to troubleshoot.
* Note that you can view your Linux distribution's file system through Windows Explorer when working with files.
* Once Nomad is installed you can launch it using the following command (note the need for sudo given Docker on WSL):
```
sudo nomad agent -dev -bind=0.0.0.0
```

### Sample Microservice Container Image

This repo includes a Dockerfile you can run to create a local image of a microservice, which is comprised of a sample Python HTTP application running on Alpine Linux. You can execute the following Docker command from the src/ folder to create the image:
```
docker build -t microservice:1.0.1 .
```
The image will start up as a container that runs Python as a nonroot user on port 8080. You can test it locally via Docker prior to deployment on Nomad using the following command. Note, when you deploy it in Nomad, it will find the image in the local repo, which it checks prior to the default of Dockerhub:
```
docker run -p 8080:8080 -dit microservice:1.0.1 
```

### Microservice Deployment in Nomad via a Job Definition

You can interact with Nomad through the 'nomad' CLI, the API, or the Web UI. Once you have Nomad running, you can access the latter via http://localhost:4646 through a browser. To deploy through the Web UI, navigate to Jobs / Run Job / Upload File and select the microservice.hcl provided within this repo. Select that file, choose Plan to ensure the dry run is successful, and then deploy accordingly. Alternately, you can use the CLI and run the following command:

```
nomad run microservice.hcl 
```

## Security Considerations

* If user credentials or other sensitive data are added, end-to-end encryption is recommended using TLS at a load balancer and a TLS listener in the application itself.
* During the development process the use of a code quality tool that also scans for security issues is recommended, along with a scanner for the image once it's built.
* Regular security scans are recommended for the Nomad servers and clients, in addition to the endpoint of each application. Any RASP tool or agent would be good too.
* Harden the operating system of any machine on which Nomad runs to enhance security. Remove unecessary software and use systems such as AppArmor, SELinux, and Seccomp.
* Avoid the use of untrusted Docker images and untrusted code. If you need to run such code consider a more secure container runtime like gVisor or Kata for sandboxing.
* Incorporate security headers into applications, such as X-XSS-Protection, and along those lines, consider the use of CORS for integration and security purposes. 
* Always leverage secure networking, isolate apps via separate subnets (e.g. internal vs external or sensitive vs nonsensitive) and implement proper firewalls and rules. 

* Security is all about layers, and leveraging features that provide defense in depth with Nomad is highly recommended, particularly for sensitive or external applications.
  * Note that Nomad is NOT considered secure by default, so a number of recommendations are provided to harden the infrastructure based on needs.
  * Nomad should be launched on machines without the dev option for test and production. Typically servers and clients would run on separate machines too.
  * mTLS can be used to provide mutual authentication through TLS, certificates, and two-way authN, which would prevent a variety of issues.
  * ACLs can be configured to authorize authenticated connections through tokens and policies that are comprised of rules and provide capabilities.
  * Consider single sign-on integration since Vault now supports OIDC and the use of Auth0 as an identity provider to centralize access management.
  * Namespaces provide logical isolation within multi-tenant clusters to control access and provide isolation for workloads and configuration.
  * In the Enterprise version of Nomad you can also leverage Sentinel (policy-as-code) to augment the native ACL system and provide more granular security.
  * The Enterprise edition also has resource quotas that can be configured to manage limits for namespace access to underlying hardware resources. 
  * In recent versions you can run Nomad through unprivileged user accounts to limit access to the underlying system, which is a common recommendation.
  * Consider using a system such as Vault to rotate credentials on a regular basis for secrets as well as the credentials used by the Nomad agents.
  * Disable any task drivers in Nomad that aren't required to prevent use and also avoid any bugs or security issues that may be discovered in those.
  * Integrate a service mesh such as Consul to control access and optimize load balancing; consider Consul Connect to encrypt service-to-service communication.

* Hashicorp Vault can be leveraged as a secure store for secrets, credentials, and keys, and such a system should be leveraged for enterprise use.
  * Secrets can be isolated through a heirarchy such as project/environment and then policies can be applied accordingly to limit access to each project.
  * Everything in Vault is path-based, and each path corresponds to an operation or secret, so policies can be configured for operations with specific secrets.
  * Once authN takes place via username/password or keys, policies (i.e. named ACL rules) dictate access and a client token is generated for subsequent requests.
  * Namespaces can be created to isolate environments within Vault so each organization, team, or app can manage and access secrets securely and independently.
  * Recent versions of Vault also support cross namespace secret sharing through group policies to reduce the overhead and burden on applications and teams.
  * An organized structure could be a namespace for a company, and within that, namespaces for each dept or team, followed by apps, each with its own secrets.
    * e.g. mycompany/legal/compliance-app or mycompany/hr/onboarding-app
    * Consider org structure, self-service, auditing, and the secrets engine itself

## Performance, Reliability, and Scalability

* Servers and clients should have adequate hardware resources as outlined in the vendor documentation.
  * A production server should have at least 4 cores, 16 GB RAM, 40 GB of fast disk, and significant network bandwidth.
  * Install multiple servers and clients in a cluster for the purpose of high availability.
* For enterprise production environments the recommendation is to have 3 - 5 servers, along with numerous clients.
  * A good practice is to have a cluster in at least 2 different regions for the purpose of disaster recovery.
  * Consul is recommended to provide features such as automatic clustering, service discovery, and dynamic configuration.
* For jobs / tasks, it's often wise to run 2 or more of each on different nodes for HA through affinity settings in the job definition.
* To scale a job you can run the command 'nomad job scale [job] [group-if-more-than-1] [count]'.
* Automatically scale a cluster or job, or dynamically size and app by installing the Nomad Autoscaler and leveraging an APM system.
  * Be sure to configure Nomad for telemetry and integrate it with your metrics system as outlined in the [Hashicrop doc](https://developer.hashicorp.com/nomad/tools/autoscaling).
  * Include a scaling block with a policy in the job definition or add a policy file on disk to configure app autoscaling.
  * Here's an example of a scaling block based on connections, which would be added to the task group in the job definition:
```
    scaling {
      min     = 2
      max     = 10
      enabled = true

      policy {
        evaluation_interval = "5s"
        cooldown            = "1m"

        check "active_connections" {
          source = "prometheus"
          query  = "scalar(open_connections_example_cache)"

          strategy "target-value" {
            target = 10
          }
        }
      }
    }
```

## Observability & Alerting

* Nomad server and client agents provide a wide range of runtime metrics for themselves, the cluster, and the allocation being run.
  * Telemetry data is captured at 1 second intervals and includes gauges, counters, and timers.
  * Data can be fetched from the /v1/metrics API, a USR1 signal to the Nomad process, or through forwarding.
    * Common forwarding configurations include Prometheus, DataDog, Circonus, and statsd monitoring.
    * Hashicorp recommends the configuration of alerting through the monitoring provider you implement.
* For KPIs, monitor memory, CPU, disk, and network use, which all scale linearly with cluster size and scheduling throughput. 
* Performance metrics can be monitored for scheduling, capacity, resource consumption, jobs and tasks, runtime, and federation (Serf).

## Troubleshooting Suggestions

* When building a microservice, you can work with it manually inside of a container to pinpoint dependencies and configuration.
  * Once the application is containerized via a Dockerfile, you can use 'docker logs [containerid]' to troubleshoot startup issues.
  * Consider installing network tools at the OS level in order to run commands such as 'netstat -an |grep LISTEN' to see listeners.
  * Install both curl and wget to help troubleshoot requests from the command-line, in addition to using those for the Nomad install.
* If you have any trouble running Nomad, ensure the install output was clean and also review the console output from Nomad in detail.
* When getting started with job definitions, you can access Jobs from the UI and run a sample job from a template to test Nomad.
* If a deployment fails, review the console log to help debug the issue, and review any app logs if the app fails to start.
* Ensure the task driver for the target deployment is healthy via the UI by choosing Clients and then clicking on the client link.

## Authors and Contact Information

Contributor names and contact info

Paul Reilly - [LinkedIn Profile](https://linked.com/in/reilly-paul)

## Version History

* 0.1
    * Initial Release

## Acknowledgments

Inspiration and documentation
* [Hashicorp Nomad Documentation](https://developer.hashicorp.com/nomad/docs)
* [Hashicorp Nomad Blog Articles](https://www.hashicorp.com/blog/products/nomad)
* [Hashicorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
* [Hashicorp Consul Documentation](https://developer.hashicorp.com/consul/docs)

