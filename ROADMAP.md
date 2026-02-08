# Fiutami Infrastructure Roadmap

## Current State
- Docker Compose for local/stage/prod environments
- GitHub Actions CI/CD pipelines
- SSH-based deployment to VPS

## Planned Improvements

### Phase 1: CI/CD Enhancement
- [ ] Convert workflows to reusable templates
- [ ] Add health check workflow
- [ ] Implement blue-green deployment

### Phase 2: Monitoring
- [ ] Add Prometheus metrics
- [ ] Configure Grafana dashboards
- [ ] Set up alerting (PagerDuty/Slack)

### Phase 3: Security
- [ ] Implement secrets rotation
- [ ] Add container scanning
- [ ] Configure SAST/DAST in CI

### Phase 4: Scalability (Future)
- [ ] Kubernetes manifests
- [ ] Helm charts
- [ ] Terraform modules for cloud resources
