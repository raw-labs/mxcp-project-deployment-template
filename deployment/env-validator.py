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
        with open(script_path, 'r') as f:
            content = f.read()
            
        # Find the for loop that builds runtime vars
        pattern = r'for var in ([A-Z_\s]+); do'
        match = re.search(pattern, content)
        if match:
            vars_str = match.group(1)
            return vars_str.split()
        return []
    
    def extract_workflow_env(self, workflow_path):
        """Extract env: block from deploy.yml"""
        with open(workflow_path, 'r') as f:
            content = yaml.safe_load(f)
            
        return content.get('env', {})
    
    def extract_mxcp_config_vars(self, config_path):
        """Extract ${VAR} references from mxcp-user-config.yml"""
        with open(config_path, 'r') as f:
            content = f.read()
            
        # Find all ${VAR_NAME} patterns
        pattern = r'\$\{(\w+)\}'
        return list(set(re.findall(pattern, content)))
    
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
        mxcp_vars = self.extract_mxcp_config_vars('deployment/mxcp-user-config.yml.template')
        config_env = self.extract_config_env_vars('deployment/config.env.template')
        
        # Validation 1: Runtime vars in Docker labels vs deploy-app-runner.sh
        print("1️⃣ Checking runtime variables (Docker labels vs deploy script)...")
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
            if var not in deploy_vars:
                self.errors.append(f"Variable ${{{var}}} used in mxcp-user-config.yml but not passed by deploy-app-runner.sh")
        
        # Validation 3: CI/CD vars properly documented
        print("3️⃣ Checking CI/CD variables...")
        cicd_vars = ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'MXCP_DATA_ACCESS_KEY_ID', 'MXCP_DATA_SECRET_ACCESS_KEY']
        for var in cicd_vars:
            if var in workflow_env and var not in docker_labels['cicd']:
                self.warnings.append(f"CI/CD variable {var} used but not documented in Docker labels")
        
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
