# Griot & Grits - Hackathon Toolkit
## Easy Setup Guide for Non-Developers

This is a development toolkit for the Griot & Grits project, which uses AI technology to help preserve minority history.

---

## What You Need to Know First

**What is this project?**
This toolkit helps you work on a web application that has three main parts:
- A website that users see (called the "Frontend")
- A server that processes information behind the scenes (called the "Backend")
- Storage systems for data and files (MongoDB for structured data, MinIO for file storage)

**Two Ways to Set This Up:**
1. **Option 1: On Your Own Computer** - Better if you have a personal laptop/desktop
2. **Option 2: On OpenShift (Cloud Platform)** - Better if you're using a work computer or prefer cloud-based development

---

## Option 1: Setting Up On Your Own Computer

### What You'll Need Installed First

Before starting, you need these programs on your computer:

1. **Git** - A tool for downloading and managing code
   - Download from: https://git-scm.com/downloads
   - Install by following the instructions for your operating system (Windows/Mac/Linux)

2. **Node.js version 18 or newer** - Software that runs JavaScript code
   - Download from: https://nodejs.org/
   - Get the "LTS" (Long Term Support) version
   - After installing, open your Terminal (Mac) or Command Prompt (Windows) and type `node --version` to confirm it's installed

3. **Python version 3.10 or newer** - A programming language
   - Download from: https://www.python.org/downloads/
   - Make sure to check "Add Python to PATH" during installation on Windows
   - After installing, type `python --version` in your Terminal/Command Prompt to confirm

4. **uv or pip** - Tools for installing Python packages
   - pip usually comes with Python automatically
   - For uv (optional, faster alternative): Visit https://docs.astral.sh/uv/ for installation

5. **make** - A tool that runs automated commands
   - Mac: Already installed
   - Windows: Install from http://gnuwin32.sourceforge.net/packages/make.htm
   - Linux: Type `sudo apt-get install make` in Terminal

### First-Time Setup Steps

**Step 1: Open Your Terminal**
- **Mac:** Open the "Terminal" app (find it in Applications > Utilities)
- **Windows:** Open "Command Prompt" or "PowerShell" (search for it in the Start menu)
- **Linux:** Open your terminal application

**Step 2: Navigate to Your Home Folder**
Type this command and press Enter:
```
cd ~
```
This takes you to your home folder (the ~ symbol means "home").

**Step 3: Download the Project**
Type this command and press Enter:
```
cd ~/rh-hackathon
```
(Note: If you haven't downloaded the project yet, you'll need to get the download link from your hackathon organizers first)

**Step 4: Run the Setup**
Type this command and press Enter:
```
make setup-local
```

What this does:
- Downloads all the necessary code files
- Installs all required software dependencies
- Sets up the storage systems (MongoDB and MinIO)
This only needs to be done once. It might take several minutes.

### Starting the Application

After the setup is complete, type this command:
```
make dev
```

This starts everything you need. You'll see text scrolling in your Terminal - that's normal! It means things are starting up.

### Accessing Your Application

Once everything is running, open your web browser (Chrome, Firefox, Safari, etc.) and visit these addresses:

1. **Main Website:** http://localhost:3000
   - This is what users would see

2. **Backend API Documentation:** http://localhost:8000/docs
   - This shows the technical documentation for how the server works

3. **MinIO Console:** http://localhost:9001
   - This is where you can see stored files

**Note:** "localhost" means "this computer" - these websites are only running on your machine.

### Helpful Commands While Running

While the application is running, open a NEW Terminal window (keep the first one running) and you can use these commands:

**Check if everything is running:**
```
make status
```

**Stop everything:**
```
make stop-services
```
Press this before closing your Terminal.

**Start again after stopping:**
```
make dev
```

**Completely reset everything (if something breaks):**
```
make clean-local
```
Warning: This removes all your stored data and downloaded files! You'll need to run `make setup-local` again afterward.

---

## Option 2: Setting Up On OpenShift (Cloud Platform)

### What You'll Need

1. **Access to an OpenShift cluster** - Your hackathon organizers will provide this
2. **make tool installed** - See instructions in Option 1 above

### Understanding OpenShift

OpenShift is a cloud platform where you can run applications without using your own computer's resources. Think of it like renting a computer in the cloud.

### First-Time Setup Steps

**Step 1: Log Into OpenShift**

First, you need to log into the OpenShift system through your Terminal:

1. Open your web browser and go to your OpenShift web console (your organizers will give you this address)
2. Click your username in the top-right corner
3. Click "Copy login command"
4. Click "Display Token"
5. Copy the command that starts with `oc login`
6. Open your Terminal and paste that command, then press Enter

**Step 2: Navigate to the Project Folder**
```
cd ~/rh-hackathon
```

**Step 3: Run the OpenShift Setup**
```
make setup-openshift
```

You'll be asked to enter your username. Type your username and press Enter.

What this does:
- Creates a personal workspace for you called "gng-yourname" (gng stands for Griot & Grits)
- Sets up a database (MongoDB)
- Sets up file storage (MinIO)
- Creates a configuration file with all your connection details

This takes a few minutes.

### Checking Your Setup

After setup completes, you can view all your information:
```
make info
```

This shows:
- The web addresses (URLs) for your services
- Login credentials
- Connection details

### Deploying Your Application Code

To actually run the website and backend server on OpenShift with automatic updates:

```
make setup-openshift-with-code
```

This will:
- Deploy your backend server (the part that processes data)
- Deploy your frontend website (the part users see)
- Set up automatic syncing so when you edit code files, the changes appear immediately
- Give you web addresses where you can access your running application

### Viewing Your Running Application

After deployment, use this command to see your web addresses:
```
make info
```

Look for lines that say:
- "Backend URL: https://backend-gng-yourname..."
- "Frontend URL: https://frontend-gng-yourname..."

Copy those URLs into your web browser to see your running application!

### Making Code Changes

Once deployed, you can edit your code files and they'll automatically sync to OpenShift:

1. Navigate to your code folder:
   ```
   cd gng-backend
   ```
   or
   ```
   cd gng-web
   ```

2. Open any file in a text editor (like Notepad, TextEdit, or VS Code)

3. Make your changes and save the file

4. Within 1 second, your changes will automatically sync to the cloud!

The application will automatically reload with your changes.

### Checking If Auto-Sync Is Running

To verify the automatic syncing is working:
```
make watch-status
```

To see what's being synced in real-time:
```
make watch-logs
```

### For Intensive Backend Development

If you're making lots of backend changes, use this special command for instant updates:
```
make watch-backend
```

This syncs your backend code both when you save files AND every 2 seconds automatically. Perfect for rapid development.

To check if it's running:
```
make watch-backend-status
```

To see what it's doing:
```
make watch-backend-logs
```

To stop it:
```
make watch-backend-stop
```

### Manual Syncing (If Automatic Isn't Working)

If you want to manually push your code changes:
```
make sync
```

Or sync specific parts:
- Backend only: `make sync-backend`
- Frontend only: `make sync-frontend`

### Viewing Your Resources

To see everything you have running in OpenShift:
```
make oc-status
```

This shows all your services, their status, and whether they're working properly.

### Viewing Logs (Troubleshooting)

If something isn't working, you can view the logs (error messages and status updates):

**Backend logs:**
```
make oc-logs-backend
```

**Frontend logs:**
```
make oc-logs-frontend
```

**Database logs:**
```
make oc-logs-mongodb
```

**Storage logs:**
```
make oc-logs-minio
```

### Starting Over (If Things Break)

If something goes wrong and you want to completely reset:

```
make clean-openshift
```

**Warning:** This deletes your entire workspace and all data! You'll need to run `make setup-openshift` again to start fresh.

If you just want to delete the workspace but keep your local configuration:
```
make delete-namespace
```

---

## Understanding the Architecture

Here's what each component does:

**Frontend (Website)**
- This is what users see and interact with
- Built with Next.js (a web framework)
- Runs on port 3000 (locally) or a web URL (on OpenShift)

**Backend (Server)**
- This processes requests, handles business logic, and talks to databases
- Built with FastAPI (a Python framework)
- Runs on port 8000 (locally) or a web URL (on OpenShift)

**MongoDB (Database)**
- Stores structured data (like user information, story records, etc.)
- Runs on port 27017

**MinIO (File Storage)**
- Stores files like audio recordings, images, documents
- Like having your own personal cloud storage
- Console runs on port 9001 (locally)

**Whisper (Optional)**
- Converts speech to text
- Only needed if you're working with audio transcription

---

## Common Tasks & Commands

### Viewing Everything At Once
```
make info
```
Shows all your URLs, passwords, and connection information in one place.

### Checking Status
**Local:** `make status`
**OpenShift:** `make oc-status`

### Stopping Services
**Local:** `make stop-services`
**OpenShift:** Services run continuously (use `make clean-openshift` to remove entirely)

### Cleaning Up Old Jobs
On OpenShift, sometimes completed tasks accumulate. Clean them up with:
```
make cleanup-jobs
```

### Getting Help
View all available commands:
```
make help
```

View common examples:
```
make examples
```

---

## Troubleshooting Common Issues

### "Port already in use" Error (Local Setup)

This means another program is using the same port.

**Fix for Mac/Linux:**
1. Find what's using the port:
   ```
   lsof -i :3000
   ```
   (Replace 3000 with whatever port is mentioned in the error)

2. Note the PID (process ID) number

3. Stop that process:
   ```
   kill -9 [PID]
   ```
   (Replace [PID] with the actual number)

**Fix for Windows:**
1. Open Task Manager (Ctrl+Shift+Esc)
2. Find and end the process using that port

### Services Won't Start (Local Setup)

1. Check what's running:
   ```
   make status
   ```

2. If things look broken, reset everything:
   ```
   make clean-local
   make setup-local
   make dev
   ```

### Can't Connect to Database (Local Setup)

Check if MongoDB is running:
```
podman logs gng-mongodb
```

If you see errors, try restarting:
```
make stop-services
make start-services
```

### Not Logged Into OpenShift

Check if you're logged in:
```
oc whoami
```

If you see an error, you need to log in again:
1. Go to your OpenShift web console
2. Click your username → "Copy login command"
3. Paste and run that command in your Terminal

### OpenShift Pods Not Running

1. Check status:
   ```
   make oc-status
   ```

2. Look for pods that say "Error" or "CrashLoopBackOff"

3. Get detailed information:
   ```
   oc describe pod [pod-name]
   ```
   (Replace [pod-name] with the actual name from the status)

4. View logs:
   ```
   make oc-logs-backend
   ```

5. If still stuck, start over:
   ```
   make clean-openshift
   make setup-openshift
   ```

### Code Changes Not Appearing (OpenShift)

1. Check if the watcher is running:
   ```
   make watch-status
   ```

2. If not running, start it:
   ```
   make watch-start
   ```

3. Or manually sync your changes:
   ```
   make sync
   ```

---

## Understanding Configuration Files

Configuration files store important settings like passwords and connection addresses.

**Local Development:**
Your settings are stored in: `~/gng-backend/.env`

**OpenShift:**
Your settings are stored in: `.env.openshift`

You don't need to edit these files manually - they're created automatically during setup.

**Important settings inside:**
- `DB_URI` - How to connect to the database
- `STORAGE_ENDPOINT` - Where files are stored
- `STORAGE_ACCESS_KEY` - Username for file storage
- `STORAGE_SECRET_KEY` - Password for file storage

---

## Optional: Adding Speech-to-Text

If your project needs to convert audio to text, you can add Whisper:

```
make deploy-whisper MODEL=base
```

**Available Models:**
- `tiny` - Fastest, least accurate (good for testing)
- `base` - Good balance (recommended)
- `small` - More accurate, slower
- `medium` - Very accurate, slow
- `large-v3` - Most accurate, very slow

Start with `base` and upgrade if you need better accuracy.

---

## Project File Structure

Here's what all the folders contain:

```
rh-hackathon/
├── scripts/          (Automated setup and deployment scripts)
├── infra/            (Infrastructure configuration for databases and services)
├── env-templates/    (Example configuration files)
├── gng-backend/      (Backend server code - appears after setup)
└── gng-web/          (Frontend website code - appears after setup)
```

You'll mainly work in `gng-backend` and `gng-web` folders.

---

## Getting Help

**View All Your Information:**
```
make info
```

**Check Application Logs:**
```
make oc-logs-backend
make oc-logs-frontend
```

**View System Events:**
```
oc get events -n gng-[yourname]
```

**Describe a Specific Resource:**
```
oc describe deployment/backend -n gng-[yourname]
```

**Contact Support:**
- Ask organizers on Slack or Discord
- Share the output of `make info` and any error messages you see

---

## Important Notes

### Automatic Namespace Detection

Most commands automatically figure out your workspace name (called a "namespace" in OpenShift). You don't need to type it every time.

Your namespace is saved in a file called `.openshift-config` during setup.

**To check your current namespace:**
```
cat .openshift-config
```

**If you need to override it:**
```
make sync NAMESPACE=gng-customname
```

### Performance Tips

For fastest code syncing during backend development:
```
make watch-backend
```

This updates your code on file save AND every 2 seconds automatically.

---

## Summary Quick Reference

**First Time Setup (Local):**
```
cd ~/rh-hackathon
make setup-local
make dev
```

**First Time Setup (OpenShift):**
```
oc login [your-cluster-url]
cd ~/rh-hackathon
make setup-openshift
make setup-openshift-with-code
```

**Daily Usage (Local):**
```
make dev          # Start everything
make status       # Check status
make stop-services # Stop when done
```

**Daily Usage (OpenShift):**
```
make info         # View all URLs and info
make watch-status # Check if auto-sync is running
make oc-logs-backend # View logs if needed
```

**Getting Help:**
```
make help         # See all commands
make info         # See all your connection details
```

---

## License

See the LICENSE file for legal details about using this code.

---

## Need More Help?

- Use `make help` to see all available commands
- Use `make examples` to see common usage patterns  
- Contact your hackathon organizers on Slack/Discord
- When asking for help, share the output of `make info` and any error messages

Good luck with your hackathon project!
