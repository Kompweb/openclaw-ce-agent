# Security Policy

## Supported Versions

Security updates are provided for the following versions of OpenClaw:

| Version | Supported          |
| ------- | ------------------ |
| 5.1.x   | ✅                 |
| 5.0.x   | ❌                 |
| 4.0.x   | ✅                 |
| < 4.0   | ❌                 |

> If you're unsure which version you're on, include the output of `openclaw --version` (or the equivalent) in your report.

---

## Reporting a Vulnerability

### Please **do not** report security issues via public GitHub issues.

Instead, report privately using one of the options below:

- **Preferred:** GitHub **Private Vulnerability Reporting** (Security tab → “Report a vulnerability”)
- **Email:** `security@openclaw.org` (replace with your real address)
- **If email is not available:** Direct message a maintainer listed in `MAINTAINERS.md`

### What to include
To help us triage quickly, please include:

- A clear description of the issue and impact
- Steps to reproduce (proof-of-concept is welcome, but keep it minimal)
- Affected versions / environments
- Any logs, stack traces, or relevant config snippets (redact secrets)
- Whether the issue is exploitable remotely / requires auth / requires user interaction

### Response timeline (what you can expect)
- **Acknowledgement:** within **2 business days**
- **Initial triage:** within **5 business days**
- **Fix or mitigation plan:** typically within **14 business days**, depending on severity/complexity

### Coordinated disclosure
We support coordinated disclosure. If you plan to publish details, please give us a reasonable window to ship a fix first. We’ll work with you on timing and credit.

---

## Severity & Handling

We generally use this severity model:

- **Critical:** RCE, auth bypass, major data exposure
- **High:** privilege escalation, significant sensitive data leakage
- **Medium:** limited data exposure, DOS with realistic impact
- **Low:** minor hardening issues, unlikely impact

### Hotfix policy
- **Critical/High:** patch release and advisory as soon as a fix is validated
- **Medium/Low:** fixed in the next scheduled release (unless risk is higher than expected)

---

## Security Best Practices (Project Defaults)

OpenClaw aims to ship with these baseline protections:

- Secrets must not be stored in the repo; CI blocks known secret patterns
- Dependencies are monitored and updated regularly
- Production builds should run with least privilege and strict network egress where possible
- Audit logging for auth events and admin actions (where applicable)
- Secure defaults: strong TLS, sane timeouts, input validation, and rate limiting where relevant

---

## Safe Harbor

We will not pursue legal action against researchers who:
- Make a good-faith effort to avoid privacy violations and disruption
- Only test against systems they own or are authorized to test
- Report issues promptly and avoid public disclosure before a fix is available
