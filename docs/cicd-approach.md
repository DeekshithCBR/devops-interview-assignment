# CI/CD Approach

The pipeline leverages GitHub Actions and includes the following stages:

1. **Build** – compile the Java service using Gradle and run unit tests.
2. **Integration tests & security scan** – ensure the application works
   end-to-end and has no vulnerable dependencies.
3. **Push to ECR** – containerize the application and push to AWS ECR
   using SHA-tagged images.
4. **Deploy to staging** – update the staging EKS cluster automatically.
5. **Manual approval** – a gate requiring human sign-off before
   production.
6. **Deploy to production** – upgrade Helm chart in the production
   cluster.  Rollbacks and failure notifications are handled automatically.

`deploy.py` provides a lightweight CLI for manual invocation or for
integration with other systems.  It supports deploy/rollback/status
commands, health checks, and logging.

Notifications on failure are sent to Slack, and the workflow includes a
`rollback` job that triggers on job failure.

Secrets (AWS roles, Slack webhook) are stored in GitHub Secrets.  The
pipeline is branch-aware and runs on pushes to `main`/`develop-*`.
