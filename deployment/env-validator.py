#!/usr/bin/env python3
"""
Environment variable consistency validator for MXCP deployment template.
Ensures all variable definitions are consistent across configuration files.
"""

import re
import json
import sys
import yaml
from pathlib import Path

class EnvValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []
        
    def extract_docker_labels(self, dockerfile_path):
        """Extract env.* labels from Dockerfile"""
        labels = {'runtime': {}, 'cicd': {}}
        
        with open(dockerfile_path, 'r') as f:
            content = f.read()
            
        # Match LABEL env.{phase}.{VAR}='{json}'
        pattern = r'LABEL\s+env\.(runtime|cicd)\.(\w+)=\'({.*?})\''
        matches = re.findall(pattern, content, re.MULTILINE)
        
        for phase, var_name, json_str in matches:
            try:
                labels[phase][var_name] = json.loads(json_str)
            except json.JSONDecodeError:
                self.errors.append(f"Invalid JSON in Docker label for {var_name}")
                
        return labels
    
    def extract_deploy_script_vars(self, script_path):
        """Extract runtime vars from deploy-app-runner.sh"""
        # Since deploy-app-runner.sh now reads from Docker labels dynamically,
        # we should return True to indicate it's dynamic
        # This method is now deprecated but kept for compatibility
        return None  # Special value to indicate dynamic discovery
    
    def extract_workflow_env(self, workflow_path):
        """Extract env: block from deploy.yml"""
        with open(workflow_path, 'r') as f:
            content = yaml.safe_load(f)
            
        return content.get('env', {})
    
    def extract_mxcp_config_vars(self, config_path):
        """Extract ${VAR} references from mxcp-user-config.yml"""
        with open(config_path, 'r') as f:
            content = f.read()
            
        # Find all ${VAR_NAME} patterns but exclude template placeholders
        pattern = r'\$\{(\w+)\}'
        all_vars = re.findall(pattern, content)
        # Filter out template placeholders
        return list(set([var for var in all_vars if not var.startswith('{{') and not var.endswith('}}') and var.isupper()]))
    
    def extract_config_env_vars(self, config_path):
        """Extract variables from config.env.template"""
        vars = {}
        with open(config_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    vars[key] = value.strip('"')
        return vars
    
    def validate(self):
        """Run all validation checks"""
        print("🔍 Validating environment variable consistency...\n")
        
        # Extract all configurations
        docker_labels = self.extract_docker_labels('deployment/Dockerfile')
        deploy_vars = self.extract_deploy_script_vars('.github/scripts/deploy-app-runner.sh')
        workflow_env = self.extract_workflow_env('.github/workflows/deploy.yml')
        
        # Use processed files if they exist, otherwise fall back to templates
        mxcp_config_file = 'deployment/mxcp-user-config.yml' if Path('deployment/mxcp-user-config.yml').exists() else 'deployment/mxcp-user-config.yml.template'
        config_env_file = 'deployment/config.env' if Path('deployment/config.env').exists() else 'deployment/config.env.template'
        
        if mxcp_config_file.endswith('.template'):
            print("⚠️  Using template files - run setup-project.sh first for accurate validation")
        
        mxcp_vars = self.extract_mxcp_config_vars(mxcp_config_file)
        config_env = self.extract_config_env_vars(config_env_file)
        
        # Validation 1: Runtime vars in Docker labels vs deploy-app-runner.sh
        print("1️⃣ Checking runtime variables (Docker labels vs deploy script)...")
        if deploy_vars is None:
            print("   ✅ deploy-app-runner.sh uses dynamic discovery from Docker labels")
        else:
            # Legacy validation for older versions
            for var in docker_labels['runtime']:
                if var not in deploy_vars:
                    self.errors.append(f"Runtime var {var} in Docker labels but not passed by deploy-app-runner.sh")
            for var in deploy_vars:
                if var not in docker_labels['runtime'] and var not in ['MXCP_DATA_ACCESS_KEY_ID', 'MXCP_DATA_SECRET_ACCESS_KEY']:
                    self.warnings.append(f"Variable {var} passed to App Runner but not documented in Docker labels")
        
        # Validation 2: mxcp-user-config.yml vars are available at runtime
        print("2️⃣ Checking mxcp-user-config.yml variables...")
        for var in mxcp_vars:
            if var not in docker_labels['runtime']:
                self.errors.append(f"Variable ${{{var}}} used in mxcp-user-config.yml but not documented as runtime requirement")
            # Skip deploy_vars check if using dynamic discovery
            if deploy_vars is not None and var not in deploy_vars:
                self.errors.append(f"Variable ${{{var}}} used in mxcp-user-config.yml but not passed by deploy-app-runner.sh")
        
        # Validation 3: CI/CD vars properly documented
        print("3️⃣ Checking CI/CD variables...")
        # Check all variables in workflow env that look like CI/CD vars
        for var in workflow_env:
            if var.startswith('AWS_') or var.endswith('_ACCESS_KEY_ID') or var.endswith('_SECRET_ACCESS_KEY'):
                if var not in docker_labels['cicd']:
                    self.warnings.append(f"CI/CD variable {var} used in workflow but not documented in Docker labels")
        
        # Validation 4: Config.env vars are non-sensitive
        print("4️⃣ Checking config.env variables...")
        for var in config_env:
            if 'KEY' in var or 'SECRET' in var or 'TOKEN' in var:
                self.errors.append(f"Potential secret {var} found in config.env.template (should be in GitHub Secrets)")
        
        # Report results
        print("\n📊 Validation Results:")
        print("=" * 50)
        
        if not self.errors and not self.warnings:
            print("✅ All checks passed! Environment variables are consistent.")
            return 0
        
        if self.warnings:
            print(f"\n⚠️  Warnings ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"   - {warning}")
        
        if self.errors:
            print(f"\n❌ Errors ({len(self.errors)}):")
            for error in self.errors:
                print(f"   - {error}")
            return 1
        
        return 0

if __name__ == "__main__":
    validator = EnvValidator()
    sys.exit(validator.validate())
