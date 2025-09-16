# Migrating Existing Projects to Template

This guide explains how to apply the template to existing MXCP projects.

## Scenario 1: Existing MXCP Project Without CI/CD

If you have an MXCP project with just the core files (`mxcp-site.yml`, `tools/`, etc.) but no deployment infrastructure:

### Steps

1. **Copy template directories to your project:**
```bash
cd your-existing-project

# Copy deployment infrastructure
cp -r /path/to/template/.github .
cp -r /path/to/template/deployment .
cp -r /path/to/template/.squirro .  # If needed for external teams

# Copy template files
cp /path/to/template/justfile.template .
cp /path/to/template/setup-project.sh .
cp /path/to/template/ENVIRONMENT.md.template .
cp /path/to/template/.gitignore .
```

2. **Run setup script:**
```bash
./setup-project.sh your-project-name
```

3. **Move your existing files if needed:**
```bash
# If you have existing docker configs, review and merge with deployment/
# If you have existing scripts, ensure they work with justfile tasks
```

4. **Configure secrets and deploy:**
```bash
# Set GitHub secrets as per ENVIRONMENT.md
git add .
git commit -m "Add deployment infrastructure"
git push origin main
```

## Scenario 2: Existing Project With Different CI/CD

If your project already has CI/CD but you want to standardize on the template:

### Steps

1. **Backup existing setup:**
```bash
# Create a backup branch
git checkout -b backup-old-cicd
git push origin backup-old-cicd
git checkout main
```

2. **Compare and merge carefully:**
```bash
# Don't blindly overwrite - compare each component:

# Compare workflows
diff -r .github/workflows /path/to/template/.github/workflows

# Compare deployment configs
diff -r deployment /path/to/template/deployment
```

3. **Selective adoption:**
```bash
# Option A: Full replacement (if you want complete standardization)
rm -rf .github deployment
cp -r /path/to/template/.github .
cp -r /path/to/template/deployment .
cp /path/to/template/justfile.template justfile.template
./setup-project.sh your-project-name

# Option B: Gradual migration
# - Keep your workflows but adopt the deployment structure
# - Or keep your Dockerfile but adopt the workflows
# - Mix and match based on your needs
```

## Scenario 3: Updating Template Components

If you already use the template but want to update specific components:

### For RAW Labs teams:
```bash
# Get latest template
cd /path/to/template
git pull origin main

# Update specific components in your project
cd /path/to/your-project
cp /path/to/template/.github/workflows/deploy.yml .github/workflows/
cp /path/to/template/deployment/Dockerfile deployment/

# Review changes
git diff
```

### For External teams (Squirro):
```bash
# Use the merge script to safely get updates
cd your-project
./.squirro/merge-from-raw.sh
```

## Component-by-Component Guide

### Essential Components (Usually Adopt)
- `.github/workflows/` - Standardized CI/CD
- `deployment/Dockerfile` - Proven container build
- `deployment/start.sh` - Health check architecture
- `justfile.template` - Modern task runner

### Customizable Components (Review First)
- `deployment/config.env.template` - Merge with your values
- `deployment/requirements.txt` - Add your dependencies
- Scripts in `scripts/` - Keep your data logic

### Optional Components
- `.squirro/` - Only if working with external teams
- `ENVIRONMENT.md.template` - Helpful but not required

## Common Patterns

### Pattern 1: Minimal Adoption
Just want the deployment to AWS App Runner:
```bash
cp -r /path/to/template/.github .
cp -r /path/to/template/deployment .
# Edit deployment/config.env with your values
```

### Pattern 2: Full Standardization
Want everything to match the template:
```bash
# Run setup script in your project
cp /path/to/template/setup-project.sh .
./setup-project.sh your-project-name
```

### Pattern 3: External Team Setup
Squirro or similar teams:
```bash
cp -r /path/to/template/.squirro .
./.squirro/setup-for-squirro.sh
```

## Validation Checklist

After migration:
- [ ] GitHub Actions workflows are in `.github/workflows/`
- [ ] Deployment configs are in `deployment/`
- [ ] `just --list` shows available tasks
- [ ] `deployment/config.env` has your AWS account details
- [ ] GitHub secrets are configured (check with `gh secret list`)
- [ ] Health check endpoint is configured (port 8000)

## Troubleshooting

### Conflicts with existing files
- Never overwrite without reviewing
- Use `diff` to compare before replacing
- Keep backups of working configurations

### Custom requirements
- The template is flexible - adapt what makes sense
- Not everything needs to be adopted
- Mix template components with your custom solutions

## Getting Help

- Review existing implementations (e.g., uae-mxcp-server)
- Contact: pavlos@raw-labs.com for guidance
- Check git history of the template for recent changes
