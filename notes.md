# NOTES

## 1. Problem: Flutter Build Failing Due to File Locking 
<strong>Error message:</strong>
Execution failed for task ':app:cleanMergeDebugAssets'.
```
> java.io.IOException: Unable to delete directory '...\build\app\intermediates\assets\debug\mergeDebugAssets'
Failed to delete some children. This might happen because a process has files open or has its working directory set in the target directory.
```
<br>

<strong>Root cause:</strong>
The Flutter project was stored inside a OneDrive-synced folder (C:\Users\srish\OneDrive\Documents\). OneDrive syncs files in the background by holding them open, which prevents Flutter's build tool (Gradle) from deleting and rebuilding temporary files in the build/ folder as it needs to. <br>

<strong>Solutions tried:</strong>
a. Pausing OneDrive sync — did not work because the files were already locked from previous sync activity <br>
b. Restarting the laptop — did not work, files remained locked <br>
c. Moving project to C:\Users\srish\Documents\ — did not work because Documents is still inside OneDrive's watch zone on Windows by default <br>
d. Moving project to C:\Projects\biblo\ — correct move, fully outside OneDrive's reach, but old locked build files came along with the move <br>
e. Force deleting the locked folders using PowerShell — this worked:

```
Remove-Item -Recurse -Force "C:\Projects\biblo\frontend\build"
Remove-Item -Recurse -Force "C:\Projects\biblo\frontend\.dart_tool"
Remove-Item -Recurse -Force "C:\Projects\biblo\frontend\ios\Flutter\ephemeral"
Remove-Item -Recurse -Force "C:\Projects\biblo\frontend\macos\Flutter\ephemeral"
```
<br>

<strong>Final resolution:</strong>
Project moved to C:\Projects\biblo\ and locked build folders force deleted. Flutter can now build successfully. <br>

<strong>Lesson learned:</strong>
Never store a Flutter project inside a cloud-synced folder (OneDrive, Google Drive, Dropbox). Always keep Flutter projects in a plain local directory like C:\Projects\.

## 2. Not able to start or "cold boot" the Android emulator due to the pop-up message "Medium Phone API 36.1 is already running as process 26564."

If the Android emulator is stuck and you're not able to reboot it and seeing the above error message, then run the following command in your Window terminal to kill the process:
```
taskkill /F /PID 26564
```
Expected output:
```
SUCCESS: The process with PID 26564 has been terminated.
```
## 3. Explanation of the initial bare minimum backend code being used

### a. main.py
```
from fastapi import FastAPI app = FastAPI() @app.get("/") def root(): return {"message": "Biblo backend running"}
```

Here, this is what the different lines actually mean: <br>
#### i. Importing the FastAPI class from the FastAPI framework 
```
from fastapi import FastAPI
```
* FastAPI is the core object that represents your web application
* Without this, you have no server, no routes, nothing

#### ii. Creating an instance of your web application
```
app = FastApi()
```
* ```app``` is now your entire backend
* Every route, middleware, config → attaches to this object

#### iii. Using a decorator
```
@app.get("/")
```
* Translation: “When someone sends a GET request to /, run the function below”
* Break it down: 
  * @ → modifies the function below it 
  * app.get(...) → defines an HTTP GET endpoint 
  * "/" → root URL (homepage of your API) 

#### iv. Defining the function that runs when / is hit
```
def root():
    return {"message": "Biblo backend running"}
```
* Function name (root)
  * Doesn’t matter to the user
  * Only used internally
* Return value
```
{"message": "Biblo backend running"}
```
This is a Python dictionary → FastAPI automatically converts it to JSON

Response sent to browser:
```
{
"message": "Biblo backend running"
}
```
This is powerful because you didn’t:

* Write JSON manually ❌
* Handle headers ❌
* Convert data ❌

FastAPI does it for you. ✅

#### v. Full Flow (what actually happens)

* You run:
```
python -m uvicorn main:app --reload
```
* Uvicorn starts your server

* A request comes in:
```
GET /
```
* FastAPI:
  * Matches ```/```
  * Sees it’s a ```GET``` route
  * Calls ```root()```

* ```root()``` returns a dictionary

* FastAPI:
  * Converts it to JSON
  * Sends it back


