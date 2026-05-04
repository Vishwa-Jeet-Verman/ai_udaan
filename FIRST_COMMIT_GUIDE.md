# First Commit Guide

## ✅ Pre-Commit Checklist

Before making your first commit, verify:

### 1. Sensitive Files Are Ignored
```bash
# Check if .env files are ignored
git check-ignore -v backend/.env frontend/.env

# Should output:
# backend/.gitignore:88:.env      backend/.env
# frontend/.gitignore:9:*.env     frontend/.env
```

### 2. Check Git Status
```bash
git status

# Should NOT show:
# - backend/.env
# - frontend/.env
# - backend/node_modules/
# - frontend/.dart_tool/
# - Any user uploads
```

### 3. Review What Will Be Committed
```bash
git status

# Should show:
# - Source code files
# - .gitignore files
# - .env.example files
# - Documentation files
# - Configuration files
```

## 🚀 Making the First Commit

### Step 1: Add All Files
```bash
git add .
```

### Step 2: Verify What's Staged
```bash
git status

# Review the list carefully
# Make sure no sensitive files are included
```

### Step 3: Check Ignored Files
```bash
git status --ignored

# Should show:
# - backend/.env
# - frontend/.env
# - backend/node_modules/
# - frontend/.dart_tool/
```

### Step 4: Create Initial Commit
```bash
git commit -m "Initial commit: AI UDAAN LMS with payment integration

- Add Flutter frontend with multi-platform support
- Add Node.js/Express backend with Moodle integration
- Add Razorpay payment gateway integration
- Add authentication and authorization
- Add messaging and notification system
- Add comprehensive documentation
- Configure .gitignore for security"
```

### Step 5: Push to GitHub
```bash
# Push to main branch
git push -u origin main
```

## 📋 What's Being Committed

### ✅ Source Code
- Frontend (Flutter/Dart)
- Backend (Node.js/Express)
- Services and utilities

### ✅ Configuration
- .gitignore files
- .env.example files
- Package configuration files

### ✅ Documentation
- README.md
- API documentation
- Setup guides
- Payment integration docs

### ✅ Assets
- Sample course images
- App icons
- Splash screens

## ❌ What's NOT Being Committed

### 🔒 Sensitive Data
- .env files (contains secrets)
- API keys and tokens
- Database credentials
- Payment gateway secrets

### 📦 Dependencies
- node_modules/
- .dart_tool/
- Build directories

### 📁 User Content
- Uploaded avatars
- User files
- Temporary files

### 💻 Development Files
- IDE settings
- OS files
- Log files

## 🔍 Verification After Push

### 1. Check GitHub Repository
Visit: https://github.com/Vishwa-Jeet-Verma/ai_udaan

Verify:
- [ ] README.md is displayed
- [ ] .env files are NOT visible
- [ ] node_modules/ is NOT visible
- [ ] Source code is visible
- [ ] Documentation is visible

### 2. Clone in New Directory (Test)
```bash
cd /tmp
git clone https://github.com/Vishwa-Jeet-Verma/ai_udaan.git test-clone
cd test-clone

# Verify .env files don't exist
ls backend/.env  # Should not exist
ls frontend/.env  # Should not exist

# Verify .env.example files exist
ls backend/.env.example  # Should exist
ls frontend/.env.example  # Should exist
```

## 🚨 If Something Goes Wrong

### If .env Files Were Committed

**CRITICAL**: Immediately rotate all credentials!

1. **Rotate Credentials**
   - Change Razorpay keys
   - Change JWT secret
   - Change Moodle tokens
   - Change email passwords

2. **Remove from Git**
   ```bash
   git rm --cached backend/.env frontend/.env
   git commit -m "Remove .env files from tracking"
   git push origin main
   ```

3. **Clean History (if needed)**
   ```bash
   # WARNING: This rewrites history
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch backend/.env frontend/.env" \
     --prune-empty --tag-name-filter cat -- --all
   
   git push origin --force --all
   ```

### If Large Files Were Committed

```bash
# Remove large file
git rm --cached path/to/large/file

# Add to .gitignore
echo "path/to/large/file" >> .gitignore

# Commit
git commit -m "Remove large file from tracking"
git push origin main
```

## 📝 Commit Message Guidelines

### Good Commit Messages
```bash
✅ "Add Razorpay payment integration"
✅ "Fix authentication bug in login flow"
✅ "Update course enrollment API"
✅ "Add dark mode support"
```

### Bad Commit Messages
```bash
❌ "Update"
❌ "Fix bug"
❌ "Changes"
❌ "WIP"
```

### Commit Message Format
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Example:**
```bash
git commit -m "feat: Add Razorpay payment integration

- Implement order creation endpoint
- Add payment verification
- Integrate with Moodle enrollment
- Add email notifications

Closes #123"
```

## 🎯 Next Steps After First Commit

1. **Set Up Branch Protection**
   - Go to GitHub repository settings
   - Enable branch protection for `main`
   - Require pull request reviews

2. **Add Collaborators**
   - Go to Settings > Collaborators
   - Add team members

3. **Set Up CI/CD** (Optional)
   - GitHub Actions
   - Automated testing
   - Automated deployment

4. **Create Development Branch**
   ```bash
   git checkout -b develop
   git push -u origin develop
   ```

5. **Set Up Issue Templates**
   - Bug report template
   - Feature request template

## 📚 Additional Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)

## ✅ Success Checklist

After first commit:
- [ ] Code is on GitHub
- [ ] .env files are NOT in repository
- [ ] README is visible
- [ ] Documentation is accessible
- [ ] Team can clone and setup
- [ ] All secrets are safe
- [ ] .gitignore is working

---

**Remember**: Once code is pushed, it's public (if public repo). Always verify before pushing!
