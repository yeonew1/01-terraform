output "alb_dns_name" {
  value       = modeul.webserver_cluster.alb_dns_name
  description = "The domain name of the load balancer"
}

