# 🔒 CampusHub Security Policy

Welcome to the **CampusHub Security Policy**.

The security of our users, contributors, and educational institutions is our highest priority.

If you discover a security vulnerability, please report it responsibly following the guidelines below.

---

# Supported Versions

| Version | Supported |
|----------|-----------|
| 1.x | ✅ |
| 0.x (Development) | ✅ |
| Older Releases | ❌ |

Only the latest development branch and current stable release receive security updates.

---

# Reporting a Vulnerability

Please **do not create a public GitHub issue** for security vulnerabilities.

Instead:

1. Prepare a detailed report.
2. Include reproduction steps.
3. Include affected versions.
4. Include screenshots or logs if applicable.
5. Suggest a fix if possible.

Send the report privately to the project maintainers.

The report should include:

- Vulnerability description
- Impact
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment
- Proof of Concept (if safe)

---

# Responsible Disclosure

We ask researchers to:

- Give maintainers reasonable time to investigate.
- Avoid public disclosure until a fix is available.
- Avoid accessing or modifying data that does not belong to you.
- Avoid disrupting production services.

We appreciate responsible security research.

---

# Security Response Process

When a report is received:

1. Acknowledge the report.
2. Reproduce the issue.
3. Assess severity.
4. Develop a fix.
5. Review the patch.
6. Release the update.
7. Publish a security advisory if appropriate.

---

# Authentication

CampusHub uses:

- JWT Access Tokens
- Refresh Tokens
- Secure Password Hashing (Argon2id)

Passwords are never stored in plain text.

---

# Authorization

CampusHub follows **Role-Based Access Control (RBAC)**.

Roles include:

- Student
- Faculty
- Placement Officer
- Admin

Every protected endpoint validates both authentication and authorization.

---

# Password Policy

Recommended minimum:

- At least 8 characters
- Uppercase letter
- Lowercase letter
- Number
- Special character

Passwords should never be logged or returned in API responses.

---

# Secrets Management

Never commit:

- JWT secrets
- Database passwords
- ImageKit keys
- Firebase credentials
- API tokens

All secrets must be stored using environment variables.

Example:

```env
DATABASE_URL=
JWT_ACCESS_SECRET=
JWT_REFRESH_SECRET=
IMAGEKIT_PUBLIC_KEY=
IMAGEKIT_PRIVATE_KEY=
IMAGEKIT_URL_ENDPOINT=
FIREBASE_SERVER_KEY=
```

`.env` files must be listed in `.gitignore`.

---

# API Security

Every protected request must include:

```
Authorization: Bearer <access_token>
```

Additional protections:

- HTTPS
- Request validation
- Rate limiting
- Security headers (Helmet)
- CORS configuration

---

# Input Validation

All incoming requests must be validated.

Recommended library:

- Zod

Validation should occur **before** business logic.

Never trust client-side validation.

---

# SQL Injection

CampusHub uses **Prisma ORM**.

Avoid:

- Raw SQL queries
- String concatenation for queries

Prefer Prisma's parameterized query APIs.

---

# Cross-Site Scripting (XSS)

Any user-generated content rendered in web interfaces should be properly escaped or sanitized.

Avoid rendering raw HTML from user input.

---

# File Upload Security

Allowed file types:

- PNG
- JPG
- JPEG
- PDF
- DOCX

Recommended limits:

- Images: 5 MB
- Documents: 20 MB

Validate:

- MIME type
- File extension
- File size

Store uploaded files outside the application server when possible (e.g., ImageKit or S3).

---

# Rate Limiting

Protect authentication and sensitive endpoints.

Examples:

- Login
- Registration
- Password reset

Recommended:

- Express Rate Limit

---

# Logging

Never log:

- Passwords
- Access tokens
- Refresh tokens
- API keys
- Personal secrets

Logs should contain only the information required for debugging.

---

# Database Security

- Use least-privilege database users.
- Restrict public access.
- Enable backups.
- Encrypt connections in production.
- Review migrations before deployment.

---

# Dependency Management

Keep dependencies up to date.

Before each release:

- Review dependency updates.
- Remove unused packages.
- Check for known vulnerabilities.

---

# Secure Development Practices

Developers should:

- Validate all input.
- Handle errors safely.
- Avoid exposing stack traces in production.
- Use prepared queries or Prisma APIs.
- Review security implications of new features.

---

# User Privacy

CampusHub should collect only the information necessary to provide its services.

Personal information should be handled in accordance with applicable privacy laws and institutional policies.

---

# Incident Response

If a serious vulnerability is confirmed:

1. Investigate immediately.
2. Develop a fix.
3. Test the fix.
4. Release a patched version.
5. Notify affected users if required.
6. Document the incident for future improvements.

---

# Security Checklist

Before every release:

- [ ] All dependencies updated
- [ ] No secrets committed
- [ ] JWT authentication verified
- [ ] Authorization checks reviewed
- [ ] Input validation implemented
- [ ] File upload validation enabled
- [ ] HTTPS configured (production)
- [ ] Error responses reviewed
- [ ] Logs checked for sensitive information
- [ ] Security tests completed

---

# Acknowledgements

We appreciate everyone who helps improve CampusHub's security through responsible disclosure and thoughtful contributions.

Security is an ongoing process, and every report helps make the platform safer for students, educators, and institutions.

---

# Contact

For security-related concerns, contact the project maintainers through the project's private security reporting channel or the contact information listed in the repository.

Thank you for helping keep CampusHub secure.
