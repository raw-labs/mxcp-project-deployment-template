#!/bin/bash
set -e

# Squirro: Merge Updates from RAW Script
# This script safely merges updates from RAW's repository while preserving Squirro's workflows

echo "🔄 Merging updates from RAW Labs repository..."

# Check if we're in a Squirro-configured repository
if [ ! -f ".github/.squirro-configured" ]; then
    echo "❌ Error: This repository doesn't appear to be configured for Squirro"
    echo "   Run .squirro/setup-for-squirro.sh first, or check if you're in the right directory"
    exit 1
fi

# Check if upstream remote exists
if ! git remote | grep -q "upstream"; then
    echo "🔗 Adding upstream remote..."
    # Replace with your RAW Labs project repository
    git remote add upstream https://github.com/raw-labs/YOUR-PROJECT-mxcp-server.git
fi

# Fetch latest from upstream
echo "📡 Fetching latest changes from RAW..."
git fetch upstream

# Show what's new
echo ""
echo "📊 Changes available from RAW:"
git log --oneline HEAD..upstream/main | head -10
if [ $(git log --oneline HEAD..upstream/main | wc -l) -gt 10 ]; then
    echo "   ... and $(( $(git log --oneline HEAD..upstream/main | wc -l) - 10 )) more commits"
fi
echo ""

# Check if there are any changes
if [ $(git log --oneline HEAD..upstream/main | wc -l) -eq 0 ]; then
    echo "✅ Already up to date with RAW!"
    exit 0
fi

# Ask for confirmation
read -p "🤔 Proceed with merge? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "❌ Merge cancelled"
    exit 1
fi

# Create backup branch
BACKUP_BRANCH="backup-before-merge-$(date +%Y%m%d-%H%M%S)"
echo "💾 Creating backup branch: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH"

# Attempt merge
echo "🔀 Merging RAW changes..."
if git merge upstream/main; then
    echo "✅ Merge successful!"
else
    echo "⚠️  Conflicts detected during merge!"
    echo ""
    echo "🔧 Auto-resolving common conflicts..."
    
    # Preserve Squirro workflows if there's a conflict
    if [ -f ".github/workflows.raw-backup" ] && git status --porcelain | grep -q ".github/workflows"; then
        echo "   🛡️  Preserving Squirro workflows..."
        git checkout --ours .github/workflows
        git add .github/workflows
        echo "   ✅ Squirro workflows preserved"
    fi
    
    # Preserve Squirro profile in mxcp-site.yml if there's a conflict
    if git status --porcelain | grep -q "mxcp-site.yml"; then
        echo "   🛡️  Checking mxcp-site.yml profile..."
        if grep -q "profile: prod" mxcp-site.yml; then
            sed -i 's/profile: prod/profile: squirro/' mxcp-site.yml
            echo "   ✅ Restored Squirro profile"
        fi
        git add mxcp-site.yml
    fi
    
    # Check if conflicts are resolved
    if git status --porcelain | grep -q "^UU\|^AA\|^DD"; then
        echo ""
        echo "❌ Some conflicts still need manual resolution:"
        git status --porcelain | grep "^UU\|^AA\|^DD"
        echo ""
        echo "📝 Manual steps needed:"
        echo "   1. Resolve the above conflicts manually"
        echo "   2. git add <resolved-files>"
        echo "   3. git commit"
        echo ""
        echo "🔄 Or to abort the merge:"
        echo "   git merge --abort"
        echo "   git checkout $BACKUP_BRANCH  # to restore previous state"
        exit 1
    else
        echo "🎉 All conflicts auto-resolved!"
        git commit -m "Merge updates from RAW Labs

- Merged upstream/main from RAW Labs MXCP project
- Preserved Squirro-specific configurations
- Auto-resolved workflow and profile conflicts"
    fi
fi

echo ""
echo "✅ Merge completed successfully!"
echo ""
echo "📝 Summary:"
echo "   - Backup created: $BACKUP_BRANCH"
echo "   - RAW updates merged"
echo "   - Squirro configurations preserved"
echo ""
echo "🧪 Recommended next steps:"
echo "   1. Test the updated system:"
echo "      just validate-config"
echo "      just test-all"
echo "   2. Run your deployment pipeline to verify everything works"
echo "   3. If issues arise, restore from backup:"
echo "      git reset --hard $BACKUP_BRANCH"
echo ""
