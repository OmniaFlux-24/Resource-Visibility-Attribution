\# Secrets Management Policy



\## 1. Principle of Zero Trust

No secret, credential, API key, or private token shall ever be committed to the RVA repository. All secrets must be managed through a dedicated secrets manager.



\## 2. Development Environment

\- Developers MUST use the `.env.example` file as a template.

\- The actual `.env` file is strictly excluded via `.gitignore`.

\- Local secrets must be rotated if accidentally committed (see Incident Response below).



\## 3. CI/CD Pipeline (GitHub Actions)

\- All production and staging secrets are stored in \*\*GitHub Secrets\*\* (Settings > Secrets and variables > Actions).

\- Secrets are injected into workflows via the `secrets:` context.

\- Example: `${{ secrets.DATABASE\_URL }}`



\## 4. Production Environment

\- \*\*AWS Secrets Manager\*\* is the canonical source of truth for production credentials.

\- Secrets are prefixed: `/rva/production/` (e.g., `/rva/production/database\_url`).

\- Application code retrieves secrets at runtime via the AWS SDK.

\- Secrets are automatically rotated every 90 days.



\## 5. Incident Response: Accidental Commit

If a secret is accidentally committed:

1\. \*\*IMMEDIATELY\*\* rotate the compromised credential.

2\. Remove the secret from Git history using `git filter-repo` or BFG Repo-Cleaner.

3\. Force-push the cleaned history.

4\. File a security incident report.



\## 6. Approved Secrets Managers

\- \*\*Development/CI:\*\* GitHub Secrets

\- \*\*Staging/Production:\*\* AWS Secrets Manager

\- \*\*Future Consideration:\*\* HashiCorp Vault for multi-cloud environments

