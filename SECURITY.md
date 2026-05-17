# Security Policy

## Reporting a vulnerability

If you believe you have found a security vulnerability in this repository
or in any of the skills it ships, please report it **privately**.

- Open a [GitHub Security Advisory](https://docs.github.com/en/code-security/security-advisories)
  on this repository, **or**
- Email the maintainers listed in `.github/CODEOWNERS`.

Please **do not** open a public issue for security problems.

We will acknowledge your report within 5 business days and aim to provide
a remediation timeline within 15 business days.

## Scope

This repository contains documentation, prompts, and plugin manifests. It
does not execute untrusted code at runtime. Security-relevant concerns
include:

- Prompts or skills that could exfiltrate source code or credentials.
- Plugin/marketplace manifests pointing to untrusted external resources.
- Fixtures containing real customer data (must always be synthetic).

## Supported versions

Only the `main` branch receives security updates.

